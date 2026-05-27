use Test2::V0;
use Test2::Require::Module 'bignum';

# Exercises Authen::OATH with Math::BigInt inputs: the `bignum`
# pragma in scope coerces numeric literals in this file to BigInts,
# so the method-input literals below are passed in as BigInts.
#
# A related historical concern (perl < 5.18 / bignum < 0.33) was
# that `bignum`'s `hex` and `oct` overrides leaked outside their
# lexical scope into Authen::OATH itself. That scenario cannot be
# exercised from caller scope on a correctly-scoped perl, so we
# don't try; see perl5180delta for context.

use bignum;

use Authen::OATH ();
use Digest::SHA  ();

my $pwd = '12345678901234567890';

subtest 'totp test vectors (RFC 6238) under bignum' => sub {

    # digits => '8' is string-quoted so bignum doesn't coerce the
    # literal into a Math::BigInt, which would fail Type::Tiny's
    # Int constraint on the Moo accessor.
    my $oath  = Authen::OATH->new( digits => '8' );
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

subtest 'hotp test vectors (RFC 4226) under bignum' => sub {
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

subtest 'BigInt digits constructor arg is rejected' => sub {

    # Locks in current behavior: Type::Tiny's Int rejects refs, and
    # under bignum the literal 8 is a Math::BigInt ref. If the type
    # is ever loosened or coerced, update the POD too.
    like(
        dies { Authen::OATH->new( digits => 8 ) },
        qr/did not pass type constraint/,
        'Math::BigInt literal as digits is rejected by Int constraint'
    );
};

done_testing;
