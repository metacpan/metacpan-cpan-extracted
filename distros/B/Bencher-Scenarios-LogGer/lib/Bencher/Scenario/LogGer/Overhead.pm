package Bencher::Scenario::LogGer::Overhead;

our $DATE = '2021-04-09'; # DATE
our $VERSION = '0.018'; # VERSION

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
        'XLog' => {},
    },
    code_startup => 1,
    participants => [
        # a benchmark for Log::ger: strict/warnings
        {code_template=>'use strict;'},
        {code_template=>'use warnings;'},
        {code_template=>'use strict; use warnings;'},

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

        {code_template=>'use XLog;'},

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

This document describes version 0.018 of Bencher::Scenario::LogGer::Overhead (from Perl distribution Bencher-Scenarios-LogGer), released on 2021-04-09.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m LogGer::Overhead

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Log::Any> 1.708

L<Log::Contextual> 0.008001

L<Log::Dispatch> 2.68

L<Log::Dispatch::Null> 2.68

L<Log::Dispatchouli> 2.019

L<Log::Log4perl> 1.49

L<Log::Log4perl::Tiny> 1.4.0

L<Log::ger> 0.038

L<Log::ger::App> 0.018

L<Log::ger::Layout::Pattern> 0.007

L<Log::ger::Output> 0.038

L<Mojo::Log>

L<XLog> 1.1.0

=head1 BENCHMARK PARTICIPANTS

=over

=item * use strict; (perl_code)

Code template:

 use strict;



=item * use warnings; (perl_code)

Code template:

 use warnings;



=item * use strict; use warnings; (perl_code)

Code template:

 use strict; use warnings;



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



=item * use XLog; (perl_code)

Code template:

 use XLog;



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.30.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.3.0-64-generic >>.

Benchmark with default options (C<< bencher -m LogGer::Overhead >>):

 #table1#
 +------------------------------------------------------------------+-----------+---------------------+-----------------------+-----------------------+-----------+---------+
 | participant                                                      | time (ms) | code_overhead_time  | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +------------------------------------------------------------------+-----------+---------------------+-----------------------+-----------------------+-----------+---------+
 | use Mojo::Log;                                                   |    110    | 102                 |                 0.00% |              1222.58% |   0.00026 |      20 |
 | use Mojo::Log; my $log=Mojo::Log->new(level=>"warn")             |    105    |  97                 |                 0.78% |              1212.35% |   4e-05   |      20 |
 | use Log::Dispatchouli;                                           |     85    |  77                 |                24.66% |               960.99% |   0.00045 |      20 |
 | use Log::Dispatch; my $null = Log::Dispatch->new(outputs=>[ ["Nu |     81    |  73                 |                31.32% |               907.18% |   0.00023 |      21 |
 | use Log::Dispatch;                                               |     73.4  |  65.4               |                44.11% |               817.75% |   5e-05   |      20 |
 | use Log::Contextual qw(:log);                                    |     71    |  63                 |                48.71% |               789.38% |   0.00024 |      20 |
 | use Log::Log4perl;                                               |     36    |  28                 |               193.56% |               350.53% |   0.0001  |      20 |
 | use Log::ger::App; use Log::ger;                                 |     29    |  21                 |               267.84% |               259.56% | 4.6e-05   |      20 |
 | use Log::ger::App;                                               |     24    |  16                 |               343.30% |               198.35% | 2.7e-05   |      20 |
 | use XLog;                                                        |     24    |  16                 |               344.67% |               197.43% | 2.5e-05   |      20 |
 | use Log::Log4perl::Tiny;                                         |     20    |  12                 |               438.17% |               145.75% | 3.6e-05   |      20 |
 | use Log::ger::Like::Log4perl;                                    |     17    |   9                 |               508.84% |               117.23% | 4.2e-05   |      20 |
 | use Log::Any q($log);                                            |     20    |  12                 |               561.57% |                99.92% |   0.00021 |      20 |
 | use Log::Any;                                                    |     14    |   6                 |               647.20% |                77.01% |   2e-05   |      20 |
 | use Log::ger::Output::Composite;                                 |     12.9  |   4.9               |               716.92% |                61.90% | 6.6e-06   |      21 |
 | use Log::ger::Output::Screen;                                    |     12    |   4                 |               758.44% |                54.07% | 1.3e-05   |      20 |
 | use Log::ger::Plugin::OptAway; use Log::ger;                     |     10.1  |   2.1               |               949.31% |                26.04% | 9.2e-06   |      21 |
 | use strict; use warnings;                                        |      9.5  |   1.5               |              1017.17% |                18.39% |   3e-05   |      20 |
 | use warnings;                                                    |      9.2  |   1.2               |              1053.37% |                14.67% |   3e-05   |      20 |
 | use Log::ger::Like::LogAny;                                      |      8.9  |   0.9               |              1093.42% |                10.82% | 2.5e-05   |      20 |
 | use Log::ger; Log::ger->get_logger;                              |      8.6  |   0.6               |              1130.54% |                 7.48% | 2.5e-05   |      20 |
 | use Log::ger;                                                    |      8.5  |   0.5               |              1143.82% |                 6.33% | 1.7e-05   |      20 |
 | use Log::ger ();                                                 |      8.5  |   0.5               |              1147.98% |                 5.98% | 2.4e-05   |      20 |
 | use strict;                                                      |      8.45 |   0.449999999999999 |              1151.79% |                 5.66% | 6.2e-06   |      20 |
 | perl -e1 (baseline)                                              |      8    |   0                 |              1222.58% |                 0.00% | 1.6e-05   |      20 |
 +------------------------------------------------------------------+-----------+---------------------+-----------------------+-----------------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-LogGer>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-LogGer>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Bencher-Scenarios-LogGer/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2018, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
