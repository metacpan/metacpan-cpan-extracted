=pod

=encoding utf-8

=head1 PURPOSE

Benchmark::Featureset::ParamCheck named implementations work.

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
my %trivial = %{ 'Benchmark::Featureset::ParamCheck'->trivial_named_data };
my %complex = %{ 'Benchmark::Featureset::ParamCheck'->complex_named_data };

for my $pkg (@cases) {
	use_module($pkg);
	next unless $pkg->accept_hash || $pkg->accept_hashref;
	subtest $pkg->long_name => sub {
		
		namespaces_clean($pkg);
		
		my $testing = sub {
			my ($args, $result, $message) = @_;
			my $prefix = $result ? "should pass" : "should fail";
			subtest "$prefix - $message" => sub {
				my $is = $result ? \&is : \&isnt;
				$is->(
					exception { $pkg->run_named_check(1, %$args) },
					undef,
					'hash',
				) if $pkg->accept_hash;
				$is->(
					exception { $pkg->run_named_check(1, $args) },
					undef,
					'hashref',
				) if $pkg->accept_hashref;
			};
		};
		
		$testing->(\%trivial, !!1, 'trivial');
		$testing->(\%complex, !!1, 'complex');
		
		for my $field (sort keys %trivial) {
			my %failing = %trivial;
			delete $failing{$field};
			$testing->(\%failing, !!0, "missing $field");
		}
		
		{
			my %failing = %complex;
			$failing{integer} += 0.5;
			$testing->(\%failing, !!0, "invalid integer");
		}
		
		{
			my %failing = %complex;
			$failing{hashes} = [ {}, {}, [] ];
			$testing->(\%failing, !!0, "invalid hashes");
		}
		
		{
			my %failing = %complex;
			$failing{object} = bless [], 'Benchmark::Featureset::ParamCheck::Implementation::Dummy';
			$testing->(\%failing, !!0, "invalid object");
		}
		
		unless ( $pkg->allow_extra_key ) {
			my %failing = %complex;
			$failing{string} = 'foobar';
			$testing->(\%failing, !!0, "extra key");
		}
	};
}

done_testing;
