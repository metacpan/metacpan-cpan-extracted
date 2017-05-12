package Bencher::Scenario::RegexpCommonVsRegexpPattern::Startup;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark module startup overhead of Regexp::Common vs Regexp::Pattern',

    # so the benchmark sample result POD displays the mod versions
    modules => {
        'Regexp::Common' => 0,
        'Regexp::Pattern' => 0,
    },

    participants => [
        {name=>'RC_defaults'  , perl_cmdline => ['-MRegexp::Common', '-e1']},
        {name=>'RC_nodefaults', perl_cmdline => ['-MRegexp::Common=no_defaults', '-e1']},
        {name=>'RP'           , perl_cmdline => ['-MRegexp::Pattern', '-e1']},
        {name=>'baseline'     , perl_cmdline => ['-e1']},
    ],
};

1;
# ABSTRACT: Benchmark module startup overhead of Regexp::Common vs Regexp::Pattern

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::RegexpCommonVsRegexpPattern::Startup - Benchmark module startup overhead of Regexp::Common vs Regexp::Pattern

=head1 VERSION

This document describes version 0.003 of Bencher::Scenario::RegexpCommonVsRegexpPattern::Startup (from Perl distribution Bencher-Scenarios-RegexpCommonVsRegexpPattern), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m RegexpCommonVsRegexpPattern::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Loading L<Regexp::Common> with C<no_defaults> (i.e. C<use Regexp::Common
'no_defaults>) actually incurs only a little overhead, compared to just C<use
Regexp::Common>.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Regexp::Common> 2016060801

L<Regexp::Pattern> 0.1.4

=head1 BENCHMARK PARTICIPANTS

=over

=item * RC_defaults (command)



=item * RC_nodefaults (command)



=item * RP (command)



=item * baseline (command)



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m RegexpCommonVsRegexpPattern::Startup >>):

 #table1#
 +---------------+-----------+-----------+------------+-----------+---------+
 | participant   | rate (/s) | time (ms) | vs_slowest |  errors   | samples |
 +---------------+-----------+-----------+------------+-----------+---------+
 | RC_defaults   |        12 |      81   |        1   |   0.00013 |      21 |
 | RC_nodefaults |       110 |       9.5 |        8.5 | 2.7e-05   |      20 |
 | RP            |       160 |       6.2 |       13   | 2.1e-05   |      20 |
 | baseline      |       220 |       4.5 |       18   |   1e-05   |      20 |
 +---------------+-----------+-----------+------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-RegexpCommonVsRegexpPattern>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-RegexpCommonVsRegexpPattern>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-RegexpCommonVsRegexpPattern>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
