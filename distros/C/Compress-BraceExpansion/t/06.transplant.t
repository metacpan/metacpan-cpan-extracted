#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;

use Test::More qw(no_plan);
use Compress::BraceExpansion;

{
    my $tree = { 'ROOT' => { a => { b => { c => { 'end' => 1 } } } } };
    my $compress = Compress::BraceExpansion->new( {} );

    is_deeply( $compress->_transplant( $tree, 1 ),
               { 'ROOT' => { 'POINTER' => 'PID:1001' } },
               'root check after transplanting single branch one node deep'
           );

    is_deeply( $compress->_get_pointers(),
               { 'PID:1001' => { 'a' => { 'b' => { 'c' => { 'end' => 1 } } } } },
               'pointer check after transplanting single branch one node deep'
           );
}

{
    my $tree = { 'ROOT' => { a => { b => { c => { 'end' => 1 } } } } };
    my $compress = Compress::BraceExpansion->new( {} );

    is_deeply( $compress->_transplant( $tree, 2 ),
               { 'ROOT' => { 'a' => { 'POINTER' => 'PID:1001' } } },
               'root check after transplanting single branch 2 nodes deep'
           );

    is_deeply( $compress->_get_pointers(),
               { 'PID:1001' => { 'b' => { 'c' => { 'end' => 1 } } } },
               'pointer check after transplanting single branch 2 nodes deep'
           );
}


{
    my $tree = { 'ROOT' => { a => { b => { c => { 'end' => 1 } } } } };
    my $compress = Compress::BraceExpansion->new( {} );

    is_deeply( $compress->_transplant( $tree, 3 ),
               { 'ROOT' => { 'a' => { b => { 'POINTER' => 'PID:1001' } } } },
               'root check after transplanting single branch 3 nodes deep'
           );

    is_deeply( $compress->_get_pointers(),
               { 'PID:1001' => { 'c' => { 'end' => 1 } } },
               'pointer check after transplanting single branch 3 nodes deep'
           );
}


{
    my $tree = { 'ROOT' => { a => { b => { c => { 'end' => 1 } } } } };
    my $compress = Compress::BraceExpansion->new( {} );

    ok( ! eval { $compress->_transplant( $tree, 4 ) },
        'transplanting single branch past end of tree',
        );

    ok( ! eval { $compress->_transplant( $tree, 5 ) },
        'transplanting single branch past end of tree',
        );

    ok( ! eval { $compress->_transplant( $tree, 6 ) },
        'transplanting single branch past end of tree',
        );
}


