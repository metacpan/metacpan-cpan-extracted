package Bench;

our $VERSION = '0.10'; # VERSION

use 5.010001;
use strict;
use warnings;

use Time::HiRes qw/gettimeofday tv_interval/;

my $bench_called;
my ($t0, $ti);

sub _set_start_time {
    $t0 = [gettimeofday];
}

sub _set_interval {
    $ti = tv_interval($t0, [gettimeofday]);
}

sub import {
    _set_start_time;
    no strict 'refs';
    my $caller = caller();
    *{"$caller\::bench"} = \&bench;
}

sub _fmt_num {
    my ($num, $unit, $nsig) = @_;
    $nsig //= 4;
    my $fmt;

    my $l = $num ? int(log(abs($num))/log(10)) : 0;
    if ($l >= $nsig) {
        $fmt = "%.0f";
    } elsif ($l < 0) {
        $fmt = "%.${nsig}f";
    } else {
        $fmt = "%.".($nsig-$l-1)."f";
    }
    #say "D:fmt=$fmt";
    sprintf($fmt, $num) . ($unit // "");
}

sub bench($;$) {
    my ($subs0, $opts) = @_;
    $opts //= {};
    $opts   = {n=>$opts} if ref($opts) ne 'HASH';
    $opts->{t} //= 1;
    $opts->{n} //= 100;
    my %subs;
    if (ref($subs0) eq 'CODE') {
        %subs = (a=>$subs0);
    } elsif (ref($subs0) eq 'HASH') {
        %subs = %$subs0;
    } elsif (ref($subs0) eq 'ARRAY') {
        my $name = "a";
        for (@$subs0) { $subs{$name++} = $_ }
    } else {
        die "Usage: bench(CODE|{a=>CODE,b=>CODE, ...}|[CODE, CODE, ...], ".
            "{opt=>val, ...})";
    }
    die "Please specify one or more subs"
        unless keys %subs;

    my $use_dumbbench;
    if ($opts->{dumbbench}) {
        $use_dumbbench++;
        require Dumbbench;
    } elsif (!defined $opts->{dumbbench}) {
        $use_dumbbench++ if $INC{"Dumbbench.pm"};
    }

    my $void = !defined(wantarray);
    if ($use_dumbbench) {

        $opts->{dumbbench_options} //= {};
        my $bench = Dumbbench->new(%{ $opts->{dumbbench_options} });
        $bench->add_instances(
            map { Dumbbench::Instance::PerlSub->new(code => $subs{$_}) }
                keys %subs
        );
        $bench->run;
        $bench->report;

    } else {
        require Benchmark;
        Benchmark::timethese(
            $opts->{n},
            \%subs,
        );
    }

    $bench_called++;
}

END {
    _set_interval;
    say _fmt_num($ti, "s") unless $bench_called || $ENV{HARNESS_ACTIVE};
}

1;
# ABSTRACT: Benchmark running times of Perl code

__END__

=pod

=encoding UTF-8

=head1 NAME

Bench - Benchmark running times of Perl code

=head1 VERSION

This document describes version 0.10 of Bench (from Perl distribution Bench), released on 2014-05-14.

=head1 SYNOPSIS

 # time the whole program
 % perl -MBench -e'...'
 0.0123s

 # basic usage of bench()
 % perl -MBench -e'bench sub { ... }'
 100 calls (58548/s), 0.0017s (0.0171ms/call)

 # get bench result in a variable
 % perl -MBench -E'my $res = bench sub { ... }'

 # specify bench options
 % perl -MBench -E'bench sub { ... }, 100'
 % perl -MBench -E'bench sub { ... }, {n=>-5}'
 304347 calls (60665/s), 5.017s (0.0165ms/call)

 # use Dumbbench as the backend
 % perl -MDumbbench -MBench -E'bench sub { ... }'
 % perl -MBench -E'bench sub { ... }, {dumbbench=>1, dumbbench_options=>{...}}'
 Ran 26 iterations (6 outliers).
 Rounded run time per iteration: 2.9029e-02 +/- 4.8e-05 (0.2%)

 # bench multiple codes
 % perl -MBench -E'bench {a=>sub{...}, b=>sub{...}}, {n=>-2}'
 % perl -MBench -E'bench [sub{...}, sub{...}]'; # automatically named a, b, ...
 b: 100 calls (5357/s), 0.0187s (0.1870ms/call)
 a: 100 calls (12120/s), 0.0083s (0.0825ms/call)
 Fastest is a (2.267x b)

=head1 DESCRIPTION

This module is an alternative interface for L<Benchmark>. It provides some nice
defaults and a simpler interface. There is only one function, B<bench()>, and it
is exported by default. If bench() is never called, the whole program will be
timed.

This module can utilize L<Dumbbench> as the backend instead of L<Benchmark>.

=head1 FUNCTIONS

=head2 bench SUB(S)[, OPTS]

Run Perl code(s) and time it (them). Exported by default. SUB can be a coderef
for specifying a single sub, or hashref/arrayref for specifying multiple subs.

Options are specified in hashref OPTS. Available options:

=over 4

=item * n => INT (default: 100)

Run the code C<n> times, or if negative, until at least C<n> CPU seconds.

=item * dumbbench => BOOL

If 0, do not use L<Dumbbench> even if it is available. If 1, require and use
L<Dumbbench>. If left undef, will use L<Dumbbench> if it is already loaded.

=item * dumbbench_options => HASHREF

Options that will be passed to Dumbbench constructor, e.g.
{target_rel_precision=>0.005, initial_runs=>20}.

=back

=head1 SEE ALSO

L<bench>, command-line interface for this module

L<Benchmark>

L<Dumbbench>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bench>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Bench>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bench>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
