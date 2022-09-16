package App::MonM::Channel::Command;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

App::MonM::Channel::Command - MonM command channel

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    <Channel MyCommand>

        Type    Command
        Enable  on

        # Real To id/address/name
        # To 14242545300
        # To +1-424-254-5300
        To      testusername

        # Schedule
        #At Sun-Sat[00:00-23:59]

        # MIME options
        #Encoding 8bit
        #    8bit, quoted-printable, 7bit, base64
        #ContentType text/plain
        #Charset utf-8

        # Command mask
        #Command curl -d "[MESSAGE]" "https://sms.com/?[MSISDN]"
        Command "echo "[NUMBER]; [SUBJECT]; [MESSAGE]" >> /tmp/fakesms.txt"

        # Schedule
        #At Sun-Sat[00:00-23:59]

        # Command Options
        Content body
        Timeout 20s

    </Channel>

=head1 DESCRIPTION

This module provides command method that send the content
of the message to an external program

=over 4

=item B<sendmsg>

For internal use only!

=back

=head1 CONFIGURATION DIRECTIVES

The basic Channel configuration options (directives) detailed describes in L<App::MonM::Channel/CONFIGURATION DIRECTIVES>

=over 4

=item B<Command>

Defines full path to external program or mask of command

Default: none

Available variables:

    [ID] -- Internal ID of the message
    [TO] -- The real "to" field of message
    [RCPT], [RECIPIENT] -- Recipient (name, account, id, number and etc.)
    [PHONE], [NUM], [TEL], [NUMBER], [MSISDN] -- Recipient too
    [TIME] -- Current time (in unix time format)
    [DATETIME] -- date and time in short-format (YYYMMDDHHMMSS)
    [DATE] -- Date in short-format (YYYMMDD)
    [SUBJECT], [SUBJ], [SBJ] -- Subject of message
    [MESSAGE], [MSG] -- The Subject too (! no real message content)

Note! The real message content body sends to STDIN of command

=item B<From>

Sender address email (optional)

=item B<Content>

    Content email

Sets the whole MIME message as content for command STDIN

    Content body

Sets the body of message as content for command STDIN

    Content none

Suppress sending content to command STDIN (no content - no problems)

Default: body

=item B<To>

Recipient address (email) or name

=item B<Timeout>

    Timeout 20s

Sets timeout for command running

    Timeout off
    Timeout 0

Disable timeout

Default: 20 sec

See also description of format for the timeout values L<App::MonM::Util/getTimeOffset>

=item B<Type>

    Type    Command

Required directive!

Defines type of channel. MUST BE set to "Command" value

=back

About common directives see L<App::MonM::Channel/CONFIGURATION DIRECTIVES>

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

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

use CTK::Util qw/ execute dformat date_time2dig date2dig /;
use CTK::ConfGenUtil;
use App::MonM::Util qw/ set2attr getTimeOffset run_cmd /;

use constant {
    TIMEOUT         => 20, # 20 sec timeout
};

sub sendmsg {
    my $self = shift;
    return $self->maybe::next::method() unless $self->type eq 'command';
    my $message = $self->message;

    # Options
    my $options = set2attr($self->chconf) || {};
    #print App::MonM::Util::explain($options);

    # Get command string
    my $command = lvalue($self->chconf, "command") || lvalue($self->chconf, "script");
    unless ($command) {
        $self->error("Command string incorrect");
        return 0;
    }

    my $phone = $self->message->recipient;
    my $command_res = dformat($command, {
            ID      => $self->message->msgid,
            TO      => $self->message->to,
            RCPT    => $phone, RECIPIENT => $phone,
            PHONE   => $phone, NUM => $phone, TEL => $phone, NUMBER => $phone, MSISDN => $phone,
            TIME    => time(), DATETIME => date_time2dig(), DATE => date2dig(),
            SUBJECT => $self->message->subject, SUBJ => $self->message->subject, SBJ => $self->message->subject,
            MESSAGE => $self->message->subject, MSG => $self->message->subject,
        });

    # Get content body
    my $ct_type = lc(lvalue($self->chconf, "content") || "body");
    my $content = undef;
    if ($ct_type eq 'body') {
        $content = $message->email->body;
    } elsif ($ct_type eq 'email' or $ct_type eq 'mail') {
        $content = $message->email->as_string;
    }

    #print App::MonM::Util::explain($self->chconf);
    #print App::MonM::Util::explain(\$body);

    # Get timeout
    my $timeout = getTimeOffset(lvalue($self->chconf, "timeout") // TIMEOUT);

    # Run command
    my $r = run_cmd($command_res, $timeout, $content);
    $self->{exitval} = $r->{code};
    $self->{content} = $r->{stdout};
    $self->error($r->{stderr});

    return $r->{status};
}

1;

__END__
