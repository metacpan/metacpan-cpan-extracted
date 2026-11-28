use strict;
use warnings;
use utf8;
use Test2::V0;

# `birthday` returns the day as a Time::Piece. It used to call `Time::Piece->( ... )` (and
# `Time::Piece->new` with a date string), which died or gave the time of the call (#7).

use Acme::PrettyCure;

my %birthday = (
    CureBlack     => '1990-10-10',
    CureWhite     => '1990-04-04',
    CureBlackMH   => '1990-10-10',
    CureWhiteMH   => '1990-04-04',
    ShinyLuminous => '1990-02-02',
    CureBloom     => '1992-08-07',
    CureEgret     => '1992-11-20',
);

for my $name ( sort keys %birthday ) {
    my ($girl) = Acme::PrettyCure->_get($name);
    my $day = eval { $girl->birthday };
    ok( $day, "$name has a birthday" ) or diag $@;
    isa_ok( $day, ['Time::Piece'], "$name: birthday is a Time::Piece" );
    is( $day && $day->ymd, $birthday{$name}, "$name: birthday is $birthday{$name}" );
}

done_testing;
