use strict;
use warnings;

use Test::More;
use Dancer2::Serializer::Dumper;

my $serializer = Dancer2::Serializer::Dumper->new;
isa_ok( $serializer, 'Dancer2::Serializer::Dumper' );
is( $serializer->content_type, 'text/x-data-dumper', 'content type' );

my $data = {
    foo => 'bar',
    list => [ 1, 2, 3 ],
    nested => { a => 1 },
};

my $serialized = $serializer->serialize($data);
like( $serialized, qr/foo/, 'serialize produces Dumper output' );

my $deserialized = $serializer->deserialize($serialized);
is_deeply( $deserialized, $data, 'serialize/deserialize round trip' );

my $via_to   = Dancer2::Serializer::Dumper->to_dumper($data);
my $via_from = Dancer2::Serializer::Dumper->from_dumper($via_to);
is_deeply( $via_from, $data, 'to_dumper/from_dumper helper round trip' );

done_testing;