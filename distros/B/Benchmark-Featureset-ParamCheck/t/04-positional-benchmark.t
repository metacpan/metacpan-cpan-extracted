=pod

=encoding utf-8

=head1 PURPOSE

Benchmark::Featureset::ParamCheck benchmarking positional parameters.

=head1 SAMPLE RESULTS

=head2 Simple Input Data

 TP-TT -  1 wallclock secs ( 0.56 usr +  0.00 sys =  0.56 CPU) @ 35.71/s (n=20)
 PVC-TT -  1 wallclock secs ( 0.65 usr +  0.00 sys =  0.65 CPU) @ 30.77/s (n=20)
 RefUtilXS -  0 wallclock secs ( 0.75 usr +  0.00 sys =  0.75 CPU) @ 26.67/s (n=20)
 PurePerl -  1 wallclock secs ( 0.98 usr +  0.01 sys =  0.99 CPU) @ 20.20/s (n=20)
 PVC-Specio -  2 wallclock secs ( 2.53 usr +  0.01 sys =  2.54 CPU) @  7.87/s (n=20)
 PVC-Moose -  2 wallclock secs ( 2.56 usr +  0.00 sys =  2.56 CPU) @  7.81/s (n=20)
 PV-TT -  3 wallclock secs ( 3.26 usr +  0.00 sys =  3.26 CPU) @  6.13/s (n=20)
 PV -  6 wallclock secs ( 5.19 usr +  0.01 sys =  5.20 CPU) @  3.85/s (n=20)
 DV-Mouse - 11 wallclock secs (11.11 usr +  0.00 sys = 11.11 CPU) @  1.80/s (n=20)
 DV-TT - 11 wallclock secs (11.25 usr +  0.00 sys = 11.25 CPU) @  1.78/s (n=20)
 DV-Moose - 11 wallclock secs (11.30 usr +  0.01 sys = 11.31 CPU) @  1.77/s (n=20)
 MXPV-Moose - 13 wallclock secs (12.11 usr +  0.02 sys = 12.13 CPU) @  1.65/s (n=20)
 MXPV-TT - 12 wallclock secs (12.16 usr +  0.01 sys = 12.17 CPU) @  1.64/s (n=20)

=head2 Complex Input Data

 TP-TT -  1 wallclock secs ( 0.63 usr +  0.01 sys =  0.64 CPU) @ 31.25/s (n=20)
 PVC-TT -  1 wallclock secs ( 0.74 usr +  0.00 sys =  0.74 CPU) @ 27.03/s (n=20)
 RefUtilXS -  1 wallclock secs ( 1.07 usr +  0.00 sys =  1.07 CPU) @ 18.69/s (n=20)
 PurePerl -  1 wallclock secs ( 1.49 usr +  0.00 sys =  1.49 CPU) @ 13.42/s (n=20)
 PVC-Specio -  2 wallclock secs ( 2.83 usr +  0.00 sys =  2.83 CPU) @  7.07/s (n=20)
 PVC-Moose -  3 wallclock secs ( 3.08 usr +  0.00 sys =  3.08 CPU) @  6.49/s (n=20)
 PV-TT -  4 wallclock secs ( 3.43 usr +  0.00 sys =  3.43 CPU) @  5.83/s (n=20)
 PV -  6 wallclock secs ( 5.89 usr +  0.00 sys =  5.89 CPU) @  3.40/s (n=20)
 DV-TT - 12 wallclock secs (11.77 usr +  0.01 sys = 11.78 CPU) @  1.70/s (n=20)
 DV-Mouse - 12 wallclock secs (11.86 usr +  0.00 sys = 11.86 CPU) @  1.69/s (n=20)
 DV-Moose - 12 wallclock secs (11.96 usr +  0.01 sys = 11.97 CPU) @  1.67/s (n=20)
 MXPV-TT - 12 wallclock secs (12.27 usr +  0.00 sys = 12.27 CPU) @  1.63/s (n=20)
 MXPV-Moose - 13 wallclock secs (12.41 usr +  0.02 sys = 12.43 CPU) @  1.61/s (n=20)

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2017 by Toby Inkster.

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
		Benchmark::Featureset::ParamCheck::Implementation::TypeParams->short_name,
		20,
		\%benchmark,
		"trivial data benchmark"
	);

	@benchmark_data = @complex;
	is_fastest(
		Benchmark::Featureset::ParamCheck::Implementation::TypeParams->short_name,
		20,
		\%benchmark,
		"complex data benchmark"
	);
}

done_testing;
