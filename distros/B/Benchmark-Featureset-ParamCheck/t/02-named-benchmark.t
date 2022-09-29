=pod

=encoding utf-8

=head1 PURPOSE

Benchmark::Featureset::ParamCheck benchmarking named parameters.

=head1 SAMPLE RESULTS

11th Gen Intel Core i3-1115G4 @ 3.00 GHz (1 physical processor, 2 cores, 4 threads);
12 GB RAM;
Linux 5.15.0-46-generic;
Ubuntu 22.04.1 LTS;
Perl 5.34.0.

=head2 Simple Input Data

 TP-TT -  1 wallclock secs ( 0.77 usr +  0.00 sys =  0.77 CPU) @ 64.94/s (n=50)
 TP2-TT -  1 wallclock secs ( 0.89 usr +  0.00 sys =  0.89 CPU) @ 56.18/s (n=50)
 TP-Moose -  1 wallclock secs ( 0.91 usr +  0.00 sys =  0.91 CPU) @ 54.95/s (n=50)
 PVC-TT -  0 wallclock secs ( 0.91 usr +  0.00 sys =  0.91 CPU) @ 54.95/s (n=50)
 RefUtilXS -  1 wallclock secs ( 0.96 usr +  0.00 sys =  0.96 CPU) @ 52.08/s (n=50)
 TP2-Moose -  1 wallclock secs ( 0.98 usr +  0.00 sys =  0.98 CPU) @ 51.02/s (n=50)
 PurePerl -  1 wallclock secs ( 1.03 usr +  0.00 sys =  1.03 CPU) @ 48.54/s (n=50)
 TP-Mouse -  1 wallclock secs ( 1.22 usr +  0.00 sys =  1.22 CPU) @ 40.98/s (n=50)
 PVC-Specio -  2 wallclock secs ( 1.23 usr +  0.00 sys =  1.23 CPU) @ 40.65/s (n=50)
 TP-Specio -  1 wallclock secs ( 1.23 usr +  0.00 sys =  1.23 CPU) @ 40.65/s (n=50)
 TP2-Mouse -  1 wallclock secs ( 1.28 usr +  0.00 sys =  1.28 CPU) @ 39.06/s (n=50)
 PVC-Moose -  1 wallclock secs ( 1.29 usr +  0.00 sys =  1.29 CPU) @ 38.76/s (n=50)
 DV-Mouse -  2 wallclock secs ( 1.30 usr +  0.00 sys =  1.30 CPU) @ 38.46/s (n=50)
 TP2-Specio -  2 wallclock secs ( 1.34 usr +  0.00 sys =  1.34 CPU) @ 37.31/s (n=50)
 PV-TT -  1 wallclock secs ( 1.36 usr +  0.00 sys =  1.36 CPU) @ 36.76/s (n=50)
 DV-TT -  1 wallclock secs ( 1.46 usr +  0.00 sys =  1.46 CPU) @ 34.25/s (n=50)
 PV -  2 wallclock secs ( 1.64 usr +  0.00 sys =  1.64 CPU) @ 30.49/s (n=50)
 DV-Moose -  2 wallclock secs ( 2.52 usr +  0.00 sys =  2.52 CPU) @ 19.84/s (n=50)
 PC-TT -  2 wallclock secs ( 2.54 usr +  0.00 sys =  2.54 CPU) @ 19.69/s (n=50)
 PC-PurePerl -  4 wallclock secs ( 3.27 usr +  0.01 sys =  3.28 CPU) @ 15.24/s (n=50)
 MXPV-Moose -  4 wallclock secs ( 4.21 usr +  0.00 sys =  4.21 CPU) @ 11.88/s (n=50)
 MXPV-TT -  4 wallclock secs ( 4.22 usr +  0.00 sys =  4.22 CPU) @ 11.85/s (n=50)
 TP-Nano -  5 wallclock secs ( 5.17 usr +  0.00 sys =  5.17 CPU) @  9.67/s (n=50)
 TP2-Nano -  6 wallclock secs ( 5.28 usr +  0.00 sys =  5.28 CPU) @  9.47/s (n=50)

=head2 Complex Input Data

 TP-TT -  1 wallclock secs ( 0.81 usr +  0.00 sys =  0.81 CPU) @ 61.73/s (n=50)
 TP2-TT -  1 wallclock secs ( 0.93 usr +  0.00 sys =  0.93 CPU) @ 53.76/s (n=50)
 PVC-TT -  0 wallclock secs ( 0.94 usr +  0.00 sys =  0.94 CPU) @ 53.19/s (n=50)
 TP-Moose -  1 wallclock secs ( 1.08 usr +  0.00 sys =  1.08 CPU) @ 46.30/s (n=50)
 RefUtilXS -  1 wallclock secs ( 1.09 usr +  0.00 sys =  1.09 CPU) @ 45.87/s (n=50)
 TP2-Moose -  1 wallclock secs ( 1.13 usr +  0.00 sys =  1.13 CPU) @ 44.25/s (n=50)
 PurePerl -  2 wallclock secs ( 1.23 usr +  0.00 sys =  1.23 CPU) @ 40.65/s (n=50)
 TP-Mouse -  2 wallclock secs ( 1.26 usr +  0.00 sys =  1.26 CPU) @ 39.68/s (n=50)
 PVC-Specio -  1 wallclock secs ( 1.32 usr +  0.00 sys =  1.32 CPU) @ 37.88/s (n=50)
 TP-Specio -  2 wallclock secs ( 1.32 usr +  0.00 sys =  1.32 CPU) @ 37.88/s (n=50)
 TP2-Mouse -  1 wallclock secs ( 1.33 usr +  0.00 sys =  1.33 CPU) @ 37.59/s (n=50)
 DV-Mouse -  2 wallclock secs ( 1.34 usr +  0.00 sys =  1.34 CPU) @ 37.31/s (n=50)
 PV-TT -  2 wallclock secs ( 1.41 usr +  0.00 sys =  1.41 CPU) @ 35.46/s (n=50)
 TP2-Specio -  1 wallclock secs ( 1.43 usr +  0.00 sys =  1.43 CPU) @ 34.97/s (n=50)
 PVC-Moose -  1 wallclock secs ( 1.45 usr +  0.00 sys =  1.45 CPU) @ 34.48/s (n=50)
 DV-TT -  2 wallclock secs ( 1.53 usr +  0.00 sys =  1.53 CPU) @ 32.68/s (n=50)
 PV -  2 wallclock secs ( 1.87 usr +  0.00 sys =  1.87 CPU) @ 26.74/s (n=50)
 PC-TT -  3 wallclock secs ( 2.64 usr +  0.00 sys =  2.64 CPU) @ 18.94/s (n=50)
 DV-Moose -  3 wallclock secs ( 2.67 usr +  0.00 sys =  2.67 CPU) @ 18.73/s (n=50)
 PC-PurePerl -  3 wallclock secs ( 3.42 usr +  0.00 sys =  3.42 CPU) @ 14.62/s (n=50)
 MXPV-TT -  4 wallclock secs ( 4.26 usr +  0.00 sys =  4.26 CPU) @ 11.74/s (n=50)
 MXPV-Moose -  4 wallclock secs ( 4.28 usr +  0.00 sys =  4.28 CPU) @ 11.68/s (n=50)
 TP-Nano - 16 wallclock secs (15.99 usr +  0.00 sys = 15.99 CPU) @  3.13/s (n=50)
 TP2-Nano - 16 wallclock secs (16.07 usr +  0.00 sys = 16.07 CPU) @  3.11/s (n=50)

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2017, 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::Modern qw( -benchmark );
use Module::Runtime qw(use_module);
use Benchmark::Featureset::ParamCheck;

my @cases = map use_module($_),
	'Benchmark::Featureset::ParamCheck'->implementations;
my %trivial = %{ 'Benchmark::Featureset::ParamCheck'->trivial_named_data };
my %complex = %{ 'Benchmark::Featureset::ParamCheck'->complex_named_data };

{
	my $benchmark_runs = 10_000;
	my %benchmark_data;

	my %benchmark = map {
		my $pkg = $_;
		$pkg->short_name => sub {
			$pkg->run_named_check($benchmark_runs, \%benchmark_data);
		};
	} @cases;

	local $TODO = "this shouldn't prevent the test script from passing";
	local $Test::Modern::VERBOSE = 1;

	%benchmark_data = %trivial;
	is_fastest(
		Benchmark::Featureset::ParamCheck::Implementation::TypeParams::TypeTiny->short_name,
		50,
		\%benchmark,
		"trivial data benchmark"
	);

	%benchmark_data = %complex;
	is_fastest(
		Benchmark::Featureset::ParamCheck::Implementation::TypeParams::TypeTiny->short_name,
		50,
		\%benchmark,
		"complex data benchmark"
	);
}

done_testing;
