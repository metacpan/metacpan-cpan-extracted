package Bencher::Scenario::Log::ger::InitTarget;

use 5.010001;
use strict;
use warnings;

use File::Temp qw(tempfile);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-10-29'; # DATE
our $DIST = 'Bencher-Scenarios-Log-ger'; # DIST
our $VERSION = '0.019'; # VERSION

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

This document describes version 0.019 of Bencher::Scenario::Log::ger::InitTarget (from Perl distribution Bencher-Scenarios-Log-ger), released on 2023-10-29.

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

 use Log::ger (); local %Log::ger::Global_Hooks = %Log::ger::Default_Hooks; use Log::ger::Output; Log::ger::Output->set("File", path=>'/tmp/Fv4G1TRKZk'); for(1..1000) { Log::ger::init_target(package => "main") }



=item * 1k with LGO:Composite (0 outputs) (perl_code)

Code template:

 use Log::ger (); local %Log::ger::Global_Hooks = %Log::ger::Default_Hooks; use Log::ger::Output; Log::ger::Output->set("Composite"); for(1..1000) { Log::ger::init_target(package => "main") }



=item * 1k with LGO:Composite (Screen) (perl_code)

Code template:

 use Log::ger (); local %Log::ger::Global_Hooks = %Log::ger::Default_Hooks; use Log::ger::Output; Log::ger::Output->set("Composite", outputs=>{Screen=>{}}); for(1..1000) { Log::ger::init_target(package => "main") }



=item * 1k with LGO:Composite (Screen+File) (perl_code)

Code template:

 use Log::ger (); local %Log::ger::Global_Hooks = %Log::ger::Default_Hooks; use Log::ger::Output; Log::ger::Output->set("Composite", outputs=>{Screen=>{}, File=>{conf=>{path=>'/tmp/Fv4G1TRKZk'}}}); for(1..1000) { Log::ger::init_target(package => "main") }



=item * 1k with LGO:Composite (Screen+File & pattern layouts) (perl_code)

Code template:

 use Log::ger (); local %Log::ger::Global_Hooks = %Log::ger::Default_Hooks; use Log::ger::Output; Log::ger::Output->set("Composite", outputs=>{Screen=>{layout=>[Pattern=>{format=>"[%d] %m"}]}, File=>{conf=>{path=>'/tmp/Fv4G1TRKZk'}, layout=>[Pattern=>{format=>"[%d] [%P] %m"}]}}); for(1..1000) { Log::ger::init_target(package => "main") }



=back

=head1 BENCHMARK SAMPLE RESULTS

=head2 Sample benchmark #1

Run on: perl: I<< v5.38.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-164-generic >>.

Benchmark command (default options):

 % bencher -m Log::ger::InitTarget

Result formatted as table:

 #table1#
 +-------------------------------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | participant                                           | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +-------------------------------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | 1k with LGO:Composite (Screen+File & pattern layouts) |     0.825 |      1210 |                 0.00% |               766.08% |   0.00088 |       7 |
 | 1k default                                            |     0.83  |      1200 |                 1.03% |               757.26% |   0.0031  |       7 |
 | 1k with LGO:Composite (Screen+File)                   |     0.88  |      1100 |                 6.84% |               710.60% |   0.0029  |       7 |
 | 1k with LGO:Composite (Screen)                        |     1.2   |       870 |                39.40% |               521.27% |   0.007   |       7 |
 | 1k with LGO:Composite (0 outputs)                     |     4.6   |       220 |               453.45% |                56.49% |   0.00042 |       7 |
 | 1k with LGO:Screen                                    |     6.9   |       140 |               741.15% |                 2.96% |   0.0014  |       7 |
 | 1k with LGO:File                                      |     7.15  |       140 |               766.08% |                 0.00% | 2.7e-05   |       7 |
 +-------------------------------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+


The above result formatted in L<Benchmark.pm|Benchmark> style:

                                                            Rate  1k with LGO:Composite (Screen+File & pattern layouts)  1k default  1k with LGO:Composite (Screen+File)  1k with LGO:Composite (Screen)  1k with LGO:Composite (0 outputs)  1k with LGO:Screen  1k with LGO:File 
  1k with LGO:Composite (Screen+File & pattern layouts)  0.825/s                                                     --          0%                                  -9%                            -28%                               -81%                -88%              -88% 
  1k default                                              0.83/s                                                     0%          --                                  -8%                            -27%                               -81%                -88%              -88% 
  1k with LGO:Composite (Screen+File)                     0.88/s                                                    10%          9%                                   --                            -20%                               -80%                -87%              -87% 
  1k with LGO:Composite (Screen)                           1.2/s                                                    39%         37%                                  26%                              --                               -74%                -83%              -83% 
  1k with LGO:Composite (0 outputs)                        4.6/s                                                   450%        445%                                 400%                            295%                                 --                -36%              -36% 
  1k with LGO:Screen                                       6.9/s                                                   764%        757%                                 685%                            521%                                57%                  --                0% 
  1k with LGO:File                                        7.15/s                                                   764%        757%                                 685%                            521%                                57%                  0%                -- 
 
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

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-Log-ger>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-Log-ger>.

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

This software is copyright (c) 2023, 2021, 2020, 2018, 2017 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-Log-ger>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
