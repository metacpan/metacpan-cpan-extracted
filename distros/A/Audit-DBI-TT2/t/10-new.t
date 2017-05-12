#!perl -T

use strict;
use warnings;

use Audit::DBI::TT2;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 4;


can_ok(
	'Audit::DBI::TT2',
	'new',
);

my $tt2;
lives_ok(
	sub
	{
		$tt2 = Audit::DBI::TT2->new();
	},
	'Instantiate object.',
);

ok(
	defined( $tt2 ),
	'The object is defined.',
);

ok(
	$tt2->isa( 'Audit::DBI::TT2' ),
	'The object has the type Audit::DBI::TT2.',
) || diag( explain( $tt2 ) );

