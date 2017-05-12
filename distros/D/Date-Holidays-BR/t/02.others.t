use Test::More tests => 2;

BEGIN {
use_ok( 'Date::Holidays::BR' );
}

my $mh = Date::Holidays::BR->new();

is($mh->holidays(), undef);
