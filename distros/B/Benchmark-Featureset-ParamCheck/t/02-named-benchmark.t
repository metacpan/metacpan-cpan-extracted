=pod

=encoding utf-8

=head1 PURPOSE

Benchmark::Featureset::ParamCheck benchmarking named parameters.

=head1 SAMPLE RESULTS

=head2 Simple Input Data

 TP-TT -  2 wallclock secs ( 2.09 usr +  0.00 sys =  2.09 CPU) @  9.57/s (n=20)
 PVC-TT -  3 wallclock secs ( 2.57 usr +  0.00 sys =  2.57 CPU) @  7.78/s (n=20)
 RefUtilXS -  2 wallclock secs ( 2.76 usr +  0.00 sys =  2.76 CPU) @  7.25/s (n=20)
 PurePerl -  3 wallclock secs ( 3.03 usr +  0.00 sys =  3.03 CPU) @  6.60/s (n=20)
 PV-TT -  4 wallclock secs ( 4.06 usr +  0.00 sys =  4.06 CPU) @  4.93/s (n=20)
 DV-Mouse -  4 wallclock secs ( 4.27 usr +  0.00 sys =  4.27 CPU) @  4.68/s (n=20)
 PVC-Moose -  5 wallclock secs ( 4.57 usr +  0.02 sys =  4.59 CPU) @  4.36/s (n=20)
 PVC-Specio -  5 wallclock secs ( 4.59 usr +  0.00 sys =  4.59 CPU) @  4.36/s (n=20)
 DV-TT -  5 wallclock secs ( 4.99 usr +  0.00 sys =  4.99 CPU) @  4.01/s (n=20)
 PV -  6 wallclock secs ( 6.05 usr +  0.00 sys =  6.05 CPU) @  3.31/s (n=20)
 PC-TT -  8 wallclock secs ( 8.74 usr +  0.01 sys =  8.75 CPU) @  2.29/s (n=20)
 DV-Moose -  9 wallclock secs ( 9.12 usr +  0.00 sys =  9.12 CPU) @  2.19/s (n=20)
 PC-PurePerl - 11 wallclock secs (11.45 usr +  0.01 sys = 11.46 CPU) @  1.75/s (n=20)
 MXPV-TT - 16 wallclock secs (15.59 usr +  0.02 sys = 15.61 CPU) @  1.28/s (n=20)
 MXPV-Moose - 16 wallclock secs (15.78 usr +  0.01 sys = 15.79 CPU) @  1.27/s (n=20)

=head2 Complex Input Data

 TP-TT -  2 wallclock secs ( 2.20 usr +  0.00 sys =  2.20 CPU) @  9.09/s (n=20)
 PVC-TT -  3 wallclock secs ( 2.78 usr +  0.00 sys =  2.78 CPU) @  7.19/s (n=20)
 RefUtilXS -  3 wallclock secs ( 3.08 usr +  0.00 sys =  3.08 CPU) @  6.49/s (n=20)
 PurePerl -  4 wallclock secs ( 3.51 usr +  0.00 sys =  3.51 CPU) @  5.70/s (n=20)
 PV-TT -  4 wallclock secs ( 4.19 usr +  0.00 sys =  4.19 CPU) @  4.77/s (n=20)
 DV-Mouse -  4 wallclock secs ( 4.41 usr +  0.01 sys =  4.42 CPU) @  4.52/s (n=20)
 PVC-Specio -  5 wallclock secs ( 4.85 usr +  0.00 sys =  4.85 CPU) @  4.12/s (n=20)
 PVC-Moose -  5 wallclock secs ( 5.01 usr +  0.00 sys =  5.01 CPU) @  3.99/s (n=20)
 DV-TT -  5 wallclock secs ( 5.14 usr +  0.00 sys =  5.14 CPU) @  3.89/s (n=20)
 PV -  7 wallclock secs ( 6.75 usr +  0.01 sys =  6.76 CPU) @  2.96/s (n=20)
 PC-TT -  9 wallclock secs ( 8.84 usr +  0.01 sys =  8.85 CPU) @  2.26/s (n=20)
 DV-Moose - 10 wallclock secs ( 9.78 usr +  0.01 sys =  9.79 CPU) @  2.04/s (n=20)
 PC-PurePerl - 13 wallclock secs (12.09 usr +  0.01 sys = 12.10 CPU) @  1.65/s (n=20)
 MXPV-Moose - 16 wallclock secs (15.71 usr +  0.02 sys = 15.73 CPU) @  1.27/s (n=20)
 MXPV-TT - 16 wallclock secs (15.94 usr +  0.01 sys = 15.95 CPU) @  1.25/s (n=20)

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
		Benchmark::Featureset::ParamCheck::Implementation::TypeParams->short_name,
		20,
		\%benchmark,
		"trivial data benchmark"
	);

	%benchmark_data = %complex;
	is_fastest(
		Benchmark::Featureset::ParamCheck::Implementation::TypeParams->short_name,
		20,
		\%benchmark,
		"complex data benchmark"
	);
}

done_testing;
