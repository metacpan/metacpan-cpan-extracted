use strict;
use warnings;

use Test::More;
use Test::Warnings;

use Data::DynamicValidator qw/validator/;

sub _v {
    my ($data, $selector) = @_;
    return validator($data)->_select($selector);
};

sub _e {
    my ($data, $selector) = @_;
    my $routes = [
        map { "$_" } @{ validator($data)->_expand_routes($selector) }
    ];
    return $routes;
}

# routes expansion
{
    my $r;

    $r = _e({ a => [5,'z']}, '/a');
    is_deeply( $r, ['/a']);

    $r = _e({ a => [5,'z']}, '//a');
    is_deeply( $r, ['/a']);

    $r = _e({ a => [5,'z']}, '/a/0');
    is_deeply( $r, ['/a/0']);

    $r = _e({ a => [5,'z']}, '/a/1');
    is_deeply( $r, ['/a/1']);

    $r = _e({ a => [5,'z']}, '/a/5');
    is_deeply( $r, []);

    $r = _e({ a => [5,'z']}, '/a/-2');
    is_deeply( $r, ['/a/-2']);

    $r = _e({ a => [5,'z']}, '/a/-1');
    is_deeply( $r, ['/a/-1']);

    $r = _e({ a => [5,'z']}, '/a/-3');
    is_deeply( $r, []);

    $r = _e({ a => [5,'z']}, '/a/*');
    is_deeply( $r, ['/a/0', '/a/1']);

    $r = _e({ a => { b => 2, c => 3, 1 => 4}}, '/a/*');
    is_deeply( $r, ['/a/1', '/a/b', '/a/c']);

    $r = _e({ a => { b => [5,'z']} }, '/a/*/*');
    is_deeply( $r, ['/a/b/0', '/a/b/1']);

    $r = _e({ a => { b => [5,'z']} }, '/*/*/*');
    is_deeply( $r, ['/a/b/0', '/a/b/1']);

    $r = _e({ a => { b => [5,'z']} }, '/*/*/1');
    is_deeply( $r, ['/a/b/1']);

    $r = _e([{ a => { b => [5,'z']} }], '/*/*/*/1');
    is_deeply( $r, ['/0/a/b/1']);
}

# check named routes
{
    my $r;
    $r = validator({ a => { b => [5,'z']} })->_expand_routes('/*/v2:*/*');
    is_deeply [ map { "$_" } @$r], ['/a/b/0', '/a/b/1'];
    is $r->[0]->named_route('v2')->to_string, '/a/b', 'has v2 at 1st route';
    is $r->[1]->named_route('v2')->to_string, '/a/b', 'has v2 at 2nd route';

    $r = validator({ a => { b => [5,'z']} })->_expand_routes('/v1:*/v2:*/v3:0');
    is_deeply [ map { "$_" } @$r], ['/a/b/0'], 'expands correctly';
    my $p = $r->[0];
    is_deeply [$p->labels], ['v1', 'v2', 'v3' ], 'all labels mentioned';

    is $p->named_route('v1')->to_string, '/a'    , 'v1 present';
    is $p->named_route('v2')->to_string, '/a/b'  , 'v2 present';
    is $p->named_route('v3')->to_string, '/a/b/0', 'v3 present';
    is $p->named_route('_')->to_string,  '/a/b/0', '_ present';
}

# check values at routes
{
    my $data = { a => { b => [5,'z']} };
    my $p = validator($data)->_expand_routes('/v1:*/v2:*/v3:0')->[0];
    is $p->value($data), 5, 'got 5';
    is $p->value($data, 'v3'), 5, 'got 5 (via label)';
    is $p->named_component('v3'), 0, 'got correct label value for v3';
    is $p->named_component('v2'), 'b', 'got correct label value for v2';
    is $p->named_component('v1'), 'a', 'got correct label value for v1';
    is_deeply $p->value($data, 'v2'), [5, 'z'], 'got correct values for v2';
    is_deeply $p->value($data, 'v1'), { b=> [5, 'z'] }, 'got correct values for v1)';
}

# check selector
{
    my $r;
    $r = validator({ a => { b => [5,'z']} })->_select('/*/*/*');
    is_deeply $r->{values}, [5, 'z'], "got correct 'values' on selector";
    my $routes = [ map { "$_" } @{ $r->{routes} } ];
    is_deeply  $routes, ['/a/b/0', '/a/b/1'], "got correct 'routes' on selector";
};

done_testing;
