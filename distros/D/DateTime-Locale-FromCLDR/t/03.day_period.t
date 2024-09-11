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
    # I am getting weird error like:
    # perl(74608) in free(): bogus pointer (double free?) 0xfcc0f72e800
    # that are most likely coming from DateTime, so I am switching for testing to its pure-perl equivalent
    $ENV{PERL_DATETIME_PP} = 1;
    use DateTime;
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
        locale => 'en',
        terms =>
        [
            # midnight
            DateTime->new(
                year => 2024,
                hour => 0
            ) => 'midnight',
            # morning1
            DateTime->new(
                year => 2024,
                hour => 7
            ) => 'in the morning',
            # noon
            DateTime->new(
                year => 2024,
                hour => 12
            ) => 'noon',
            # afternoon1
            DateTime->new(
                year => 2024,
                hour => 13
            ) => 'in the afternoon',
            # evening1
            DateTime->new(
                year => 2024,
                hour => 19
            ) => 'in the evening',
            # night1
            DateTime->new(
                year => 2024,
                hour => 22
            ) => 'at night',
        ],
    },
    {
        locale => 'ja-Kana-JP',
        terms =>
        [
            # midnight
            DateTime->new(
                year => 2024,
                hour => 0
            ) => '真夜中',
            # morning1
            DateTime->new(
                year => 2024,
                hour => 7
            ) => '朝',
            # noon
            DateTime->new(
                year => 2024,
                hour => 12
            ) => '正午',
            # afternoon1
            DateTime->new(
                year => 2024,
                hour => 13
            ) => '昼',
            # evening1
            DateTime->new(
                year => 2024,
                hour => 18
            ) => '夕方',
            # night1
            DateTime->new(
                year => 2024,
                hour => 20
            ) => '夜',
            # night2
            DateTime->new(
                year => 2024,
                hour => 23
            ) => '夜中',
        ],
    },
    {
        locale => 'fr',
        terms =>
        [
            # midnight
            DateTime->new(
                year => 2024,
                hour => 0
            ) => 'minuit',
            # morning1
            DateTime->new(
                year => 2024,
                hour => 7
            ) => 'matin',
            # noon
            DateTime->new(
                year => 2024,
                hour => 12
            ) => 'midi',
            # afternoon1
            DateTime->new(
                year => 2024,
                hour => 13
            ) => 'après-midi',
            # evening1
            DateTime->new(
                year => 2024,
                hour => 18
            ) => 'soir',
            # evening1
            DateTime->new(
                year => 2024,
                hour => 20
            ) => 'soir',
            # night1
            DateTime->new(
                year => 2024,
                hour => 3
            ) => 'matin',
        ],
    },
];

my $year = DateTime->now->year;
my( $dt1, $dt2, $diff );

foreach my $def ( @$tests )
{
    subtest $def->{locale} => sub
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
            for( my $i = 0; $i < scalar( @{$def->{terms}} ); $i += 2 )
            {
                my $dt = $def->{terms}->[$i];
                my $expect = $def->{terms}->[$i+1];
                my $str = $locale->day_period_format_abbreviated( $dt );
                is( $str, $expect, 'day_period for ' . $dt->iso8601 . ' -> ' . $expect );
            }
        };
    };
}

done_testing();

__END__
