=pod

=encoding utf-8

=head1 PURPOSE

Benchmark::Featureset::ParamCheck positional implementations work.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2017 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::Modern qw( -default -clean );
use Module::Runtime qw(use_module);
use Benchmark::Featureset::ParamCheck;

my @cases   =    'Benchmark::Featureset::ParamCheck'->implementations;
my @trivial = @{ 'Benchmark::Featureset::ParamCheck'->trivial_positional_data };
my @complex = @{ 'Benchmark::Featureset::ParamCheck'->complex_positional_data };

for my $pkg (@cases) {
	use_module($pkg);
	next unless $pkg->accept_array || $pkg->accept_arrayref;
	subtest $pkg->long_name => sub {
		
		namespaces_clean($pkg);
		
		my $testing = sub {
			my ($args, $result, $message) = @_;
			my $prefix = $result ? "should pass" : "should fail";
			subtest "$prefix - $message" => sub {
				my $is = $result ? \&is : \&isnt;
				$is->(
					exception { $pkg->run_positional_check(1, @$args) },
					undef,
					'array',
				) if $pkg->accept_array;
				$is->(
					exception { $pkg->run_positional_check(1, $args) },
					undef,
					'arrayref',
				) if $pkg->accept_arrayref;
			};
		};
		
		$testing->(\@trivial, !!1, 'trivial');
		$testing->(\@complex, !!1, 'complex');
		
		{
			my @failing = @trivial;
			pop @failing;
			$testing->(\@failing, !!0, "not enough parameters");
		}
		
		{
			my @failing = @complex;
			$failing[0] += 0.5;
			$testing->(\@failing, !!0, "invalid integer");
		}
		
		{
			my @failing = @complex;
			$failing[1] = [ {}, {}, [] ];
			$testing->(\@failing, !!0, "invalid hashes");
		}
		
		{
			my @failing = @complex;
			$failing[2] = bless [], 'Benchmark::Featureset::ParamCheck::Implementation::Dummy';
			$testing->(\@failing, !!0, "invalid object");
		}
		
		unless ( 0 ) {
			my @failing = @complex;
			push @failing, 'foobar';
			$testing->(\@failing, !!0, "extra value");
		}
	};
}

done_testing;
