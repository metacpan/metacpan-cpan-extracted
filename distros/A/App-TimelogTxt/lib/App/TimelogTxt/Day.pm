package App::TimelogTxt::Day;

use warnings;
use strict;

use App::TimelogTxt::Utils;
use List::Util qw/sum/;

our $VERSION = '0.22';

sub new {
    my ($class, $stamp) = @_;
    die "Missing required stamp.\n" unless $stamp;
    die "Invalid stamp format.\n" unless App::TimelogTxt::Utils::is_datestamp( $stamp );

    return bless {
        stamp => $stamp,
        start => undef,
        dur => 0,
        tasks => {},
        proj_dur => {},
        last_start => 0,
    }, $class;
}

sub is_empty    { return !$_[0]->{dur}; }
sub is_complete { return !$_[0]->{last_start}; }
sub date_stamp  { return $_[0]->{stamp}; }
sub has_tasks   { return !!keys %{$_[0]->{tasks}}; }

sub update_dur
{
    my ($self, $last, $epoch) = @_;
    my $curr_dur = $last ? $epoch - $last->epoch : 0;

    $self->{tasks}->{$last->task}->{dur} += $curr_dur if $last && $last->task;
    $self->{proj_dur}->{$last->project} += $curr_dur  if $last && $last->project;
    $self->{dur} += $curr_dur;

    return;
}

sub day_filtered_by_project
{
    my ($self, $project) = @_;
    my $result = __PACKAGE__->new( $self->date_stamp );
    $project = qr/$project/ unless ref $project;
    my @tasks = grep { $self->{tasks}->{$_}->{proj} =~ $project } keys %{$self->{tasks}};
    @{$result->{tasks}}{@tasks} = @{$self->{tasks}}{@tasks};
    my @projs = grep { $_ =~ $project } keys %{$self->{proj_dur}};
    @{$result->{proj_dur}}{@projs} = @{$self->{proj_dur}}{@projs};
    $result->{dur} = sum( 0, values %{$result->{proj_dur}} );
    return $result;
}

sub close_day
{
    my ($self, $last) = @_;
    return if $self->is_complete();

    $self->update_dur( $last, $self->day_end() );
    $self->{last_start} = 0;
    return;
}

sub start_task {
    my ($self, $event) = @_;
    if( $event->is_stop() )
    {
        $self->{last_start} = 0;
        return;
    }
    my $task = $event->task;
    $self->{last_start} = $event->epoch;
    return if $self->{tasks}->{$task};
    $self->{tasks}->{$task} = { start => $event->epoch, proj => $event->project, dur => 0 };
    return;
}

sub print_day_detail {
    my ($self, $fh) = @_;
    $fh ||= \*STDOUT;

    my ($tasks, $proj_dur) = @{$self}{ qw/tasks proj_dur/ };
    my $last_proj = '';

    print {$fh} "\n", _format_stamp_line( $self );
    foreach my $t ( sort { ($tasks->{$a}->{proj} cmp $tasks->{$b}->{proj}) || ($tasks->{$b}->{start} <=> $tasks->{$a}->{start}) }  keys %{$tasks} )
    {
        my $curr = $tasks->{$t};
        if( $curr->{proj} ne $last_proj )
        {
            print {$fh} _format_project_line( $curr->{proj}, $proj_dur->{$curr->{proj}} );
            $last_proj = $curr->{proj};
        }
        my $task = $t;
        print {$fh} _format_task_line( $t, $curr->{dur} );
    }
    return;
}

sub print_day_summary {
    my ($self, $fh) = @_;
    $fh ||= \*STDOUT;

    my $proj_dur = $self->{proj_dur};

    print {$fh}  _format_stamp_line( $self );
    foreach my $p ( sort keys %{$proj_dur} )
    {
        print {$fh} _format_project_line( $p, $proj_dur->{$p} );
    }
    return;
}

sub print_hours {
    my ($self, $fh) = @_;
    $fh ||= \*STDOUT;

    print {$fh} _format_stamp_line( $self, ':' );
    return;
}

sub print_duration {
    my ($self, $fh) = @_;
    $fh ||= \*STDOUT;

    print {$fh} _format_dur( $self->{dur} ), "\n";
    return;
}

sub day_end
{
    my ($self) = @_;

    return App::TimelogTxt::Utils::stamp_to_localtime( $self->{stamp} );
}

sub _format_dur
{
    my ($dur) = @_;
    $dur += 30; # round, don't truncate.
    return sprintf( '%2d:%02d', int($dur/3600), int(($dur%3600)/60) );
}

sub _format_stamp_line
{
    my ($self, $sep) = @_;
    $sep ||= '';

    return "$self->{stamp}$sep " . _format_dur( $self->{dur} ) . "\n";
}

sub _format_task_line
{
    my ($task, $dur) = @_;

    $task =~ s/\+\S+\s//;
    if ( $task =~ s/\@(\S+)\s*// )
    {
        if ( $task ) {
            return sprintf( "    %-20s%s (%s)\n", $1, _format_dur( $dur ), $task );
        }
        else {
            return sprintf( "    %-20s%s\n", $1, _format_dur( $dur ) );
        }
    }
    else {
        return sprintf( "    %-20s%s\n", $task, _format_dur( $dur ) );
    }
    return;
}

sub _format_project_line
{
    my ($proj, $dur) = @_;

    return sprintf( '  %-13s%s',  $proj, _format_dur( $dur ). "\n" );
}

1;
__END__

=head1 NAME

App::TimelogTxt::Day - Class representing a day as a set of times, events, and
durations.

=head1 VERSION

This document describes App::TimelogTxt::Day version 0.22

=head1 SYNOPSIS

    use App::TimelogTxt::Day;

    my $day = App::TimelogTxt::Day->new( '2013-07-02' );
    my $last;
    while( my $event = get_new_event() )
    {
        $day->update_dur( \%last, $event->epoch );
        $day->start_task( $event );
        $last = $event;
    }
    $day->print_day_detail( \*STDOUT );

=head1 DESCRIPTION

Objects of this class represent the events of a particular day. The object
tracks projects and combines time spent on the same task from multiple points
in the day.

The class also provides the ability to print various reports on the day's
activities.

=head1 INTERFACE

=head2 new( $stamp )

Creates a Day object that collects the events for the date specified by
the C<$stamp>. This C<$stamp> must be in the standard format YYYY-MM-DD

=head2 $d->is_empty()

Returns C<true> only if no events have been added to the day.

=head2 $d->is_complete()

Returns C<true> only the day is complete.

=head2 $d->date_stamp()

Returns the date stamp for the day in C<YYYY-MM-DD> form.

=head2 $d->update_dur( $last, $epoch )

Update the duration of the most recent task, using the C<$last> variable
which contains the information from the last event and the C<$epoch> time
from the new event.

=head2 $d->close_day( $last )

Update the duration of the most recent task, using the C<$last> variable
which contains the information from the last event and the end of the
day time.

=head2 $d->start_task( $event )

Initialize a new task item in the day based on the L<App::TimelogTxt::Event>
object supplied in C<$event>. This method only starts a task if no previous
matching task exists in the day.

=head2 $d->print_day_detail( $fh )

Print formatted day information to the supplied filehandle C<$fh>. If no
filehandle is supplied, print to C<STDOUT>.

The output starts with the current datestamp and duration for the day. Indented
under that are individual projects. Individual tasks are indented under the
projects.

This is the most detailed report.

=head2 $d->print_day_summary( $fh )

Print formatted day information to the supplied filehandle C<$fh>. If no
filehandle is supplied, print to C<STDOUT>.

The output starts with the current datestamp and duration for the day. Indented
under that are individual projects.

=head2 $d->print_hours( $fh )

Print formatted day information to the supplied filehandle C<$fh>. If no
filehandle is supplied, print to C<STDOUT>.

The output only displays the current datestamp and duration for the day.

=head2 $d->print_duration( $fh )

Print formatted duration information to the supplied filehandle C<$fh>. If no
filehandle is supplied, print to C<STDOUT>.

=head2 $d->has_tasks()

Returns C<true> if the day contains one or more tasks.

=head2 $d->day_filtered_by_project( $project )

Make a copy of the current C<Day> object containing only the tasks associated
with the supplied  C<$project>.

=head2 $day->is_complete()

Returns C<true> if the day is not currently in a task.

=head2 $d->day_end()

Return the epoch time for the last second of the associated date.

This is the least detailed report.

=head1 CONFIGURATION AND ENVIRONMENT

App::TimelogTxt::Day requires no configuration files or environment variables.

=head1 DEPENDENCIES

None.

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
