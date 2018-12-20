package Bencher::Scenario::LogGer::Overhead;

our $DATE = '2018-12-20'; # DATE
our $VERSION = '0.014'; # VERSION

use 5.010001;
use strict;
use warnings;

use File::Temp qw(tempfile);

my ($fh, $fname) = tempfile();

our $scenario = {
    summary => 'Measure startup overhead of various codes',
    modules => {
        'Log::Any' => {},
        'Log::ger' => {version=>'0.019'},
        'Log::ger::App' => {version=>'0.002'},
        'Log::ger::Output' => {version=>'0.005'},
        'Log::ger::Layout::Pattern' => {version=>'0'},
        'Log::Contextual' => {version=>'0'},
        'Log::Dispatch' => {version=>'0'},
        'Log::Dispatch::Null' => {version=>'0'},
        'Log::Log4perl' => {version=>'0'},
        'Log::Log4perl::Tiny' => {version=>'0'},
        'Log::Dispatchouli' => {version=>'0'},
        'Mojo::Log' => {version=>'0'},
    },
    code_startup => 1,
    participants => [
        {code_template=>'use Log::ger ();'},
        {code_template=>'use Log::ger;'},
        {code_template=>'use Log::ger; Log::ger->get_logger;'},
        {code_template=>'use Log::ger::App;'},
        {code_template=>'use Log::ger::App; use Log::ger;'},
        {code_template=>'use Log::ger::Plugin::OptAway; use Log::ger;'},
        {code_template=>'use Log::ger::Like::LogAny;'},
        {code_template=>'use Log::ger::Like::Log4perl;'},
        {code_template=>'use Log::ger::App;'},

        {code_template=>'use Log::Any;'},
        {code_template=>'use Log::Any q($log);'},

        {code_template=>'use Log::Contextual qw(:log);'},

        {code_template=>'use Log::Log4perl;'},

        {code_template=>'use Log::Log4perl::Tiny;'},

        {code_template=>'use Log::Dispatch;'},
        {code_template=>'use Log::Dispatch; my $null = Log::Dispatch->new(outputs=>[ ["Null", min_level=>"warn"] ])', tags=>['output']},

        {code_template=>'use Log::Dispatchouli;'},

        {code_template=>'use Log::ger::Output::Screen;', tags=>['output']},
        {code_template=>'use Log::ger::Output::Composite;', tags=>['output']},

        {code_template=>'use Mojo::Log;'},
        {code_template=>'use Mojo::Log; my $log=Mojo::Log->new(level=>"warn")'},

        # TODO: Lg + Composite (2 outputs)
        # TODO: Lg + Composite (2 outputs + pattern layouts)
        # TODO: Log::Any + Screen
        # TODO: Log::Log4perl + easy_init
    ],
};

1;
# ABSTRACT: Measure startup overhead of various codes

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::LogGer::Overhead - Measure startup overhead of various codes

=head1 VERSION

This document describes version 0.014 of Bencher::Scenario::LogGer::Overhead (from Perl distribution Bencher-Scenarios-LogGer), released on 2018-12-20.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m LogGer::Overhead

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Log::Any> 1.707

L<Log::Contextual> 0.007001

L<Log::Dispatch> 2.65

L<Log::Dispatch::Null> 2.65

L<Log::Dispatchouli> 2.015

L<Log::Log4perl> 1.49

L<Log::Log4perl::Tiny> 1.4.0

L<Log::ger> 0.025

L<Log::ger::App> 0.009

L<Log::ger::Layout::Pattern> 0.001

L<Log::ger::Output> 0.025

L<Mojo::Log>

=head1 BENCHMARK PARTICIPANTS

=over

=item * use Log::ger (); (perl_code)

Code template:

 use Log::ger ();



=item * use Log::ger; (perl_code)

Code template:

 use Log::ger;



=item * use Log::ger; Log::ger->get_logger; (perl_code)

Code template:

 use Log::ger; Log::ger->get_logger;



=item * use Log::ger::App; (perl_code)

Code template:

 use Log::ger::App;



=item * use Log::ger::App; use Log::ger; (perl_code)

Code template:

 use Log::ger::App; use Log::ger;



=item * use Log::ger::Plugin::OptAway; use Log::ger; (perl_code)

Code template:

 use Log::ger::Plugin::OptAway; use Log::ger;



=item * use Log::ger::Like::LogAny; (perl_code)

Code template:

 use Log::ger::Like::LogAny;



=item * use Log::ger::Like::Log4perl; (perl_code)

Code template:

 use Log::ger::Like::Log4perl;



=item * use Log::ger::App; (perl_code)

Code template:

 use Log::ger::App;



=item * use Log::Any; (perl_code)

Code template:

 use Log::Any;



=item * use Log::Any q($log); (perl_code)

Code template:

 use Log::Any q($log);



=item * use Log::Contextual qw(:log); (perl_code)

Code template:

 use Log::Contextual qw(:log);



=item * use Log::Log4perl; (perl_code)

Code template:

 use Log::Log4perl;



=item * use Log::Log4perl::Tiny; (perl_code)

Code template:

 use Log::Log4perl::Tiny;



=item * use Log::Dispatch; (perl_code)

Code template:

 use Log::Dispatch;



=item * use Log::Dispatch; my $null = Log::Dispatch->new(outputs=>[ ["Nu (perl_code) [output]

Code template:

 use Log::Dispatch; my $null = Log::Dispatch->new(outputs=>[ ["Null", min_level=>"warn"] ])



=item * use Log::Dispatchouli; (perl_code)

Code template:

 use Log::Dispatchouli;



=item * use Log::ger::Output::Screen; (perl_code) [output]

Code template:

 use Log::ger::Output::Screen;



=item * use Log::ger::Output::Composite; (perl_code) [output]

Code template:

 use Log::ger::Output::Composite;



=item * use Mojo::Log; (perl_code)

Code template:

 use Mojo::Log;



=item * use Mojo::Log; my $log=Mojo::Log->new(level=>"warn") (perl_code)

Code template:

 use Mojo::Log; my $log=Mojo::Log->new(level=>"warn")



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.0 >>, CPU: I<< Intel(R) Core(TM) i5-2400 CPU @ 3.10GHz (4 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.2 >>, OS kernel: I<< Linux version 4.8.0-53-generic >>.

Benchmark with default options (C<< bencher -m LogGer::Overhead >>):

 #table1#
 +------------------------------------------------------------------+-----------+-------------------------+------------+-----------+---------+
 | participant                                                      | time (ms) | code_overhead_time (ms) | vs_slowest |  errors   | samples |
 +------------------------------------------------------------------+-----------+-------------------------+------------+-----------+---------+
 | use Log::Dispatchouli;                                           |     110   |                   104   |        1   |   0.00018 |      20 |
 | use Log::Dispatch; my $null = Log::Dispatch->new(outputs=>[ ["Nu |     100   |                    94   |        1   |   0.00014 |      20 |
 | use Log::Dispatch;                                               |     100   |                    94   |        1.1 |   0.00048 |      20 |
 | use Mojo::Log;                                                   |      94   |                    88   |        1.1 |   0.00024 |      20 |
 | use Mojo::Log; my $log=Mojo::Log->new(level=>"warn")             |      92   |                    86   |        1.2 |   0.00019 |      20 |
 | use Log::Contextual qw(:log);                                    |      80   |                    74   |        1.3 |   0.00014 |      20 |
 | use Log::Log4perl;                                               |      40   |                    34   |        2.7 |   0.00022 |      20 |
 | use Log::ger::App; use Log::ger;                                 |      23   |                    17   |        4.6 | 6.1e-05   |      20 |
 | use Log::Log4perl::Tiny;                                         |      23   |                    17   |        4.7 |   0.00012 |      20 |
 | use Log::ger::App;                                               |      17   |                    11   |        6.4 | 5.5e-05   |      20 |
 | use Log::ger::Like::Log4perl;                                    |      16   |                    10   |        6.4 | 3.3e-05   |      20 |
 | use Log::Any q($log);                                            |      15   |                     9   |        6.9 | 4.5e-05   |      20 |
 | use Log::Any;                                                    |      14   |                     8   |        7.4 | 4.7e-05   |      20 |
 | use Log::ger::Output::Screen;                                    |      12   |                     6   |        8.7 | 3.6e-05   |      21 |
 | use Log::ger::Output::Composite;                                 |       9.1 |                     3.1 |       12   | 3.1e-05   |      20 |
 | use Log::ger::Plugin::OptAway; use Log::ger;                     |       9   |                     3   |       12   | 4.5e-05   |      21 |
 | use Log::ger::Like::LogAny;                                      |       7   |                     1   |       15   |   4e-05   |      20 |
 | use Log::ger; Log::ger->get_logger;                              |       6.6 |                     0.6 |       16   | 2.3e-05   |      20 |
 | use Log::ger;                                                    |       6.6 |                     0.6 |       16   | 3.9e-05   |      21 |
 | use Log::ger ();                                                 |       6.5 |                     0.5 |       16   | 5.1e-05   |      20 |
 | perl -e1 (baseline)                                              |       6   |                     0   |       18   | 5.5e-05   |      20 |
 +------------------------------------------------------------------+-----------+-------------------------+------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-LogGer>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-LogGer>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-LogGer>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
