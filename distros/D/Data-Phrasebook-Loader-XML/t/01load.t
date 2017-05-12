#!/usr/bin/perl -w
use strict;
use lib 't';
use vars qw( $class );

use Test::More tests => 26;

# ------------------------------------------------------------------------

$class = 'Data::Phrasebook::Loader::XML';
use_ok($class);

my $file = 't/01phrases.xml';

# ------------------------------------------------------------------------

{
    my $obj = $class->new();
    isa_ok( $obj => $class, "Bare new" );

    eval { $obj->load(); };
    ok($@);
    eval { $obj->load( 'blah' ); };
    ok($@);
    eval { $obj->load( 't/01bad.xml' ); };
    ok($@);
    eval { $obj->load( 't/01bad2.xml' ); };
    ok($@);

    my $baz1 = '
  1
 2 
 3
   ';
    my $baz2 = '1 2 3'; 
    my $baz3 = 'Welcome to wherever'; 
    my $foo1 = 'my world';

    $obj->load( $file );

    my $phrase = $obj->get();
    is($phrase,undef);
    $phrase = $obj->get('blah');
    is($phrase,undef);
    $phrase = $obj->get('foo');
    is( $phrase, $foo1);
    $phrase = $obj->get('baz');
    is( $phrase, $baz1);

    $obj->load( $file, 'BLAH' );

    $phrase = $obj->get();
    is($phrase,undef);
    $phrase = $obj->get('blah');
    is($phrase,undef);
    $phrase = $obj->get('foo');
    is( $phrase, $foo1);
    $phrase = $obj->get('baz');
    is( $phrase, $baz1);

    $obj->load( $file, 'BASE' );

    $phrase = $obj->get();
    is($phrase,undef);
    $phrase = $obj->get('blah');
    is($phrase,undef);
    $phrase = $obj->get('foo');
    is( $phrase, $foo1);
    $phrase = $obj->get('baz');
    is( $phrase, $baz1);

    $obj->load( {file => $file, ignore_whitespace => 1}, 'BASE' );

    $phrase = $obj->get();
    is($phrase,undef);
    $phrase = $obj->get('blah');
    is($phrase,undef);
    $phrase = $obj->get('foo');
    is( $phrase, $foo1);
    $phrase = $obj->get('baz');
    is( $phrase, $baz2);

    $obj->load( {file => $file, ignore_whitespace => 1}, 'OTHER' );

    $phrase = $obj->get();
    is($phrase,undef);
    $phrase = $obj->get('blah');
    is($phrase,undef);
    $phrase = $obj->get('foo');
    is( $phrase, $foo1);
    $phrase = $obj->get('baz');
    is( $phrase, $baz3);
}

