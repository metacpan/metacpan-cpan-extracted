package Bencher::Scenario::Shell::Startup;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-07-08'; # DATE
our $DIST = 'Bencher-Scenario-Shell-Startup'; # DIST
our $VERSION = '0.001'; # VERSION

our $scenario = {
    summary => 'Benchmark startup overhead of various Unix shells',
    participants => [
        {
            cmdline=>["bash","--noprofile","--norc","-c","true"],
        },
        {
            cmdline=>["dash","-c","true"],
        },
        {
            cmdline=>["csh","-f","-c",":"],
        },
        {
            cmdline=>["tcsh","-f","-c",":"],
        },
        {
            cmdline=>["zsh","-f","-c","true"],
        },
    ],
};

1;
# ABSTRACT: Benchmark startup overhead of various Unix shells

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Shell::Startup - Benchmark startup overhead of various Unix shells

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::Shell::Startup (from Perl distribution Bencher-Scenario-Shell-Startup), released on 2023-07-08.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Shell::Startup

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARK PARTICIPANTS

=over

=item * bash (command)

Command line:

 bash --noprofile --norc -c true



=item * dash (command)

Command line:

 dash -c true



=item * csh (command)

Command line:

 csh -f -c :



=item * tcsh (command)

Command line:

 tcsh -f -c :



=item * zsh (command)

Command line:

 zsh -f -c true



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with default options (C<< bencher -m Shell::Startup >>):

 #table1#
 {dataset=>undef}
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | csh         |       123 |      8.1  |                 0.00% |                57.10% | 5.3e-06 |      20 |
 | tcsh        |       124 |      8.09 |                 0.10% |                56.95% | 8.1e-06 |      20 |
 | zsh         |       160 |      6.2  |                31.71% |                19.28% | 7.6e-06 |      20 |
 | bash        |       180 |      5.6  |                45.06% |                 8.31% | 1.2e-05 |      21 |
 | dash        |       190 |      5.2  |                57.10% |                 0.00% | 7.4e-06 |      20 |
 +-------------+-----------+-----------+-----------------------+-----------------------+---------+---------+

Formatted as L<Benchmark.pm|Benchmark> result:

         Rate  csh  tcsh   zsh  bash  dash 
  csh   123/s   --    0%  -23%  -30%  -35% 
  tcsh  124/s   0%    --  -23%  -30%  -35% 
  zsh   160/s  30%   30%    --   -9%  -16% 
  bash  180/s  44%   44%   10%    --   -7% 
  dash  190/s  55%   55%   19%    7%    -- 
 
 Legends:
   bash: participant=bash
   csh: participant=csh
   dash: participant=dash
   tcsh: participant=tcsh
   zsh: participant=zsh


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenario-Shell-Startup>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenario-Shell-Startup>.

=head1 SEE ALSO

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenario-Shell-Startup>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
