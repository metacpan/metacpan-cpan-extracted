package Bencher::Scenario::LogGer::InitTarget;

our $DATE = '2020-01-13'; # DATE
our $VERSION = '0.016'; # VERSION

use 5.010001;
use strict;
use warnings;

use File::Temp qw(tempfile);

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

Bencher::Scenario::LogGer::InitTarget - Benchmark init_target()

=head1 VERSION

This document describes version 0.016 of Bencher::Scenario::LogGer::InitTarget (from Perl distribution Bencher-Scenarios-LogGer), released on 2020-01-13.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m LogGer::InitTarget

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

 use Log::ger (); local %Log::ger::Global_Hooks = %Log::ger::Default_Hooks; use Log::ger::Output; Log::ger::Output->set("File", path=>'/tmp/Whjzmfyuq5'); for(1..1000) { Log::ger::init_target(package => "main") }



=item * 1k with LGO:Composite (0 outputs) (perl_code)

Code template:

 use Log::ger (); local %Log::ger::Global_Hooks = %Log::ger::Default_Hooks; use Log::ger::Output; Log::ger::Output->set("Composite"); for(1..1000) { Log::ger::init_target(package => "main") }



=item * 1k with LGO:Composite (Screen) (perl_code)

Code template:

 use Log::ger (); local %Log::ger::Global_Hooks = %Log::ger::Default_Hooks; use Log::ger::Output; Log::ger::Output->set("Composite", outputs=>{Screen=>{}}); for(1..1000) { Log::ger::init_target(package => "main") }



=item * 1k with LGO:Composite (Screen+File) (perl_code)

Code template:

 use Log::ger (); local %Log::ger::Global_Hooks = %Log::ger::Default_Hooks; use Log::ger::Output; Log::ger::Output->set("Composite", outputs=>{Screen=>{}, File=>{conf=>{path=>'/tmp/Whjzmfyuq5'}}}); for(1..1000) { Log::ger::init_target(package => "main") }



=item * 1k with LGO:Composite (Screen+File & pattern layouts) (perl_code)

Code template:

 use Log::ger (); local %Log::ger::Global_Hooks = %Log::ger::Default_Hooks; use Log::ger::Output; Log::ger::Output->set("Composite", outputs=>{Screen=>{layout=>[Pattern=>{format=>"[%d] %m"}]}, File=>{conf=>{path=>'/tmp/Whjzmfyuq5'}, layout=>[Pattern=>{format=>"[%d] [%P] %m"}]}}); for(1..1000) { Log::ger::init_target(package => "main") }



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.30.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 19.04 >>, OS kernel: I<< Linux version 5.0.0-37-generic >>.

Benchmark with default options (C<< bencher -m LogGer::InitTarget >>):

 #table1#
 +-------------------------------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | participant                                           | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +-------------------------------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | 1k with LGO:Composite (Screen+File & pattern layouts) |      3.1  |     320   |                 0.00% |               232.95% |   0.0004  |       7 |
 | 1k default                                            |      3.16 |     316   |                 1.68% |               227.45% |   0.00022 |       7 |
 | 1k with LGO:Composite (Screen+File)                   |      3.33 |     301   |                 6.95% |               211.32% |   0.00027 |       7 |
 | 1k with LGO:Composite (Screen)                        |      4.6  |     220   |                49.11% |               123.30% |   0.00028 |       7 |
 | 1k with LGO:File                                      |      7.6  |     130   |               144.84% |                35.99% |   0.00018 |       7 |
 | 1k with LGO:Composite (0 outputs)                     |     10    |      97   |               231.10% |                 0.56% |   0.00017 |       7 |
 | 1k with LGO:Screen                                    |     10.4  |      96.5 |               232.95% |                 0.00% | 6.7e-05   |       7 |
 +-------------------------------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+


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

This software is copyright (c) 2020, 2018, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
