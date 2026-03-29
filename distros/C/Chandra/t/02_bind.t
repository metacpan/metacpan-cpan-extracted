#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Chandra');
use_ok('Chandra::Bind');
use_ok('Chandra::Bridge');
use_ok('Chandra::Event');

# Test Chandra::Bind
my $bind = Chandra::Bind->new();

# Test binding a function
my $called = 0;
$bind->bind('test_func', sub {
    my ($x, $y) = @_;
    $called = 1;
    return $x + $y;
});

ok($bind->is_bound('test_func'), 'function is bound');
ok(!$bind->is_bound('nonexistent'), 'nonexistent function not bound');

# Test dispatch of a call
my $json = '{"type":"call","id":1,"method":"test_func","args":[2,3]}';
my $result = $bind->dispatch($json);

ok($called, 'function was called');
is($result->{id}, 1, 'result has correct id');
is($result->{result}, 5, 'function returned correct value');
ok(!defined $result->{error}, 'no error');

# Test dispatch with unknown method
$json = '{"type":"call","id":2,"method":"unknown","args":[]}';
$result = $bind->dispatch($json);
is($result->{id}, 2, 'result has correct id');
ok(defined $result->{error}, 'error for unknown method');
like($result->{error}, qr/Unknown method/, 'error message mentions unknown method');

# Test unbind
$bind->unbind('test_func');
ok(!$bind->is_bound('test_func'), 'function unbound');

# Test Chandra::Bridge
my $js = Chandra::Bridge->js_code;
ok(length($js) > 100, 'JS bridge code is non-empty');
like($js, qr/window\.chandra/, 'JS contains window.chandra');
like($js, qr/invoke/, 'JS contains invoke');

# Test Chandra::Event
my $event = Chandra::Event->new({
    type => 'click',
    targetId => 'btn1',
    targetName => 'submit',
    value => 'hello',
});

is($event->type, 'click', 'event type');
is($event->target_id, 'btn1', 'event target_id');
is($event->target_name, 'submit', 'event target_name');
is($event->value, 'hello', 'event value');

done_testing();
