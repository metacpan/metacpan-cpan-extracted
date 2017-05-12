#!/usr/bin/perl -w

use strict;
use vars qw( $class );
use Test::More tests => 16;

# ------------------------------------------------------------------------

BEGIN {
    $class = 'Data::Phrasebook::Loader::YAML';
    use_ok($class);
}

my $file = 't/03phrases.yaml';

# ------------------------------------------------------------------------

{
    my $obj = $class->new();
    isa_ok( $obj => $class, "Bare new" );

    eval { $obj->load( $file ); 1; };
    ok(! $@, 'Load did not die');

    is_deeply( [$obj->dicts], ['first','second'], 'all dicts in file' );
    is_deeply( [$obj->keywords], ['baz','foo'], 'default keywords in file' );
    is_deeply( [$obj->keywords('second')], ['baz','foo','one','three'], 'keywords in specified dict' );
    is_deeply( [$obj->keywords([$obj->dicts])], ['baz','foo','one','three'], 'all keywords in file' );

    my $phrase = $obj->get();
    is($phrase,undef,'get nothing');

    $phrase = $obj->get('quux');
    is($phrase,undef,'get unknown');

    $phrase = $obj->get('foo');
    is( $phrase, 'bar', 'get known key in default');

    $phrase = $obj->get('one');
    is($phrase,undef,'get known in unavailable dict');

    $obj->load( $file, 'second' );
    is_deeply( [$obj->keywords], ['baz','foo','one','three'], 'default keywords in file' );
    is_deeply( [$obj->keywords([$obj->dicts])], ['baz','foo','one','three'], 'all keywords in file' );
}

{
	my @dicts = ('third','first');

    my $obj = $class->new();
	$obj->load( $file, @dicts );
    my $phrase = $obj->get('three');
    is( $phrase, undef, 'get wrong key with missing dictionary');
    $phrase = $obj->get('foo');
    is( $phrase, 'bar', 'get default key with missing dictionary');

    is_deeply( [$obj->keywords(\@dicts)], ['baz','foo'], 'default keywords in file' );

}