#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Chandra::Event');

# --- basic construction ---
{
    my $e = Chandra::Event->new({
        type       => 'click',
        targetId   => 'btn1',
        targetName => 'submit',
        value      => 'hello',
        checked    => 1,
        key        => 'Enter',
        keyCode    => 13,
    });

    isa_ok($e, 'Chandra::Event');
    is($e->type, 'click', 'type accessor');
    is($e->target_id, 'btn1', 'target_id accessor');
    is($e->target_name, 'submit', 'target_name accessor');
    is($e->value, 'hello', 'value accessor');
    is($e->checked, 1, 'checked accessor');
    is($e->key, 'Enter', 'key accessor');
    is($e->key_code, 13, 'key_code accessor');
}

# --- empty event ---
{
    my $e = Chandra::Event->new({});
    is($e->type, undef, 'empty event type is undef');
    is($e->target_id, undef, 'empty event target_id is undef');
    is($e->value, undef, 'empty event value is undef');
    is($e->checked, undef, 'empty event checked is undef');
    is($e->key, undef, 'empty event key is undef');
    is($e->key_code, undef, 'empty event key_code is undef');
}

# --- undef data argument ---
{
    my $e = Chandra::Event->new(undef);
    isa_ok($e, 'Chandra::Event');
    is($e->type, undef, 'undef data: type is undef');
}

# --- no argument ---
{
    my $e = Chandra::Event->new();
    isa_ok($e, 'Chandra::Event');
    is($e->type, undef, 'no args: type is undef');
}

# --- data() accessor ---
{
    my $e = Chandra::Event->new({
        type => 'custom',
        data => { foo => 'bar', nested => { deep => 1 } },
    });

    is_deeply($e->data, { foo => 'bar', nested => { deep => 1 } }, 'data() returns full hash');
    is($e->data('foo'), 'bar', 'data(key) returns value');
    is_deeply($e->data('nested'), { deep => 1 }, 'data(key) returns nested ref');
    is($e->data('nonexistent'), undef, 'data(missing key) returns undef');
}

# --- data() when data is not a hash ---
{
    my $e = Chandra::Event->new({
        type => 'test',
        data => 'just_a_string',
    });
    is($e->data, 'just_a_string', 'data() returns scalar');
    is($e->data('key'), undef, 'data(key) returns undef when data is not a hash');
}

# --- data() when no data field ---
{
    my $e = Chandra::Event->new({ type => 'test' });
    is($e->data, undef, 'data() returns undef when no data field');
    is($e->data('key'), undef, 'data(key) returns undef when no data field');
}

# --- get() for arbitrary fields ---
{
    my $e = Chandra::Event->new({
        type    => 'keyup',
        custom1 => 'val1',
        custom2 => 42,
        nested  => { a => 1 },
    });

    is($e->get('type'), 'keyup', 'get(type)');
    is($e->get('custom1'), 'val1', 'get(custom1)');
    is($e->get('custom2'), 42, 'get(custom2)');
    is_deeply($e->get('nested'), { a => 1 }, 'get(nested)');
    is($e->get('nonexistent'), undef, 'get(nonexistent) returns undef');
}

# --- checkbox event ---
{
    my $e = Chandra::Event->new({
        type       => 'change',
        targetId   => 'chk1',
        checked    => 0,
        value      => 'on',
    });
    is($e->checked, 0, 'checkbox unchecked is 0');
    is($e->type, 'change', 'change event type');
}

# --- keyboard event ---
{
    my $e = Chandra::Event->new({
        type    => 'keydown',
        key     => 'Escape',
        keyCode => 27,
    });
    is($e->key, 'Escape', 'keyboard key');
    is($e->key_code, 27, 'keyboard keyCode');
}

# --- UTF-8 values ---
{
    my $e = Chandra::Event->new({
        type  => 'input',
        value => '日本語テキスト',
    });
    is($e->value, '日本語テキスト', 'UTF-8 value');
}

done_testing();
