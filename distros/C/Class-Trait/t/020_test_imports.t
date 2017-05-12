#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 25;

BEGIN {
    unshift @INC => ( 't/test_lib', '/test_lib' );
}

# we have to use it directly because it uses an INIT block to flatten traits
use BasicTraitImport;

can_ok( BasicTraitImport => 'getName' );
is( BasicTraitImport->getName(), 'TImport',
    '... and it should have the method from the trait' );

ok( BasicTraitImport->does("TImport"), '.. BasicTraitImport is TImport' );

ok( exists( $BasicTraitImport::{"TRAITS"} ), '... the $TRAITS are properly stored' );

my $trait;
{
    no strict 'refs';

    # get the trait out
    $trait = ${"BasicTraitImport::TRAITS"};
}

# check to see what it is
isa_ok( $trait, 'Class::Trait::Config' );

# now examine the trait itself

can_ok( $trait, 'name' );
is( $trait->name, 'TImport', '... get the traits name' );

can_ok( $trait, 'sub_traits' );
is( ref( $trait->sub_traits ), "ARRAY", '... our sub_trait is an array ref' );
ok( eq_array( $trait->sub_traits, [] ), '... both should be empty' );

can_ok( $trait, 'requirements' );
is( ref( $trait->requirements ), "HASH",
    '... our requirements is an hash ref' );
ok( eq_hash( $trait->requirements, {} ), '... both should be empty' );

can_ok( $trait, 'overloads' );
is( ref( $trait->overloads ), "HASH", '... our overloads is an hash ref' );
ok( eq_hash( $trait->overloads, {} ), '... both should be empty' );

can_ok( $trait, 'conflicts' );
is( ref( $trait->conflicts ), "HASH", '... our conflicts is an hash ref' );
ok( eq_hash( $trait->conflicts, {} ), '... both should be empty' );

can_ok( $trait, 'methods' );
is( ref( $trait->methods ), "HASH", '... our methods is an hash ref' );
ok( eq_hash( $trait->methods, { "getName" => 'TImport::getName' } ),
    '... both should NOT be empty' );

can_ok 'TImport', 'getName';

# XXX note that even though these methods are here, they are not considered
# "provided" methods by the trait because the trait imported them.
can_ok 'TImport', 'this';
can_ok 'TImport', 'that';
