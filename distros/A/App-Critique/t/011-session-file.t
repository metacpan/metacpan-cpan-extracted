#!perl

use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('App::Critique::Session::File');
}


subtest '... basic session file' => sub {

    my $f = App::Critique::Session::File->new( path => __FILE__ );
    isa_ok($f, 'App::Critique::Session::File');

    isa_ok($f->path, 'Path::Tiny');
    is($f->path->stringify, __FILE__, '... got the expected path');

    is_deeply(
        $f->pack,
        {
            path => __FILE__,
            meta => {},
        },
        '... got the expected packed values'
    );

    $f->remember( foo => 'bar' );
    $f->remember( bar => 'baz' );

    is($f->recall('foo'), 'bar', '... got the remembered value foo');
    is($f->recall('bar'), 'baz', '... got the remembered value bar');

    is_deeply(
        $f->pack,
        {
            path => __FILE__,
            meta => { foo => 'bar', bar => 'baz' },
        },
        '... got the expected packed values (with remembered values)'
    );

    is($f->forget('foo'), 'bar', '... forget the remembered foo value (and return it)');
    is($f->recall('foo'), undef, '... and we no longer remember the value');

    is_deeply(
        $f->pack,
        {
            path => __FILE__,
            meta => { bar => 'baz' },
        },
        '... got the expected packed values (with the forgotten foo value)'
    );

};

subtest '... basic session file' => sub {

    my $f = App::Critique::Session::File->unpack({
        path => __FILE__,
        meta => { foo => 'bar', bar => 'baz' }
    });

    isa_ok($f, 'App::Critique::Session::File');

    is_deeply(
        $f->pack,
        {
            path => __FILE__,
            meta => { foo => 'bar', bar => 'baz' },
        },
        '... got the expected packed values'
    );

};

done_testing;

