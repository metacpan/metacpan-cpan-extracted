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
[
    # NOTE: Bh skeletons (hour + day period)
    {
        locale => 'en',
        options  => { hour => 'numeric', dayPeriod => 'short' },
        expects => 'Bh', # Matches "h B" (hour with day period)
    },
    {
        locale => 'en',
        options  => { hour => 'numeric', minute => 'numeric', dayPeriod => 'short' },
        expects => 'Bhm', # Matches "h:mm B" (hour, minute with day period)
    },
    {
        locale => 'en',
        options  => { hour => 'numeric', minute => 'numeric', second => 'numeric', dayPeriod => 'short' },
        expects => 'Bhms', # Matches "h:mm:ss B" (hour, minute, second with day period)
    },
    
    # NOTE: E skeletons (weekday)
    {
        locale => 'en',
        options  => { weekday => 'short' },
        expects => 'E', # Matches "E" (short weekday, e.g., Mon)
    },
    {
        locale => 'en',
        options  => { weekday => 'short', hour => 'numeric', minute => 'numeric', dayPeriod => 'short' },
        expects => 'EBhm', # Matches "E h:mm B" (weekday, hour, minute, day period)
    },
    {
        locale => 'en',
        options  => { weekday => 'short', hour => 'numeric', minute => 'numeric', second => 'numeric', dayPeriod => 'short' },
        expects => 'EBhms', # Matches "E h:mm:ss B" (weekday, hour, minute, second, day period)
    },
    {
        locale => 'en',
        options  => { weekday => 'short', hour => 'numeric', minute => 'numeric', hour12 => 0 },
        expects => 'EHm', # Matches "E HH:mm" (weekday, hour, minute in 24-hour format)
    },
    {
        locale => 'en',
        options  => { weekday => 'short', hour => 'numeric', minute => 'numeric', second => 'numeric', hour12 => 0 },
        expects => 'EHms', # Matches "E HH:mm:ss" (weekday, hour, minute, second in 24-hour format)
    },

    {
        locale => 'en',
        options => { weekday => 'short', hour => 'numeric', minute => 'numeric', hour12 => 1 },
        expects => 'Ehm', # Matches "E h:mm a" (weekday, hour, minute in 12-hour format)
    },

    {
        locale => 'en',
        options => { weekday => 'short', hour => 'numeric', minute => 'numeric', second => 'numeric', hour12 => 1 },
        expects => 'Ehms', # Matches "E h:mm:ss a" (weekday, hour, minute, second in 12-hour format)
    },

    # NOTE: test #10
    # NOTE: Ed skeletons (weekday + day)
    {
        locale => 'en',
        options  => { weekday => 'short', day => 'numeric' },
        expects => 'Ed', # Matches "E d" (weekday, day)
    },

    # NOTE: Gy skeletons (year + era)
    {
        locale => 'en',
        options  => { year => 'numeric', era => 'short' },
        expects => 'Gy', # Matches "y G" (year with era)
    },
    {
        locale => 'en',
        options  => { year => 'numeric', month => 'short', era => 'short' },
        expects => 'GyMMM', # Matches "MMM y G" (month, year with era)
    },
    {
        locale => 'en',
        options  => { weekday => 'short', year => 'numeric', month => 'short', day => 'numeric', era => 'short' },
        expects => 'GyMMMEd', # Matches "E, MMM d, y G" (weekday, month, day, year with era)
    },
    {
        locale => 'en',
        options  => { year => 'numeric', month => 'short', day => 'numeric', era => 'short' },
        expects => 'GyMMMd', # Matches "MMM d, y G" (month, day, year with era)
    },
    {
        locale => 'en',
        options  => { year => 'numeric', month => 'numeric', day => 'numeric', era => 'short' },
        expects => 'GyMd', # Matches "M/d/y G" (month, day, year with era)
    },

    # NOTE: H skeletons (24-hour clock)
    {
        locale => 'en',
        options  => { hour => 'numeric', hour12 => 0 },
        expects => 'H', # Matches "HH" (24-hour format)
    },
    {
        locale => 'en',
        options  => { hour => 'numeric', minute => 'numeric', hour12 => 0 },
        expects => 'Hm', # Matches "HH:mm" (hour, minute in 24-hour format)
    },
    {
        locale => 'en',
        options  => { hour => 'numeric', minute => 'numeric', second => 'numeric', hour12 => 0 },
        expects => 'Hms', # Matches "HH:mm:ss" (hour, minute, second in 24-hour format)
    },
    {
        locale => 'en',
        options  => { hour => 'numeric', minute => 'numeric', second => 'numeric', timeZoneName => 'short', hour12 => 0 },
        expects => 'Hmsv', # Matches "HH:mm:ss v" (hour, minute, second, short time zone in 24-hour format)
    },
    # NOTE: test #20
    {
        locale => 'en',
        options  => { hour => 'numeric', minute => 'numeric', timeZoneName => 'short', hour12 => 0 },
        expects => 'Hmv', # Matches "HH:mm v" (hour, minute, short time zone in 24-hour format)
    },

    # NOTE: Md skeletons (month + day)
    {
        locale => 'en',
        options  => { month => 'numeric', day => 'numeric' },
        expects => 'Md', # Matches "M/d"
    },

    # NOTE: M skeletons (month)
    {
        locale => 'en',
        options  => { month => 'numeric' },
        expects => 'M', # Matches "M" (numeric month)
    },
    {
        locale => 'en',
        options  => { weekday => 'short', month => 'numeric', day => 'numeric' },
        expects => 'MEd', # Matches "E, M/d" (weekday, month, day)
    },
    {
        locale => 'en',
        options  => { month => 'short' },
        expects => 'MMM', # Matches "MMM" (abbreviated month)
    },
    # NOTE: non-existing skeleton, but I want to test anyway
    {
        locale => 'en',
        options  => { month => 'long' },
        expects => 'MMM', # Matches "MMM" (abbreviated month, but the pattern will be adjusted to wide month)
    },
    {
        locale => 'en',
        options  => { month => 'narrow' },
        expects => 'MMM', # Matches "MMM" (abbreviated month, but the pattern will be adjusted to narrow month)
    },
    {
        locale => 'en',
        options  => { weekday => 'short', month => 'short', day => 'numeric' },
        expects => 'MMMEd', # Matches "E, MMM d" (weekday, abbreviated month, day)
    },
    {
        locale => 'en',
        options  => { month => 'long', day => 'numeric' },
        expects => 'MMMMd', # Matches "MMMM d" (full month name, day)
    },
    # This skeleton cannot be mapped to any option.
#     {
#         locale => 'en',
#         options  => { year => 'numeric', month => 'long', day => 'numeric' }, # week is implicit from the date
#         expects => 'MMMMW', # Matches "'week' W 'of' MMMM" (week of the month)
#     },
    {
        locale => 'en',
        options  => { month => 'short', day => 'numeric' },
        expects => 'MMMd', # Matches "MMM d" (abbreviated month, day)
    },

    # NOTE: test #30
    # NOTE: d skeletons (day)
    {
        locale => 'en',
        options  => { day => 'numeric' },
        expects => 'd', # Matches "d" (numeric day)
    },

    # NOTE: h skeletons (12-hour clock)
    {
        locale => 'en',
        options  => { hour => 'numeric', hour12 => 1 },
        expects => 'h', # Matches "h" (12-hour format)
    },
    {
        locale => 'en',
        options  => { hour => 'numeric', minute => 'numeric', hour12 => 1 },
        expects => 'hm', # Matches "h:mm a" (12-hour format with AM/PM)
    },
    {
        locale => 'en',
        options  => { hour => 'numeric', minute => 'numeric', second => 'numeric', hour12 => 1 },
        expects => 'hms', # Matches "h:mm:ss a" (12-hour format with AM/PM)
    },
    {
        locale => 'en',
        options  => { hour => 'numeric', minute => 'numeric', second => 'numeric', timeZoneName => 'short', hour12 => 1 },
        expects => 'hmsv', # Matches "h:mm:ss a v" (12-hour format with time zone)
    },
    {
        locale => 'en',
        options  => { hour => 'numeric', minute => 'numeric', timeZoneName => 'short', hour12 => 1 },
        expects => 'hmv', # Matches "h:mm a v" (12-hour format with time zone)
    },

    # ms skeletons (minute + second)
    {
        locale => 'en',
        options  => { minute => 'numeric', second => 'numeric' },
        expects => 'ms', # Matches "mm:ss"
    },

    # y skeletons (year)
    {
        locale => 'en',
        options  => { year => 'numeric' },
        expects => 'y', # Matches "y" (numeric year)
    },
    {
        locale => 'en',
        options  => { year => 'numeric', month => 'numeric' },
        expects => 'yM', # Matches "M/y" (month, year)
    },
    {
        locale => 'en',
        options  => { weekday => 'short', year => 'numeric', month => 'numeric', day => 'numeric' },
        expects => 'yMEd', # Matches "E, M/d/y" (weekday, month, day, year)
    },
    # NOTE: test #40
    {
        locale => 'en',
        options  => { year => 'numeric', month => 'short' },
        expects => 'yMMM', # Matches "MMM y" (abbreviated month, year)
    },
    {
        locale => 'en',
        options  => { weekday => 'short', year => 'numeric', month => 'short', day => 'numeric' },
        expects => 'yMMMEd', # Matches "E, MMM d, y" (weekday, abbreviated month, day, year)
    },
    {
        locale => 'en',
        options  => { year => 'numeric', month => 'long' },
        expects => 'yMMMM', # Matches "MMMM y" (full month name, year)
    },
    {
        locale => 'en',
        options  => { year => 'numeric', month => 'short', day => 'numeric' },
        expects => 'yMMMd', # Matches "MMM d, y" (abbreviated month, day, year)
    },
    {
        locale => 'en',
        options  => { year => 'numeric', month => 'numeric', day => 'numeric' },
        expects => 'yMd', # Matches "M/d/y" (month, day, year)
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
                diag( "Error getting the best skeleton: ", $fmt->error );
            }
            if( !is( $skeleton => $test->{expects}, "\$fmt->skeleton -> '$test->{expects}'" ) )
            {
                # push( @$failed, { test => $i, skeleton => $test->{expects} } );
                push( @$failed, { test => $i, pattern => $best_pattern, skeleton => $skeleton, %$test } );
            }
        };
    };
}


done_testing();

__END__
