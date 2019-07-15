package App::MonM::Notifier::Channel::Email; # $Id: Email.pm 60 2019-07-14 09:57:26Z abalama $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

App::MonM::Notifier::Channel::Email - monotifier email channel

=head1 VERSION

Version 1.01

=head1 SYNOPSIS

    <Channel MyEmail>
        Type    Email

        # Real To and From
        To      test@example.com
        From    root@example.com

        # Options
        #Encoding base64

        # Headers
        <Headers>
            X-Foo foo
            X-Bar bar
        </Headers>

        # SMTP options
        # If there are requirements to the register of parameter
        # names, use the Set directive, for example:
        # By default will use <SendMail> section of general config file
        Set host 192.168.0.1
        Set port 25
        #Set sasl_username TeStUser
        #Set sasl_password MyPassword

    </Channel>

=head1 DESCRIPTION

This module provides email method

=head2 DIRECTIVES

=over 4

=item B<From>

Sender address or name

=item B<Set>

Sets SMTP options:

    Set host SMTPHOST

SMTP option "host". Contains hostname or IP of remote SMTP server

Default: localhost

    Set port PORT

SMTP option "port". Contains port to connect to

Defaults to 25 for non-SSL, 465 for 'ssl', 587 for 'starttls'

    Set timeout TIMEOUT

Maximum time in secs to wait for server

Default: 120

    Set helo HELOSTRING

SMTP attribute. What to say when saying HELO. Optional

No default

    Set sasl_username USERNAME

This is sasl_username SMTP attribute. Optional

Contains the username to use for auth

    Set sasl_password PASSWORD

This is sasl_password SMTP attribute. Optional

    Set ssl 1

This is ssl SMTP attribute: if 'starttls', use STARTTLS;
if 'ssl' (or 1), connect securely; otherwise, no security.

Default: undef

See L<Email::Sender::Transport::SMTP>

=item B<To>

Recipient address or name

=item B<Type>

Defines type of channel. MUST BE set to "Email" value

=back

About other options (base) see L<App::MonM::Notifier::Channel/DIRECTIVES>

=head2 METHODS

=over 4

=item B<process>

For internal use only!

=back

=head1 HISTORY

See C<Changes> file

=head1 DEPENDENCIES

L<Email::MIME>, L<Email::Sender>, L<Net::SMTP>

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<App::MonM::Notifier>, L<App::MonM::Notifier::Channel>, L<Email::MIME>, L<Email::Sender>,
L<Net::SMTP>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/$VERSION/;
$VERSION = '1.01';

use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;
use Email::Sender::Simple qw//;
use Email::Sender::Transport::SMTP;
use Try::Tiny;

use App::MonM::Util qw/ set2attr /;

sub process {
    my $self = shift;
    my $type = $self->type;
    return $self->maybe::next::method() unless $type eq 'email';
    my $message = $self->message;
    unless ($message) {
        $self->error("Incorrect Email::MIME object");
        return;
    }
    my $message_id = $self->genId(
            $self->data->{id} || 0,
            $self->data->{pubdate} || 0,
            $self->data->{to} || "anonymous",
        );

    # eXtra headers (extension headers)
    $message->header_str_set("X-Id" => $message_id );
    $message->header_str_set("X-Mailer" => sprintf("%s/%s", __PACKAGE__, $VERSION) );

    # Options
    my $configobj = $self->{configobj};
    my $options = set2attr($self->config);
    my $sendmail_def = $configobj->conf("sendmail") if $configobj;

    # SMTP options
    my %smtp_opts = %$options;
    unless (%smtp_opts) {
        $smtp_opts{host} = value($sendmail_def, "smtp") if value($sendmail_def, "smtp");
        $smtp_opts{sasl_username} = value($sendmail_def, "smtpuser") if value($sendmail_def, "smtpuser");
        $smtp_opts{sasl_password} = value($sendmail_def, "smtppass") if value($sendmail_def, "smtppass");
    }

    # General
    my $try_sendmail_first = $smtp_opts{host} ? 0 : 1;
    my $sent_status = 1;
    my $sent_error = "";

    # Try via sendmail
    if ($try_sendmail_first) {
        try {
            Email::Sender::Simple->send($message);
        } catch {
            $sent_status = 0;
            $sent_error = $_ || 'unknown error';
        };
        return $self->status($sent_status) if $sent_status;
    }

    # Now send via SMTP
    $sent_status = 1;
    my $transport = Email::Sender::Transport::SMTP->new({%smtp_opts});
    try {
        Email::Sender::Simple->send($message, { transport => $transport });
    } catch {
        $sent_status = 0;
        $sent_error = $_ || 'unknown error';
    };
    return $self->status($sent_status) if $sent_status;

    # Errors
    $self->error(sprintf("Can't send message: %s", $sent_error // "unknown error"));
    return;
}

1;

__END__
