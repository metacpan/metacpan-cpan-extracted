use strict;
use warnings;

use Test::More 0.88; # for done_testing
use lib 't/lib';

local $@;
eval 'require DBIx::Simple::Concrete';
is $@, !1, 'DBIx::Simple::Concrete loads without problems';

#  +fscking->indirect( 'method_syntax' )
ok +DBIx::Simple->can( 'fake_you_and_the_horse_you_rode_in_on' ),
	'... and loads the fake DBIx::Simple required for testing';

is_deeply [ DBIx::Simple->cquery( { hole => [1] } ) ], [ 'DBIx::Simple', 'hole IN (?)', 1 ],
	'... which it then patches correctly';

ok not( __PACKAGE__->can( 'sql_render' ) ),
	'It does not export anything by default';

DBIx::Simple::Concrete->import( ':core' );
is __PACKAGE__->can( 'sql_render' ), \&SQL::Concrete::sql_render,
	'... but does just that when asked';

done_testing;
