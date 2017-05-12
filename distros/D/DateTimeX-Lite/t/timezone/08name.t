use strict;
use warnings;

use File::Spec;
use Test::More;

use lib File::Spec->catdir( File::Spec->curdir, 't' );

use DateTimeX::Lite::TimeZone;

plan tests => 4;

{
    my $tz = DateTimeX::Lite::TimeZone->load( name => '-0300' );
    is( $tz->name, '-0300', 'name should match value given in constructor' );
}

{
    my $tz = DateTimeX::Lite::TimeZone->load( name => 'floating' );
    is( $tz->name, 'floating', 'name should match value given in constructor' );
}

{
    my $tz = DateTimeX::Lite::TimeZone->load( name => 'America/Chicago' );
    is( $tz->name, 'America/Chicago', 'name should match value given in constructor' );
}

{
    my $tz = DateTimeX::Lite::TimeZone->load( name => 'UTC' );
    is( $tz->name, 'UTC', 'name should match value given in constructor' );
}
