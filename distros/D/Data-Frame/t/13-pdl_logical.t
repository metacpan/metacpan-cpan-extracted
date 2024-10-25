#!perl

use 5.010;
use strict;
use warnings;

use PDL::Core qw(pdl);
use PDL::Factor  ();
use PDL::SV      ();
use PDL::Logical ();

use Test2::V0;
use Test2::Tools::PDL;

subtest construction => sub {
    my $l1a = PDL::Logical->new("hello");
    pdl_is( $l1a, PDL::Logical->new( pdl(1) ), 'new($scalar)' );
    my $l1b = PDL::Logical->new(undef);
    pdl_is( $l1b, PDL::Logical->new( pdl(0) ), 'new($scalar)' );

    my $x2a = pdl( [qw(0 1 2 0)] );
    my $l2a = PDL::Logical->new($x2a);
    pdl_is( $l2a, PDL::Logical->new( [qw(0 1 1 0)] ), 'new($pdl)' );
    pdl_is( $l2a->shape, pdl( [4] ) );

    my $l2b = PDL::Logical->new($x2a);
    pdl_is( $l2b, PDL::Logical->new( [qw(0 1 1 0)] ), 'new($logical)' );

    my $x3 = [ [ 0, 1, 2 ], [ 3, 0, 0 ] ];
    my $l3 = PDL::Logical->new($x3);
    pdl_is( $l3, PDL::Logical->new( [ [ 0, 1, 1 ], [ 1, 0, 0 ] ] ),
        'new($aref_nd)' );
    pdl_is( $l3->shape, pdl( [ 3, 2 ] ) );

    isa_ok $l1a->initialize, 'PDL::Logical';
};

done_testing;
