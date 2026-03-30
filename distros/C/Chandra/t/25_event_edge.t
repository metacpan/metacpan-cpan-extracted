#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Chandra::Event');

# === deeply nested data structure ===
{
    my $e = Chandra::Event->new({
        type => 'custom',
        data => {
            level1 => {
                level2 => {
                    level3 => 'deep value',
                },
            },
        },
    });
    is_deeply($e->data('level1'), { level2 => { level3 => 'deep value' } }, 'nested data accessible');
    is($e->data('level1')->{level2}{level3}, 'deep value', 'deep traversal works');
}

# === data with array value ===
{
    my $e = Chandra::Event->new({
        type => 'test',
        data => { items => [1, 2, 3] },
    });
    is_deeply($e->data('items'), [1, 2, 3], 'array value in data');
}

# === data when data is undef ===
{
    my $e = Chandra::Event->new({ type => 'test', data => undef });
    is($e->data, undef, 'data() returns undef when data is undef');
    is($e->data('key'), undef, 'data(key) returns undef when data is undef');
}

# === data when data is numeric ===
{
    my $e = Chandra::Event->new({ type => 'test', data => 42 });
    is($e->data, 42, 'data() returns numeric');
    is($e->data('key'), undef, 'data(key) returns undef for numeric data');
}

# === data when data is arrayref (not hash) ===
{
    my $e = Chandra::Event->new({ type => 'test', data => [1, 2, 3] });
    is_deeply($e->data, [1, 2, 3], 'data() returns arrayref');
    is($e->data('key'), undef, 'data(key) returns undef for arrayref data');
}

# === get with all standard fields ===
{
    my $e = Chandra::Event->new({
        type       => 'keydown',
        targetId   => 'input1',
        targetName => 'username',
        value      => 'test',
        checked    => 0,
        key        => 'a',
        keyCode    => 65,
    });
    is($e->get('type'), 'keydown', 'get type');
    is($e->get('targetId'), 'input1', 'get targetId');
    is($e->get('targetName'), 'username', 'get targetName');
    is($e->get('value'), 'test', 'get value');
    is($e->get('checked'), 0, 'get checked');
    is($e->get('key'), 'a', 'get key');
    is($e->get('keyCode'), 65, 'get keyCode');
}

# === get with custom fields ===
{
    my $e = Chandra::Event->new({
        type     => 'custom',
        clientX  => 100,
        clientY  => 200,
        shiftKey => 1,
        altKey   => 0,
    });
    is($e->get('clientX'), 100, 'custom field clientX');
    is($e->get('clientY'), 200, 'custom field clientY');
    is($e->get('shiftKey'), 1, 'custom field shiftKey');
    is($e->get('altKey'), 0, 'custom field altKey');
}

# === get returns undef for nonexistent keys ===
{
    my $e = Chandra::Event->new({ type => 'click' });
    is($e->get('nope'), undef, 'get nonexistent key');
    is($e->get(''), undef, 'get empty string key');
}

# === boolean-like values ===
{
    my $e = Chandra::Event->new({
        type    => 'change',
        checked => 0,
        value   => '',
    });
    is($e->checked, 0, 'checked false is 0 not undef');
    is($e->value, '', 'value empty string not undef');
    ok(defined $e->checked, 'checked=0 is defined');
    ok(defined $e->value, 'value="" is defined');
}

# === special characters in value ===
{
    my $e = Chandra::Event->new({
        type  => 'input',
        value => "line1\nline2\ttab<html>&amp;'\"",
    });
    like($e->value, qr/\n/, 'newline in value');
    like($e->value, qr/\t/, 'tab in value');
    like($e->value, qr/<html>/, 'html in value');
    like($e->value, qr/&amp;/, 'ampersand in value');
}

# === event with all undef fields ===
{
    my $e = Chandra::Event->new({
        type       => undef,
        targetId   => undef,
        targetName => undef,
        value      => undef,
        checked    => undef,
        key        => undef,
        keyCode    => undef,
    });
    is($e->type, undef, 'explicit undef type');
    is($e->target_id, undef, 'explicit undef target_id');
    is($e->value, undef, 'explicit undef value');
}

# === numeric type field ===
{
    my $e = Chandra::Event->new({ type => 42 });
    is($e->type, 42, 'numeric type accepted');
}

# === data hash with numeric keys ===
{
    my $e = Chandra::Event->new({
        type => 'test',
        data => { 0 => 'zero', 1 => 'one', '2' => 'two' },
    });
    is($e->data(0), 'zero', 'numeric key 0');
    is($e->data(1), 'one', 'numeric key 1');
    is($e->data('2'), 'two', 'string-numeric key');
}

# === large event payload ===
{
    my %big_data;
    $big_data{"key_$_"} = "value_$_" for 1..100;
    my $e = Chandra::Event->new({
        type => 'bulk',
        data => \%big_data,
    });
    is($e->data('key_50'), 'value_50', 'large data accessible');
    is($e->data('key_100'), 'value_100', 'last key accessible');
    is(scalar keys %{$e->data}, 100, '100 keys in data');
}

done_testing;
