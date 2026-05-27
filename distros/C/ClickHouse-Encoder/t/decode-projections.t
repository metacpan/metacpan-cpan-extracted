#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch';
use ClickHouse::Encoder;

# Column projections: pass a hashref of column names to KEEP; columns
# not in the set still decode (to advance the cursor) but their values
# array is replaced with one undef per row and the column carries a
# `skipped => 1` marker.

my $enc = ClickHouse::Encoder->new(columns => [
    ['id',   'UInt64'],
    ['user', 'String'],
    ['tags', 'Array(String)'],
    ['ts',   'DateTime'],
]);
my $bytes = $enc->encode([
    [1, 'alice', ['a','b'], 1700_000_000],
    [2, 'bob',   ['c'],     1700_000_001],
    [3, 'carol', [],        1700_000_002],
]);

# No filter -> full decode
{
    my $block = ClickHouse::Encoder->decode_block($bytes);
    is($block->{ncols}, 4, 'full decode: ncols');
    is($block->{nrows}, 3, 'full decode: nrows');
    is_deeply($block->{columns}[1]{values}, ['alice','bob','carol'],
              'full decode: user values');
}

# Filter to two columns
{
    my $block = ClickHouse::Encoder->decode_block(
        $bytes, 0, { id => 1, user => 1 });
    is($block->{ncols}, 4, 'filter: ncols still reflects wire shape');
    is($block->{columns}[0]{name}, 'id',   'col 0 name');
    is($block->{columns}[1]{name}, 'user', 'col 1 name');
    is($block->{columns}[2]{name}, 'tags', 'col 2 name');
    is($block->{columns}[3]{name}, 'ts',   'col 3 name');

    ok(!$block->{columns}[0]{skipped}, 'kept col: no skipped marker');
    ok(!$block->{columns}[1]{skipped}, 'kept col: no skipped marker');
    is($block->{columns}[2]{skipped}, 1, 'tags: skipped marker');
    is($block->{columns}[3]{skipped}, 1, 'ts: skipped marker');

    is_deeply($block->{columns}[0]{values}, [1,2,3],
              'kept col values intact');
    is_deeply($block->{columns}[1]{values}, ['alice','bob','carol'],
              'kept col values intact');
    is_deeply($block->{columns}[2]{values}, [undef, undef, undef],
              'skipped col: placeholder undefs');
    is_deeply($block->{columns}[3]{values}, [undef, undef, undef],
              'skipped col: placeholder undefs');
}

# Filter that matches nothing -> all columns skipped, but bytes consumed
{
    my $block = ClickHouse::Encoder->decode_block(
        $bytes, 0, { nonexistent => 1 });
    is_deeply([map $_->{skipped}, @{ $block->{columns} }],
              [1, 1, 1, 1],
              'no matches: every column skipped');
    is($block->{consumed}, length $bytes, 'cursor advanced fully');
}

# Empty filter hashref -> same as no-match
{
    my $block = ClickHouse::Encoder->decode_block($bytes, 0, {});
    is_deeply([map $_->{skipped}, @{ $block->{columns} }],
              [1, 1, 1, 1], 'empty filter: all skipped');
}

# undef filter -> full decode (3rd arg is optional)
{
    my $block = ClickHouse::Encoder->decode_block($bytes, 0, undef);
    is_deeply($block->{columns}[1]{values}, ['alice','bob','carol'],
              'undef filter: full decode');
}

# Non-hashref filter is rejected
{
    my $err = eval {
        ClickHouse::Encoder->decode_block($bytes, 0, ['id']); 1
    } ? '' : $@;
    like($err, qr/columns filter must be a hashref/,
         'arrayref filter rejected');
}

# Plain (non-ref) scalar filter is also rejected, without crashing on
# SvRV(non-ref) inside the error-message format.
{
    my $err = eval {
        ClickHouse::Encoder->decode_block($bytes, 0, "id,user"); 1
    } ? '' : $@;
    like($err, qr/columns filter must be a hashref/,
         'string filter rejected (no segfault)');
}

done_testing();
