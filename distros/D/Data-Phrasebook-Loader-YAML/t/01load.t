#!/usr/bin/perl -w
use strict;
use lib 't';
use vars qw( $class );

use Test::More tests => 7;

# ------------------------------------------------------------------------

$class = 'Data::Phrasebook::Loader::YAML';
use_ok($class);

my $file = 't/01phrases.yaml';
my $file2 = 't/01phrases2.yaml';

# ------------------------------------------------------------------------

{
    my $obj = $class->new();
    isa_ok( $obj => $class, "Bare new" );

    my $phrase = $obj->get();
    is($phrase,undef);
    $phrase = $obj->get('foo');
    is($phrase,undef);

    eval { $obj->load(); };
    ok($@);

    $obj->load( $file );
    $phrase = $obj->get('foo');
    like( $phrase, qr/Welcome to/);
}

{
    my $obj = $class->new();
    eval { $obj->load( $file2 ); };
    like( $@, qr/Badly formatted YAML/);
}

