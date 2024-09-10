#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use open ':std' => ':utf8';
    use vars qw( $DEBUG );
    use utf8;
    use version;
    use Test::More;
    use DateTime;
    use DBD::SQLite;
    if( version->parse( $DBD::SQLite::sqlite_version ) < version->parse( '3.6.19' ) )
    {
        plan skip_all => 'SQLite driver version 3.6.19 or higher is required. You have version ' . $DBD::SQLite::sqlite_version;
    }
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use_ok( 'DateTime::Locale::FromCLDR' ) || BAIL_OUT( 'Unable to load DateTime::Locale::FromCLDR' );
};

use strict;
use warnings;
use utf8;


my $tests = [
    {
        timezone => 'America/Los_Angeles',
        expects => 1,
    },
    {
        timezone => 'Asia/Tokyo',
        expects => 0,
    },
    {
        timezone => 'Europe/Paris',
        expects => 1,
    },
    {
        timezone => 'America/Atka',
        expects => 1,
    },
    {
        timezone => 'America/Adak',
        expects => 1,
    },
];

my $locale = DateTime::Locale::FromCLDR->new( 'en' );
isa_ok( $locale => 'DateTime::Locale::FromCLDR', 'DateTime::Locale::FromCLDR object instantiated' );
if( !defined( $locale ) )
{
    diag( "Error instantiating a DateTime::Locale::FromCLDR object for locale 'en': ", DateTime::Locale::FromCLDR->error );
    BAIL_OUT( DateTime::Locale::FromCLDR->error );
}

foreach my $def ( @$tests )
{
    subtest "has_dst( $def->{timezone} )" => sub
    {
        my $bool = $locale->has_dst( $def->{timezone} );
        is( $bool => $def->{expects}, "time zone $def->{timezone} -> " . ( $def->{expects} ? "has" : "has not" ) . " daylight saving time" );
    };
}

$tests = [
    {
        datetime => { year => 2024, month => 7, day => 1, time_zone => 'America/Los_Angeles' },
        expects => 1,
    },
    {
        datetime => { year => 2024, month => 1, day => 1, time_zone => 'America/Los_Angeles' },
        expects => 0
    },
    {
        datetime => { year => 2024, month => 7, day => 1, time_zone => 'Asia/Tokyo' },
        expects => 0,
    },
    {
        datetime => { year => 2024, month => 1, day => 1, time_zone => 'Asia/Tokyo' },
        expects => 0,
    },
    {
        datetime => { year => 2024, month => 7, day => 1, time_zone => 'Europe/Paris' },
        expects => 1,
    },
    {
        datetime => { year => 2024, month => 1, day => 1, time_zone => 'Europe/Paris' },
        expects => 0,
    },
    {
        datetime => { year => 2024, month => 7, day => 1, time_zone => 'America/Atka' },
        expects => 1,
    },
    {
        datetime => { year => 2024, month => 1, day => 1, time_zone => 'America/Atka' },
        expects => 0,
    },
    {
        datetime => { year => 2024, month => 7, day => 1, time_zone => 'America/Adak' },
        expects => 1,
    },
    {
        datetime => { year => 2024, month => 1, day => 1, time_zone => 'America/Adak' },
        expects => 0,
    },
];

foreach my $def ( @$tests )
{
    subtest "is_dst( " . $def->{datetime}->{time_zone} . " )" => sub
    {
        my $dt = eval
        {
            DateTime->new( %{$def->{datetime}}, locale => 'en' );
        };
        diag( "Error instantiating a DateTime object for time zone " . $def->{datetime}->{time_zone} . ": $@" ) if( $@ );
        isa_ok( $dt => 'DateTime', "instantiated a DateTime object for " . $def->{datetime}->{time_zone} );
        if( !defined( $dt ) )
        {
            BAIL_OUT( "Unable to instantiate a DateTime object: $@" );
        }
        my $bool = $locale->is_dst( $dt );
        is( $bool => $def->{expects}, "time zone " . $def->{datetime}->{time_zone} . ( $def->{expects} ? " is" : " is not" ) . " using daylight saving time" );
    };
}

done_testing();

__END__
