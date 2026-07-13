#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;
use Test::Exception;

use CBOR::Free;
use CBOR::Free::Decoder;
use CBOR::Free::SequenceDecoder;

sub cbor {
    my ($hex) = @_;
    $hex =~ s/\s+//g;
    return pack 'H*', $hex;
}

sub rejects_duplicate {
    my ($code, $name) = @_;
    throws_ok { $code->() } 'CBOR::Free::X::DuplicateMapKey', $name;
    return $@;
}

my $duplicate_text = cbor('a2 61 61 01 61 61 02');

is_deeply(CBOR::Free::decode($duplicate_text), { a => 2 },
    'functional decoder keeps the later duplicate by default');

my $decoder = CBOR::Free::Decoder->new();
is_deeply($decoder->decode($duplicate_text), { a => 2 },
    'object decoder keeps the later duplicate by default');
ok($decoder->reject_duplicate_keys(), 'duplicate-key rejection can be enabled');

my $duplicate_error = rejects_duplicate(
    sub { $decoder->decode($duplicate_text) },
    'duplicate text key is rejected',
);

like(
    ref($duplicate_error) ? $duplicate_error->get_message() : '',
    qr<offset 4>,
    'duplicate-key error gives the second key offset',
);

my @duplicates = (
    [ 'integer key'         => 'a2 01 01 01 02' ],
    [ 'indefinite text key' => 'a2 7f 61 61 ff 01 7f 61 61 ff 02' ],
    [ 'nested map'          => 'a1 61 78 a2 61 61 01 61 61 02' ],
    [ 'undefined value'     => 'a2 61 61 f7 61 61 02' ],
    [ 'text/binary'         => 'a2 61 61 01 41 61 02' ],
    [ 'integer/text'        => 'a2 01 01 61 31 02' ],
);

for my $case (@duplicates) {
    rejects_duplicate(sub { $decoder->decode(cbor($case->[1])) },
        "$case->[0] duplicate is rejected");
}

is_deeply(
    $decoder->decode(cbor('a2 61 61 01 61 62 02')),
    { a => 1, b => 2 },
    'decoder can decode distinct keys after a duplicate-key error');

ok(!$decoder->reject_duplicate_keys(0), 'duplicate-key rejection can be disabled');
is_deeply($decoder->decode($duplicate_text), { a => 2 },
    'disabled decoder restores default behavior');

my $partial = CBOR::Free::SequenceDecoder->new();
$partial->reject_duplicate_keys();
is($partial->give(substr($duplicate_text, 0, 5)), undef,
    'partial duplicate key waits for its remaining bytes');
rejects_duplicate(sub { $partial->give(substr($duplicate_text, 5)) },
    'duplicate split across sequence chunks is rejected');

done_testing;
