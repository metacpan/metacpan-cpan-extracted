package Bencher::Scenario::LogGer::InitTarget;

our $DATE = '2017-07-02'; # DATE
our $VERSION = '0.009'; # VERSION

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
        {name=>"default" ,
         code_template => 'use Log::ger (); local %Log::ger::Global_Hooks = %Log::ger::Default_Hooks; for(1..1000) { Log::ger::init_target(package =>"main") }'},
        {name=>"with LGO:Screen" ,
         code_template => 'use Log::ger (); local %Log::ger::Global_Hooks = %Log::ger::Default_Hooks; use Log::ger::Output; Log::ger::Output->set("Screen"); for(1..1000) { Log::ger::init_target(package => "main") }'},
        {name=>"with LGO:File" ,
         code_template => 'use Log::ger (); local %Log::ger::Global_Hooks = %Log::ger::Default_Hooks; use Log::ger::Output; Log::ger::Output->set("File", path=>'.qq('$fname').'); for(1..1000) { Log::ger::init_target(package => "main") }'},
        {name=>"with LGO:Composite (0 outputs)" ,
         code_template => 'use Log::ger (); local %Log::ger::Global_Hooks = %Log::ger::Default_Hooks; use Log::ger::Output; Log::ger::Output->set("Composite"); for(1..1000) { Log::ger::init_target(package => "main") }'},
        {name=>"with LGO:Composite (Screen)" ,
         code_template => 'use Log::ger (); local %Log::ger::Global_Hooks = %Log::ger::Default_Hooks; use Log::ger::Output; Log::ger::Output->set("Composite", outputs=>{Screen=>{}}); for(1..1000) { Log::ger::init_target(package => "main") }'},
        {name=>"with LGO:Composite (Screen+File)" ,
         code_template => 'use Log::ger (); local %Log::ger::Global_Hooks = %Log::ger::Default_Hooks; use Log::ger::Output; Log::ger::Output->set("Composite", outputs=>{Screen=>{}, File=>{conf=>{path=>'.qq('$fname').'}}}); for(1..1000) { Log::ger::init_target(package => "main") }'},
        {name=>"with LGO:Composite (Screen+File & pattern layouts)" ,
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

This document describes version 0.009 of Bencher::Scenario::LogGer::InitTarget (from Perl distribution Bencher-Scenarios-LogGer), released on 2017-07-02.

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

=item * default (perl_code)

Code template:

 use Log::ger (); local %Log::ger::Global_Hooks = %Log::ger::Default_Hooks; for(1..1000) { Log::ger::init_target(package =>"main") }



=item * with LGO:Screen (perl_code)

Code template:

 use Log::ger (); local %Log::ger::Global_Hooks = %Log::ger::Default_Hooks; use Log::ger::Output; Log::ger::Output->set("Screen"); for(1..1000) { Log::ger::init_target(package => "main") }



=item * with LGO:File (perl_code)

Code template:

 use Log::ger (); local %Log::ger::Global_Hooks = %Log::ger::Default_Hooks; use Log::ger::Output; Log::ger::Output->set("File", path=>'/tmp/UkXHBlQHxp'); for(1..1000) { Log::ger::init_target(package => "main") }



=item * with LGO:Composite (0 outputs) (perl_code)

Code template:

 use Log::ger (); local %Log::ger::Global_Hooks = %Log::ger::Default_Hooks; use Log::ger::Output; Log::ger::Output->set("Composite"); for(1..1000) { Log::ger::init_target(package => "main") }



=item * with LGO:Composite (Screen) (perl_code)

Code template:

 use Log::ger (); local %Log::ger::Global_Hooks = %Log::ger::Default_Hooks; use Log::ger::Output; Log::ger::Output->set("Composite", outputs=>{Screen=>{}}); for(1..1000) { Log::ger::init_target(package => "main") }



=item * with LGO:Composite (Screen+File) (perl_code)

Code template:

 use Log::ger (); local %Log::ger::Global_Hooks = %Log::ger::Default_Hooks; use Log::ger::Output; Log::ger::Output->set("Composite", outputs=>{Screen=>{}, File=>{conf=>{path=>'/tmp/UkXHBlQHxp'}}}); for(1..1000) { Log::ger::init_target(package => "main") }



=item * with LGO:Composite (Screen+File & pattern layouts) (perl_code)

Code template:

 use Log::ger (); local %Log::ger::Global_Hooks = %Log::ger::Default_Hooks; use Log::ger::Output; Log::ger::Output->set("Composite", outputs=>{Screen=>{layout=>[Pattern=>{format=>"[%d] %m"}]}, File=>{conf=>{path=>'/tmp/UkXHBlQHxp'}, layout=>[Pattern=>{format=>"[%d] [%P] %m"}]}}); for(1..1000) { Log::ger::init_target(package => "main") }



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m LogGer::InitTarget >>):

 #table1#
 +----------------------------------------------------+-----------+-----------+------------+-----------+---------+
 | participant                                        | rate (/s) | time (ms) | vs_slowest |  errors   | samples |
 +----------------------------------------------------+-----------+-----------+------------+-----------+---------+
 | with LGO:Composite (Screen+File & pattern layouts) |      2.6  |       380 |       1    |   0.0011  |       7 |
 | default                                            |      2.66 |       377 |       1.02 |   0.00037 |       7 |
 | with LGO:Composite (Screen+File)                   |      2.8  |       350 |       1.1  |   0.00054 |       8 |
 | with LGO:Composite (Screen)                        |      3.7  |       270 |       1.4  |   0.00042 |       7 |
 | with LGO:File                                      |      8.23 |       122 |       3.16 | 2.6e-05   |       7 |
 | with LGO:Composite (0 outputs)                     |      8.3  |       120 |       3.2  |   0.00029 |       7 |
 | with LGO:Screen                                    |      8.3  |       120 |       3.19 | 7.1e-05   |       8 |
 +----------------------------------------------------+-----------+-----------+------------+-----------+---------+


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

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
