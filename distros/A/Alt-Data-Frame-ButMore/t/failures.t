#!/usr/bin/env perl

use strict; use warnings;
use Test::More;

use Data::Frame;
use Test::Fatal;

use PDL::Factor;


subtest 'Data::Frame throws exception objects' => sub {

	my $a = Data::Frame->new( columns => [
			x => [ qw/foo br baz/ ],
		],
	);

	my $b = Data::Frame->new( columns => [
			x => [qw/ a b c /],
			y => [1..3],
		],
	);


	isa_ok( exception { $a == $b }, 'failure::columns::mismatch' );

	isa_ok( exception { $a->column_names(qw/a b/) }, 'failure::columns::length' );

	isa_ok( exception { $a->row_names(qw/a b/) }, 'failure::rows::length' );
	isa_ok( exception { $a->row_names(qw/a b b/) }, 'failure::rows::unique' );

	isa_ok( exception { $a->column('ape') }, 'failure::column::exists' );

	#isa_ok( exception { $a->nth_column }, 'failure::index' );
	isa_ok( exception { $a->nth_column(5) }, 'failure::index::exists' );

	isa_ok( exception { $a->add_column(1) }, 'failure::column::name::string' );
	isa_ok( exception { $a->add_column(c => [1..4]) }, 'failure::rows::length' );
	isa_ok( exception { $a->add_column('x') }, 'failure::column::exists' );

	isa_ok( exception { $a->add_columns(x => [1..3], 'y') }, 'failure::columns::unbalanced' );
};

subtest 'PDL::Factor throws exception objects' => sub {
	my $a = PDL::Factor->new(['b'], levels => [qw/a b c/],);
	my $b = PDL::Factor->new(['b'], levels => [qw/c b a/],);

	isa_ok( exception { $a == $b }, 'failure::levels::mismatch' );


	isa_ok( exception { $a->levels(qw/a b c d/) }, 'failure::levels::number' );
};
done_testing;

