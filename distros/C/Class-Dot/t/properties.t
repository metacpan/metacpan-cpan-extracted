use strict;
use warnings;
# ^^^^^ Must not be moved. The first line is used in a test of isa_File!

# $Id: properties.t 32 2007-10-31 14:46:57Z asksol $
# $Source$
# $Author: asksol $
# $HeadURL: https://class-dot.googlecode.com/svn/branches/stable-1.5.0/t/properties.t $
# $Revision: 32 $
# $Date: 2007-10-31 15:46:57 +0100 (Wed, 31 Oct 2007) $

use Test::More;
use FindBin qw($Bin);
use English qw( -no_match_vars );
use lib 'lib';
use lib $Bin;
use lib 't';
use lib "$Bin/../lib";
use Scalar::Util qw(refaddr);
use TestProperties;
use Cat;

our $THIS_TEST_HAS_TESTS = 60;

plan( tests => $THIS_TEST_HAS_TESTS );

use_ok('Class::Dot');

ok(! Class::Dot::property( ), 
    'property without property'
);

my $testo  = TestProperties->new( );
my $cat    = Cat->new( );
my $testo2 = TestProperties->new({ obj => $cat });

my $testo3 = TestProperties->new({ obj => $cat });
is( $testo3->obj, $cat, 'defaults ok after second instance' );

for my $property (qw(foo set_foo bar set_bar obj set_obj defval set_defval
    digit set_digit hash set_hash array set_array
    nodefault set_nodefault intnoval set_intnoval string set_string)) {
    can_ok($testo, $property);
}
isa_ok( $testo->obj,  'Cat',
   'isa_Object creates a new object of the type it is by default'
);
is(refaddr($testo2->obj), refaddr($cat),
   'isa_Object doesn\'t create new object if object already set.'
);
ok( ! defined $testo->mystery_object, 'isa_Object with no default class' );
ok(! $testo->foo, 'isa_Data has no default value' );
$testo->set_foo('foofoo', 'set a value');
is($testo->foo, 'foofoo', 'retrieve a value');
$testo->set_bar('barbar', 'set another value');
is($testo->bar, 'barbar', 'retrieve another value');
is_deeply($testo->array, [qw(the quick brown fox ...)],
    'array with default_values'
);
is_deeply($testo->hash, {
        hello => 'world',
        goobye => 'wonderful',
    },
    'isa_Hash default value',
);

is( $testo->digit, 303, 'isa_Int default value' );

is( $testo->nofunc, 'This does not use isa_*',
    'property that does not use isa_*'
);

ok(! $testo->intnoval, 'int with no default value is not true' );

ok(! defined $testo->intnoval, 'int with no default is not defined' );

ok(! $testo->nodefault, 'property with no type set is not true' );

ok(! defined $testo->nodefault, 'property with no type set is not defined' );

ok(! $testo->string, 'string with no default value is not true' );

ok(! defined $testo->string, 'string with no default value is not defined' );

is($testo->defval, 'la liberation', 'default value for isa_String');

eval '$testo->bar("this should croak")';
like($EVAL_ERROR,
    qr/You tried to set a value with bar\(\)\. Did you mean set_bar\(\) \?/,
    'croak on bar("value")'
);

isa_ok($testo->code,    'CODE', 'return value of isa_Code w/o default');
isa_ok($testo->codedef, 'CODE', 'return value of isa_Code w/  default');
is($testo->codedef->(), 10, 'isa_Code property is callable');
isa_ok($testo->filehandle, 'FileHandle',
    'return value of isa_File w/o default'
);
isa_ok($testo->myself, 'GLOB',
    'return value of isa_File w/ default'
);
my $fh = $testo->myself;
my $line = <$fh>;
like($line, qr/use strict/, 'read from a isa_File');

can_ok($testo, '__setattr__');
can_ok($testo, '__getattr__');
can_ok($testo, '__hasattr__');
ok( $testo->__hasattr__('string'),    '->__hasattr__() existing' );
ok(!$testo->__hasattr__('stringnot'), '->__hasattr__() nonexisting' );
ok( $testo->__setattr__('string', 'the blob jumps high over the flob'),
	'->__setattr__() with existing attr'
);
ok(!$testo->__setattr__('stringnot', 'the blob jumps high over the flob'),
	'->__setattr__() with nonexisting attr'
);
is( $testo->__getattr__('string'), 'the blob jumps high over the flob',
	'->__getattr()__ set after ->__setattr__()'
);
is( $testo->string, 'the blob jumps high over the flob',
	'->$property() set after ->__setattr__()'
);

is( $testo->override, 'not modified', 'override with after_property_set');

$testo->set_override('modified');
is( $testo->override, 'modified',     'override with after_property_get');

is( $testo->override2, 'xxx not modified', 'override with sub set_xxx {...}');

$testo->set_override('xxx modified');
is( $testo->override, 'xxx modified',     'override with sub xxx {...}');

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
# End:
# vim: expandtab tabstop=4 shiftwidth=4 shiftround
