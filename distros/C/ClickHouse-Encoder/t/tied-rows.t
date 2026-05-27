#!/usr/bin/env perl
# Tied AVs as input rows. DBI's fetchall_arrayref / fetchrow_arrayref
# can return magical arrays (especially with FETCH-side magic from a
# DBI subclass or a tied wrapper). The encoder reaches every element
# via av_fetch which honors magic; pin that the round-trip works for
# both the outer (rows) AV and the inner (per-row) AVs.
use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch';
use ClickHouse::Encoder;

# Simple tied AV that just delegates to a backing array. Each FETCH
# bumps a counter so the test can assert the encoder actually walked
# every element through tie magic (not via some "bypass" backdoor).
{
    package TestTie::Array;
    sub TIEARRAY {
        my ($class, @initial) = @_;
        return bless { data => [@initial], fetches => 0 }, $class;
    }
    sub FETCH    { $_[0]{fetches}++; $_[0]{data}[$_[1]] }
    sub FETCHSIZE{ scalar @{ $_[0]{data} } }
    sub STORE    { $_[0]{data}[$_[1]] = $_[2] }
    sub STORESIZE{ $#{ $_[0]{data} } = $_[1] - 1 }
    sub EXTEND   { }
    sub EXISTS   { exists $_[0]{data}[$_[1]] }
    sub DELETE   { delete $_[0]{data}[$_[1]] }
    sub CLEAR    { @{ $_[0]{data} } = () }
    sub PUSH     { push @{ $_[0]{data} }, @_[1..$#_] }
}

# Tied OUTER array (rows AV) holding plain inner AVs.
{
    tie my @rows, 'TestTie::Array', [1,'a'], [2,'b'], [3,'c'];

    my $enc = ClickHouse::Encoder->new(columns => [['x','Int32'], ['s','String']]);
    my $bytes = $enc->encode(\@rows);
    my $blk = ClickHouse::Encoder->decode_block($bytes);

    is($blk->{nrows}, 3, 'tied outer AV: nrows correct');
    is_deeply($blk->{columns}[0]{values}, [1, 2, 3],
              'tied outer AV: Int32 column intact');
    is_deeply($blk->{columns}[1]{values}, ['a','b','c'],
              'tied outer AV: String column intact');

    my $obj = tied @rows;
    cmp_ok($obj->{fetches}, '>=', 3,
           'tied outer AV: FETCH was called at least once per row');
}

# Tied INNER arrays (per-row AVs). The encoder must av_fetch through
# every column position; tie magic must fire.
{
    tie my @row1, 'TestTie::Array', 100, "alpha";
    tie my @row2, 'TestTie::Array', 200, "beta";
    my $enc = ClickHouse::Encoder->new(columns => [['x','Int32'], ['s','String']]);
    my $bytes = $enc->encode([\@row1, \@row2]);
    my $blk = ClickHouse::Encoder->decode_block($bytes);
    is_deeply($blk->{columns}[0]{values}, [100, 200],
              'tied inner AV: Int32 values via tie FETCH');
    is_deeply($blk->{columns}[1]{values}, ['alpha','beta'],
              'tied inner AV: String values via tie FETCH');
    cmp_ok((tied @row1)->{fetches}, '>=', 2,
           'tied inner AV row1: at least 2 FETCH calls (one per column)');
}

# Tied AVs in BOTH outer and inner positions (full DBI-style pattern).
{
    tie my @r1, 'TestTie::Array', 1, [10, 20, 30];
    tie my @r2, 'TestTie::Array', 2, [40, 50];
    tie my @rows, 'TestTie::Array', \@r1, \@r2;
    my $enc = ClickHouse::Encoder->new(columns =>
        [['id','Int32'], ['vals','Array(Int32)']]);
    my $bytes = $enc->encode(\@rows);
    my $blk   = ClickHouse::Encoder->decode_block($bytes);
    is($blk->{nrows}, 2, 'doubly-tied: nrows');
    is_deeply($blk->{columns}[0]{values}, [1, 2], 'doubly-tied: ids');
    is_deeply($blk->{columns}[1]{values},
              [[10,20,30], [40,50]],
              'doubly-tied: Array(Int32) values via nested tie FETCH');
}

# encode_columns also threads through SvGETMAGIC on per-column AVs.
# Same pattern as do_encode but the column-oriented entry point - tied
# per-column input from a DBI-ish source must work too.
{
    tie my @col_n, 'TestTie::Array', 10, 20, 30;
    tie my @col_s, 'TestTie::Array', 'x', 'y', 'z';
    my $enc = ClickHouse::Encoder->new(
        columns => [['n','Int32'], ['s','String']]);
    my $bytes = $enc->encode_columns({ n => \@col_n, s => \@col_s });
    my $blk = ClickHouse::Encoder->decode_block($bytes);
    is_deeply($blk->{columns}[0]{values}, [10, 20, 30],
              'encode_columns: tied per-column Int32 via SvGETMAGIC');
    is_deeply($blk->{columns}[1]{values}, ['x', 'y', 'z'],
              'encode_columns: tied per-column String via SvGETMAGIC');
}

# Clean-warnings sanity: tied AV access shouldn't emit "Use of
# uninitialized value" or similar. Capture warnings and assert none
# come from the encode call.
{
    tie my @rows, 'TestTie::Array', [7, 'x'], [8, 'y'];
    my $enc = ClickHouse::Encoder->new(
        columns => [['n','Int32'], ['s','String']]);
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    my $bytes = $enc->encode(\@rows);
    is(scalar @warnings, 0,
       'no warnings emitted while encoding from a tied row source')
        or diag(join "\n", @warnings);
    ok(length $bytes > 0, 'tied input produced non-empty encoded bytes');
}

done_testing();
