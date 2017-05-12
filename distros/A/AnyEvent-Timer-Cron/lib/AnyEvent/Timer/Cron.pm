package AnyEvent::Timer::Cron;
use Moo;

our $VERSION = '0.002000';
$VERSION = eval $VERSION;

use AnyEvent;
use Scalar::Util qw(weaken);
use Safe::Isa;
use DateTime;
use DateTime::Event::Cron;
use namespace::clean;

has 'cb' => (is => 'ro', required => 1);
has 'time_zone' => (is => 'ro');
has '_cron' => (
    is => 'ro',
    required => 1,
    init_arg => 'cron',
    coerce => sub {
        my $cron = shift;
        if (!ref $cron) {
            $cron = DateTime::Event::Cron->new($cron);
        }
        if ($cron->$_can('next')) {
            return sub { $cron->next(@_) };
        }
        elsif ($cron->$_can('get_next_valid_time_after')) {
            return sub { $cron->get_next_valid_time_after(@_) };
        }
        die "Invalid cron!";
    },
);
has '_timer' => (is => 'rw');

sub BUILD {
    my $self = shift;
    $self->create_timer;
}

sub create_timer {
    my $self = shift;
    weaken $self;
    my $now = DateTime->from_epoch(epoch => AnyEvent->now);
    $now->set_time_zone( $self->time_zone ) if $self->time_zone;
    my $next = $self->next_event($now);
    return
        if not $next;
    my $interval = $next->subtract_datetime_absolute($now)->in_units('nanoseconds') / 1_000_000_000;
    $self->_timer(AnyEvent->timer(
        after => $interval,
        cb => sub {
            $self->{cb}->();
            $self && $self->create_timer;
        },
    ));
}

sub next_event {
    my $self = shift;
    my $now = shift || DateTime->from_epoch(epoch => AnyEvent->now);
    $now->set_time_zone( $self->time_zone ) if $self->time_zone;
    $self->_cron->($now);
}

1;
__END__

=head1 NAME

AnyEvent::Timer::Cron - cron based timers for AnyEvent

=head1 SYNOPSIS

    use AnyEvent;
    use AnyEvent::Timer::Cron;

    my $w; $w = AnyEvent::Timer::Cron->new(cron => '0 1 * * *', cb => sub {
        undef $w;
        ...
    });
    AnyEvent->condvar->recv;

=head1 DESCRIPTION

This module creates timers based on cron rules.

This module primarily exists to replace similar that try to do too
much work, instead providing the simplest implementation, and using
AnyEvent's standard conventions for timer lifetime.

=head1 METHODS

=head2 new( cron => $cron, cb => sub {} )

Creates a new cron timer.  The callback will be called continually
according to the cron rules until the object is destroyed.

=over 4

=item cron

Required.  A cron rule, either in string form or as a
L<DateTime::Event::Cron>, L<DateTime::Event::Cron::Quartz>, or
L<DateTime::Set> object.

=item cb

Required.  The callback to call for the cron events.

=item time_zone

A cron rule will be calculated under the specified time zone.  If not specified,
events will be calculated using UTC.

=back

=head1 SEE ALSO

=over 4

=item L<AnyEvent::Cron>

=item L<AnyEvent::DateTime::Cron>

=back

=head1 AUTHOR

haarg - Graham Knop (cpan:HAARG) <haarg@haarg.org>

=head2 CONTRIBUTORS

keedi - Keedi Kim (cpan:KEEDI) <keedi@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2013 the AnyEvent::Timer::Cron L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut
