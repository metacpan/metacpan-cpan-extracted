package Bencher::Scenario::IPC::System::Options;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-05-06'; # DATE
our $DIST = 'Bencher-Scenario-IPC-System-Options'; # DIST
our $VERSION = '0.040'; # VERSION

our $scenario = {
    summary => "Measure the overhead of IPC::System::Options's system()".
        "over CORE::system()",
    modules => {
        'IPC::System::Options' => {version=>0.339},
    },
    default_precision => 0.005,
    participants => [
        {
            name => 'core-true',
            code => sub {
                system {"/bin/true"} "/bin/true";
            },
        },
        {
            name => 'iso-true',
            module => 'IPC::System::Options',
            code => sub {
                IPC::System::Options::system({shell=>0}, "/bin/true");
            },
        },
        {
            name => 'core-perl',
            code => sub {
                system {$^X} $^X, "-e1";
            },
        },
        {
            name => 'iso-perl',
            module => 'IPC::System::Options',
            code => sub {
                IPC::System::Options::system({shell=>0}, $^X, "-e1");
            },
        },
    ],
};

1;
# ABSTRACT: Measure the overhead of IPC::System::Options's system()over CORE::system()

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::IPC::System::Options - Measure the overhead of IPC::System::Options's system()over CORE::system()

=head1 VERSION

This document describes version 0.040 of Bencher::Scenario::IPC::System::Options (from Perl distribution Bencher-Scenario-IPC-System-Options), released on 2022-05-06.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m IPC::System::Options

To run module startup overhead benchmark:

 % bencher --module-startup -m IPC::System::Options

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Conclusion: Testing on my system (L<IPC::System::Options> 0.24, perl: 5.22.0,
CPU: Intel(R) Core(TM) i5-2400 CPU @ 3.10GHz (4 cores)) shows the overhead to be
~40μs (0.04ms) so for benchmarking commands that have overhead in the range of
10-100ms we normally don't need to worry about the overhead of
IPC::System::Option (0.04-0.4%) when we are using default precision (~1%).

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<IPC::System::Options> 0.340

=head1 BENCHMARK PARTICIPANTS

=over

=item * core-true (perl_code)



=item * iso-true (perl_code)

L<IPC::System::Options>



=item * core-perl (perl_code)



=item * iso-perl (perl_code)

L<IPC::System::Options>



=back

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 19 >>, OS kernel: I<< Linux version 5.3.0-68-generic >>.

Benchmark command (default options):

 % bencher -m IPC::System::Options

Result formatted as table:

 #table1#
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | iso-perl    |       170 |       5.8 |                 0.00% |                53.98% | 2.8e-05 |      25 |
 | core-perl   |       180 |       5.5 |                 6.08% |                45.15% | 2.7e-05 |     185 |
 | iso-true    |       250 |       4   |                47.38% |                 4.48% | 1.9e-05 |     178 |
 | core-true   |       260 |       3.8 |                53.98% |                 0.00% | 1.9e-05 |     224 |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

              Rate  iso-perl  core-perl  iso-true  core-true 
  iso-perl   170/s        --        -5%      -31%       -34% 
  core-perl  180/s        5%         --      -27%       -30% 
  iso-true   250/s       44%        37%        --        -5% 
  core-true  260/s       52%        44%        5%         -- 
 
 Legends:
   core-perl: participant=core-perl
   core-true: participant=core-true
   iso-perl: participant=iso-perl
   iso-true: participant=iso-true

=head2 Sample benchmark #2

Benchmark command (benchmarking module startup overhead):

 % bencher -m IPC::System::Options --module-startup

Result formatted as table:

 #table2#
 +----------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant          | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +----------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | IPC::System::Options |       8.7 |                 3 |                 0.00% |                51.87% | 4.2e-05 |     243 |
 | perl -e1 (baseline)  |       5.7 |                 0 |                51.87% |                 0.00% | 2.8e-05 |      32 |
 +----------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                          Rate  IS:O  perl -e1 (baseline) 
  IS:O                 114.9/s    --                 -34% 
  perl -e1 (baseline)  175.4/s   52%                   -- 
 
 Legends:
   IS:O: mod_overhead_time=3 participant=IPC::System::Options
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-IPC-System-Options>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-IPC-System-Options>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-IPC-System-Options>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
