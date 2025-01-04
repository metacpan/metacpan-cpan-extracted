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
    # NOTE: en -> {}
    {
        locale => 'en',
        options => {},
        expects => 
        {
            locale => 'en',
            style  => 'long',
            numeric => 'always',
            numberingSystem => 'latn',
        },
    },
    # NOTE: fr -> {style}
    {
        locale => 'fr',
        options =>
        {
            style => 'long',
        },
        expects => 
        {
            locale => 'fr',
            style  => 'long',
            numeric => 'always',
            numberingSystem => 'latn',
        },
    },
    # NOTE: ja-JP -> {style}
    {
        locale => 'ja-JP',
        options =>
        {
            style => 'long',
        },
        expects => 
        {
            locale => 'ja-JP',
            style  => 'long',
            numeric => 'always',
            numberingSystem => 'latn',
        },
    },
    # NOTE: fr-CH,de-CH  -> {style}
    {
        locale => ['fr-CH', 'de-CH'],
        options =>
        {
            style => 'long',
        },
        expects => 
        {
            locale => 'fr-CH',
            style  => 'long',
            numeric => 'always',
            numberingSystem => 'latn',
        },
    },
    # NOTE: ja-Kana-JP-u-ca-gregory-nu-jpanfin-tz-jptyo -> {style}
    {
        # locale => 'ja-Kana-JP-u-ca-japanese-nu-jpanfin-tz-jptyo',
        locale => 'ja-Kana-JP-u-ca-gregory-nu-jpanfin-tz-jptyo',
        options => 
        {
            style => 'long',
        },
        expects => 
        {
            locale => 'ja-Kana-JP-u-ca-gregory-nu-jpanfin-tz-jptyo',
            style  => 'long',
            numeric => 'always',
            numberingSystem => 'latn',
        },
    },
    # NOTE: ja-Kana-JP-u-ca-gregory-nu-jpanfin-tz-jptyo -> {}
    {
        # locale => 'ja-Kana-JP-u-ca-japanese-nu-jpanfin-tz-jptyo',
        locale => 'ja-Kana-JP-u-ca-gregory-nu-jpanfin-tz-jptyo',
        options => {},
        expects => 
        {
            locale => 'ja-Kana-JP-u-ca-gregory-nu-jpanfin-tz-jptyo',
            style  => 'long',
            numeric => 'always',
            numberingSystem => 'latn',
        },
    },
    # NOTE: ar-EG-u-ca-gregory-nu-arab-tz-egcai -> {}
    {
        locale => 'ar-EG-u-ca-gregory-nu-arab-tz-egcai',
        options => {},
        expects => 
        {
            locale => 'ar-EG-u-ca-gregory-nu-arab-tz-egcai',
            style  => 'long',
            numeric => 'always',
            numberingSystem => 'arab',
        },
    },
    # NOTE: en -> {style}
    {
        locale => "en",
        options => { style => "long" },
        expects => 
        {
            locale => 'en',
            style  => 'long',
            numeric => 'always',
            numberingSystem => 'latn',
        },
    },
    # NOTE: es -> {}
    {
        locale => 'es',
        options => {},
        expects => 
        {
            locale => 'es',
            style  => 'long',
            numeric => 'always',
            numberingSystem => 'latn',
        },
    },
    # NOTE: de -> {numeric}
    {
        locale => 'de',
        options =>
        {
            numeric => 'auto',
        },
        expects => 
        {
            locale => 'de',
            style  => 'long',
            numeric => 'auto',
            numberingSystem => 'latn',
        },
    },
    # NOTE: en-IN -> {numberingSystem}
    {
        locale => 'en-IN',
        options =>
        {
            numberingSystem => 'deva',
        },
        expects => 
        {
            locale => 'en-IN',
            style  => 'long',
            numeric => 'always',
            numberingSystem => 'deva',
        },
    },
    # NOTE: ar-SA -> {style, numeric}
    {
        locale => 'ar-SA',
        options =>
        {
            style => 'narrow',
            numeric => 'auto',
        },
        expects => 
        {
            locale => 'ar-SA',
            style  => 'narrow',
            numeric => 'auto',
            numberingSystem => 'arab',
        },
    },
    # NOTE: zh-Hant-TW -> {style}
    {
        locale => 'zh-Hant-TW',
        options =>
        {
            style => 'short',
        },
        expects => 
        {
            locale => 'zh-Hant-TW',
            style  => 'short',
            numeric => 'always',
            numberingSystem => 'latn',
        },
    },
    # NOTE: invalid_locale -> {}
    {
        locale => 'xx-XX',
        options => {},
        expects => 
        {
            locale => 'en',
            style  => 'long',
            numeric => 'always',
            numberingSystem => 'latn',
        },
    },
    # NOTE: ja -> {style, numeric, numberingSystem}
    {
        locale => 'ja',
        options =>
        {
            style => 'long',
            numeric => 'always',
            numberingSystem => 'jpan',
        },
        expects => 
        {
            locale => 'ja',
            style  => 'long',
            numeric => 'always',
            numberingSystem => 'latn',
        },
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
    subtest 'DateTime::Format::RelativeTime->new( ' . ( ref( $test->{locale} ) eq 'ARRAY' ? "[@{$test->{locale}}]" : $test->{locale} ) . ", \{@keys\} )" => sub
    {
        local $SIG{__DIE__} = sub
        {
            diag( "Test No ${i} died: ", join( '', @_ ) );
        };
        my $fmt = DateTime::Format::RelativeTime->new( $test->{locale}, $test->{options} );
        diag( "Error instantiating a new DateTime::Format::RelativeTime object: ", DateTime::Format::RelativeTime->error ) if( !defined( $fmt ) );
        isa_ok( $fmt => 'DateTime::Format::RelativeTime' );
        return if( !defined( $fmt ) );
        my $opts = $fmt->resolvedOptions;
        my $has_failed = 0;
        foreach my $k ( sort( keys( %{$test->{expects}} ) ) )
        {
            if( !exists( $opts->{ $k } ) )
            {
                fail( "Missing expected option \"${k}\" in resolvedOptions hash." );
                $has_failed++;
                push( @$failed, { test => $i, %$test } );
            }
            elsif( ( !defined( $opts->{ $k } ) && defined( $test->{expects}->{ $k } ) ) ||
                     $opts->{ $k } ne $test->{expects}->{ $k } )
            {
                fail( "Option \"${k}\" value expected was \"" . ( $test->{expects}->{ $k } // 'undef' ) . "\", but got \"" . ( $opts->{ $k } // 'undef' ) . "\"." );
                $has_failed++;
                push( @$failed, { test => $i, %$test } );
            }
        }
        pass( "resolvedOptions hash received matches: @keys" ) unless( $has_failed );
    };
}

done_testing();

__END__
