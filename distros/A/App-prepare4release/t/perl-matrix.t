#!perl
use strict;
use warnings;
use Test2::V1;
use Test2::Tools::Basic qw(ok done_testing);
use Test2::Tools::Spec qw(describe tests);

use App::prepare4release;

describe 'perl_matrix_tags' => sub {
	tests 'even minors between 5.10 and 5.16' => sub {
		my @m = App::prepare4release->perl_matrix_tags( 'v5.10.0', '5.16' );
		ok(
			join( ' ', @m ) eq '5.10 5.12 5.14 5.16',
			'matrix list'
		);
	};

	tests 'odd floor / odd ceiling' => sub {
		my @m = App::prepare4release->perl_matrix_tags( 'v5.11.0', '5.15.0' );
		ok( join( ' ', @m ) eq '5.12 5.14', 'rounded range' );
	};

	tests 'makefile-only MIN_PERL_VERSION' => sub {
		my $min = App::prepare4release->resolve_combined_min_perl(
			"MIN_PERL_VERSION => '5.008007',",
			undef
		);
		ok( defined $min, 'resolved' );
	};
};

done_testing;
