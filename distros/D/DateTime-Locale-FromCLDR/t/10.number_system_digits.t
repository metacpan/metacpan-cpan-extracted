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
        number_system => 'latn',
        expects => ["0","1","2","3","4","5","6","7","8","9"],
    },
    {
        number_system => 'jpan',
        expects => ["〇","一","二","三","四","五","六","七","八","九"],
    },
    {
        number_system => 'hebr',
        expects => ["״","א","ב","ג","ד","ה","ו","ז","ח","ט"],
    },
    {
        number_system => 'arab',
        expects => ["٠","١","٢","٣","٤","٥","٦","٧","٨","٩"],
    },
];

my $locale = DateTime::Locale::FromCLDR->new( 'en' );
if( !defined( $locale ) )
{
    BAIL_OUT( "Error instantiating a DateTime::Locale::FromCLDR object for locale 'en': ", DateTime::Locale::FromCLDR->error );
}

foreach my $def ( @$tests )
{
    subtest $def->{number_system} => sub
    {
        SKIP:
        {
            my $digits = $locale->number_system_digits( $def->{number_system} );
            diag( "Error trying to get the digits for the number system '$def->{number_system}': ", $locale->error ) if( !defined( $digits ) && $locale->error );
            is_deeply( $digits => $def->{expects}, 'digits' );
        };
    };
}

done_testing();

__END__
