package Bencher::Scenario::LogGer::Overhead;

our $DATE = '2019-09-18'; # DATE
our $VERSION = '0.015'; # VERSION

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

This document describes version 0.015 of Bencher::Scenario::LogGer::Overhead (from Perl distribution Bencher-Scenarios-LogGer), released on 2019-09-18.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m LogGer::Overhead

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Log::Any> 1.705

L<Log::Contextual> 0.008001

L<Log::Dispatch> 2.67

L<Log::Dispatch::Null> 2.67

L<Log::Dispatchouli> 2.015

L<Log::Log4perl> 1.49

L<Log::Log4perl::Tiny> 1.4.0

L<Log::ger> 0.028

L<Log::ger::App> 0.011

L<Log::ger::Layout::Pattern> 0.004

L<Log::ger::Output> 0.028

L<Mojo::Log>

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



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.1 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.3 >>, OS kernel: I<< Linux version 4.10.0-38-generic >>.

Benchmark with default options (C<< bencher -m LogGer::Overhead >>):

 #table1#
 +------------------------------------------------------------------+-----------+-------------------------+------------+-----------+---------+
 | participant                                                      | time (ms) | code_overhead_time (ms) | vs_slowest |  errors   | samples |
 +------------------------------------------------------------------+-----------+-------------------------+------------+-----------+---------+
 | use Mojo::Log; my $log=Mojo::Log->new(level=>"warn")             |      92   |      85.8               |       1    |   0.00036 |      20 |
 | use Mojo::Log;                                                   |      92   |      85.8               |       1    |   0.00035 |      20 |
 | use Log::Dispatchouli;                                           |      91   |      84.8               |       1    |   0.00035 |      20 |
 | use Log::Dispatch; my $null = Log::Dispatch->new(outputs=>[ ["Nu |      88   |      81.8               |       1.1  |   0.00019 |      20 |
 | use Log::Dispatch;                                               |      84   |      77.8               |       1.1  |   0.00046 |      20 |
 | use Log::Contextual qw(:log);                                    |      64.8 |      58.6               |       1.42 | 5.1e-05   |      20 |
 | use Log::Log4perl;                                               |      32.6 |      26.4               |       2.82 | 1.3e-05   |      20 |
 | use Log::ger::App; use Log::ger;                                 |      21.1 |      14.9               |       4.38 | 1.9e-05   |      20 |
 | use Log::Log4perl::Tiny;                                         |      19.2 |      13                 |       4.81 | 1.2e-05   |      20 |
 | use Log::ger::Like::Log4perl;                                    |      16   |       9.8               |       5.9  | 3.4e-05   |      20 |
 | use Log::ger::App;                                               |      14.9 |       8.7               |       6.2  | 1.1e-05   |      20 |
 | use Log::Any q($log);                                            |      14   |       7.8               |       6.7  | 1.6e-05   |      20 |
 | use Log::Any;                                                    |      13   |       6.8               |       7    | 1.7e-05   |      20 |
 | use Log::ger::Output::Composite;                                 |      12   |       5.8               |       7.7  |   2e-05   |      20 |
 | use Log::ger::Output::Screen;                                    |      11.3 |       5.1               |       8.18 |   1e-05   |      20 |
 | use Log::ger::Plugin::OptAway; use Log::ger;                     |       9   |       2.8               |      10    | 1.6e-05   |      20 |
 | use strict; use warnings;                                        |       8.2 |       2                 |      11    | 1.3e-05   |      20 |
 | use warnings;                                                    |       7.9 |       1.7               |      12    | 1.7e-05   |      20 |
 | use Log::ger::Like::LogAny;                                      |       7.3 |       1.1               |      13    | 2.3e-05   |      20 |
 | use Log::ger;                                                    |       7.2 |       1                 |      13    | 1.4e-05   |      20 |
 | use Log::ger; Log::ger->get_logger;                              |       7.1 |       0.899999999999999 |      13    | 1.2e-05   |      20 |
 | use Log::ger ();                                                 |       7.1 |       0.899999999999999 |      13    | 9.6e-06   |      22 |
 | use strict;                                                      |       6.7 |       0.5               |      14    | 1.5e-05   |      20 |
 | perl -e1 (baseline)                                              |       6.2 |       0                 |      15    | 1.2e-05   |      21 |
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

This software is copyright (c) 2019, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
