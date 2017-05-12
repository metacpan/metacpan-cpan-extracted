#!/usr/local/bin/perl -w
# ========================================================================
# delta.pl - calculate Benchmark::Timer object call overhead
# Andrew Ho (andrew@zeuscat.com)
#
# This program contains embedded documentation in Perl POD (Plain Old
# Documentation) format. Search for the string "=head1" in this document
# to find documentation snippets, or use "perldoc" to read it; utilities
# like "pod2man" and "pod2html" can reformat as well.
#
# Copyright(c) 2000-2001 Andrew Ho.
#
# This script is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# Last modified March 29, 2001
# ========================================================================

=head1 NAME

delta.pl - calculate Benchmark::Timer object call overhead
     
=head1 SYNOPSIS

    % ./delta.pl [n]

=head1 DESCRIPTION

This short script calculates the approximate speed overhead, on your
system, of using Benchmark::Timer to time repeated benchmark calls,
rather than using Time::HiRes and lexical temporary values directly.
By default, it does 10,000 trials of timing nothing. It benchmarks
using first Benchmark::Timer, then bare Time::HiRes calls, and reports
the average times taken to perform the no-op.

Subtract the second from the first to find the approximate overhead imposed
by using Benchmark::Timer. This is typically significant and consistent,
but pretty tiny, on the order of microseconds. The magnitude of the
overhead also falls quickly and asymptotically as the number of trials
increases from one, levelling off at anything over around 100 trials.

=head1 SEE ALSO

L<Benchmark>, L<Time::HiRes>

=head1 AUTHOR

Andrew Ho E<lt>andrew@zeuscat.comE<gt>

=head1 COPYRIGHT

Copyright(c) 2000-2001 Andrew Ho.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


# ------------------------------------------------------------------------
# Main loop.

use strict;

use Benchmark::Timer;
use Time::HiRes qw( gettimeofday tv_interval );

use vars qw($N); $N = shift || 10_000;

my $t = new Benchmark::Timer;
foreach(1 .. $N) {
    $t->start('noop');
    $t->stop;
}
my $bt = $t->result('noop');
printf "Benchmark::Timer => %s\n", Benchmark::Timer::timestr($bt);

my @interval = ();
foreach(1 .. $N) {
    my $before = [ gettimeofday ];
    my $elapsed = tv_interval( $before, [ gettimeofday ] );
    push @interval, $elapsed;
}
my $interval = 0; $interval += $_ foreach @interval; $interval /= @interval;
printf "Time::HiRes => %s\n", Benchmark::Timer::timestr($interval);

exit 0;


# ========================================================================
__END__
