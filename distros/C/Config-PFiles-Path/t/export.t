#!perl

use Test::More tests => 5;

use strict;
use warnings;

use Config::PFiles::Path;


sub test {

    my ( $pfiles, $exp ) = @_;

    my $env = Config::PFiles::Path->new( $pfiles );

    $pfiles ||= "''";

    # test overloading at the same time
    is( "$env", $exp, $pfiles );
}

test( 'a;b', 'a;b' );

test( ';b', ';b' );

test( 'a;', 'a' );

test( 'a:b:c', 'a:b:c' );

test( 'a::c', 'a:c' );
