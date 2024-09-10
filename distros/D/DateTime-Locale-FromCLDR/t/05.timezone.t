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
    # NOTE: metazone name (en -> America_Pacific)
    {
        name => 'metazone names',
        locale => 'en',
        tests =>
        [
            {
                method => 'metazone_daylight_long',
                args => [qw( metazone America_Pacific )],
                expects => 'Pacific Daylight Time',
            },
            {
                method => 'metazone_daylight_short',
                args => [qw( metazone America_Pacific )],
                expects => 'PDT',
            },
            {
                method => 'metazone_generic_long',
                args => [qw( metazone America_Pacific )],
                expects => 'Pacific Time',
            },
            {
                method => 'metazone_generic_short',
                args => [qw( metazone America_Pacific )],
                expects => 'PT',
            },
            {
                method => 'metazone_standard_long',
                args => [qw( metazone America_Pacific )],
                expects => 'Pacific Standard Time',
            },
            {
                method => 'metazone_standard_short',
                args => [qw( metazone America_Pacific )],
                expects => 'PST',
            },
        ],
    },
    # NOTE: metazone name (ja -> America_Pacific)
    {
        name => 'metazone names',
        locale => 'ja',
        tests =>
        [
            {
                method => 'metazone_daylight_long',
                args => [qw( metazone America_Pacific )],
                expects => 'アメリカ太平洋夏時間',
            },
            {
                method => 'metazone_daylight_short',
                args => [qw( metazone America_Pacific )],
                expects => '',
            },
            {
                method => 'metazone_generic_long',
                args => [qw( metazone America_Pacific )],
                expects => 'アメリカ太平洋時間',
            },
            {
                method => 'metazone_generic_short',
                args => [qw( metazone America_Pacific )],
                expects => '',
            },
            {
                method => 'metazone_standard_long',
                args => [qw( metazone America_Pacific )],
                expects => 'アメリカ太平洋標準時',
            },
            {
                method => 'metazone_standard_short',
                args => [qw( metazone America_Pacific )],
                expects => '',
            },
        ],
    },
    # NOTE: metazone name (ja -> Japan)
    {
        name => 'metazone names',
        locale => 'ja',
        tests =>
        [
            {
                method => 'metazone_daylight_long',
                args => [qw( metazone Japan )],
                expects => '日本夏時間',
            },
            {
                method => 'metazone_daylight_short',
                args => [qw( metazone Japan )],
                expects => 'JDT',
            },
            {
                method => 'metazone_generic_long',
                args => [qw( metazone Japan )],
                expects => '日本時間',
            },
            {
                method => 'metazone_generic_short',
                args => [qw( metazone Japan )],
                expects => '',
            },
            {
                method => 'metazone_standard_long',
                args => [qw( metazone Japan )],
                expects => '日本標準時',
            },
            {
                method => 'metazone_standard_short',
                args => [qw( metazone Japan )],
                expects => 'JST',
            },
        ],
    },
    # NOTE: metazone name (fr -> America_Pacific)
    {
        name => 'metazone names',
        locale => 'fr',
        tests =>
        [
            {
                method => 'metazone_daylight_long',
                args => [qw( metazone America_Pacific )],
                expects => 'heure d’été du Pacifique nord-américain',
            },
            {
                method => 'metazone_daylight_short',
                args => [qw( metazone America_Pacific )],
                expects => 'HEP',
            },
            {
                method => 'metazone_generic_long',
                args => [qw( metazone America_Pacific )],
                expects => 'heure du Pacifique nord-américain',
            },
            {
                method => 'metazone_generic_short',
                args => [qw( metazone America_Pacific )],
                expects => 'HP',
            },
            {
                method => 'metazone_standard_long',
                args => [qw( metazone America_Pacific )],
                expects => 'heure normale du Pacifique nord-américain',
            },
            {
                method => 'metazone_standard_short',
                args => [qw( metazone America_Pacific )],
                expects => 'HNP',
            },
        ],
    },
    # NOTE: timezone city (en -> Europe/Vatican)
    {
        name => 'timezone city',
        locale => 'fr',
        tests =>
        [
            {
                method => 'timezone_city',
                args => [qw( timezone Europe/Vatican )],
                expects => 'Le Vatican',
            },
        ],
    },
    # NOTE: timezone city (ja -> Europe/Vatican)
    {
        name => 'timezone city',
        locale => 'ja',
        tests =>
        [
            {
                method => 'timezone_city',
                args => [qw( timezone Europe/Vatican )],
                expects => 'バチカン',
            },
        ],
    },
    # NOTE: timezone city (ja -> Europe/Paris)
    {
        name => 'timezone city',
        locale => 'ja',
        tests =>
        [
            {
                method => 'timezone_city',
                args => [qw( timezone Europe/Paris )],
                expects => 'パリ',
            },
        ],
    },
    # NOTE: timezone city (ko -> Europe/Paris)
    {
        name => 'timezone city',
        locale => 'ko',
        tests =>
        [
            {
                method => 'timezone_city',
                args => [qw( timezone Europe/Paris )],
                expects => '파리',
            },
        ],
    },
    # NOTE: timezone city (en -> Etc/Unknown)
    {
        name => 'timezone city',
        locale => 'en',
        tests =>
        [
            {
                method => 'timezone_city',
                args => [qw( timezone Etc/Unknown )],
                expects => 'Unknown City',
            },
        ],
    },
    # NOTE: timezone city (fr -> Etc/Unknown)
    {
        name => 'timezone city',
        locale => 'fr',
        tests =>
        [
            {
                method => 'timezone_city',
                args => [qw( timezone Etc/Unknown )],
                expects => 'ville inconnue',
            },
        ],
    },
    # NOTE: timezone city (ja -> Etc/Unknown)
    {
        name => 'timezone city',
        locale => 'ja',
        tests =>
        [
            {
                method => 'timezone_city',
                args => [qw( timezone Etc/Unknown )],
                expects => '地域不明',
            },
        ],
    },
    # NOTE: timezone format (en)
    {
        name => 'timezone format',
        locale => 'en',
        tests =>
        [
            {
                method => 'timezone_format_fallback',
                args => [],
                expects => '{1} ({0})',
            },
            {
                method => 'timezone_format_gmt',
                args => [],
                expects => 'GMT{0}',
            },
            # Does not exist in 'en', but does in its parent 'und'
            {
                method => 'timezone_format_gmt_zero',
                args => [],
                expects => 'GMT',
            },
            {
                method => 'timezone_format_hour',
                args => [],
                expects => [qw( +HH:mm -HH:mm )],
            },
            {
                method => 'timezone_format_region',
                args => [],
                expects => '{0} Time',
            },
            {
                method => 'timezone_format_region_daylight',
                args => [],
                expects => '{0} Daylight Time',
            },
            {
                method => 'timezone_format_region_standard',
                args => [],
                expects => '{0} Standard Time',
            },
        ],
    },
    # NOTE: timezone format (fr)
    {
        name => 'timezone format',
        locale => 'fr',
        tests =>
        [
            {
                method => 'timezone_format_fallback',
                args => [],
                expects => '{1} ({0})',
            },
            {
                method => 'timezone_format_gmt',
                args => [],
                expects => 'UTC{0}',
            },
            {
                method => 'timezone_format_gmt_zero',
                args => [],
                expects => 'UTC',
            },
            {
                method => 'timezone_format_hour',
                args => [],
                expects => [qw( +HH:mm −HH:mm )],
            },
            {
                method => 'timezone_format_region',
                args => [],
                expects => 'heure : {0}',
            },
            {
                method => 'timezone_format_region_daylight',
                args => [],
                expects => '{0} (heure d’été)',
            },
            {
                method => 'timezone_format_region_standard',
                args => [],
                expects => '{0} (heure standard)',
            },
        ],
    },
    # NOTE: timezone format (ja)
    {
        name => 'timezone format',
        locale => 'ja',
        tests =>
        [
            {
                method => 'timezone_format_fallback',
                args => [],
                expects => '{1}（{0}）',
            },
            {
                method => 'timezone_format_gmt',
                args => [],
                expects => 'GMT{0}',
            },
            {
                method => 'timezone_format_gmt_zero',
                args => [],
                expects => 'GMT',
            },
            {
                method => 'timezone_format_hour',
                args => [],
                expects => [qw( +HH:mm -HH:mm )],
            },
            {
                method => 'timezone_format_region',
                args => [],
                expects => '{0}時間',
            },
            {
                method => 'timezone_format_region_daylight',
                args => [],
                expects => '{0}夏時間',
            },
            {
                method => 'timezone_format_region_standard',
                args => [],
                expects => '{0}標準時',
            },
        ],
    },
    # NOTE: timezone name (en -> America/Los_Angeles)
    {
        name => 'timezone names',
        locale => 'en',
        tests =>
        [
            {
                method => 'timezone_daylight_long',
                args => [qw( timezone Europe/London )],
                expects => 'British Summer Time',
            },
            {
                method => 'timezone_daylight_short',
                args => [qw( timezone Europe/London )],
                expects => '',
            },
            {
                method => 'timezone_daylight_short',
                args => [qw( timezone Pacific/Honolulu )],
                expects => 'HDT',
            },
            {
                method => 'timezone_generic_long',
                args => [qw( timezone Europe/London )],
                expects => '',
            },
            {
                method => 'timezone_generic_short',
                args => [qw( timezone Europe/London )],
                expects => '',
            },
            {
                method => 'timezone_generic_short',
                args => [qw( timezone Pacific/Honolulu )],
                expects => 'HST',
            },
            {
                method => 'timezone_standard_long',
                args => [qw( timezone Europe/London )],
                expects => '',
            },
            {
                method => 'timezone_standard_short',
                args => [qw( timezone Europe/London )],
                expects => '',
            },
            {
                method => 'timezone_standard_short',
                args => [qw( timezone Pacific/Honolulu )],
                expects => 'HST',
            },
        ],
    },
    # NOTE: timezone formatting
    {
        name => 'timezone names (en)',
        locale => 'en',
        tests =>
        [
            {
                method => 'format_timezone_location',
                args => [qw( timezone America/Los_Angeles )],
                expects => 'Los Angeles Time',
            },
            {
                method => 'format_timezone_location',
                args => [qw( timezone America/Buenos_Aires )],
                expects => 'Buenos Aires Time',
            },
            {
                method => 'format_timezone_non_location',
                args => [qw( timezone Europe/Dublin type daylight )],
                expects => 'Irish Standard Time',
            },
            {
                method => 'format_timezone_non_location',
                args => [qw( timezone America/Phoenix type generic )],
                expects => 'Mountain Time',
            },
        ],
    },
    {
        name => 'timezone names (ja)',
        locale => 'ja',
        tests =>
        [
            {
                method => 'format_timezone_non_location',
                args => [qw( timezone America/Los_Angeles type standard )],
                expects => 'アメリカ太平洋標準時',
            },
        ],
    },
    {
        name => 'timezone names (en_CA)',
        locale => 'en_CA',
        tests =>
        [
            {
                method => 'format_timezone_non_location',
                args => [qw( timezone America/Vancouver type generic )],
                expects => 'Pacific Time',
            },
        ],
    },
    {
        name => 'timezone names (en_US)',
        locale => 'en_US',
        tests =>
        [
            {
                method => 'format_timezone_non_location',
                args => [qw( timezone America/Los_Angeles type generic )],
                expects => 'Pacific Time',
            },
        ],
    },
];

foreach my $def ( @$tests )
{
    subtest $def->{name} . ' (' . $def->{locale} . ')' => sub
    {
        my $locale = DateTime::Locale::FromCLDR->new( $def->{locale} );
        SKIP:
        {
            if( !defined( $locale ) )
            {
                diag( "Error instantiating a DateTime::Locale::FromCLDR object for locale '$def->{locale}': ", DateTime::Locale::FromCLDR->error );
                fail( DateTime::Locale::FromCLDR->error );
                skip( "Unable to instantiate a DateTime::Locale::FromCLDR object for locale '$def->{locale}'", 1 );
            }
            isa_ok( $locale, 'DateTime::Locale::FromCLDR' );
            foreach my $def2 ( @{$def->{tests}} )
            {
                next unless( exists( $def2->{method} ) && exists( $def2->{expects} ) );
                my $coderef = $locale->can( $def2->{method} );
                if( !defined( $coderef ) )
                {
                    fail( "$def->{locale} -> $def2->{method} non-existent" );
                    next;
                }
                my $data = $coderef->( $locale, @{$def2->{args}} );
                if( ref( $def2->{expects} ) eq 'ARRAY' )
                {
                    is_deeply( $data, $def2->{expects}, "$def->{locale} -> $def2->{method} -> '" . ( $def2->{expects} ? join( ', ', @{$def2->{expects}} ) : 'undef' ) . "'" );
                }
                else
                {
                    is( $data, $def2->{expects}, "$def->{locale} -> $def2->{method} -> '" . ( $def2->{expects} // 'undef' ) . "'" );
                }
            }
        };
    };
}

done_testing();

__END__
