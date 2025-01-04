#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use open ':std' => ':utf8';
    use vars qw( $DEBUG $TEST_ID );
    use utf8;
    use version;
    use Test::More;
    # 2024-12-31T11:47:47
    use Test::Time time => 1735645667;
    use DateTime;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
    $TEST_ID = $ENV{TEST_ID} if( exists( $ENV{TEST_ID} ) );
};

BEGIN
{
    use_ok( 'DateTime::Format::RelativeTime' ) || BAIL_OUT( 'Unable to load DateTime::Format::RelativeTime' );
};

use strict;
use warnings;
use utf8;

my $tests =
[
    {
        locale => 'en',
        options => {},
        args => [0, 'second'],
        expects => 'in 0 seconds',
    },
    {
        locale => 'en',
        options => { numeric => 'auto' },
        args => [0, 'second'],
        expects => 'now',
    },
    {
        locale => 'en',
        options => { numeric => 'auto' },
        # Using 1 DateTime object
        args => [
            DateTime->new(
                year => 2024,
                month => 2,
                day => 1,
            )
        ],
        expects => 'in 3 quarters',
    },
    {
        locale => 'en',
        options => { numeric => 'auto' },
        # Using 2 DateTime objects
        args => [
            DateTime->new(
                year => 2024,
                month => 12,
                day => 1,
            ),
            DateTime->new(
                year => 2024,
                month => 2,
                day => 1,
            ),
        ],
        expects => '3 quarters ago',
    },
    # Test with Spanish locale
    {
        locale => 'es',
        options => { numeric => 'auto' },
        args => [1, 'day'],
        expects => 'mañana',
    },
    
    # Test with French locale
    {
        locale => 'fr',
        options => { numeric => 'auto' },
        args => [-1, 'day'],
        expects => 'hier',
    },

    # Test with Japanese locale for year difference
    {
        locale => 'ja',
        options => { numeric => 'auto' },
        args => [
            DateTime->new(
                year => 2023,
                month => 12,
                day => 31,
            )
        ],
        expects => '来年',
    },

    # Test with German locale for week difference
    {
        locale => 'de',
        options => { numeric => 'auto' },
        args => [
            DateTime->new(
                year => 2024,
                month => 12,
                day => 24,
            )
        ],
        # Assuming the week starts on Monday and 'now' is Tue, Dec 31
        expects => 'nächste Woche',
    },

    # Test with Russian locale for hour difference
    {
        locale => 'ru',
        options => { numeric => 'auto' },
        args => [2, 'hour'],
        expects => 'через 2 часа',
    },

    # Test with Arabic locale for minute difference
    {
        locale => 'ar',
        options => { numeric => 'auto' },
        args => [-3, 'minute'],
        expects => 'قبل ٣ دقائق',
    },

    # Test with a locale that uses different plural forms (Polish for example)
    {
        locale => 'pl',
        options => { numeric => 'auto' },
        args => [5, 'day'],
        expects => 'za 5 dni',
    },

    # Test for edge case where the day changes but it's less than a full day
    {
        locale => 'en',
        options => { numeric => 'auto' },
        args => [
            DateTime->new(
                year => 2024,
                month => 12,
                day => 31,
                hour => 10,
                minute => 47,
                second => 47,
            )
        ],
        expects => 'in 1 hour',
    },
];

my $failed = [];
for( my $i = 0; $i < scalar( @$tests ); $i++ )
{
    if( defined( $TEST_ID ) )
    {
        next unless( $i == $TEST_ID );
        last if( $i > $TEST_ID );
    }
    my $test = $tests->[$i];
    my @keys = sort( keys( %{$test->{options}} ) );
    local $" = ', ';
    my $argv_str = join( ', ', map{ "$_ => '" . $test->{options}->{ $_ } . "'" } @keys );
    subtest 'DateTime::Format::RelativeTime->new( ' . ( ref( $test->{locale} ) eq 'ARRAY' ? "[@{$test->{locale}}]" : $test->{locale} ) . ", \{ ${argv_str} \} )->format( @{$test->{args}} )" => sub
    {
        local $SIG{__DIE__} = sub
        {
            diag( "Test No ${i} died: ", join( '', @_ ) );
        };
        my $fmt = DateTime::Format::RelativeTime->new( $test->{locale}, $test->{options} );
        SKIP:
        {
            isa_ok( $fmt => 'DateTime::Format::RelativeTime' );
            if( !defined( $fmt ) )
            {
                diag( "Error instantiating the DateTime::Format::RelativeTime object: ", DateTime::Format::RelativeTime->error );
                skip( "Unable to instantiate a new DateTime::Format::RelativeTime object.", 1 );
            }
            my $str = $fmt->format( @{$test->{args}} );
            if( !defined( $str ) )
            {
                diag( "Error formatting relative time with arguments '", join( "', '", @{$test->{args}} ), "': ", $fmt->error );
            }
            $str =~ s/[[:blank:]\h]/ /g;
            if( !is( $str => $test->{expects}, "\$fmt->format( @{$test->{args}} ) -> '$test->{expects}'" ) )
            {
                # push( @$failed, { test => $i, skeleton => $test->{skeleton}, got => $str, expected => $test->{expects} } );
                push( @$failed, { test => $i, got => $str, %$test } );
            }
        };
    };
}


done_testing();

__END__
