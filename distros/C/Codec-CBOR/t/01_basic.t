use v5.40;
use Test2::V0;
use lib 'lib';
use Codec::CBOR;
#
my $codec = Codec::CBOR->new();
#
subtest 'Basic Roundtrip' => sub {
    my @cases = (
        undef, 0, 1, 23, 24, 255, 256, 65535, 65536, 4294967295, 4294967296, -1, -24, -255, -65536, 'hello',
        'world with spaces',
        "unicode \x{1f600}",
        [ 1, 2, 3 ],
        { a     => 1,              b => 2 },
        { inner => [ { x => 1 } ], y => 'z' }
    );
    for my $case (@cases) {
        my $encoded = $codec->encode($case);
        my $decoded = $codec->decode($encoded);
        is $decoded, $case, 'Roundtrip for ' . ( defined $case ? ( ref $case // $case ) : 'undef' );
    }
};
subtest 'DAG-CBOR Determinism' => sub {
    my $h1 = { a => 1, b => 2, c => 3 };
    my $h2 = { c => 3, a => 1, b => 2 };
    is $codec->encode($h1), $codec->encode($h2), 'Hash encoding is deterministic';
};
subtest 'Sequence Decoding' => sub {
    my $data  = $codec->encode( { a => 1 } ) . $codec->encode( { b => 2 } );
    my @items = $codec->decode_sequence($data);
    is scalar(@items), 2, 'Decoded 2 items from sequence';
    is $items[0], { a => 1 }, '1st item correct';
    is $items[1], { b => 2 }, '2nd item correct';
};
subtest 'Tag 42 (CID)' => sub {
    {
        # Mock a CID object
        package Mock::CID;
        sub new { bless { raw => 'foobar' }, shift }
        sub raw { shift->{raw} }
    }
    my $cid     = Mock::CID->new();
    my $encoded = $codec->encode($cid);
    my $decoded = $codec->decode($encoded);
    is ref $decoded, 'HASH', 'Decoded Tag 42 into hash (default handler)';

    # Default handler strips the leading 00 if present
    is $decoded->{cid_raw}, 'foobar', 'Extracted cid_raw matches';
};
#
done_testing;
