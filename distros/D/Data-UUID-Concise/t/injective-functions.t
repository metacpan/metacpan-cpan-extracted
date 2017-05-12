use strictures;
use Data::UUID;
use Data::UUID::Concise;
use Test::More;
use Test::Exception;

my $du  = Data::UUID->new;
my $duc = Data::UUID::Concise->new;

{
    my $uuid =
        ( Data::UUID->new )
        ->from_string( '6ca4f0f8-2508-4bac-b8f1-5d1e3da2247a' );

    ok( $du->compare( $duc->decode( $duc->encode( $uuid ) ), $uuid ),
        'the mapping is injective and preserves the value of the UUID'
    );
}

my %encoded_uuids;

$encoded_uuids{ $duc->encode( $du->create ) } = 1 for 1 .. 300;

{

    is( scalar keys %encoded_uuids,
        300, 'our encoding preserves uniqueness' );
}

SKIP: {
    skip
        'these tests fail inconsistently based on the from_string method in Data::UUID',
        scalar keys %encoded_uuids;
    for my $uuid ( keys %encoded_uuids ) {
        lives_ok(
            sub {
                my $encoded = $duc->encode( $uuid );
                my $decoded = $duc->decode( $encoded );
                $du->compare( $uuid, $decoded );
            }
        );
    }
}

done_testing;
