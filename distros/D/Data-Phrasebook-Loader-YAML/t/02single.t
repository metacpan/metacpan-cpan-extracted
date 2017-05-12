#!/usr/bin/perl -w

use strict;
use vars qw( $class );
use Test::More tests => 12;

# ------------------------------------------------------------------------

BEGIN {
    $class = 'Data::Phrasebook::Loader::YAML';
    use_ok($class);
}

my $file = 't/01phrases.yaml';

# ------------------------------------------------------------------------

{
    my $obj = $class->new();
    isa_ok( $obj => $class, "Bare new" );

    is_deeply( [$obj->dicts], [], 'pre load dicts' );
    is_deeply( [$obj->keywords], [], 'pre load keywords' );

    my $phrase = $obj->get();
    is($phrase,undef,'pre load null get');
    $phrase = $obj->get('foo');
    is($phrase,undef,'pre load unknown get');

    eval { $obj->load(); };
    ok($@, 'load dies without a file');

    $obj->load( $file );
    $phrase = $obj->get('foo');

    is_deeply( [$obj->dicts], [], 'single dict empty dict list' );
    is_deeply( [$obj->keywords], ['bar','foo'], 'single dict sorted keywords' );
    is_deeply( [$obj->keywords('quux')], ['bar','foo'], 'override dict in keyword farm' );
    is_deeply( [$obj->keywords([$obj->dicts])], ['bar','foo'], 'farm all keywords' );

    like( $phrase, qr/Welcome to/, 'single dict retrieve');
}

