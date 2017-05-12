#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 10;

use_ok('CatalystX::CRUD::Controller');
ok( my $controller = CatalystX::CRUD::Controller->new( 'MyApp', {} ),
    "new controller" );
is( $controller->page_size, 50, 'default page_size' );
ok( $controller->page_size(10), "set page_size" );
is( $controller->page_size, 10, "get page_size" );

{

    package MyC;
    @MyC::ISA = ('CatalystX::CRUD::Controller');
    MyC->config( page_size => 30, primary_key => [qw( foo bar )] );
}
{

    package MyObj;
    sub new { return bless( {}, 'MyObj' ) }
    sub foo { return '1;2' }
    sub bar { return '3/4' }
}

ok( my $myc = MyC->new( 'MyApp', {} ), "new MyC" );
is( $myc->page_size, 30, "set page_size in package config" );

ok( my $obj = MyObj->new, "new MyObj" );
ok( my $pk_escaped = $myc->make_primary_key_string($obj),
    "make_primary_key_string" );
is( $pk_escaped, "1%3b2;;3%2f4", "pk escaped" );
