package Apache::SMTP::Server;

use 5.006001;
use strict;
use warnings FATAL => 'all';

use base 'Net::Server::Mail::SMTP';
use Apache::Server ();
use Apache::ServerUtil ();
use Apache::Connection ();

our $VERSION = '0.01';

sub my_config {
    my ($self, $c) = @_;
    my $s = $c->base_server;
    die "MailHost undefined" unless defined $s->dir_config('MailHost');
    $self->{mailport} = '25';                                          
    $self->{mailport} = $s->dir_config('MailPort') if
        defined $s->dir_config('MailPort');
    $self->{local_ip} = $c->local_ip;      
    $self->{mailhost} = $s->dir_config('MailHost');
    $self->{remote_ip} = $c->remote_ip;
}

sub get_local_ip {
    my $self = shift;
    my $local_ip = $self->{local_ip};
    return($local_ip ? $local_ip : '127.0.0.1');
}

sub get_hostname {
    my $self = shift;
    my $hostname = $self->{hostname};
    return($hostname ? $hostname : undef);
}

sub get_remote_ip {
    my $self = shift;
    my $remote_ip = $self->{remote_ip};
    return($remote_ip ? $remote_ip : undef);
}

sub get_mailhost {
    my $self = shift;
    my $mailhost = $self->{mailhost};
    return($mailhost ? $mailhost : undef);
}

sub get_mailport {
    my $self = shift;
    my $mailport = $self->{mailport};
    return($mailport ? $mailport : 25);
}

#this is a copy of helo from Net::Server::Mail::SMTP with the minor change
#of setting $self->{hostname} so we can get it later
sub helo
{
    my($self, $hostname) = @_;

    unless(defined $hostname && length $hostname)
    {
        $self->reply(501, 'Syntax error in parameters or arguments');
        return;
    }
    $self->{hostname} = $hostname;
    $self->make_event
    (
        name => 'HELO',
        arguments => [$hostname],
        on_success => sub
        {
            # according to the RFC, HELO ensures "that both the SMTP client
            # and the SMTP server are in the initial state"
            $self->step_reverse_path(1);
            $self->step_forward_path(0);
            $self->step_maildata_path(0);
        },
        success_reply => [250, 'Requested mail action okay, completed'],
    );

    return;
}

1;
__END__

=head1 NAME

Apache::SMTP::Server - Subclass of Net::Server::Mail::SMTP with some additional
methods for getting remote ip and hostname and some config bits from Apache's
httpd.conf

=head1 SYNOPSIS

  use Apache::SMTP::Server;
  sub handler {
    my $c = shift;
    my $ath = Apache::TieBucketBrigade->new_tie($c);
                                                    
    my $smtp = Apache::SMTP::Server->new(         
        handle_in => $ath,
        handle_out => $ath,
    );
    $smtp->my_config($c);
    $smtp->set_callback(HELO => \&validate_hostname);
    $smtp->set_callback(RCPT => \&validate_recipient);
    $smtp->set_callback(DATA => \&queue_message);
    $smtp->set_callback(MAIL => \&validate_sender);
    $smtp->process;
    Apache::OK;
  }


=head1 DESCRIPTION

This module is used by Apache::SMTP to add some usefull functions to 
Net::Server::Mail::SMTP.  You probably don't need to subclass it yourself, but
you may want to if you need to add more configuration bits.  See Apache::SMTP
for example of use.

=head2 METHODS

=over 4

=item new ( handle_in => IO::Handle, handle_out => IO::Handle )

Takes an IO::Handle object for read and write, returns an 
Net::Server::Mail::SMTP object.

=item my_config ( Apache::Connection object )

Takes an Apache::Connection object and sets up some config variables.

=item get_local_ip

returns the ip bound in httpd.conf

=item get_hostname

returns hostname as given to HELO

=item get_remote_ip

returns ip of remote host

=item get_mailhost

returns hostname or ip used for outbound smtp connections from
PerlSetVar	MailHost	my.host.name
in httpd.conf

=item get_mailport

returns port to connect to for outbound smtp connections from
PerlSetVar	MailPort	25
in httpd.conf

=head1 SEE ALSO

Apache::SMTP
Net::Server::Mail
Net::Server::Mail::SMTP
Apache::TieBucketBrigade
Net::SMTP


=head1 AUTHOR

mock, E<lt>mock@obscurity.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Will Whittaker and Ken Simpson

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
