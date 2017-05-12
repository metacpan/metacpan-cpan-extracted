use strict;
use warnings;

use File::Spec;
use Test::More;

use lib File::Spec->catdir( File::Spec->curdir, 't' );


use DateTimeX::Lite::TimeZone;

my @links = DateTimeX::Lite::TimeZone::links();

plan tests => @links + 2;

for my $link (@links)
{
    my $tz = DateTimeX::Lite::TimeZone->load( name => $link );
    isa_ok( $tz, 'DateTimeX::Lite::TimeZone' );
}

my $tz = DateTimeX::Lite::TimeZone->load( name => 'Libya' );
is( $tz->name, 'Africa/Tripoli', 'check ->name' );

$tz = DateTimeX::Lite::TimeZone->load( name => 'US/Central' );
is( $tz->name, 'America/Chicago', 'check ->name' );
