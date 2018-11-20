
use strict;
use warnings;
use Test::More;

use Data::Bool qw(true false is_bool);

plan tests => 25;

ok( is_bool(true),  'true is_bool()' );
ok( is_bool(false), 'false is_bool()' );

is( ref true,  Data::Bool::BOOL_PACKAGE, 'ref true' );
is( ref false, Data::Bool::BOOL_PACKAGE, 'ref false' );

ok( !is_bool(undef), 'undef not is_bool()' );
ok( !is_bool(''),    '"" not is_bool()' );
ok( !is_bool(0),     '0 not is_bool()' );

ok( !is_bool(1), '1 not is_bool()' );

ok( !is_bool( \0 ), '\0 not is_bool()' );
ok( !is_bool( \1 ), '\1 not is_bool()' );

ok( !is_bool('true'),  '"true" not is_bool()' );
ok( !is_bool('false'), '"false" not is_bool()' );

ok( !is_bool('Data::Bool'),       '"Data::Bool" not is_bool()' );
ok( !is_bool('Data::Bool::Impl'), '"Data::Bool::Impl" not is_bool()' );
ok( !is_bool('JSON::PP::Boolean'), '"JSON::PP::Boolean" not is_bool()' );

ok( !is_bool( [] ), '[] not is_bool()' );
ok( !is_bool( {} ), '{} not is_bool()' );

ok( is_bool( do { bless \( my $dummy = 0 ), 'Data::Bool::Impl' } ), 'bless \0, "Data::Bool::Impl" is_bool()' );
ok( is_bool( do { bless \( my $dummy = 0 ), 'JSON::PP::Boolean' } ), 'bless \0, "JSON::PP::Boolean" is_bool()' );
ok( is_bool( do { bless \( my $dummy = 1 ), 'Data::Bool::Impl' } ), 'bless \1, "Data::Bool::Impl" is_bool()' );
ok( is_bool( do { bless \( my $dummy = 1 ), 'JSON::PP::Boolean' } ), 'bless \1, "JSON::PP::Boolean" is_bool()' );

package Bool2;
our @ISA = qw(Data::Bool::Impl);

package Bool3;
our @ISA = qw(JSON::PP::Boolean);

package main;

ok( is_bool( do { bless \( my $dummy = 0 ), 'Bool2' } ), 'bless \0, "Bool2" is_bool()' );
ok( is_bool( do { bless \( my $dummy = 0 ), 'Bool3' } ), 'bless \0, "Bool3" is_bool()' );
ok( is_bool( do { bless \( my $dummy = 1 ), 'Bool2' } ), 'bless \1, "Bool2" is_bool()' );
ok( is_bool( do { bless \( my $dummy = 1 ), 'Bool3' } ), 'bless \1, "Bool3" is_bool()' );
