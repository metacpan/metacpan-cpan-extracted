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
        expects => ["latn", ["0","1","2","3","4","5","6","7","8","9"]],
    },
    {
        locale => 'ja',
        expects => ["latn", ["0","1","2","3","4","5","6","7","8","9"]],
    },
    {
        locale => 'ar',
        expects => ["arab", ["٠","١","٢","٣","٤","٥","٦","٧","٨","٩"]],
    },
    {
        locale => 'mr',
        expects => ["deva", ["०","१","२","३","४","५","६","७","८","९"]],
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
            my $ref = $locale->locale_number_system;
            is( $ref->[0] => $def->{expects}->[0], 'numbering system -> ' . $def->{expects}->[0] );
            is_deeply( $ref->[1] => $def->{expects}->[1], 'digits' );
        };
    };
}

done_testing();

__END__
