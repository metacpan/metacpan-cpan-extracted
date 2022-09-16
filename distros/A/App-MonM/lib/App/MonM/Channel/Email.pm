package App::MonM::Channel::Email;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

App::MonM::Channel::Email - MonM email channel

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    <Channel MyEmail>

        Type    Email
        Enable  on

        # Real Email addresses
        To      to@example.com
        #Cc     cc@example.com
        #Bcc    bcc@example.com
        From    from@example.com

        # Schedule
        #At Sun-Sat[00:00-23:59]

        # MIME options
        #Encoding 8bit
        #    8bit, quoted-printable, 7bit, base64
        #ContentType text/plain
        #Charset utf-8

        # SMTP extra headers
        #<Headers>
        #    X-Foo foo
        #    X-Bar bar
        #</Headers>

        # Attachments
        #<Attachment>
        #    Filename    screenshot.png
        #    Type        image/png
        #    Encoding    base64
        #    Disposition attachment
        #    Path        ./screenshot.png
        #</Attachment>
        #<Attachment>
        #    Filename    payment.pdf
        #    Type        application/pdf
        #    Encoding    base64
        #    Disposition attachment
        #    Path        ./payment.pdf
        #</Attachment>

        # SMTP options
        # If there are requirements to the case sensitive of parameter
        # names, use the "Set" directives
        # By default will use <Channel SendMail> section of general config file
        Set host 192.168.0.1
        Set port 25
        #Set sasl_username TestUser
        #Set sasl_password MyPassword
        Set timeout 20

    </Channel>

=head1 DESCRIPTION

This module provides email method

=over 4

=item B<sendmsg>

For internal use only!

=back

=head1 CONFIGURATION DIRECTIVES

The basic Channel configuration options (directives) detailed describes in L<App::MonM::Channel/CONFIGURATION DIRECTIVES>

=over 4

=item B<From>

Sender address (email)

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

=item B<To>, B<Cc>, B<Bcc>

Recipient address (Email addresses)

=item B<Type>

    Type    Email

Required directive!

Defines type of channel. MUST BE set to "Email" value

=back

About common directives see L<App::MonM::Channel/CONFIGURATION DIRECTIVES>

=head1 HISTORY

See C<Changes> file

=head1 DEPENDENCIES

L<Email::MIME>, L<Email::Sender>, L<Net::SMTP>

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<Email::MIME>, L<Email::Sender>, L<Net::SMTP>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2022 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/$VERSION/;
$VERSION = '1.00';

use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;
use Email::Sender::Simple qw//;
use Email::Sender::Transport::SMTP;
use Try::Tiny;

use App::MonM::Util qw/ set2attr /;

sub sendmsg {
    my $self = shift;
    return $self->maybe::next::method() unless $self->type eq 'email';
    my $message = $self->message;

    #printf "Send message %s to %s (%s) via %s\n", $self->message->msgid, $self->message->to, $self->message->recipient,  $self->type;
    #print App::MonM::Util::explain($self->chconf);

    # eXtra headers (extension headers)
    $message->email->header_str_set("X-Mailer" => sprintf("%s/%s", __PACKAGE__, $VERSION) );

    # SMTP Options
    my $options = set2attr($self->chconf) || {};
    #print App::MonM::Util::explain($options);

    # General
    my $try_sendmail_first = value($options, "host") ? 0 : 1;
    my $sent_status = 1;
    my $sent_error = "";

    # Try via sendmail
    if ($try_sendmail_first) {
        try {
            Email::Sender::Simple->send($message->email);
        } catch {
            $sent_status = 0;
            $sent_error = $_ || 'unknown sendmail error';
        };
        return 1 if $sent_status;
    }

    # Now send via SMTP
    $sent_status = 1;
    my $transport = Email::Sender::Transport::SMTP->new($options);
    try {
        Email::Sender::Simple->send($message->email, { transport => $transport });
    } catch {
        $sent_status = 0;
        $sent_error = $_ || 'unknown SMTP error';
    };
    return 1 if $sent_status;

    # Errors
    $self->error(sprintf("Can't send message: %s", $sent_error // "unknown error"));
    return 0;
}

1;

__END__
