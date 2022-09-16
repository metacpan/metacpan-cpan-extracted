package App::MonM::Channel;
use warnings;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

App::MonM::Channel - The MonM channel class

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    use App::MonM::Channel;

=head1 DESCRIPTION

This module provides channel base methods

=head2 new

    my $channel = App::MonM::Notifier::Channel->new;

Returns the channel object

=head2 chconf

    my $channel_conf = $channel->chconf;

Returns current channel config structure

=head2 cleanup

    my $self = $channel->cleanup;

Cleaning up of working variables

=head2 error

    my $error = $channel->error;
    my $error = $channel->error( "New error" );

Sets/gets error message

=head2 message

    my $email = $channel->message;
    my $email = $channel->message( App::MonM::Message->new );

Gets/sets the App::MonM::Message object

=head2 type

    my $type = $channel->type;
    my $type = $channel->type( "File" );

Gets/sets the type value

=head2 sendmsg

    my $status = $channel->sendmsg( $message, $chconf )
        or die($channel->error);

This method runs process of sending message to channel and returns
operation status.

=head2 scheduler

    my $scheduler = $channel->scheduler;

Returns App::MonM::Util::Sheduler object

=over 4

=item C<$message>

The App::MonM::Message object

=item C<$chconf>

Channel config structure (hash)

=back

=head1 CONFIGURATION DIRECTIVES

General configuration options (directives) detailed describes in L<App::MonM/GENERAL DIRECTIVES>

The channel configuration directives are specified in named
sections <channel NAME> where NAME is the name of the channel section.
The NAME is REQUIRED attribute. For example:

    <Channel SendMail>
        Type    Email
        Enable  on
        From    to@example.com
        From    from@example.com
    </Channel>

Each the channel section can contain the following basic directives:

=over 4

=item B<At>

    At Sun-Sat[00:00-23:59]
    At Sun[6:30-12:00,14-20:30];Mon[7:00-20:30];Tue-Thu[9:00-17:00];Fri-Sat[off]

This directive describes the notification schedule.
Notification schedule allows you to schedule time intervals for sending different types of notification to end recipients.
Intervals can be specified based the channel level (<Channel NAME> sections) or user level (<User NAME> sections).
For defining the days of the week in which the schedule is active use a directive B<At>.
The B<At> directive consists of blocks separated by semicolons in the format:

    Weekday[interval]
    Weekday[interval,interval,...]
    Weekday-Weekday[interval,interval,...]

The "Weekday" should be defined as a name of the day of the week in full or abbreviated form:

    Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, Saturday
    Sun, Mon, Tue, Wed, Thu, Fri, Sat

Define how you want to use a schedule. If you want to activate a notification template only during specific
time spans you have the option to combine recurring days of the week into daily intervals by defining
the week interval for these days. You can unite several days into block for repetitive notification use
according to the appointed block settings. In this case Days of the week should be separating them
with "-" character, for example, "Sun-Sat" (all days from Sunday to Saturdays inclusive), or
"Mon-Sun" (all days from Monday to Sunday inclusive). If some day of the week is omitted, then this day
is automatically excluded from the notification schedule

The "Interval" is the Time intervals. To define the hours of the day in which the schedule is
active use an Interval. Time intervals should be written in the form: hh:mm-hh:mm, for example:

    00:00-10:00
    12-14:50
    15-16

If interval is not specified, interval 00:00-23:59 would be applied by default.
You can use the "off" (or "none", "-") value to disable selected day of shedule.
When the time will set as a 00:00-00:00 - it will lead to cancel all notifications for the day


B<Please, note:>
If the At directive is not specified the check scheduling will be disabled and the end user will receive
messages at any time of the day and day of the week. The same effect will have setting of the value of
the At directive as Sun-Sat[00:00-23:59]

Default: Sun-Sat[00:00-23:59]

=item B<Attachment>

    <Attachment>
        Filename    payment.pdf
        Type        application/pdf
        Encoding    base64
        Disposition attachment
        Path        /tmp/payment.pdf
    </Attachment>

Section (sections) that defines attachments for each message

Default: no attachments

See also L<Email::MIME>

=item B<BasedOn>

    BasedOn SendMail

Sets name of the common channel (not user channel) for loading directives from it

=item B<Charset>

Sets the charset

Default: utf-8

See also L<Email::MIME>

=item B<ContentType>

Sets the content type

Default: text/plain

See also L<Email::MIME>

=item B<Enable>

    Enable  yes

The main switcher of the channel section

Default: no

=item B<Encoding>

Sets encoding (8bit, base64, quoted-printable)

Default: 8bit

See also L<Email::MIME>

=item B<Headers>

    <Headers>
        X-Foo foo
        X-Bar bar
    </Headers>

Container for MIME headers definitions

=item B<Type>

Defines type of channel

Allowed types: File, Command, Email

=back

The "Email" channel directives are describes in L<App::MonM::Channel::Email/CONFIGURATION DIRECTIVES>,
the "Command" channel directives are describes in L<App::MonM::Channel::Command/CONFIGURATION DIRECTIVES>,
the "File" channel directives are describes in L<App::MonM::Channel::File/CONFIGURATION DIRECTIVES>

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<Email::MIME>

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

use mro;

use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;

use parent qw/
        App::MonM::Channel::File
        App::MonM::Channel::Email
        App::MonM::Channel::Command
    /;

sub new {
    my $class = shift;
    my %args = @_;

    # Create Sheduler object
    my $scheduler = App::MonM::Util::Scheduler->new;

    my $self = bless {
            error => "",
            type => "",
            message => undef,
            chconf => {},
            content => undef, # Output content
            exitval => 0, # ExitVal code
            scheduler => $scheduler,
        }, $class;

    return $self;
}

sub cleanup {
    my $self = shift;
    $self->{error}   = ''; # Error message
    $self->{type}    = ''; # email/file/command
    $self->{message} = undef; # Message object
    $self->{chconf} = {}; # Channel config
    return $self;
}
sub error {
    my $self = shift;
    my $v = shift;
    $self->{error} = $v if defined $v;
    return $self->{error};
}
sub type {
    my $self = shift;
    my $v = shift;
    $self->{type} = $v if defined $v;
    return $self->{type};
}
sub chconf {
    my $self = shift;
    my $v = shift;
    $self->{chconf} = $v if defined $v;
    return $self->{chconf};
}
sub message {
    my $self = shift;
    my $v = shift;
    $self->{message} = $v if defined $v;
    return $self->{message};
}
sub scheduler {
    my $self = shift;
    return $self->{scheduler};

}

sub sendmsg {
    my $self = shift;
    my $message = shift; # App::MonM::Message->new
    my $chconf = shift; # Channel config section
    $self->cleanup;

    # Check message object
    unless ($message) {
        $self->error("Incorrect App::MonM::Message object");
        return;
    }

    # Enable?
    unless (lvalue($chconf, 'enable') || lvalue($chconf, 'enabled')) {
        $self->error("Channel is disabled. Set \"Enable\" option to \"on\"");
        return 1; # SKIP
    }

    # Schedule
    my $scheduler = $self->scheduler;
    my $chname = value($chconf, 'chname');
    if ($chname) {
        $scheduler->add($chname, lvalue($chconf, 'at'));
        unless ($scheduler->check($chname)) {
            $self->error(sprintf("Skipped by the \"%s\" schedule conditions", $chname));
            return 1; # SKIP
        }
    }

    # Set data
    $self->chconf($chconf);
    $self->message($message);
    $self->type(lc(uv2null(value($chconf, 'type'))));

    #printf "Oops: %s\n", $self->type;

    # Go to backend!
    return $self->maybe::next::method();
}

1;

__END__
