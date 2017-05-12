use strict;
use warnings;

use Test::More;

plan skip_all => "not HP-UX" unless $^O eq 'hpux';

use DateTime::TimeZone::HPUX;
plan skip_all => "no Java" unless DateTime::TimeZone::HPUX::_java_bin();

diag DateTime::TimeZone::HPUX::_java_bin();

plan tests => 4;

# No timezone in the environment
local $ENV;
delete $ENV{TZ};

# Skip /etc/TIMEZONE
sub DateTime::TimeZone::Local::hpux::SKIP_ETC_TIMEZONE { 1 }

use DateTime::TimeZone;

$SIG{__WARN__} = sub {
    my $w = $_[0];
    #chomp $w;
    pass "Warning raised";
    diag "Expected warn: $w";
};

my $tz1 = DateTime::TimeZone->new( name => 'local' );
isa_ok( $tz1, 'DateTime::TimeZone' );
diag($tz1->name);

my $tz2 = DateTime::TimeZone->new( name => $tz1->name );
isa_ok( $tz2, 'DateTime::TimeZone' );
is( $tz2->name, $tz1->name, "Can recreate object from name");
