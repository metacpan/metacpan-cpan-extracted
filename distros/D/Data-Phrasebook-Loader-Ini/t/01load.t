#!/usr/bin/perl -w
use strict;
use lib 't';
use vars qw( $class );

use Test::More tests => 10;

# ------------------------------------------------------------------------

$class = 'Data::Phrasebook::Loader::Ini';
use_ok($class);

my $file = 't/01phrases.ini';
my $dict = 'BASE';

# ------------------------------------------------------------------------

{
    my $obj = $class->new();
    isa_ok( $obj => $class, "Bare new" );

    eval { $obj->load(); };
    ok($@);
    eval { $obj->load( 'blah' ); };
    ok($@);

    eval { $obj->load( $file ); };
    ok(!$@);
    eval { $obj->load( $file, 'BLAH' ); };
    ok(!$@);
    eval { $obj->load( $file, $dict ); };
    ok(!$@);

    my $phrase = $obj->get();
    is($phrase,undef);
    $phrase = $obj->get('blah');
    is($phrase,undef);
    $phrase = $obj->get('foo');
    like( $phrase, qr/Welcome to/);
}

