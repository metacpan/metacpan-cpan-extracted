#! perl

use strict;
use warnings;

use Test::More 0.89;

use CPAN::Meta::Prereqs;
use CPAN::Meta::Prereqs::Filter 'filter_prereqs';

my $first = CPAN::Meta::Prereqs->new({
	runtime => {
		requires => {
			Carp => 0,
			'CPAN::Meta::Prereqs::Filter' => 0.001,
		},
	},
});

my $filtered1 = filter_prereqs($first, omit_core => 5.008)->as_string_hash;
is_deeply($filtered1, { runtime => { requires => { 'CPAN::Meta::Prereqs::Filter' => 0.001 } } }, 'C::M::P::F is not in core') or diag explain $filtered1->as_string;

my $second = CPAN::Meta::Prereqs->new({
	runtime => {
		requires => {
			Carp => 0,
			'CPAN::Meta::Prereqs::Filter' => 0,
			'Non::Existent' => 1,
		},
	},
});

my $filtered2 = filter_prereqs($second, only_missing => 1)->as_string_hash;
is_deeply($filtered2, { runtime => { requires => { 'Non::Existent' => 1 } } }, 'Only Non::Existent is missing') or diag explain $filtered2;

my $third = CPAN::Meta::Prereqs->new({
	runtime => {
		requires => {
			Carp => 1,
		},
	},
	testing => {
		requires => {
			Carp => 0.001,
		},
	},
});

my $filtered3 = filter_prereqs($third, sanatize => 1)->as_string_hash;
is_deeply($filtered3, { runtime => { requires => { 'Carp' => 1 } } }, 'Sanatize cleans up testing') or diag explain $filtered3;

done_testing();
