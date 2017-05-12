#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 24;
use Compress::BraceExpansion;

use lib "t";
use CompressBraceExpansionTestCases;

{
    while ( my $test_case = CompressBraceExpansionTestCases::get_next_test_case() ) {
        is( Compress::BraceExpansion->new( $test_case->{expanded} )->shrink(),
            $test_case->{'compressed'},
            $test_case->{'description'},
        );
    }
}

{
    my $compress = Compress::BraceExpansion->new( { 'strings' => [ qw( aabb aacc ) ] } );
    is( $compress->shrink(  ),
        "aa{bb,cc}",
        "aabb aacc                                                        = aa{bb,cc}",
    );
}

{
    my $compress = Compress::BraceExpansion->new( { 'strings' => [ qw( aabb aacc aad ) ] } );
    is( $compress->shrink(  ),
        "aa{bb,cc,d}",
        "aabb aacc aad                                                    = aa{bb,cc,d}",
    );
}

{
    my $compress = Compress::BraceExpansion->new( { 'strings' => [ qw( app-xy-02a app-xy-02b ) ] } );
    is( $compress->shrink(  ),
        "app-xy-02{a,b}",
        "app-xy-02a app-xy-02b                                            = app-xy-02{a,b}",
    );
}

{
    my $compress = Compress::BraceExpansion->new( { 'strings' => [ qw( app-xy-02a app-zz-02b ) ] } );
    is( $compress->shrink(  ),
        "app-{xy-02a,zz-02b}",
        "app-xy-02a app-zz-02b                                            = app-{xy-02a,zz-02b}",
    );
}

{
    my $compress = Compress::BraceExpansion->new( { 'strings' => [ qw( app-xy-02a app-xy-02b app-xy-03a app-xy-03b ) ] } );
    is( $compress->shrink(  ),
        "app-xy-0{2,3}{a,b}",
        "app-xy-02a app-xy-02b app-xy-03a app-xy-03b                     = app-xy-0{2,3}{a,b}",
    );
}

{
    my $compress = Compress::BraceExpansion->new( { 'strings' => [ qw( app-xy-02a app-xy-02b app-xy-03a app-xy-03b app-xy-09 app-xy-10 ) ] } );
    is( $compress->shrink(  ),
        "app-xy-{0{2{a,b},3{a,b},9},10}",
        "app-xy-02a app-xy-02b app-xy-03a app-xy-03b app-xy-09 app-xy-10 = app-xy-{0{2{a,b},3{a,b},9},10}",
    );
}

{
    my $compress = Compress::BraceExpansion->new( { 'strings' => [ qw( app-xy-02a cci-zz-app03 ) ] } );
    is( $compress->shrink(  ),
        "{app-xy-02a,cci-zz-app03}",
        "app-xy-02a cci-zz-app03                                         = {app-xy-02a,cci-zz-app03}",
    );
}

{
    my $compress = Compress::BraceExpansion->new( { 'strings' => [ qw( xxbbcc yybbcc ) ] } );
    is( $compress->shrink(  ),
        "{xx,yy}bbcc",
        "xxbbcc yybbcc                                                   = {xx,yy}bbcc",
    );
}

{
    my $compress = Compress::BraceExpansion->new( { 'strings' => [ qw( xxbbcc yybbcc zzbbcc ) ] } );
    is( $compress->shrink(  ),
        "{xx,yy,zz}bbcc",
        "xxbbcc yybbcc zzbbcc                                            = {xx,yy,zz}bbcc",
    );
}

{
    my $compress = Compress::BraceExpansion->new( { 'strings' => [ qw( app-xy-02a app-zz-02a ) ] } );
    is( $compress->shrink(  ),
        "app-{xy,zz}-02a",
        "app-xy-02a app-zz-02a                                           = app-{xy,zz}-02a",
    );
}

{
    my $compress = Compress::BraceExpansion->new( { 'strings' => [ qw( htadiehtcjnr htheeehtcjnr ) ] } );
    is( $compress->shrink(  ),
        "ht{adi,hee}ehtcjnr",
        "htadiehtcjnr htheeehtcjnr                                       = ht{adi,hee}ehtcjnr",
    );
}


#
#_* Future Test Cases
#

# the tree splits, then comes back together, then splits again
# is( $compress->shrink( qw( app-xy-02a app-zz-02a app-xy-02b app-zz-02b ) ),
#     "app-{xy,zz}-{02a,02b}",
#     "app-{xy,zz}-{02a,02b}"
# );

# tricky++...  multiple compressions are possible, 'a{bc,yz},xbc' is
# the most likely given the tree algorithm, but '{a,x}bc,ayz' is more
# efficient.
#is( $compress->shrink( qw( abc ayz xbc ) ),
#    "{a,x}bc,ayz",
#    "{a,x}bc,ayz",
#);

