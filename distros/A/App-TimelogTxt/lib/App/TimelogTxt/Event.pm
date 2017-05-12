package App::TimelogTxt::Event;

use warnings;
use strict;
use Time::Local;
use App::TimelogTxt::Utils;

our $VERSION = '0.22';

sub new
{
    my ($class, $task, $time) = @_;
    $time ||= time;
    my ( $proj ) = $task =~ m/\+(\S+)/;
    my $obj = {
        epoch => $time, task => $task, project => $proj
    };
    return bless $obj, $class;
}

sub new_from_line
{
    my ($class, $line) = @_;
    die "Not a valid event line.\n" unless $line;

    my ( $stamp, $time, $task ) = App::TimelogTxt::Utils::parse_event_line( $line );
    my ( $proj ) = $task =~ m/\+(\S+)/;
    $stamp       = App::TimelogTxt::Utils::canonical_datestamp( $stamp );
    my $datetime = "$stamp $time";
    my $obj = {
        stamp => $stamp, task => $task, project => $proj, _date_time => $datetime
    };
    return bless $obj, $class;
}

sub task    { return $_[0]->{task}; }
sub project { return $_[0]->{project}; }

sub to_string
{
    my ($self) = @_;
    return $self->_date_time . ' ' . $self->task;
}

sub epoch
{
    my ($self) = @_;
    if( !defined $self->{epoch} )
    {
        my @fields = split /[^0-9]/, $self->{_date_time};
        $fields[0] -= 1900;
        $fields[1] -= 1;
        $self->{epoch} = timelocal( reverse @fields );
    }
    return $self->{epoch};
}

sub _date_time {
    my ($self) = @_;
    if( !defined $self->{_date_time} )
    {
        $self->{_date_time} = App::TimelogTxt::Utils::fmt_time( $self->{epoch} );
    }
    return $self->{_date_time};
}

sub stamp
{
    my ($self) = @_;
    $self->{stamp} ||= App::TimelogTxt::Utils::fmt_date( $self->{epoch} );
    return $_[0]->{stamp};
}

sub is_stop
{
    my ($self) = @_;
    return App::TimelogTxt::Utils::is_stop_cmd( $_[0]->{task} );
}

1;
__END__

=head1 NAME

App::TimelogTxt::Event - Class representing an event to log.

=head1 VERSION

This document describes ModName version 0.22

=head1 SYNOPSIS

    use App::TimelogTxt::Event;

    my @events;
    while(<>)
    {
        my $event = App::TimelogTxt::Event->new_from_line( $_ );
        if( $event->stamp eq $wanted_stamp )
        {
            push @events, $event;
        }
    }

=head1 DESCRIPTION

Objects of this class represent the individual lines in the F<timelog.txt> file.
Each event has a date and time stamp, an optional project, and a task.

=head1 INTERFACE

=head2 new( $task, $time )

Create a new object representing the supplied C<$task> at the supplied epoch
C<$time>. If no C<$time> is supplied, use the current time.

=head2 new_from_line( $line )

Create a new object representing the event from the supplied line. This event
must be formatted as described in L<App::TimelogTxt::Format>.

=head2 $event->task()

Return a string containing all of the event except the time and date.

=head2 $event->project()

Return the string designated as the project, if any, from the event.

=head2 $event->to_string()

Return a string representing the event, formatted as described in
L<App::TimelogTxt::Format>.

=head2 $event->epoch()

Return the time for the start of the event in epoch seconds.

=head2 $event->stamp()

Return the date stamp of the event in 'YYYY-MM-DD' format.

=head2 $event->is_stop()

Return C<true> if this was a stop event.

=head1 CONFIGURATION AND ENVIRONMENT

App::TimelogTxt::Event requires no configuration files or environment variables.

=head1 DEPENDENCIES

Time:Local.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

G. Wade Johnson  C<< gwadej@cpan.org >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, G. Wade Johnson C<< gwadej@cpan.org >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
