#!/usr/bin/perl -w

use strict;
use vars qw( $class );
use Test::More tests => 23;

# ------------------------------------------------------------------------

BEGIN {
    $class = 'Data::Phrasebook::Loader::YAML';
    use_ok($class);
}

my $file = 't/04phrases.yaml';

# ------------------------------------------------------------------------

{
    my $obj = $class->new();
    isa_ok( $obj => $class, "Bare new" );

    eval { $obj->load( $file ); 1; };
    ok(! $@, 'Load did not die');

    is_deeply( [$obj->dicts], ['cabbage','onion','potato','sprout'], 'all dicts in file' );
    is_deeply( [$obj->keywords], ['cooked','raw'], 'default keywords in file' );
    is_deeply( [$obj->keywords('potato')], ['cook','cooked','grow','raw'], 'keywords in specified dict' );
    is_deeply( [$obj->keywords([$obj->dicts])], ['cat','cook','cooked','dog','grow','nice','notnice','perl','raw'], 'all keywords in file' );

    my $phrase = $obj->get();
    is($phrase,undef,'get nothing');

    $phrase = $obj->get('quux');
    is($phrase,undef,'get unknown');

    $phrase = $obj->get('cooked');
    is( $phrase, 'okay', 'get known key in default');

    $phrase = $obj->get('nice');
    is($phrase,undef,'get known in unavailable dict');

    $obj->set_default('potato');
    $obj->load( $file );

    is_deeply( [$obj->keywords], ['cook','cooked','grow','raw'], 'default keywords changed' );
    is_deeply( [$obj->keywords('potato')], ['cook','cooked','grow','raw'], 'keywords in specified dict changed 1' );
    is_deeply( [$obj->keywords('sprout')], ['cat','cook','cooked','dog','grow','raw'], 'keywords in specified dict changed 2' );
    is_deeply( [$obj->keywords([$obj->dicts])], ['cat','cook','cooked','dog','grow','nice','notnice','perl','raw'], 'all keywords in file' );

    $phrase = $obj->get();
    is($phrase,undef,'get nothing');

    $phrase = $obj->get('quux');
    is($phrase,undef,'get unknown');

    $phrase = $obj->get('cooked');
    is( $phrase, 'great', 'get known key in default');

    $phrase = $obj->get('nice');
    is($phrase,undef,'get known in unavailable dict');

    $obj->set_default('potato');
    $obj->load( $file, ['sprout','onion'] );

    $phrase = $obj->get('cooked');
    is( $phrase, 'terrible', 'get known key 1');

    $phrase = $obj->get('grow');
    is( $phrase, 'easy', 'get known key 2');

    $phrase = $obj->get('perl');
    is( $phrase, 'just right', 'get known key 3');

    is_deeply( [$obj->keywords], ['cat','cook','cooked','dog','grow','nice','notnice','perl','raw'], 'default keywords changed' );
}

