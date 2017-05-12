#!/usr/bin/perl

use strict;
use warnings;

{

    package Not::main;

    # this is imported into a different package to avoid conflicts with "is()"
    use Test::More tests => 52;
}

use overload ();

BEGIN {
    unshift @INC => ( 't/test_lib', '/test_lib' );

    # we have to require Class::Trait to avoid importing
    # and it must be in a BEGIN block to ensure that rename_does
    # fires before the does() method is installed
    require Class::Trait;
    Test::More::can_ok 'Class::Trait', 'rename_does';
    eval { Class::Trait->rename_does('$$') };
    Test::More::like $@, qr/Illegal name for trait relation method \(\$\$\)/,
      '... calling rename_does() with an illegal method name should die';
    Test::More::ok +Class::Trait->rename_does('is'),
      '... but calling it with a legal method name should succeed';
}

# we have to use it directly because it uses an INIT block to flatten traits
use TraitTest;

Test::More::can_ok( "TraitTest", 'new' );

my $trait_1 = TraitTest->new(3);
my $trait_2 = TraitTest->new(3);

Test::More::isa_ok( $trait_1, 'TraitTest' );
Test::More::isa_ok( $trait_1, 'TraitTestBase' );

Test::More::isa_ok( $trait_2, 'TraitTest' );
Test::More::isa_ok( $trait_2, 'TraitTestBase' );

Test::More::ok( $trait_1->is("TPrintable"), '... trait 1 is TPrintable' );
Test::More::ok( $trait_1->is("TCompositeTest"),
    '... trait 1 is TCompositeTest' );
Test::More::ok( $trait_1->is("TComparable"),
    '... trait 1 is TComparable (because of TCompositeTest' );

Test::More::ok( $trait_2->is("TPrintable"), '... trait 2 is TPrintable' );
Test::More::ok( $trait_2->is("TCompositeTest"),
    '... trait 2 is TCompositeTest' );
Test::More::ok( $trait_2->is("TComparable"),
    '... trait 2 is TComparable (because of TCompositeTest' );

# check that it "can" execute the methods
# that it should have gotten from the traits
foreach my $method (
    qw/ compositeTestRequirement compositeTest /,    # from CompositeTest
    qw/ toString stringValue /,                      # from TPrintable
    qw/ compare equalTo notEqualTo /,                # from TComparable
  )
{
    Test::More::can_ok( $trait_1, $method );
    Test::More::can_ok( $trait_2, $method );
}

# test the aliased method strVal
Test::More::can_ok( $trait_1, 'strVal' );
Test::More::can_ok( $trait_2, 'strVal' );

# check overloads as well....

# for TComparable
Test::More::ok( overload::Method( $trait_1, '==' ), '... trait 1 overload ==' );
Test::More::ok( overload::Method( $trait_1, '!=' ), '... trait 1 overload !=' );
Test::More::ok( overload::Method( $trait_1, '<=>' ),
    '... trait 1 overload <=>' );

# for TPrintable
Test::More::ok( overload::Method( $trait_1, '""' ), '... trait 1 overload ""' );

# for TComparable
Test::More::ok( overload::Method( $trait_2, '==' ), '... trait 2 overload ==' );
Test::More::ok( overload::Method( $trait_2, '!=' ), '... trait 2 overload !=' );
Test::More::ok( overload::Method( $trait_2, '<=>' ),
    '... trait 2 overload <=>' );

# for TPrintable
Test::More::ok( overload::Method( $trait_2, '""' ), '... trait 2 overload ""' );

# now check if they behave as we expect

# check "" operator from TPrintable
Test::More::is(
    "$trait_1",
    '3.000 (overridden stringification)',
    '... and it should be stringified correctly'
);
Test::More::is(
    "$trait_2",
    '3.000 (overridden stringification)',
    '... and it should be stringified correctly'
);

# check == operator	from TComparable
# XXX using cmp_ok generates correct, but irrelevent "not numeric" warnings
Test::More::ok( $trait_1 == $trait_2, '... and they should be equal' );

# check != operator	from TComparable
Test::More::ok( !( $trait_1 != $trait_2 ),
    '... and they shouldnt be not equal' );

# check the compare <=> operator
Test::More::cmp_ok( ( $trait_1 <=> $trait_2 ),
    '==', 0, '... and they shouldnt be equal and therefore <=> return 0' );

# check the aliased stringValue function
Test::More::like(
    $trait_1->strVal,
    qr/TraitTest=HASH\(0x[a-fA-F0-9]+\)/,
    '... and should return a reasonable strVal'
);
Test::More::like(
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
Test::More::isa_ok( $trait, 'Class::Trait::Config' );

# now examine the trait itself
Test::More::is( $trait->name, 'COMPOSITE', '... get the traits name' );

Test::More::ok(
    Test::More::eq_array(
        $trait->sub_traits, [ 'TCompositeTest', 'TPrintable' ]
    ),
    '... this should not be empty'
);

Test::More::ok( Test::More::eq_hash( $trait->conflicts, {} ),
    '... this should be empty' );

Test::More::ok(
    Test::More::eq_hash(
        $trait->requirements,
        {
            compare                  => 1,
            compositeTestRequirement => 1,
            toString                 => 2    # this was required twice
        }
    ),
    '... this should not be empty'
);

Test::More::ok(
    Test::More::eq_hash(
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

Test::More::ok(
    Test::More::eq_set(
        [ keys %{ $trait->methods } ],
        [
            'stringValue', 'compositeTest', 'strVal',  'equalTo',
            'notEqualTo',  'isSameTypeAs',  'isExactly'
        ]
    ),
    '... this should not be empty'
);
