package Algorithm::EventsPerSecond;

use 5.006;
use strict;
use warnings;

=head1 NAME

Algorithm::EventsPerSecond - A sliding-window events-per-second rate counter with a optional XS backend for additional zoomies.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

our $BACKEND;

BEGIN {
    $BACKEND = 'PP';
    unless ( $ENV{ALGORITHM_EVENTSPERSECOND_PP} ) {
        local $@;
        if ( eval { require Algorithm::EventsPerSecond::XS; 1 } ) {
            $BACKEND = 'XS';
        }
    }
}

=head1 SYNOPSIS

    use Algorithm::EventsPerSecond;

    my $meter = Algorithm::EventsPerSecond->new( window => 10 );  # 10-second window

    while (my $event = get_next_event()) {
        $meter->mark;                 # record one event
        # $meter->mark(5);            # or record several at once

        printf "current rate: %.2f events/sec\n", $meter->rate;
    }

    print "events seen in window: ", $meter->count, "\n";
    print "lifetime total:        ", $meter->total, "\n";


=head1 DESCRIPTION

Algorithm::EventsPerSecond keeps per-second counts in a fixed-size ring buffer and
reports the average event rate over the most recent N seconds (the
"window"). Memory use is constant regardless of event volume, and both
C<mark> and C<rate> are O(1) averaged out over time.

=head1 METHODS

=head2 new( window => $seconds )

Construct a meter. C<window> is the length of the averaging window in
seconds and defaults to 60.

=cut

sub new {
    my ($class, %args) = @_;

    my $window = $args{window} // 60;
    die "window must be a positive integer" unless $window =~ /^\d+$/ && $window > 0;

    my $self = {
        window  => $window,
        total   => 0,                   # lifetime event count
        started => time(),
    };

    if ( $BACKEND eq 'XS' ) {
        # packed int64_t ring buffers, scanned in C
        $self->{buckets} = "\0" x ( $window * 8 );
        $self->{stamps}  = "\0" x ( $window * 8 );
    }
    else {
        $self->{buckets} = [ (0) x $window ];   # counts, indexed by (epoch_sec % window)
        $self->{stamps}  = [ (0) x $window ];   # epoch second each bucket belongs to
    }

    return bless $self, $class;
}

# Internal, PP backend: get the bucket for the current second, clearing it if stale.
sub _bucket_index {
    my ($self, $now_sec) = @_;
    my $i = $now_sec % $self->{window};
    if ($self->{stamps}[$i] != $now_sec) {
        $self->{buckets}[$i] = 0;
        $self->{stamps}[$i]  = $now_sec;
    }
    return $i;
}

=head2 mark( [$count] )

Record one event, or C<$count> events. Returns the meter object, so calls
can be chained.

=cut

sub _mark_pp {
    my ($self, $count) = @_;
    $count //= 1;

    my $now_sec = int(time());
    my $i = $self->_bucket_index($now_sec);

    $self->{buckets}[$i] += $count;
    $self->{total}       += $count;

    return $self;
}

sub _mark_xs {
    my ($self, $count) = @_;
    $count //= 1;

    Algorithm::EventsPerSecond::XS::_xs_mark(
        $self->{buckets}, $self->{stamps},
        $self->{window},  int(time()), $count,
    );
    $self->{total} += $count;

    return $self;
}

=head2 count

Number of events recorded within the current window.

=cut

sub _count_pp {
    my ($self) = @_;

    my $now_sec = int(time());
    my $window  = $self->{window};
    my $oldest  = $now_sec - $window + 1;

    my $sum = 0;
    for my $i (0 .. $window - 1) {
        $sum += $self->{buckets}[$i]
            if $self->{stamps}[$i] >= $oldest;
    }
    return $sum;
}

sub _count_xs {
    my ($self) = @_;

    my $now_sec = int(time());
    return Algorithm::EventsPerSecond::XS::_xs_count(
        $self->{buckets}, $self->{stamps},
        $self->{window},  $now_sec - $self->{window} + 1,
    );
}

if ( $BACKEND eq 'XS' ) {
    *mark  = \&_mark_xs;
    *count = \&_count_xs;
}
else {
    *mark  = \&_mark_pp;
    *count = \&_count_pp;
}

=head2 rate

Average events per second over the window. If the meter has been alive
for less time than the window, the elapsed lifetime is used instead, so
early readings are not artificially deflated.

=cut

sub rate {
    my ($self) = @_;

    my $elapsed = time() - $self->{started};
    my $span    = $elapsed < $self->{window} ? $elapsed : $self->{window};
    return 0 if $span <= 0;

    return $self->count / $span;
}

=head2 total

Lifetime count of all events ever recorded, regardless of window.

=cut

sub total { $_[0]->{total} }

=head2 window

The configured window length in seconds.

=cut

sub window { $_[0]->{window} }

=head2 reset

Clear all counts and restart the clock. Returns the meter object.

=cut

sub reset {
    my ($self) = @_;
    if ( $BACKEND eq 'XS' ) {
        $self->{buckets} = "\0" x ( $self->{window} * 8 );
        $self->{stamps}  = "\0" x ( $self->{window} * 8 );
    }
    else {
        @{ $self->{buckets} } = (0) x $self->{window};
        @{ $self->{stamps} }  = (0) x $self->{window};
    }
    $self->{total}   = 0;
    $self->{started} = time();
    return $self;
}

=head2 backend

Returns C<'XS'> when the accelerated backend is in use, C<'PP'> for the
pure Perl fallback. May be called as a class or instance method.

=cut

sub backend { $BACKEND }

=head2 simd

Returns which SIMD flavor the XS backend was compiled with: C<'AVX2'>,
C<'SSE4.2'>, or C<'scalar'> (plain C, left to the compiler's
auto-vectorizer). Returns undef when the pure Perl backend is in use.

=cut

sub simd {
    return undef unless $BACKEND eq 'XS';
    return Algorithm::EventsPerSecond::XS::_xs_simd();
}

=head1 ACCELERATION

If a working C compiler is available at install time, an accelerated XS
backend, L<Algorithm::EventsPerSecond::XS>, is built and loaded
automatically. It keeps the ring buffer in packed C<int64_t> buffers and
scans the window in C, using SIMD (AVX2 or SSE4.2) when the compiler
targets a CPU that has it. If the backend cannot be loaded for any
reason (not built, no compiler at install time), a pure Perl
implementation with identical behavior is used instead.

The following control this.

=head2 IF_OPT

Environment variable read by C<Makefile.PL>: the C<-O> optimization
value used when compiling the XS backend during install. C<IF_OPT=2>
(or C<IF_OPT=-O2>) compiles with C<-O2>. The default is C<-O3>.

=head2 IF_ARCH

Environment variable read by C<Makefile.PL>: optionally sets the
architecture used for the build during the install. C<IF_ARCH=native>
(or C<IF_ARCH=-march=native>) compiles with C<-march=native>, enabling
the SIMD paths the build host supports. When unset the compiler's
baseline architecture is used.

=head2 PUREPERL_ONLY

C<perl Makefile.PL PUREPERL_ONLY=1> skips building the XS backend.

=head2 ALGORITHM_EVENTSPERSECOND_PP

Environment variable read at runtime: when true, skip the XS backend
entirely and use pure Perl.

Which backend is in use can be checked via L</backend> and L</simd>.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-algorithm-eventspersecond at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Algorithm-EventsPerSecond>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Algorithm::EventsPerSecond


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Algorithm-EventsPerSecond>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Algorithm-EventsPerSecond>

=item * Search CPAN

L<https://metacpan.org/release/Algorithm-EventsPerSecond>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999


=cut

1; # End of Algorithm::EventsPerSecond
