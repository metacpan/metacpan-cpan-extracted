package Data::EventStream;
use 5.010;
use Moose;
our $VERSION = "0.13";
$VERSION = eval $VERSION;
use Carp;
use Data::EventStream::Window;

=head1 NAME

Data::EventStream - Perl extension for event processing

=head1 VERSION

This document describes Data::EventStream version 0.13

=head1 SYNOPSIS

    use Data::EventStream;
    $es = Data::EventStream->new;
    $es->add_aggregator( $agg, %params );
    while ( my $event = get_event() ) {
        $es->add_event($event);
    }

=head1 DESCRIPTION

Module provides methods to analyze stream of events.

Please check L<Project
Homepage|http://trinitum.github.io/perl-Data-EventStream/> for more information
about using this module and examples.

=head1 METHODS

=head2 $class->new(%params)

Creates a new instance. The following parameters are accepted:

=over 4

=item B<time>

Initial model time, by default 0

=item B<time_sub>

Reference to a subroutine that returns time associated with the event passed to
it as the only parameter. This argument is not required if you are only going
to use count based sliding windows.

=item B<filter>

Reference to a subroutine that is invoked every time new event is being added.
The new event is passed as the only argument to this subroutine. If subroutine
returns false event is ignored.

=back

=cut

has time => ( is => 'ro', default => 0 );

has time_sub => ( is => 'ro', );

has events => (
    is      => 'ro',
    default => sub { [] },
);

has aggregators => (
    is      => 'ro',
    default => sub { [] },
);

=head2 $self->set_filter(\&sub)

Set a new filter

=head2 $self->remove_filter

Remove filter

=cut

has filter => (
    is      => 'ro',
    isa     => 'CodeRef',
    writer  => 'set_filter',
    clearer => 'remove_filter',
);

has time_length => ( is => 'ro', default => 0, );

has length => ( is => 'ro', default => 0, );

has _next_leave => ( is => 'rw', );

=head2 $self->set_time($time)

Set new model time. This time must not be less than the current model time.

=cut

sub set_time {
    my ( $self, $time ) = @_;
    croak "new time ($time) is less than current time ($self->{time})" if $time < $self->{time};
    $self->{time} = $time;
    my $gt = $self->{time_sub};
    croak "time_sub must be defined if you using time aggregators" unless $gt;

    my $as         = $self->aggregators;
    my $next_leave = $time + $self->{time_length};
    my @deleted;

  AGGREGATOR:
    for my $n ( 0 .. $#$as ) {
        my $aggregator = $as->[$n];
        my $win        = $aggregator->{_window};
        my $obj        = $aggregator->{_obj};
        if ( $aggregator->{duration} ) {
            next if $win->{start_time} > $time;
            my $period = $aggregator->{duration};
            if ( $aggregator->{batch} ) {
                while ( $time - $win->{start_time} >= $period ) {
                    $win->{end_time} = $win->{start_time} + $period;
                    $obj->window_update($win);
                    $aggregator->{on_reset}->($obj) if $aggregator->{on_reset};
                    $win->{start_time} = $win->{end_time};
                    $win->{count}      = 0;
                    $obj->reset($win);
                    if ( $aggregator->{disposable} ) {
                        push @deleted, $n;
                        next AGGREGATOR;
                    }
                }
                $win->{end_time} = $time;
                my $nl = $win->{start_time} + $period;
                $next_leave = $nl if $nl < $next_leave;
            }
            else {
                $win->{end_time} = $time;
                if ( $win->time_length >= $period ) {
                    my $st = $time - $period;
                    while ( $win->{count}
                        and ( my $ev_time = $gt->( $win->get_event(0) ) ) <= $st )
                    {
                        $win->{start_time} = $ev_time;
                        $obj->window_update($win);
                        $aggregator->{on_leave}->($obj) if $aggregator->{on_leave};
                        $obj->leave( $win->_shift_event, $win );
                    }
                    $win->{start_time} = $st;
                }
                if ( $win->{count} ) {
                    my $nl = $gt->( $win->get_event(0) ) + $period;
                    $next_leave = $nl if $nl < $next_leave;
                }
            }
            $obj->window_update($win);
        }
        else {
            $win->{end_time} = $time;
            $win->{start_time} = $time unless $win->{count};
            $obj->window_update($win);
        }
    }
    while ( my $n = pop @deleted ) {
        splice @$as, $n, 1;
    }
    $self->_next_leave($next_leave);

    my $limit = $self->{time} - $self->{time_length};
    my $ev    = $self->{events};
    while ( @$ev > $self->{length}
        and $gt->( $ev->[0] ) <= $limit )
    {
        shift @$ev;
    }
}

=head2 $self->next_leave

Return time of the next nearest leave or reset event

=cut

sub next_leave {
    shift->_next_leave;
}

=head2 $self->add_aggregator($aggregator, %params)

Add a new aggregator object. An aggregator that is passed as the first argument
should implement interface described in L<Data::EventStream::Aggregator>
documentation. Parameters that go next can be the following::

=over 4

=item B<count>

Maximum number of event for which aggregator can aggregate data. When number
of aggregated events reaches this limit, each time before a new event enters
aggregator, the oldest aggregated event will leave it.

=item B<duration>

Maximum period of time handled by aggregator. Each time the model time is
updated, events with age exceeding specified duration are leaving aggregator.

=item B<batch>

If enabled, when I<count> or I<duration> limit is reached, aggregator is reset
and all events leaving it at once.

=item B<start_time>

Time when the first period should start. Used in conjunction with I<duration>
and I<batch>. By default current model time.

=item B<disposable>

Used in conjunction with I<batch>. Aggregator only aggregates specified period
once and on reset it is removed from the list of aggregators.

=item B<on_enter>

Callback that should be invoked after event entered aggregator.  Aggregator
object is passed as the only argument to callback.

=item B<on_leave>

Callback that should be invoked before event leaves aggregator.
Aggregator object is passed as the only argument to callback.

=item B<on_reset>

Callback that should be invoked before resetting the aggregator.
Aggregator object is passed as the only argument to callback.

=back

=cut

sub add_aggregator {
    my ( $self, $aggregator, %params ) = @_;
    $params{_obj}    = $aggregator;
    $params{_window} = Data::EventStream::Window->new(
        events     => $self->{events},
        start_time => $params{start_time} // $self->{time},
    );

    unless ( $params{count} or $params{duration} ) {
        croak 'At least one of "count" or "duration" parameters must be provided';
    }
    if ( $params{count} ) {
        if ( $params{count} > $self->{length} ) {
            $self->{length} = $params{count};
        }
    }
    if ( $params{duration} ) {
        croak "time_sub must be defined for using time aggregators"
          unless $self->{time_sub};
        if ( $params{duration} > $self->{time_length} ) {
            $self->{time_length} = $params{duration};
        }
    }
    push @{ $self->{aggregators} }, \%params;
}

=head2 $self->add_event($event)

Add new event

=cut

sub add_event {
    my ( $self, $event ) = @_;
    if ( $self->{filter} ) {
        return unless $self->{filter}->($event);
    }
    my $ev     = $self->{events};
    my $ev_num = @$ev;
    my $as     = $self->aggregators;
    my $time;
    my $gt = $self->{time_sub};
    if ($gt) {
        $time = $gt->($event);
        $self->set_time($time);
    }

    for my $aggregator (@$as) {
        if ( $aggregator->{count} ) {
            my $win = $aggregator->{_window};
            if ( $win->{count} and $win->{count} == $aggregator->{count} ) {

                if ($gt) {
                    $win->{start_time} = $gt->( $win->get_event(0) );
                    $aggregator->{_obj}->window_update($win);
                }
                $aggregator->{on_leave}->( $aggregator->{_obj} ) if $aggregator->{on_leave};
                my $ev_out = $win->_shift_event;
                if ($gt) {
                    if ( $win->{count} ) {
                        $win->{start_time} = $gt->( $win->get_event(0) );
                    }
                    else {
                        $win->{start_time} = $time;
                    }
                    $aggregator->{_obj}->window_update($win);
                }
                $aggregator->{_obj}->leave( $ev_out, $win );
            }
        }
    }

    push @$ev, $event;

    my $next_leave = $self->_next_leave;
    my @deleted;

  AGGREGATOR:
    for my $n ( 0 .. $#$as ) {
        my $aggregator = $as->[$n];
        my $win        = $aggregator->{_window};
        if ( $aggregator->{count} ) {
            my $ev_in = $win->_push_event;
            $aggregator->{_obj}->enter( $ev_in, $win );
            $aggregator->{on_enter}->( $aggregator->{_obj} ) if $aggregator->{on_enter};
            if ( $aggregator->{batch} and $win->{count} == $aggregator->{count} ) {
                $aggregator->{on_reset}->( $aggregator->{_obj} ) if $aggregator->{on_reset};

                $win->{count} = 0;
                if ($gt) {
                    $win->{start_time} = $gt->($ev_in);
                }
                $aggregator->{_obj}->reset($win);
                if ( $aggregator->{disposable} ) {
                    push @deleted, $n;
                    next AGGREGATOR;
                }
            }
        }
        else {
            my $ev_in = $win->_push_event;
            $aggregator->{_obj}->enter( $ev_in, $win );
            $aggregator->{on_enter}->( $aggregator->{_obj} ) if $aggregator->{on_enter};
        }
        if ( $aggregator->{duration} and $win->{count} ) {
            my $nl = $gt->( $win->get_event(0) ) + $aggregator->{duration};
            $next_leave = $nl if $nl < $next_leave;
        }
    }
    while ( my $n = pop @deleted ) {
        splice @$as, $n, 1;
    }
    $self->_next_leave($next_leave);

    my $time_limit = $self->{time} - $self->{time_length};
    while ( @$ev > $self->{length} ) {
        if ($gt) {
            if ( $gt->( $ev->[0] ) <= $time_limit ) {
                shift @$ev;
            }
            else {
                last;
            }
        }
        else {
            shift @$ev;
        }
    }
}

no Moose;

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 SEE ALSO

Project homepage at L<http://trinitum.github.io/perl-Data-EventStream/>

=head1 BUGS

Please report any bugs or feature requests via GitHub bug tracker at
L<http://github.com/trinitum/perl-Data-EventStream/issues>.

=head1 AUTHOR

Pavel Shaydo C<< <zwon at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 Pavel Shaydo

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
