use Test2::V0;

use Authen::OATH ();
use Digest::SHA  ();

my $pwd = '12345678901234567890';

subtest 'defaults' => sub {
    my $oath = Authen::OATH->new;
    isa_ok( $oath, ['Authen::OATH'] );
    is( $oath->digits,   6,             'default digits is 6' );
    is( $oath->digest,   'Digest::SHA', 'default digest is Digest::SHA' );
    is( $oath->timestep, 30,            'default timestep is 30' );
};

subtest 'totp test vectors (RFC 6238)' => sub {
    my $oath  = Authen::OATH->new( digits => 8 );
    my @cases = (
        [ 59,         '94287082' ],
        [ 1111111109, '07081804' ],
        [ 1111111111, '14050471' ],
        [ 1234567890, '89005924' ],
        [ 2000000000, '69279037' ],
    );
    for my $case (@cases) {
        my ( $time, $expected ) = @{$case};
        is(
            $oath->totp( $pwd, $time ), $expected,
            "totp at time $time"
        );
    }
};

subtest 'hotp test vectors (RFC 4226)' => sub {
    my $oath  = Authen::OATH->new;
    my @cases = (
        [ 0, '755224' ],
        [ 1, '287082' ],
        [ 2, '359152' ],
        [ 3, '969429' ],
        [ 4, '338314' ],
        [ 5, '254676' ],
        [ 6, '287922' ],
        [ 7, '162583' ],
        [ 8, '399871' ],
        [ 9, '520489' ],
    );
    for my $case (@cases) {
        my ( $counter, $expected ) = @{$case};
        is(
            $oath->hotp( $pwd, $counter ), $expected,
            "hotp counter $counter"
        );
    }
};

done_testing;
