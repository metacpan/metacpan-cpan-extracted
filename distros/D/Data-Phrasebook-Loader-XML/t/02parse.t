#!/usr/bin/perl -w
use strict;
use lib 't';
use vars qw( $class );

use Test::More tests => 3;

# ------------------------------------------------------------------------

$class = 'Data::Phrasebook::Loader::XML';
use_ok($class);

my $file = 't/02phrases.xml';

# ------------------------------------------------------------------------

{
    my $obj = $class->new();
    isa_ok( $obj => $class, "Bare new" );

    $obj->load( {file => $file}, 'BASE' );
    my $phrase = $obj->get('check');
    is($phrase,'SELECT * FROM test WHERE id < 10');
}

