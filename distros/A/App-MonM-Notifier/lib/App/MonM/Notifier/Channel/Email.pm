package App::MonM::Notifier::Channel::Email; # $Id: Email.pm 31 2017-11-21 16:31:59Z abalama $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

App::MonM::Notifier::Channel::Email - monotifier email channel

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

	use App::MonM::Notifier::Channel;

	# Create channel object
	my $channel = new App::MonM::Notifier::Channel(
	        timeout => 300, # Default: 300
	    );

	# Send message via email channel
	$channel->email(
	    {
	        id      => 1,
	        to      => "anonymous\@example.com",
	        from    => "root\@example.com",
	        subject => "Test message",
	        message => "Content of the message",
	        headers => {
	                   "X-Foo"	=> "Extended eXtra value",
	            },
	    },
	    {
	        encoding => 'base64', # Default: 8bit
	        content_type => undef, # Default: text/plain
	        charset => undef, # Default: utf-8

	        # SMTP options
	        host    => '127.0.0.1', # Default: localhost
	        port    => 25, # Default: 25

	        # General options
	        timeout => 120, # Default: 120
	        helo    => 'host.example.com', # Default: undef

	        # SASL & SSL options
	        #username    => '', # Default: undef
	        #password    => '', # Default: undef
	        ssl         => 0, # Default: undef
	        ssl_options => {}, # Default: undef
	    }) or warn( $channel->error );

	# See error
	print $channel->error unless $channel->status;

	# Also see trace for error details
	print $channel->trace unless $channel->status;


=head1 DESCRIPTION

This module provides "email" method.

	my $status = $channel->email( $data, $options );

The $data structure (hashref) describes body of message, the $options
structure (hashref) describes parameters of the connection via external modules

=head2 DATA

It is a structure (hash), that can contain the following fields:

=over 8

=item B<id>

Contains internal ID of the message. This ID is converted to an X-Id header

=item B<to>

EMail address of the recipient

=item B<from>

EMail address of the sender

=item B<subject>

Subject of the message

=item B<message>

Body of the message

=item B<headers>

Optional field. Contains eXtra headers (extension headers). For example:

    headers => {
            "bcc" => "bcc\@example.com",
            "X-Mailer" => "My mailer",
        }

=back

=head2 OPTIONS

It is a structure (hash), that can contain the following fields:

=over 8

=item B<encoding>

Encoding: 'quoted-printable', base64' or '8bit'

Default: 8bit

See L<Email::MIME>

=item B<content_type>

The content type

Default: text/plain

See L<Email::MIME>

=item B<charset>

Part of common Content-Type attribute. Defines charset

Default: utf-8

See L<Email::MIME>

=item B<host>

SMTP option "host". Contains hostname or IP of remote SMTP server

Default: localhost

=item B<port>

SMTP option "port". Contains port to connect to

Defaults to 25 for non-SSL, 465 for 'ssl', 587 for 'starttls'

=item B<timeout>

Maximum time in secs to wait for server

Default: 120

=item B<helo>

SMTP attribute. What to say when saying HELO

No default

=item B<username>

This is sasl_username SMTP attribute, is optional field.

Contains the username to use for auth

=item B<password>

This is sasl_password SMTP attribute, the password to use for auth;
required if username is provided

=item B<ssl>

This is ssl SMTP attribute: if 'starttls', use STARTTLS;
if 'ssl' (or 1), connect securely; otherwise, no security.

Default: undef

See L<Email::Sender::Transport::SMTP>

=item B<ssl_options>

This is ssl_options SMTP attribute (hashref): passed to L<Net::SMTP>
constructor for 'ssl' connections or to starttls for 'starttls'
connections; should contain extra options for L<IO::Socket::SSL>

Default: undef

See L<Email::Sender::Transport::SMTP>

=back

=head2 METHODS

=over 8

=item B<init>

For internal use only!

Called from base class. Returns initialize structure

=item B<handler>

For internal use only!

Called from base class. Returns status of the operation

=back

=head1 HISTORY

See C<CHANGES> file

=head1 DEPENDENCIES

L<CTK>, L<Email::MIME>, L<Email::Sender>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<App::MonM::Notifier>, L<Email::MIME>, L<Email::Sender>, L<Net::SMTP>,
L<IO::Socket::SSL>, L<App::MonM::Notifier::Channel>

=head1 AUTHOR

Sergey Lepenkov (Serz Minus) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2017 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

See C<LICENSE> file

=cut

use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;
use Email::Sender::Simple qw//;
use Email::Sender::Transport::SMTP;
use Try::Tiny;

use vars qw/$VERSION $BANNER/;
$VERSION = '1.00';

use constant {
    PREFIX    => 'monotifier',
};

sub init {
	$BANNER = sprintf("%s/%.2f", PREFIX, "$VERSION");
    return (
        type 	=> "Email",
        banner 	=> $BANNER,
        validation => {
                data => {
                        id  => {
                                optional    => 1,
                                regexp      => qr/^[0-9a-z]+$/i,
                                minlength   => 0,
                                maxlength   => 128,
                                type        => "str",
                                error       => "Field \"id\" incorrect",
                            },
                        to  => {
                                optional    => 0,
                                regexp      => qr/\@/,
                                minlength   => 1,
                                maxlength   => 255,
                                type        => "str",
                                error       => "Field \"to\" incorrect",
                            },
                    },
                options => {
                        host  => {
                                optional    => 1,
                                #regexp      => qr//,
                                minlength   => 1,
                                maxlength   => 255,
                                type        => "str",
                                error       => "SMTP option \"host\" incorrect",
                            },
                        port  => {
                                optional    => 1,
                                regexp      => qr/^[0-9]{1,5}$/,
                                minlength   => 1,
                                maxlength   => 5,
                                type        => "int",
                                error       => "SMTP option \"port\" incorrect",
                            },
                    },
            },
    )
}

sub handler {
    my $self = shift;
    my $data = shift;
    my $options = shift;
    #print Dumper([$self, $data, $options]);

    # eXtra headers (extension headers)
    my %headers = ();
    if ($data->{headers} && is_hash($data->{headers})) {
    	my $inh = hash($data => "headers");
    	%headers = %$inh;
    }
    $headers{"X-Id"} = $data->{id} if $data->{id} && is_int($data->{id});
    $headers{"X-Mailer"} //= $BANNER;
    $data->{headers} = {%headers};

    # Get email object
    unless ($self->default( $data, $options ) && $self->{email}) {
        return $self->error("Can't get Email::MIME object");
    }
    my $email = $self->{email};
    #print $email->as_string;

	# Options
	my $host = value($options => "host");
	my $try_sendmail_first = $host && length($host) ? 0 : 1;
	my %smtp_opts;
	$smtp_opts{host} = $host if $host && length($host); # Default: localhost
	my $port = value($options => "port");
	$smtp_opts{port} = $port if $port && is_int($port); # Default: 25

    # General options
    my $timeout = fv2zero(value($options => "timeout"));
	$smtp_opts{timeout} = $timeout if $timeout; # Default: 120
	my $helo = fv2null(value($options => "helo"));
	$smtp_opts{helo} = $helo if length($helo); # Default: hostname()

    # SASL & SSL options
	my $username = value($options => "username");
	my $password = value($options => "password");
	$smtp_opts{sasl_username} = $username if defined($username) && length($username);
	$smtp_opts{sasl_password} = $password if defined($password) && length($password);
    my $ssl = value($options => "ssl");
    if ($ssl) {
    	$smtp_opts{ssl} = $ssl; # Default: 0
    	$smtp_opts{ssl_options} = hash($options => "ssl_options"); # Default: {}
    }
    #print Dumper(\%smtp_opts);

    my $sent_status = 1;
    my $sent_error = "";

    # Via sendmail
	if ($try_sendmail_first) {
	    try {
	        Email::Sender::Simple->send($email);
	    } catch {
	        $sent_status = 0;
	        $sent_error = $_ || 'unknown error';
	    };
	    return 1 if $sent_status;
	}

	# Via SMTP
    $sent_status = 1;

    my $transport = Email::Sender::Transport::SMTP->new({%smtp_opts});
    try {
        Email::Sender::Simple->send($email, { transport => $transport });
    } catch {
        $sent_status = 0;
        $sent_error = $_ || 'unknown error';
    };
    return 1 if $sent_status;

	# $sent_status = 0
	# $sent_error  = "...";

	my $err =  $1 if $sent_error =~ /(.+)?$/m;
	return $self->error(sprintf("Can't send message: %s", $err // "Unknown error"), $sent_error);
}

1;
