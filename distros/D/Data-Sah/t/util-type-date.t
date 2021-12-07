#!perl

use 5.010;
use strict;
use warnings;

use Test::More 0.98;

use Data::Sah::Util::Type::Date qw(coerce_date);

my @datemods = (qw/Time::Moment DateTime Time::Piece/);
my %mod_available;
for my $mod (@datemods) {
    $mod_available{$mod} = eval "require $mod; 1" ? 1:0;
}

plan tests => scalar @datemods;
for my $mod (@datemods) {
    SKIP: {
        skip "$mod not available", 1 unless $mod_available{$mod};

        local $Data::Sah::Util::Type::Date::DATE_MODULE = $mod;

        subtest "coerce_date ($mod)" => sub {
            ok(!defined(coerce_date(undef)));
            ok(!defined(coerce_date("x")));
            ok(!defined(coerce_date(100_000)));
            ok(!defined(coerce_date(3_000_000_000)));
            #ok(!defined(coerce_date("2014-04-31"))); # Time::Piece accepts this
            ok(!defined(coerce_date("2014-04-32")));

            is( ref(coerce_date("2014-04-25")), $mod);
            is( ref(coerce_date("2014-04-25T10:20:30Z")), $mod);
            is( ref(coerce_date(100_000_000)), $mod);
            is( ref(coerce_date(DateTime->now)), $mod) if $mod_available{DateTime};
            is( ref(coerce_date(Time::Moment->now)), $mod) if $mod_available{'Time::Moment'};
            is( ref(coerce_date(scalar Time::Piece->gmtime)), $mod) if $mod_available{'Time::Piece'};
        };
    }
}
