use Test::More tests => 2;

BEGIN {
use_ok( 'Date::Holidays::PT' );
}

my $mh = Date::Holidays::PT->new();

is($mh->holidays(), undef);
