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
    use DateTime::Locale::FromCLDR;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
    $TEST_ID = $ENV{TEST_ID} if( exists( $ENV{TEST_ID} ) );
};

BEGIN
{
    use_ok( 'DateTime::Format::Intl' ) || BAIL_OUT( 'Unable to load DateTime::Format::Intl' );
};

use strict;
use warnings;
use utf8;


my $unicode = DateTime::Locale::FromCLDR->new( 'en' );
isa_ok( $unicode => 'DateTime::Locale::FromCLDR' ) || BAIL_OUT( "Unable to create an instance of DateTime::Locale::FromCLDR" );
my $patterns = $unicode->available_format_patterns;
my @skeletons = keys( %$patterns );
my $patterns_to_skeletons = {};
@$patterns_to_skeletons{ @$patterns{ @skeletons } } = @skeletons;

my $tests = 
my $test_cases = 
[
    # NOTE: test 0
    {
        options => { day => "numeric", month => "short", year => "numeric", hour => "numeric", minute => "numeric" },
        expects_date => "yMMMd",
        expects_time => "hm",
        expects_pattern => 'MMM d, y, h:mm a',
        expects_skeleton => "yMMMd, hm",
        locale => "en"
    },
    {
        options => { weekday => "short", month => "long", day => "numeric", hour => "2-digit", minute => "2-digit" },
        expects_date => "MMMEd",
        expects_time => "hm",
        expects_pattern => "E, MMMM d 'at' hh:mm a",
        expects_skeleton => "MMMEd 'at' hm",
        locale => "en"
    },
    {
        options => { weekday => "long", month => "long", day => "numeric", hour => "numeric", minute => "numeric" },
        expects_date => "MMMEd",
        expects_time => "hm",
        expects_pattern => "EEEE, MMMM d 'at' h:mm a",
        expects_skeleton => "MMMEd 'at' hm",
        locale => "en"
    },
    {
        options => { year => "numeric", month => "long", day => "numeric", hour => "2-digit", minute => "numeric", second => "numeric" },
        expects_date => "yMMMd",
        expects_time => "hms",
        expects_pattern => "MMMM d, y 'at' hh:mm:ss a",
        expects_skeleton => "yMMMd 'at' hms",
        locale => "en"
    },
    {
        options => { month => "numeric", day => "numeric", hour => "numeric", minute => "numeric", dayPeriod => "short" },
        expects_date => "Md",
        expects_time => "hm",
        expects_pattern => 'M/d, h:mm a',
        expects_skeleton => "Md, hm",
        locale => "en"
    },
    {
        options => { year => "numeric", month => "narrow", weekday => "long", hour => "numeric", minute => "numeric", timeZoneName => "short" },
        expects_date => "yMMMM",
        expects_time => "hmv",
        expects_pattern => "MMMMM y EEEE, h:mm a z",
        expects_skeleton => "yMMMM, hmv",
        locale => "en"
    },
    {
        options => { year => "numeric", month => "narrow", day => "numeric", hour => "2-digit", minute => "2-digit" },
        expects_date => "yMMMd",
        expects_time => "hm",
        expects_pattern => 'MMMMM d, y, hh:mm a',
        expects_skeleton => "yMMMd, hm",
        locale => "en"
    },
    {
        options => { year => "numeric", month => "long", day => "numeric", weekday => "short", hour => "numeric", minute => "numeric" },
        expects_date => "yMMMEd",
        expects_time => "hm",
        expects_pattern => "E, MMMM d, y 'at' h:mm a",
        expects_skeleton => "yMMMEd 'at' hm",
        locale => "en"
    },
    {
        options => { year => "numeric", month => "short", day => "numeric", weekday => "short", hour => "2-digit", minute => "2-digit" },
        expects_date => "yMMMEd",
        expects_time => "hm",
        expects_pattern => "E, MMM d, y, hh:mm a",
        expects_skeleton => "yMMMEd, hm",
        locale => "en"
    },
    {
        options => { year => "numeric", month => "long", weekday => "long", hour => "2-digit", minute => "2-digit" },
        expects_date => "yMMMM",
        expects_time => "hm",
        expects_pattern => "MMMM y EEEE 'at' hh:mm a",
        expects_skeleton => "yMMMM 'at' hm",
        locale => "en"
    },
    # NOTE: test #10
    {
        options => {
            year => "numeric", 
            month => "long", 
            day => "numeric",
            hour => "2-digit", 
            minute => "2-digit"
        },
        expects_date => "yMMMd",
        expects_time => "hm",
        expects_pattern => "MMMM d, y 'at' hh:mm a",
        expects_skeleton => "yMMMd 'at' hm",
        locale => "en"
    },
    {
        options => {
            weekday => "long", 
            month => "long", 
            day => "numeric",
            hour => "2-digit", 
            minute => "2-digit",
            second => "2-digit"
        },
        expects_date => "MMMEd",
        expects_time => "hms",
        expects_pattern => "EEEE, MMMM d 'at' hh:mm:ss a",
        expects_skeleton => "MMMEd 'at' hms",
        locale => "en"
    },
    {
        options => {
            month => "short", 
            day => "2-digit",
            hour => "numeric", 
            minute => "numeric",
            timeZoneName => "short"
        },
        expects_date => "MMMd",
        expects_time => "hmv",
        expects_pattern => 'MMM dd, h:mm a z',
        expects_skeleton => "MMMd, hmv",
        locale => "en"
    },
    {
        options => {
            year => "numeric", 
            month => "narrow", 
            day => "numeric",
            hour => "2-digit"
        },
        expects_date => "yMMMd",
        expects_time => "h",
        expects_pattern => 'MMMMM d, y, hh a',
        expects_skeleton => "yMMMd, h",
        locale => "en"
    },
    {
        options => {
            weekday => "short",
            month => "numeric",
            day => "numeric",
            hour => "2-digit",
            minute => "2-digit",
            second => "2-digit",
            timeZoneName => "long"
        },
        expects_date => "MEd",
        expects_time => "hmsv",
        expects_pattern => 'E, M/d, hh:mm:ss a zzzz',
        expects_skeleton => "MEd, hmsv",
        locale => "en"
    },
    {
        options => {
            year => "2-digit",
            month => "long",
            weekday => "long",
            hour => "2-digit", 
            minute => "2-digit"
        },
        expects_date => "yMMMM",
        expects_time => "hm",
        expects_pattern => "MMMM yy EEEE 'at' hh:mm a",
        expects_skeleton => "yMMMM 'at' hm",
        locale => "en"
    },
    {
        options => {
            year => "numeric",
            month => "numeric",
            hour => "2-digit", 
            minute => "2-digit",
            second => "2-digit"
        },
        expects_date => "yM",
        expects_time => "hms",
        expects_pattern => 'M/y, hh:mm:ss a',
        expects_skeleton => "yM, hms",
        locale => "en"
    },
    {
        options => {
            month => "long",
            day => "numeric",
            hour => "2-digit", 
            minute => "2-digit",
            timeZoneName => "short"
        },
        expects_date => "MMMMd",
        expects_time => "hmv",
        expects_pattern => "MMMM d 'at' hh:mm a z",
        expects_skeleton => "MMMMd 'at' hmv",
        locale => "en"
    },
    {
        options => {
            era => "short",
            year => "numeric",
            month => "long",
            hour => "2-digit", 
            minute => "2-digit"
        },
        expects_date => "GyMMM",
        expects_time => "hm",
        expects_pattern => "MMMM y G 'at' hh:mm a",
        expects_skeleton => "GyMMM 'at' hm",
        locale => "en"
    },
    {
        options => {
            year => "numeric",
            month => "short",
            day => "numeric",
            hour => "2-digit", 
            minute => "2-digit"
        },
        expects_date => "yMMMd",
        expects_time => "hm",
        expects_pattern => "MMM d, y, hh:mm a",
        expects_skeleton => "yMMMd, hm",
        locale => "en"
    }
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
    subtest 'DateTime::Format::Intl->new( ' . ( ref( $test->{locale} ) eq 'ARRAY' ? "[@{$test->{locale}}]" : $test->{locale} ) . ", \{@keys\} )" => sub
    {
        local $SIG{__DIE__} = sub
        {
            diag( "Test No ${i} died: ", join( '', @_ ) );
        };
        my $fmt = DateTime::Format::Intl->new( $test->{locale}, $test->{options} );
        SKIP:
        {
            isa_ok( $fmt => 'DateTime::Format::Intl' );
            if( !defined( $fmt ) )
            {
                diag( "Error instantiating the DateTime::Format::Intl object: ", DateTime::Format::Intl->error );
                skip( "Unable to instantiate a new DateTime::Format::Intl object.", 1 );
            }
            # my $best_pattern = $fmt->_select_best_pattern( $patterns, $test->{options} );
            my $best_pattern = $fmt->pattern;
            my $skeleton = $fmt->skeleton;
            if( !defined( $best_pattern ) )
            {
                diag( "Error getting the datetime skeleton: ", $fmt->error );
            }
            if( !is( $skeleton => $test->{expects_skeleton}, "\$fmt->skeleton -> '$test->{expects_skeleton}'" ) )
            {
                push( @$failed, { test => $i, pattern => $best_pattern, skeleton => $skeleton, %$test } );
            }
            if( !is( $best_pattern => $test->{expects_pattern}, "\$fmt->pattern -> '$test->{expects_pattern}'" ) )
            {
                push( @$failed, { test => $i, pattern => $best_pattern, skeleton => $skeleton, %$test } );
            }
        };
    };
}

done_testing();

__END__
