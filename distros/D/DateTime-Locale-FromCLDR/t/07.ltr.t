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
    {
        locale => 'en',
        expects => 0,
    },
    {
        locale => 'ja',
        expects => 0,
    },
    {
        locale => 'ar',
        expects => 1,
    },
    {
        locale => 'he',
        expects => 1,
    },
];

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
            my $bool = $locale->is_ltr;
            is( $bool => $def->{expects}, "locale $def->{locale} -> " . ( $def->{expects} ? "is" : "is not" ) . " left-to-right" );
        };
    };
}

done_testing();

__END__
