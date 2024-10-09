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
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use_ok( 'DateTime::Format::Intl' ) || BAIL_OUT( 'Unable to load DateTime::Format::Intl' );
};

use strict;
use warnings;
use utf8;


my $tests =
[
    {
        locales => ['ja-t-de-t0-und-x0-medical', 'he-IL-u-ca-hebrew-tz-jeruslm', 'en-GB'],
        expects => ['ja', 'he-IL', 'en-GB'],
        # my $array = DateTime::Format::Intl->supportedLocalesOf( ['ja-t-de-t0-und-x0-medical', 'he-IL-u-ca-hebrew-tz-jeruslm', 'en-GB']
    },
];

local $" = ', ';
foreach my $test ( @$tests )
{
    subtest "supportedLocalesOf( [@{$test->{locales}}] ) -> [@{$test->{expects}}]" => sub
    {
        my $array = DateTime::Format::Intl->supportedLocalesOf( $test->{locales} );
        if( !defined( $array ) )
        {
            diag( "Error: ", DateTime::Format::Intl->error );
        }
        is( ref( $array ) => 'ARRAY', 'returns an array reference' );
        is( "@$array", "@{$test->{expects}}", "[@{$test->{expects}}]" );
    };
}

done_testing();

__END__
