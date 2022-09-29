=pod

=encoding utf-8

=head1 PURPOSE

Benchmark::Featureset::ParamCheck benchmarking positional parameters.

=head1 SAMPLE RESULTS

11th Gen Intel Core i3-1115G4 @ 3.00 GHz (1 physical processor, 2 cores, 4 threads);
12 GB RAM;
Linux 5.15.0-46-generic;
Ubuntu 22.04.1 LTS;
Perl 5.34.0.

=head2 Simple Input Data

 TP2-TT -  0 wallclock secs ( 0.26 usr +  0.00 sys =  0.26 CPU) @ 192.31/s (n=50)
 RefUtilXS -  1 wallclock secs ( 0.27 usr +  0.00 sys =  0.27 CPU) @ 185.19/s (n=50)
 TP-TT -  1 wallclock secs ( 0.27 usr +  0.00 sys =  0.27 CPU) @ 185.19/s (n=50)
 PVC-TT -  0 wallclock secs ( 0.27 usr +  0.00 sys =  0.27 CPU) @ 185.19/s (n=50)
 PurePerl -  0 wallclock secs ( 0.32 usr +  0.00 sys =  0.32 CPU) @ 156.25/s (n=50)
 TP2-Moose -  0 wallclock secs ( 0.37 usr +  0.00 sys =  0.37 CPU) @ 135.14/s (n=50)
 TP-Moose -  1 wallclock secs ( 0.38 usr +  0.00 sys =  0.38 CPU) @ 131.58/s (n=50)
 PVC-Specio -  1 wallclock secs ( 0.76 usr +  0.00 sys =  0.76 CPU) @ 65.79/s (n=50)
 TP2-Mouse -  1 wallclock secs ( 0.78 usr +  0.00 sys =  0.78 CPU) @ 64.10/s (n=50)
 PVC-Moose -  0 wallclock secs ( 0.79 usr +  0.00 sys =  0.79 CPU) @ 63.29/s (n=50)
 TP-Mouse -  1 wallclock secs ( 0.81 usr +  0.01 sys =  0.82 CPU) @ 60.98/s (n=50)
 TP-Specio -  1 wallclock secs ( 0.83 usr +  0.00 sys =  0.83 CPU) @ 60.24/s (n=50)
 TP2-Specio -  0 wallclock secs ( 0.85 usr +  0.00 sys =  0.85 CPU) @ 58.82/s (n=50)
 PV-TT -  1 wallclock secs ( 1.09 usr +  0.00 sys =  1.09 CPU) @ 45.87/s (n=50)
 PV -  1 wallclock secs ( 1.43 usr +  0.00 sys =  1.43 CPU) @ 34.97/s (n=50)
 DV-Moose -  3 wallclock secs ( 2.86 usr +  0.00 sys =  2.86 CPU) @ 17.48/s (n=50)
 DV-Mouse -  3 wallclock secs ( 2.98 usr +  0.00 sys =  2.98 CPU) @ 16.78/s (n=50)
 DV-TT -  3 wallclock secs ( 2.98 usr +  0.00 sys =  2.98 CPU) @ 16.78/s (n=50)
 MXPV-Moose -  4 wallclock secs ( 4.01 usr +  0.00 sys =  4.01 CPU) @ 12.47/s (n=50)
 MXPV-TT -  4 wallclock secs ( 4.17 usr +  0.00 sys =  4.17 CPU) @ 11.99/s (n=50)
 TP-Nano -  5 wallclock secs ( 4.74 usr +  0.00 sys =  4.74 CPU) @ 10.55/s (n=50)
 TP2-Nano -  4 wallclock secs ( 4.77 usr +  0.00 sys =  4.77 CPU) @ 10.48/s (n=50)

=head2 Complex Input Data

 TP-TT -  0 wallclock secs ( 0.29 usr +  0.00 sys =  0.29 CPU) @ 172.41/s (n=50)
 TP2-TT -  1 wallclock secs ( 0.31 usr +  0.00 sys =  0.31 CPU) @ 161.29/s (n=50)
 PVC-TT -  1 wallclock secs ( 0.32 usr +  0.00 sys =  0.32 CPU) @ 156.25/s (n=50)
 RefUtilXS -  0 wallclock secs ( 0.37 usr +  0.00 sys =  0.37 CPU) @ 135.14/s (n=50)
 PurePerl -  1 wallclock secs ( 0.51 usr +  0.00 sys =  0.51 CPU) @ 98.04/s (n=50)
 TP-Moose -  0 wallclock secs ( 0.53 usr +  0.00 sys =  0.53 CPU) @ 94.34/s (n=50)
 TP2-Moose -  0 wallclock secs ( 0.53 usr +  0.00 sys =  0.53 CPU) @ 94.34/s (n=50)
 TP2-Mouse -  0 wallclock secs ( 0.81 usr +  0.00 sys =  0.81 CPU) @ 61.73/s (n=50)
 PVC-Specio -  1 wallclock secs ( 0.85 usr +  0.00 sys =  0.85 CPU) @ 58.82/s (n=50)
 TP-Mouse -  0 wallclock secs ( 0.86 usr +  0.00 sys =  0.86 CPU) @ 58.14/s (n=50)
 PVC-Moose -  1 wallclock secs ( 0.91 usr +  0.00 sys =  0.91 CPU) @ 54.95/s (n=50)
 TP-Specio -  1 wallclock secs ( 0.92 usr +  0.00 sys =  0.92 CPU) @ 54.35/s (n=50)
 TP2-Specio -  1 wallclock secs ( 0.92 usr +  0.00 sys =  0.92 CPU) @ 54.35/s (n=50)
 PV-TT -  1 wallclock secs ( 1.13 usr +  0.00 sys =  1.13 CPU) @ 44.25/s (n=50)
 PV -  1 wallclock secs ( 1.55 usr +  0.00 sys =  1.55 CPU) @ 32.26/s (n=50)
 DV-Moose -  3 wallclock secs ( 3.05 usr +  0.00 sys =  3.05 CPU) @ 16.39/s (n=50)
 DV-Mouse -  4 wallclock secs ( 3.17 usr +  0.00 sys =  3.17 CPU) @ 15.77/s (n=50)
 DV-TT -  3 wallclock secs ( 3.19 usr +  0.00 sys =  3.19 CPU) @ 15.67/s (n=50)
 MXPV-TT -  5 wallclock secs ( 4.22 usr +  0.00 sys =  4.22 CPU) @ 11.85/s (n=50)
 MXPV-Moose -  4 wallclock secs ( 4.33 usr +  0.00 sys =  4.33 CPU) @ 11.55/s (n=50)
 TP-Nano - 16 wallclock secs (15.52 usr +  0.00 sys = 15.52 CPU) @  3.22/s (n=50)
 TP2-Nano - 16 wallclock secs (15.80 usr +  0.01 sys = 15.81 CPU) @  3.16/s (n=50)

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
my @trivial = @{ 'Benchmark::Featureset::ParamCheck'->trivial_positional_data };
my @complex = @{ 'Benchmark::Featureset::ParamCheck'->complex_positional_data };

{
	my $benchmark_runs = 10_000;
	my @benchmark_data;

	my %benchmark =
		map {
			my $pkg = $_;
			$pkg->short_name => sub {
				$pkg->run_positional_check($benchmark_runs, @benchmark_data);
			};
		}
		grep $_->accept_array, @cases;

	local $TODO = "this shouldn't prevent the test script from passing";
	local $Test::Modern::VERBOSE = 1;

	@benchmark_data = @trivial;
	is_fastest(
		Benchmark::Featureset::ParamCheck::Implementation::TypeParams::TypeTiny->short_name,
		50,
		\%benchmark,
		"trivial data benchmark"
	);

	@benchmark_data = @complex;
	is_fastest(
		Benchmark::Featureset::ParamCheck::Implementation::TypeParams::TypeTiny->short_name,
		50,
		\%benchmark,
		"complex data benchmark"
	);
}

done_testing;
