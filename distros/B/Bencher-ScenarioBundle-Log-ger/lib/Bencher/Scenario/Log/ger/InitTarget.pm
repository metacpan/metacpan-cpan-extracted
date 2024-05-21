package Bencher::Scenario::Log::ger::InitTarget;

use 5.010001;
use strict;
use warnings;

use File::Temp qw(tempfile);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-05-12'; # DATE
our $DIST = 'Bencher-ScenarioBundle-Log-ger'; # DIST
our $VERSION = '0.020'; # VERSION

my ($fh, $fname) = tempfile();

our $scenario = {
    summary => 'Benchmark init_target()',
    description => <<'_',

Each participant performs 1000 times init_target() to a single package, with
different configuration.

_
    participants => [
        {name=>"1k default" ,
         code_template => 'use Log::ger (); local %Log::ger::Global_Hooks = %Log::ger::Default_Hooks; for(1..1000) { Log::ger::init_target(package =>"main") }'},
        {name=>"1k with LGO:Screen" ,
         code_template => 'use Log::ger (); local %Log::ger::Global_Hooks = %Log::ger::Default_Hooks; use Log::ger::Output; Log::ger::Output->set("Screen"); for(1..1000) { Log::ger::init_target(package => "main") }'},
        {name=>"1k with LGO:File" ,
         code_template => 'use Log::ger (); local %Log::ger::Global_Hooks = %Log::ger::Default_Hooks; use Log::ger::Output; Log::ger::Output->set("File", path=>'.qq('$fname').'); for(1..1000) { Log::ger::init_target(package => "main") }'},
        {name=>"1k with LGO:Composite (0 outputs)" ,
         code_template => 'use Log::ger (); local %Log::ger::Global_Hooks = %Log::ger::Default_Hooks; use Log::ger::Output; Log::ger::Output->set("Composite"); for(1..1000) { Log::ger::init_target(package => "main") }'},
        {name=>"1k with LGO:Composite (Screen)" ,
         code_template => 'use Log::ger (); local %Log::ger::Global_Hooks = %Log::ger::Default_Hooks; use Log::ger::Output; Log::ger::Output->set("Composite", outputs=>{Screen=>{}}); for(1..1000) { Log::ger::init_target(package => "main") }'},
        {name=>"1k with LGO:Composite (Screen+File)" ,
         code_template => 'use Log::ger (); local %Log::ger::Global_Hooks = %Log::ger::Default_Hooks; use Log::ger::Output; Log::ger::Output->set("Composite", outputs=>{Screen=>{}, File=>{conf=>{path=>'.qq('$fname').'}}}); for(1..1000) { Log::ger::init_target(package => "main") }'},
        {name=>"1k with LGO:Composite (Screen+File & pattern layouts)" ,
         code_template => 'use Log::ger (); local %Log::ger::Global_Hooks = %Log::ger::Default_Hooks; use Log::ger::Output; Log::ger::Output->set("Composite", outputs=>{Screen=>{layout=>[Pattern=>{format=>"[%d] %m"}]}, File=>{conf=>{path=>'.qq('$fname').'}, layout=>[Pattern=>{format=>"[%d] [%P] %m"}]}}); for(1..1000) { Log::ger::init_target(package => "main") }'},
    ],
    precision => 7,
};

1;
# ABSTRACT: Benchmark init_target()

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::Log::ger::InitTarget - Benchmark init_target()

=head1 VERSION

This document describes version 0.020 of Bencher::Scenario::Log::ger::InitTarget (from Perl distribution Bencher-ScenarioBundle-Log-ger), released on 2024-05-12.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m Log::ger::InitTarget

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Each participant performs 1000 times init_target() to a single package, with
different configuration.


Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARK PARTICIPANTS

=over

=item * 1k default (perl_code)

Code template:

 use Log::ger (); local %Log::ger::Global_Hooks = %Log::ger::Default_Hooks; for(1..1000) { Log::ger::init_target(package =>"main") }



=item * 1k with LGO:Screen (perl_code)

Code template:

 use Log::ger (); local %Log::ger::Global_Hooks = %Log::ger::Default_Hooks; use Log::ger::Output; Log::ger::Output->set("Screen"); for(1..1000) { Log::ger::init_target(package => "main") }



=item * 1k with LGO:File (perl_code)

Code template:

 use Log::ger (); local %Log::ger::Global_Hooks = %Log::ger::Default_Hooks; use Log::ger::Output; Log::ger::Output->set("File", path=>'/tmp/meZxsdSHNx'); for(1..1000) { Log::ger::init_target(package => "main") }



=item * 1k with LGO:Composite (0 outputs) (perl_code)

Code template:

 use Log::ger (); local %Log::ger::Global_Hooks = %Log::ger::Default_Hooks; use Log::ger::Output; Log::ger::Output->set("Composite"); for(1..1000) { Log::ger::init_target(package => "main") }



=item * 1k with LGO:Composite (Screen) (perl_code)

Code template:

 use Log::ger (); local %Log::ger::Global_Hooks = %Log::ger::Default_Hooks; use Log::ger::Output; Log::ger::Output->set("Composite", outputs=>{Screen=>{}}); for(1..1000) { Log::ger::init_target(package => "main") }



=item * 1k with LGO:Composite (Screen+File) (perl_code)

Code template:

 use Log::ger (); local %Log::ger::Global_Hooks = %Log::ger::Default_Hooks; use Log::ger::Output; Log::ger::Output->set("Composite", outputs=>{Screen=>{}, File=>{conf=>{path=>'/tmp/meZxsdSHNx'}}}); for(1..1000) { Log::ger::init_target(package => "main") }



=item * 1k with LGO:Composite (Screen+File & pattern layouts) (perl_code)

Code template:

 use Log::ger (); local %Log::ger::Global_Hooks = %Log::ger::Default_Hooks; use Log::ger::Output; Log::ger::Output->set("Composite", outputs=>{Screen=>{layout=>[Pattern=>{format=>"[%d] %m"}]}, File=>{conf=>{path=>'/tmp/meZxsdSHNx'}, layout=>[Pattern=>{format=>"[%d] [%P] %m"}]}}); for(1..1000) { Log::ger::init_target(package => "main") }



=back

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.38.2 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-164-generic >>.

Benchmark command (default options):

 % bencher -m Log::ger::InitTarget

Result formatted as table:

 #table1#
 +-------------------------------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | participant                                           | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +-------------------------------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | 1k with LGO:Composite (Screen+File & pattern layouts) |     0.82  |      1200 |                 0.00% |               950.97% |   0.0042  |       7 |
 | 1k default                                            |     0.837 |      1190 |                 2.38% |               926.55% |   0.0012  |       7 |
 | 1k with LGO:Composite (Screen+File)                   |     0.87  |      1100 |                 6.64% |               885.51% |   0.0042  |       7 |
 | 1k with LGO:Composite (Screen)                        |     1.2   |       860 |                42.47% |               637.70% |   0.0049  |       7 |
 | 1k with LGO:Screen                                    |     7.22  |       138 |               783.26% |                18.99% | 8.6e-05   |       7 |
 | 1k with LGO:File                                      |     7.51  |       133 |               818.50% |                14.42% |   0.00011 |       9 |
 | 1k with LGO:Composite (0 outputs)                     |     8.59  |       116 |               950.97% |                 0.00% | 4.7e-05   |      10 |
 +-------------------------------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                                                            Rate  1k with LGO:Composite (Screen+File & pattern layouts)  1k default  1k with LGO:Composite (Screen+File)  1k with LGO:Composite (Screen)  1k with LGO:Screen  1k with LGO:File  1k with LGO:Composite (0 outputs) 
  1k with LGO:Composite (Screen+File & pattern layouts)   0.82/s                                                     --          0%                                  -8%                            -28%                -88%              -88%                               -90% 
  1k default                                             0.837/s                                                     0%          --                                  -7%                            -27%                -88%              -88%                               -90% 
  1k with LGO:Composite (Screen+File)                     0.87/s                                                     9%          8%                                   --                            -21%                -87%              -87%                               -89% 
  1k with LGO:Composite (Screen)                           1.2/s                                                    39%         38%                                  27%                              --                -83%              -84%                               -86% 
  1k with LGO:Screen                                      7.22/s                                                   769%        762%                                 697%                            523%                  --               -3%                               -15% 
  1k with LGO:File                                        7.51/s                                                   802%        794%                                 727%                            546%                  3%                --                               -12% 
  1k with LGO:Composite (0 outputs)                       8.59/s                                                   934%        925%                                 848%                            641%                 18%               14%                                 -- 
 
 Legends:
   1k default: participant=1k default
   1k with LGO:Composite (0 outputs): participant=1k with LGO:Composite (0 outputs)
   1k with LGO:Composite (Screen): participant=1k with LGO:Composite (Screen)
   1k with LGO:Composite (Screen+File & pattern layouts): participant=1k with LGO:Composite (Screen+File & pattern layouts)
   1k with LGO:Composite (Screen+File): participant=1k with LGO:Composite (Screen+File)
   1k with LGO:File: participant=1k with LGO:File
   1k with LGO:Screen: participant=1k with LGO:Screen

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-ScenarioBundle-Log-ger>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-ScenarioBundle-Log-ger>.

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

This software is copyright (c) 2024, 2023, 2021, 2020, 2018, 2017 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-ScenarioBundle-Log-ger>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
