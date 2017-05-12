package Apache2::Protocol::ESMTP;
=head1 NAME

Apache2::Protocol::ESMTP - Perl extension for 

=head1 SYNOPSIS

  package My::Server;
  use base qw/Apache2::Protocol::ESMTP/;
  
  sub handler {
     my $c = shift;
     my $p = shift || My::Server->new;
     Apache2::Protocol::ESMTP::handler($c, $p);
  }

  sub CONNECT { ... };
  sub HELO { ... };
  sub EHLO { ... };
  .
  .
  .
  sub QUIT { ... };

=head1 DESCRIPTION

Apache2 ESMTP protocol base class. Out of the box this module can
carry on and SMTP conversation. However, it's up to you to make it
do anything interesting.

=head1 CONFIGURATION

=head2 Apache Configuration File

    LoadModule perl_module modules/mod_perl.so
    <VirtualHost myhost.com>
    ...
    PerlModule                   Apache2::Protocol::ESMTP 
    PerlProcessConnectionHandler Apache2::Protocol::ESMTP
    ...
    </VirtualHost>

=cut
use 5.008005;
use strict;
use warnings;

our $VERSION = '0.01';

=head1 METHODS

The following methods may be overridden by the subclass. All of the overridden
methods except HEADER, EOH and BODY must return a proper status code and
message, return($code, @msgs).  For example return(250, 'Ok', 'Your command was
successful).

=head2 CONNECT()

Gets called when a client connects to the server. By default the base class
returns (220, 'ESMTP Mail Server').

=head2 UNKNOWN($command)

Gets called if the client sends a command that is not a part of the ESMTP
protocol that we understand. By default the base class returns 
(500, "Command unrecognized: $line")

=head2 HELO($domain)

Gets called when the client sends the HELO command. $domain is the 
FQDN the client claims. By default the base class returns
(250, 'OK').

=head2 EHLO($domain)

Gets called when the client sends the EHLO command. $domain is the 
FQDN the client claims. By default the base class returns
(250, $self->client . ', pleased to meet you', 'HELP');

=head2 MAIL($env_sender)

Gets called when the client sends the MAIL command. $env_sender is 
the email address claimed by the sender of the message. By default
the base class returns (250, $self->env_sender . ', sender ok');

=head2 RCPT($env_recipient)

Gets called when the client sends the RCPT command. $env_recipient is 
the email address the message is to be delivered to. By default
the base class returns (250, $rcpt . ', recipient ok');

=head2 DATA()

Gets called when the client sends the DATA command. By default the
base class returns (354, 'Enter mail, end with "." on a line by itself');

=head2 HEADER($name, $value)

Gets called for each message header. $name is the header name and $value is the
header value. EOH is called when and line containing nothing except a <CR><LF>
is sent or when a line is sent that does not conform to the specification for
an ESMTP message header. No response is sent to the client. 

=head2 EOH()

Gets called when and line containing nothing except a <CR><LF> is sent or when
a line is sent that does not conform to the specification for an ESMTP message
header. No response is sent to the client. 

=head2 BODY($chunk)

Gets called for each chunk of data in the message body sent by the client. No
response is sent to the client.

=head2 EOM()

Gets called when the client sends a line of the message body that contains
nothing except '.<CR><LF>'. By default the base class returns 
(250, 'Message accepted for delivery');

=head2 EXPN($address)

Gets called when the client sends the EXPN command. By default the base class
returns (502, 'Sorry we don\'t allow this operation');

=head2 VRFY($address)

Gets called when the client sends the VRFY command. By default the base class
returns (252, 'Cannot VRFY user; try RCPT to attempt delivery');

=head2 NOOP()

Gets called when the client sends the NOOP command. By default the base class
returns (250, 'OK');

=head2 RSET()

Gets called when the client sends the RSET command. By default the base class
returns (250, 'OK');

=head2 HELP($command||undef)

Gets called when the client sends the HELP command. By default the base class
returns (214, 'This is SMTP::Proxy 1.0');

=head2 QUIT()

Gets called when the client sends the QUIT command. By default the base class
returns (221, 'Closing connection');

=head1 PROPERTIES

=head2 input_handle

Handle to read data from the client.

=head2 output_handle

Handle to write data to the client.

=head2 chunkmode

If set to true the next available data from the client
will be read in chunks of size B<chunksize>. If set to 
false data will be read a line at a time. The default
behaviour is to start in line mode, switch to chunkmode
after the message headers (EOH) and then switch back line
mode after the message body (EOM).

=head2 chunksize

Sets the size of the chunks of data read from the client
when B<chunkmode> is set to true.

=head2 disconnect

When set to true, the sever will close the client connection
when the current operation is complete. By default the client
connection will be shutdown when the QUIT operation has completed.

=cut

use base qw/Apache2::Protocol/;
use Apache2::ServerUtil ();
use Fcntl ':flock';
use base qw/Class::Accessor/;
__PACKAGE__->mk_accessors(qw//);

use POSIX 'strftime';

sub handler {
    my $c = shift;
    my $p = shift || Apache2::Protocol::ESMTP->new;

    $p->connecthandler(\&_connect);
    $p->default_line_handler(\&_unknown);
    $p->chunkhandler(\&_body);

    $p->register_callback(qr/^helo\s+(\S*?)?\s*$/i, \&_helo, 'protocol');
    $p->register_callback(qr/^ehlo\s+(\S*?)?\s*$/i, \&_ehlo, 'protocol');
    $p->register_callback(qr/^mail from:\s*<?(\S+?)?>?\s*$/i, \&_mail, 'protocol'); 
    $p->register_callback(qr/^rcpt to:\s*<?(\S+?)?>?\s*$/i, \&_rcpt, 'protocol');
    $p->register_callback(qr/^data\s*$/i, \&_data, 'protocol');
    $p->register_callback(qr/^expn\s+(\S+?)?\s*$/i, \&_expn, 'protocol');
    $p->register_callback(qr/^vrfy\s+(\S+?)?\s*$/i, \&_vrfy, 'protocol');
    $p->register_callback(qr/^rset\s*$/i, \&_rset, 'protocol');
    $p->register_callback(qr/^noop\s*$/i, \&_noop, 'protocol');
    $p->register_callback(qr/^help\s*(\S*?)?\s*$/i, \&_help, 'protocol');
    $p->register_callback(qr/^quit\s*$/i, \&_quit, 'protocol');
    $p->enable_callbacks('protocol');

    $p->setup_logging($c);

    Apache2::Protocol::handler($c, $p);
}

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my $self = bless($class->SUPER::new(@_), $class);

    $self->{_bodystate}   = '';
    $self->{_headername}  = '';
    $self->{_headervalue} = '';
    $self->{_seenDATA}    = 0;
    $self->{_seenHELO}    = 0;
    $self->{_seenMAIL}    = 0;
    $self->{_seenRCPT}    = 0;

    return $self;
}

sub setup_logging {
    my $self = shift;
    my $c = shift;

    my $s = $c->base_server;

    $self->{_log_level} = $s->dir_config('ESMTPLogLevel');
    if(defined $self->{_log_level}) {
	$self->{_log_filename} = $s->dir_config('ESMTPLogFileName');
	$self->{_log_filename} = Apache2::ServerUtil::server_root . '/logs/' . $self->{_log_filename}
	    unless $self->{_log_filename} =~ m@^/@;
	$self->{_log_remotehost} = $c->get_remote_host;
    }
}

sub log_ESMTP {
    my $self = shift;
    my $level = shift;
    unless (defined $self->{_log_filename}) {
        warn "Too early for logging: " . caller;
        return;
    }
    return unless defined $self->{_log_level} && $level <= $self->{_log_level};
    my $data = shift;
    my $date = strftime('%Y-%m-%d %H:%M:%S', localtime);

    open(LOG, ">>$self->{_log_filename}") or die "Can't open log $self->{_log_filename}: $!";
    flock(LOG, LOCK_EX);
    seek(LOG, 0, 2);
    $data = "$self->{_msgid} $data" if $self->{_msgid};
    $data .= " [$self->{_log_remotehost}]" if $self->{_log_remotehost};
    print LOG "$date $data\n";
    flock(LOG, LOCK_UN);
    close(LOG);
}

sub _unknown {
    my $self = shift;
    $self->send_response($self->UNKNOWN(@_));
}

sub UNKNOWN {
    my $self = shift;
    my $line = shift;
    chomp($line);
    return(500, "Command unrecognized: $line");
}

sub _header {
    my $self = shift;
    my $line = shift;
    
    if($line =~ /^([\041-\071\073-\176.]+):\s*(.+)$/) {

        my $name  = $1;
        my $value = $2;

	if($self->{_headername} ne '') {
	    $self->HEADER($self->{_headername}, $self->{_headervalue});
	}

	$self->{_headername} = $name;
	$self->{_headervalue} = $value;

	# State management
	$self->{_seenDATA} = 1;
    }
    elsif($line =~ /^(\s+.+)$/ and $self->{_headername} ne '') {
	$self->{_headervalue} .= $1;
    }
    else {
	if($self->{_headername} ne '') {
	    $self->HEADER($self->{_headername}, $self->{_headervalue});
	    $self->{_headername} = '';
	    $self->{_headervalue} = '';
	}

	$self->_eoh($line);
    }
}

sub HEADER {
}

sub _eoh {
    my $self = shift;
    my $line = shift;

    #$self->disable_callbacks('headers');
    $self->chunkmode(1);
    $self->EOH();
    $self->_body($line);
}

sub EOH {
}

sub _body {
    my $self  = shift;
    my $chunk = shift;

    my $eom = 0;

    # Check for a message body that contains nothing except
    # the EOM sequence
    if(not $self->{_seenDATA} and $chunk =~ s/\.\r\n$/\r\n/) {
	$eom = 1;
    }
    # Now we've seen some data
    $self->{_seenDATA} = 1;

    # Prepend the bodystate so we can determine if we received a
    # segmented read of the EOM sequence
    $chunk = $self->{_bodystate} . $chunk;

    # Check for the EOM sequence 
    if($chunk =~ s/\r\n\.\r\n(.*)/\r\n/) {
	warn "Discarding extra data: $1\n" if $1;
	$eom = 1;
    }
    
    # If we haven't already found the EOM sequence then
    # search for a partial at the end of the chunk that
    # we will buffer until the next chunk comes in
    unless($eom) {
	$chunk =~ s/(\r(?:\n(?:\.(?:\r(?:\n)?)?)?)?)$//;
	$self->{_bodystate} = $1 || '';
    }

    # Send the chunk off to be processed by the subclass
    $self->BODY($chunk);

    if($eom) {
	$self->_eom();
    }
}

sub BODY {
}

sub _eom {
    my $self = shift;

    $self->chunkmode(0);
    $self->enable_callbacks('protocol');
    $self->default_line_handler(\&_unknown);

    # Clear state
    $self->{_bodystate} = '';
    $self->{_seenMAIL} = 0;
    $self->{_seenRCPT} = 0;
    $self->{_seenDATA} = 0;

    $self->send_response($self->EOM());
}

sub EOM {
    return(250, 'Message accepted for delivery');
}

#   CONNECTION ESTABLISHMENT
#      S: 220
#      E: 554
sub _connect {
    my $self = shift;
    $self->send_response($self->CONNECT(@_));
}

sub CONNECT {
    return(220, "Apache2::Protocol::ESMTP Version $VERSION");
}

#   EHLO or HELO
#      S: 250
#      E: 504, 550
sub _helo {
    my $self = shift;

    if($_[0]) {
	$self->{_seenHELO} = 1;
	$self->{_seenMAIL} = 0;
	$self->{_seenRCPT} = 0;
	$self->{_bodystate} = '';

	$self->send_response($self->HELO(@_));
    }
    else {
	$self->send_response(501, 'HELO requires domain address');
    }
    # Return OK
}

sub HELO {
    return(250, 'OK');
}

sub _ehlo {
    my $self = shift;
    
    if($_[0]) {
	$self->{_seenHELO} = 1;
	$self->{_seenMAIL} = 0;
	$self->{_seenRCPT} = 0;
	$self->{_bodystate} = '';
	
	$self->send_response($self->EHLO(@_));
    }
    else {
	$self->send_response(501, 'EHLO requires domain address');
    }
    # Return OK
}

sub EHLO {
    my $self = shift;
    return(250, 'OK', 'HELP');
}

#   MAIL
#      S: 250
#      E: 552, 451, 452, 550, 553, 503
sub _mail {
    my $self = shift;

    if($self->{_seenMAIL}) {
	$self->send_response(503, 'Sender already specified');
    }
    elsif(not $_[0]) {
	$self->send_response(501, 'MAIL requires return-path');
    }
    else {
	$self->{_seenMAIL} = 1;
	$self->send_response($self->MAIL(@_));
    }
    # Return OK
}

sub MAIL {
    my $self = shift;
    return(250, 'OK');
}

#   RCPT
#      S: 250, 251 (but see section 3.4 for discussion of 251 and 551)
#      E: 550, 551, 552, 553, 450, 451, 452, 503, 550
sub _rcpt {
    my $self = shift;

    unless($self->{_seenMAIL}) {
	$self->send_response(503, 'Need MAIL before RCPT');
    }
    elsif(not $_[0]) {
	$self->send_response(501, 'RCPT requires forward-path');
    }
    else {
	$self->{_seenRCPT} = 1;
	$self->send_response($self->RCPT(@_));
    }
    # Return OK
}

sub RCPT {
    my $self = shift;
    my $rcpt = shift;
    return(250, 'OK');
}

#   DATA
#      I: 354 -> data -> S: 250
#                        E: 552, 554, 451, 452
#      E: 451, 554, 503
sub _data {
    my $self = shift;

    if(not $self->{_seenMAIL}) {
	$self->send_response(503, 'Need MAIL command');
    }
    elsif(not $self->{_seenRCPT}) {
	$self->send_response(503, 'Need RCPT (recipient)');
    }
    else {
	$self->disable_callbacks('protocol');
	$self->default_line_handler(\&_header);
	$self->send_response($self->DATA(@_));
    }
    # Return OK
}

sub DATA {
    return(354, 'Enter mail, end with "." on a line by itself');
}

#   RSET
#      S: 250
sub _rset {
    my $self = shift;

    # Clear state
    $self->{_seenMAIL} = 0;
    $self->{_seenRCPT} = 0;
    $self->{_seenDATA} = 0;
    $self->{_bodystate} = '';

    $self->send_response($self->RSET(@_));
    # Return OK
}

sub RSET {
    return(250, 'OK');
}

#   VRFY
#      S: 250, 251, 252
#      E: 550, 551, 553, 502, 504
sub _vrfy {
    my $self = shift;
    $self->send_response($self->VRFY(@_));
    # Return OK
}

sub VRFY {
    return(252, 'Cannot VRFY user; try RCPT to attempt delivery');
}

#   EXPN
#      S: 250, 252
#      E: 550, 500, 502, 504
sub _expn {
    my $self = shift;
    $self->send_response($self->EXPN(@_));
    # Return OK
}

sub EXPN {
    return(502, 'Sorry we don\'t allow this operation');
}

#   HELP
#      S: 211, 214
#      E: 502, 504
sub _help {
    my $self = shift;
    $self->send_response($self->HELP(@_));
    # Return OK
}

sub HELP {
    my $self = shift;
    my $subj = shift;
    return(214, "This is Apache2::Protocol::ESMTP $VERSION");
}

#   NOOP
#      S: 250
sub _noop {
    my $self = shift;
    $self->send_response($self->NOOP(@_));
    # Return OK
}

sub NOOP {
    return(250, 'OK');
}

#   QUIT
#      S: 221
sub _quit {
    my $self = shift;

    # Clear state
    $self->{_seenHELO} = 0;
    $self->{_seenMAIL} = 0;
    $self->{_seenRCPT} = 0;
    $self->{_seenDATA} = 0;
    $self->{_bodystate} = '';

    $self->disconnect(1);
    $self->send_response($self->QUIT(@_));
    # Return OK
}

sub QUIT {
    return(221, 'Closing connection');
}

sub send_response {
    my $self  = shift;
    my $code  = shift;
    my @msgs  = @_;
    my $oh    = $self->output_handle;

    for(my $i = 0; $i < @msgs; $i++) {
	print $oh $code;
	print $oh ($i == @msgs - 1 ? ' ' : '-');
	print $oh $msgs[$i], ($msgs[$i] =~ m@$/$@ ? '' : "\n");
    }
}

1;

__END__

=head1 SEE ALSO

Apache2::Protocol
Apache2::ServerUtil

=head1 AUTHOR

Mike Smith <mike@mailchannels.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by MailChannels Corporation.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
