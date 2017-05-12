#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 49;

use overload ();

BEGIN {
    unshift @INC => ( 't/test_lib', '/test_lib' );
}

# we have to use it directly because it uses an INIT block to flatten traits
use TraitTest;

can_ok( "TraitTest", 'new' );

my $trait_1 = TraitTest->new(3);
my $trait_2 = TraitTest->new(3);

isa_ok( $trait_1, 'TraitTest' );
isa_ok( $trait_1, 'TraitTestBase' );

isa_ok( $trait_2, 'TraitTest' );
isa_ok( $trait_2, 'TraitTestBase' );

ok( $trait_1->does("TPrintable"),     '... trait 1 is TPrintable' );
ok( $trait_1->does("TCompositeTest"), '... trait 1 is TCompositeTest' );
ok( $trait_1->does("TComparable"),
    '... trait 1 is TComparable (because of TCompositeTest' );

ok( $trait_2->does("TPrintable"),     '... trait 2 is TPrintable' );
ok( $trait_2->does("TCompositeTest"), '... trait 2 is TCompositeTest' );
ok( $trait_2->does("TComparable"),
    '... trait 2 is TComparable (because of TCompositeTest' );

# check that it "can" execute the methods
# that it should have gotten from the traits
foreach my $method (
    qw/ compositeTestRequirement compositeTest /,    # from CompositeTest
    qw/ toString stringValue /,                      # from TPrintable
    qw/ compare equalTo notEqualTo /,                # from TComparable
  )
{
    can_ok( $trait_1, $method );
    can_ok( $trait_2, $method );
}

# test the aliased method strVal
can_ok( $trait_1, 'strVal' );
can_ok( $trait_2, 'strVal' );

# check overloads as well....

# for TComparable
ok( overload::Method( $trait_1, '==' ),  '... trait 1 overload ==' );
ok( overload::Method( $trait_1, '!=' ),  '... trait 1 overload !=' );
ok( overload::Method( $trait_1, '<=>' ), '... trait 1 overload <=>' );

# for TPrintable
ok( overload::Method( $trait_1, '""' ), '... trait 1 overload ""' );

# for TComparable
ok( overload::Method( $trait_2, '==' ),  '... trait 2 overload ==' );
ok( overload::Method( $trait_2, '!=' ),  '... trait 2 overload !=' );
ok( overload::Method( $trait_2, '<=>' ), '... trait 2 overload <=>' );

# for TPrintable
ok( overload::Method( $trait_2, '""' ), '... trait 2 overload ""' );

# now check if they behave as we expect

# check "" operator from TPrintable
is(
    "$trait_1",
    '3.000 (overridden stringification)',
    '... and it should be stringified correctly'
);
is(
    "$trait_2",
    '3.000 (overridden stringification)',
    '... and it should be stringified correctly'
);

# check == operator	from TComparable
# XXX using cmp_ok generates correct, but irrelevent "not numeric" warnings
ok( $trait_1 == $trait_2, '... and they should be equal' );

# check != operator	from TComparable
ok( !( $trait_1 != $trait_2 ), '... and they shouldnt be not equal' );

# check the compare <=> operator
cmp_ok( ( $trait_1 <=> $trait_2 ),
    '==', 0, '... and they shouldnt be equal and therefore <=> return 0' );

# check the aliased stringValue function
like(
    $trait_1->strVal,
    qr/TraitTest=HASH\(0x[a-fA-F0-9]+\)/,
    '... and should return a reasonable strVal'
);
like(
    $trait_2->strVal,
    qr/TraitTest=HASH\(0x[a-fA-F0-9]+\)/,
    '... and should return a reasonable strVal'
);

# now lets extract the actul trait and examine it

my $trait;
{
    no strict 'refs';

    # get the trait out
    $trait = ${"TraitTest::TRAITS"};
}

# check to see it is what we want it to be
isa_ok( $trait, 'Class::Trait::Config' );

# now examine the trait itself
is( $trait->name, 'COMPOSITE', '... get the traits name' );

ok( eq_array( $trait->sub_traits, [ 'TCompositeTest', 'TPrintable' ] ),
    '... this should not be empty' );

ok( eq_hash( $trait->conflicts, {} ), '... this should be empty' );

ok(
    eq_hash(
        $trait->requirements,
        {
            compare                  => 1,
            compositeTestRequirement => 1,
            toString                 => 2    # this was required twice
        }
    ),
    '... this should not be empty'
);

ok(
    eq_hash(
        $trait->overloads,
        {
            '<=>' => 'compare',
            '=='  => 'equalTo',
            '""'  => 'toString',
            '!='  => 'notEqualTo'
        }
    ),
    '... this should not be empty'
);

ok(
    eq_set(
        [ keys %{ $trait->methods } ],
        [
            'stringValue', 'compositeTest', 'strVal',  'equalTo',
            'notEqualTo',  'isSameTypeAs',  'isExactly'
        ]
    ),
    '... this should not be empty'
);
