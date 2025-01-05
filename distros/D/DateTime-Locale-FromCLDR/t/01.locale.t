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

my $locale = DateTime::Locale::FromCLDR->new( 'en' );
isa_ok( $locale, 'DateTime::Locale::FromCLDR' );

# To generate this list:
# perl -lnE '/^sub (?!new|[A-Z]|_)/ and say "can_ok( \$locale, \''", [split(/\s+/, $_)]->[1], "\'' );"' ./lib/DateTime/Locale/FromCLDR.pm
can_ok( $locale, 'am_pm_abbreviated' );
can_ok( $locale, 'am_pm_format_abbreviated' );
can_ok( $locale, 'am_pm_format_narrow' );
can_ok( $locale, 'am_pm_format_wide' );
can_ok( $locale, 'am_pm_standalone_abbreviated' );
can_ok( $locale, 'am_pm_standalone_narrow' );
can_ok( $locale, 'am_pm_standalone_wide' );
can_ok( $locale, 'as_string' );
can_ok( $locale, 'available_formats' );
can_ok( $locale, 'available_format_patterns' );
can_ok( $locale, 'calendar' );
can_ok( $locale, 'code' );
can_ok( $locale, 'date_at_time_format_full' );
can_ok( $locale, 'date_at_time_format_long' );
can_ok( $locale, 'date_at_time_format_medium' );
can_ok( $locale, 'date_at_time_format_short' );
can_ok( $locale, 'date_format_default' );
can_ok( $locale, 'date_format_full' );
can_ok( $locale, 'date_format_long' );
can_ok( $locale, 'date_format_medium' );
can_ok( $locale, 'date_format_short' );
can_ok( $locale, 'date_formats' );
can_ok( $locale, 'datetime_format' );
can_ok( $locale, 'datetime_format_default' );
can_ok( $locale, 'datetime_format_full' );
can_ok( $locale, 'datetime_format_long' );
can_ok( $locale, 'datetime_format_medium' );
can_ok( $locale, 'datetime_format_short' );
can_ok( $locale, 'day_format_abbreviated' );
can_ok( $locale, 'day_format_narrow' );
can_ok( $locale, 'day_format_short' );
can_ok( $locale, 'day_format_wide' );
can_ok( $locale, 'day_period_format_abbreviated' );
can_ok( $locale, 'day_period_format_narrow' );
can_ok( $locale, 'day_period_format_wide' );
can_ok( $locale, 'day_period_stand_alone_abbreviated' );
can_ok( $locale, 'day_period_stand_alone_narrow' );
can_ok( $locale, 'day_period_stand_alone_wide' );
can_ok( $locale, 'day_periods' );
can_ok( $locale, 'day_stand_alone_abbreviated' );
can_ok( $locale, 'day_stand_alone_narrow' );
can_ok( $locale, 'day_stand_alone_short' );
can_ok( $locale, 'day_stand_alone_wide' );
can_ok( $locale, 'default_date_format_length' );
can_ok( $locale, 'default_time_format_length' );
can_ok( $locale, 'era_abbreviated' );
can_ok( $locale, 'era_narrow' );
can_ok( $locale, 'era_wide' );
can_ok( $locale, 'error' );
can_ok( $locale, 'fatal' );
can_ok( $locale, 'first_day_of_week' );
can_ok( $locale, 'format_for' );
can_ok( $locale, 'format_gmt' );
can_ok( $locale, 'format_timezone_location' );
can_ok( $locale, 'format_timezone_non_location' );
can_ok( $locale, 'has_dst' );
can_ok( $locale, 'interval_format' );
can_ok( $locale, 'interval_formats' );
can_ok( $locale, 'interval_greatest_diff' );
can_ok( $locale, 'is_dst' );
can_ok( $locale, 'is_ltr' );
can_ok( $locale, 'is_rtl' );
can_ok( $locale, 'language' );
can_ok( $locale, 'language_code' );
can_ok( $locale, 'locale' );
can_ok( $locale, 'locale_number_system' );
can_ok( $locale, 'metazone_daylight_long' );
can_ok( $locale, 'metazone_daylight_short' );
can_ok( $locale, 'metazone_generic_long' );
can_ok( $locale, 'metazone_generic_short' );
can_ok( $locale, 'metazone_standard_long' );
can_ok( $locale, 'metazone_standard_short' );
can_ok( $locale, 'month_format_abbreviated' );
can_ok( $locale, 'month_format_narrow' );
can_ok( $locale, 'month_format_wide' );
can_ok( $locale, 'month_stand_alone_abbreviated' );
can_ok( $locale, 'month_stand_alone_narrow' );
can_ok( $locale, 'month_stand_alone_wide' );
can_ok( $locale, 'name' );
can_ok( $locale, 'native_language' );
can_ok( $locale, 'native_name' );
can_ok( $locale, 'native_script' );
can_ok( $locale, 'native_territory' );
can_ok( $locale, 'native_variant' );
can_ok( $locale, 'native_variants' );
can_ok( $locale, 'number_symbols' );
can_ok( $locale, 'number_system' );
can_ok( $locale, 'number_systems' );
can_ok( $locale, 'number_system_digits' );
can_ok( $locale, 'pass_error' );
can_ok( $locale, 'prefers_24_hour_time' );
can_ok( $locale, 'quarter_format_abbreviated' );
can_ok( $locale, 'quarter_format_narrow' );
can_ok( $locale, 'quarter_format_wide' );
can_ok( $locale, 'quarter_stand_alone_abbreviated' );
can_ok( $locale, 'quarter_stand_alone_narrow' );
can_ok( $locale, 'quarter_stand_alone_wide' );
can_ok( $locale, 'script' );
can_ok( $locale, 'script_code' );
can_ok( $locale, 'split_interval' );
can_ok( $locale, 'territory' );
can_ok( $locale, 'territory_code' );
can_ok( $locale, 'territory_info' );
can_ok( $locale, 'time_format_allowed' );
can_ok( $locale, 'time_format_default' );
can_ok( $locale, 'time_format_full' );
can_ok( $locale, 'time_format_long' );
can_ok( $locale, 'time_format_medium' );
can_ok( $locale, 'time_format_preferred' );
can_ok( $locale, 'time_format_short' );
can_ok( $locale, 'time_formats' );
can_ok( $locale, 'timezone_canonical' );
can_ok( $locale, 'timezone_city' );
can_ok( $locale, 'timezone_daylight_long' );
can_ok( $locale, 'timezone_daylight_short' );
can_ok( $locale, 'timezone_format_fallback' );
can_ok( $locale, 'timezone_format_gmt' );
can_ok( $locale, 'timezone_format_gmt_zero' );
can_ok( $locale, 'timezone_format_hour' );
can_ok( $locale, 'timezone_format_region' );
can_ok( $locale, 'timezone_format_region_daylight' );
can_ok( $locale, 'timezone_format_region_standard' );
can_ok( $locale, 'timezone_generic_long' );
can_ok( $locale, 'timezone_generic_short' );
can_ok( $locale, 'timezone_id' );
can_ok( $locale, 'timezone_standard_long' );
can_ok( $locale, 'timezone_standard_short' );
can_ok( $locale, 'variant' );
can_ok( $locale, 'variant_code' );
can_ok( $locale, 'variants' );
can_ok( $locale, 'version' );

like( $locale->version, qr/^\d+\.\d+$/, 'version' );

# NOTE: core test data
my $tests = [
    {
        am_pm_abbreviated => ["AM", "PM"],
        am_pm_format_abbreviated => ["AM", "PM"],
        am_pm_format_narrow => ["a", "p"],
        am_pm_format_wide => ["AM", "PM"],
        am_pm_standalone_abbreviated => ["AM", "PM"],
        am_pm_standalone_narrow => ["AM", "PM"],
        am_pm_standalone_wide => ["AM", "PM"],
        available_formats => ["Bh", "Bhm", "Bhms", "d", "E", "EBhm", "EBhms", "Ed", "Ehm", "EHm", "Ehms", "EHms", "Gy", "GyMd", "GyMMM", "GyMMMd", "GyMMMEd", "h", "H", "hm", "Hm", "hms", "Hms", "hmsv", "Hmsv", "hmv", "Hmv", "M", "Md", "MEd", "MMM", "MMMd", "MMMEd", "MMMMd", "MMMMW", "ms", "y", "yM", "yMd", "yMEd", "yMMM", "yMMMd", "yMMMEd", "yMMMM", "yQQQ", "yQQQQ", "yw"],
        available_format_patterns => {
	        Bh => "h B",
	        Bhm => "h:mm B",
	        Bhms => "h:mm:ss B",
	        d => "d",
	        E => "ccc",
	        EBhm => "E h:mm B",
	        EBhms => "E h:mm:ss B",
	        Ed => "d E",
	        Ehm => "E h:mm a",
	        EHm => "E HH:mm",
	        Ehms => "E h:mm:ss a",
	        EHms => "E HH:mm:ss",
	        Gy => "y G",
	        GyMd => "M/d/y G",
	        GyMMM => "MMM y G",
	        GyMMMd => "MMM d, y G",
	        GyMMMEd => "E, MMM d, y G",
	        h => "h a",
	        H => "HH",
	        Hm => "HH:mm",
	        hm => "h:mm a",
	        hms => "h:mm:ss a",
	        Hms => "HH:mm:ss",
	        Hmsv => "HH:mm:ss v",
	        hmsv => "h:mm:ss a v",
	        Hmv => "HH:mm v",
	        hmv => "h:mm a v",
	        M => "L",
	        Md => "M/d",
	        MEd => "E, M/d",
	        MMM => "LLL",
	        MMMd => "MMM d",
	        MMMEd => "E, MMM d",
	        MMMMd => "MMMM d",
	        MMMMW => "'week' W 'of' MMMM",
	        ms => "mm:ss",
	        y => "y",
	        yM => "M/y",
	        yMd => "M/d/y",
	        yMEd => "E, M/d/y",
	        yMMM => "MMM y",
	        yMMMd => "MMM d, y",
	        yMMMEd => "E, MMM d, y",
	        yMMMM => "MMMM y",
	        yQQQ => "QQQ y",
	        yQQQQ => "QQQQ y",
	        yw => "'week' w 'of' Y",
	    },
        calendar => q{gregorian},
        code => q{en},
        date_at_time_format_full => q{EEEE, MMMM d, y 'at' h:mm:ss a zzzz},
        date_at_time_format_long => q{MMMM d, y 'at' h:mm:ss a z},
        date_at_time_format_medium => q{MMM d, y, h:mm:ss a},
        date_at_time_format_short => q{M/d/yy, h:mm a},
        date_format_default => q{MMM d, y},
        date_format_full => q{EEEE, MMMM d, y},
        date_format_long => q{MMMM d, y},
        date_format_medium => q{MMM d, y},
        date_format_short => q{M/d/yy},
        date_formats => {
	        full => "EEEE, MMMM d, y",
	        long => "MMMM d, y",
	        medium => "MMM d, y",
	        short => "M/d/yy",
	    },
        datetime_format => q{MMM d, y, h:mm:ss a},
        datetime_format_default => q{MMM d, y, h:mm:ss a},
        datetime_format_full => q{EEEE, MMMM d, y, h:mm:ss a zzzz},
        datetime_format_long => q{MMMM d, y, h:mm:ss a z},
        datetime_format_medium => q{MMM d, y, h:mm:ss a},
        datetime_format_short => q{M/d/yy, h:mm a},
        day_format_abbreviated => ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
        day_format_narrow => ["M", "T", "W", "T", "F", "S", "S"],
        day_format_short => ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"],
        day_format_wide => ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"],
        day_periods => {
	        afternoon1 => [qw( 12:00 18:00 )],
	        evening1 => [qw( 18:00 21:00 )],
	        midnight => [qw( 00:00 00:00 )],
	        morning1 => [qw( 06:00 12:00 )],
	        night1 => [qw( 21:00 06:00 )],
	        noon => [qw( 12:00 12:00 )],
	    },
        day_stand_alone_abbreviated => ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
        day_stand_alone_narrow => ["M", "T", "W", "T", "F", "S", "S"],
        day_stand_alone_short => ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"],
        day_stand_alone_wide => ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"],
        default_date_format_length => q{medium},
        default_time_format_length => q{medium},
        era_abbreviated => ["BC", "AD"],
        era_narrow => ["B", "A"],
        era_wide => ["Before Christ", "Anno Domini"],
        first_day_of_week => q{7},
        interval_formats => {
	        Bh => [qw( B h )],
	        Bhm => [qw( B h m )],
	        d => ["d"],
	        default => ["default"],
	        Gy => [qw( G y )],
	        GyM => [qw( G M y )],
	        GyMd => [qw( d G M y )],
	        GyMEd => [qw( d G M y )],
	        GyMMM => [qw( G M y )],
	        GyMMMd => [qw( d G M y )],
	        GyMMMEd => [qw( d G M y )],
	        h => [qw( a h )],
	        H => ["H"],
	        Hm => [qw( H m )],
	        hm => [qw( a h m )],
	        Hmv => [qw( H m )],
	        hmv => [qw( a h m )],
	        Hv => ["H"],
	        hv => [qw( a h )],
	        M => ["M"],
	        Md => [qw( d M )],
	        MEd => [qw( d M )],
	        MMM => ["M"],
	        MMMd => [qw( d M )],
	        MMMEd => [qw( d M )],
	        y => ["y"],
	        yM => [qw( M y )],
	        yMd => [qw( d M y )],
	        yMEd => [qw( d M y )],
	        yMMM => [qw( M y )],
	        yMMMd => [qw( d M y )],
	        yMMMEd => [qw( d M y )],
	        yMMMM => [qw( M y )],
	    },
        is_ltr => q{0},
        is_rtl => q{1},
        language => q{English},
        language_code => q{en},
        locale => q{en},
        locale_number_system => ["latn", [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]],
        month_format_abbreviated => ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"],
        month_format_narrow => ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"],
        month_format_wide => ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"],
        month_stand_alone_abbreviated => ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"],
        month_stand_alone_narrow => ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"],
        month_stand_alone_wide => ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"],
        name => q{English},
        native_language => q{English},
        native_name => q{English},
        native_script => undef,
        native_territory => undef,
        native_variant => undef,
        native_variants => [],
        number_symbols => {
	        approximately => "~",
	        decimal => ".",
	        exponential => "E",
	        group => ",",
	        infinity => "∞",
	        list => ";",
	        minus => "-",
	        nan => "NaN",
	        per_mille => "‰",
	        percent => "%",
	        plus => "+",
	        superscript => "\xD7",
	        time_separator => ":",
	    },
        number_system => q{latn},
        number_systems => {
	        finance => undef,
	        native => "latn",
	        number_system => "latn",
	        traditional => undef,
	    },
        number_system_digits => ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"],
        prefers_24_hour_time => q{0},
        quarter_format_abbreviated => ["Q1", "Q2", "Q3", "Q4"],
        quarter_format_narrow => ["1", "2", "3", "4"],
        quarter_format_wide => ["1st quarter", "2nd quarter", "3rd quarter", "4th quarter"],
        quarter_stand_alone_abbreviated => ["Q1", "Q2", "Q3", "Q4"],
        quarter_stand_alone_narrow => ["1", "2", "3", "4"],
        quarter_stand_alone_wide => ["1st quarter", "2nd quarter", "3rd quarter", "4th quarter"],
        script => undef,
        script_code => undef,
        territory => undef,
        territory_code => undef,
        territory_info => {
	        calendars => undef,
	        contains => undef,
	        currency => "USD",
	        first_day => 7,
	        gdp => 24660000000000,
	        languages => [qw(
	            en es zh-Hant fr de fil it vi ko ru nv yi pdc hnj haw
	            frc chr esu dak cho lkt ik mus io cic cad jbo osa zh
	        )],
	        literacy_percent => 99,
	        min_days => 1,
	        parent => "021",
	        population => 341963000,
	        status => "regular",
	        territory => "US",
	        territory_id => 297,
	        weekend => undef,
	    },
        time_format_allowed => ["h", "hb", "H", "hB"],
        time_format_default => q{h:mm:ss a},
        time_format_full => q{h:mm:ss a zzzz},
        time_format_long => q{h:mm:ss a z},
        time_format_medium => q{h:mm:ss a},
        time_format_preferred => q{h},
        time_format_short => q{h:mm a},
        time_formats => {
	        full => "h:mm:ss a zzzz",
	        long => "h:mm:ss a z",
	        medium => "h:mm:ss a",
	        short => "h:mm a",
	    },
        timezone_format_gmt => q{GMT{0}},
        timezone_format_gmt_zero => q{GMT},
        timezone_format_hour => ["+HH:mm", "-HH:mm"],
        timezone_format_region => q{{0} Time},
        timezone_format_region_daylight => q{{0} Daylight Time},
        timezone_format_region_standard => q{{0} Standard Time},
        variant => undef,
        variant_code => undef,
        variants => [],
    },
    {
        am_pm_abbreviated => ["am", "pm"],
        am_pm_format_abbreviated => ["am", "pm"],
        am_pm_format_narrow => ["am", "pm"],
        am_pm_format_wide => ["am", "pm"],
        am_pm_standalone_abbreviated => ["am", "pm"],
        am_pm_standalone_narrow => ["am", "pm"],
        am_pm_standalone_wide => ["am", "pm"],
        available_formats => ["GyMd", "GyMMMEEEEd", "MEd", "MMMEd", "MMMEEEEd", "MMMMEEEEd", "yMMMEEEEd", "yMMMMEEEEd"],
        available_format_patterns => {
	        GyMd => "dd/MM/y G",
	        GyMMMEEEEd => "EEEE, d MMM y G",
	        MEd => "E dd/MM",
	        MMMEd => "E d MMM",
	        MMMEEEEd => "EEEE d MMM",
	        MMMMEEEEd => "EEEE d MMMM",
	        yMMMEEEEd => "EEEE, d MMM y",
	        yMMMMEEEEd => "EEEE, d MMMM y",
	    },
        calendar => q{gregorian},
        code => q{en-GB},
        date_at_time_format_full => q{EEEE, d MMMM y 'at' HH:mm:ss zzzz},
        date_at_time_format_long => q{d MMMM y 'at' HH:mm:ss z},
        date_at_time_format_medium => q{d MMM y, HH:mm:ss},
        date_at_time_format_short => q{dd/MM/y, HH:mm},
        date_format_default => q{d MMM y},
        date_format_full => q{EEEE, d MMMM y},
        date_format_long => q{d MMMM y},
        date_format_medium => q{d MMM y},
        date_format_short => q{dd/MM/y},
        date_formats => {
	        full => "EEEE, d MMMM y",
	        long => "d MMMM y",
	        medium => "d MMM y",
	        short => "dd/MM/y",
	    },
        datetime_format => q{d MMM y, HH:mm:ss},
        datetime_format_default => q{d MMM y, HH:mm:ss},
        datetime_format_full => q{EEEE, d MMMM y, HH:mm:ss zzzz},
        datetime_format_long => q{d MMMM y, HH:mm:ss z},
        datetime_format_medium => q{d MMM y, HH:mm:ss},
        datetime_format_short => q{dd/MM/y, HH:mm},
        day_format_abbreviated => ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
        day_format_narrow => ["M", "T", "W", "T", "F", "S", "S"],
        day_format_short => ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"],
        day_format_wide => ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"],
        day_periods => {
	        afternoon1 => [qw( 12:00 18:00 )],
	        evening1 => [qw( 18:00 21:00 )],
	        midnight => [qw( 00:00 00:00 )],
	        morning1 => [qw( 06:00 12:00 )],
	        night1 => [qw( 21:00 06:00 )],
	        noon => [qw( 12:00 12:00 )],
	    },
        day_stand_alone_abbreviated => ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
        day_stand_alone_narrow => ["M", "T", "W", "T", "F", "S", "S"],
        day_stand_alone_short => ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"],
        day_stand_alone_wide => ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"],
        default_date_format_length => q{medium},
        default_time_format_length => q{medium},
        era_abbreviated => ["BC", "AD"],
        era_narrow => ["B", "A"],
        era_wide => ["Before Christ", "Anno Domini"],
        first_day_of_week => q{1},
        interval_formats => {
	        GyMMMEEEEd => [qw( d G M y )],
	        MMMEd => ["d"],
	        yMMMEd => ["d"],
	        yMMMEEEEd => [qw( d M y )],
	        yMMMMEEEEd => [qw( d M y )],
	    },
        is_ltr => q{0},
        is_rtl => q{1},
        language => q{English},
        language_code => q{en},
        locale => q{en-GB},
        locale_number_system => ["latn", [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]],
        month_format_abbreviated => ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"],
        month_format_narrow => ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"],
        month_format_wide => ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"],
        month_stand_alone_abbreviated => ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"],
        month_stand_alone_narrow => ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"],
        month_stand_alone_wide => ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"],
        name => q{British English},
        native_language => q{English},
        native_name => q{British English},
        native_script => undef,
        native_territory => q{United Kingdom},
        native_variant => undef,
        native_variants => [],
        number_symbols => {
	        approximately => "~",
	        decimal => ".",
	        exponential => "E",
	        group => ",",
	        infinity => "∞",
	        list => ";",
	        minus => "-",
	        nan => "NaN",
	        per_mille => "‰",
	        percent => "%",
	        plus => "+",
	        superscript => "\xD7",
	        time_separator => ":",
	    },
        number_system => q{latn},
        number_systems => {
	        finance => undef,
	        native => "latn",
	        number_system => "latn",
	        traditional => undef,
	    },
        number_system_digits => ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"],
        prefers_24_hour_time => q{1},
        quarter_format_abbreviated => ["Q1", "Q2", "Q3", "Q4"],
        quarter_format_narrow => ["1", "2", "3", "4"],
        quarter_format_wide => ["1st quarter", "2nd quarter", "3rd quarter", "4th quarter"],
        quarter_stand_alone_abbreviated => ["Q1", "Q2", "Q3", "Q4"],
        quarter_stand_alone_narrow => ["1", "2", "3", "4"],
        quarter_stand_alone_wide => ["1st quarter", "2nd quarter", "3rd quarter", "4th quarter"],
        script => undef,
        script_code => undef,
        territory => q{United Kingdom},
        territory_code => q{GB},
        territory_info => {
	        calendars => undef,
	        contains => undef,
	        currency => "GBP",
	        first_day => 1,
	        gdp => 3700000000000,
	        languages => [qw(
	            en fr de es pl pa ur ta gu sco cy ro bn ar zh-Hant it lt
	            pt so tr ga gd kw en-Shaw
	        )],
	        literacy_percent => 99,
	        min_days => 4,
	        parent => 154,
	        population => 68459100,
	        status => "regular",
	        territory => "GB",
	        territory_id => 121,
	        weekend => undef,
	    },
        time_format_allowed => ["H", "h", "hb", "hB"],
        time_format_default => q{HH:mm:ss},
        time_format_full => q{HH:mm:ss zzzz},
        time_format_long => q{HH:mm:ss z},
        time_format_medium => q{HH:mm:ss},
        time_format_preferred => q{H},
        time_format_short => q{HH:mm},
        time_formats => {
	        full => "HH:mm:ss zzzz",
	        long => "HH:mm:ss z",
	        medium => "HH:mm:ss",
	        short => "HH:mm",
	    },
        timezone_format_gmt => q{GMT{0}},
        timezone_format_gmt_zero => q{GMT},
        timezone_format_hour => ["+HH:mm", "-HH:mm"],
        timezone_format_region => q{{0} Time},
        timezone_format_region_daylight => q{{0} Daylight Time},
        timezone_format_region_standard => q{{0} Standard Time},
        variant => undef,
        variant_code => undef,
        variants => [],
    },
    {
        am_pm_abbreviated => ["a. m.", "p. m."],
        am_pm_format_abbreviated => ["a. m.", "p. m."],
        am_pm_format_narrow => ["a. m.", "p. m."],
        am_pm_format_wide => ["a. m.", "p. m."],
        am_pm_standalone_abbreviated => ["a. m.", "p. m."],
        am_pm_standalone_narrow => ["a. m.", "p. m."],
        am_pm_standalone_wide => ["a. m.", "p. m."],
        available_formats => ["Ed", "Ehm", "EHm", "Ehms", "EHms", "Gy", "GyMd", "GyMMM", "GyMMMd", "GyMMMEd", "GyMMMM", "GyMMMMd", "GyMMMMEd", "h", "H", "hm", "Hm", "hms", "Hms", "hmsv", "Hmsv", "hmsvvvv", "Hmsvvvv", "hmv", "Hmv", "Md", "MEd", "MMd", "MMdd", "MMMd", "MMMEd", "MMMMd", "MMMMEd", "MMMMW", "yM", "yMd", "yMEd", "yMM", "yMMM", "yMMMd", "yMMMEd", "yMMMM", "yMMMMd", "yMMMMEd", "yQQQ", "yQQQQ", "yw"],
        available_format_patterns => {
	        Ed => "E d",
	        Ehm => "E, h:mm a",
	        EHm => "E, H:mm",
	        Ehms => "E, h:mm:ss a",
	        EHms => "E, H:mm:ss",
	        Gy => "y G",
	        GyMd => "d/M/y GGGGG",
	        GyMMM => "MMM y G",
	        GyMMMd => "d MMM y G",
	        GyMMMEd => "E, d MMM y G",
	        GyMMMM => "MMMM 'de' y G",
	        GyMMMMd => "d 'de' MMMM 'de' y G",
	        GyMMMMEd => "E, d 'de' MMMM 'de' y G",
	        h => "h a",
	        H => "H",
	        Hm => "H:mm",
	        hm => "h:mm a",
	        hms => "h:mm:ss a",
	        Hms => "H:mm:ss",
	        Hmsv => "H:mm:ss v",
	        hmsv => "h:mm:ss a v",
	        Hmsvvvv => "H:mm:ss (vvvv)",
	        hmsvvvv => "h:mm:ss a (vvvv)",
	        Hmv => "H:mm v",
	        hmv => "h:mm a v",
	        Md => "d/M",
	        MEd => "E, d/M",
	        MMd => "d/M",
	        MMdd => "d/M",
	        MMMd => "d MMM",
	        MMMEd => "E, d MMM",
	        MMMMd => "d 'de' MMMM",
	        MMMMEd => "E, d 'de' MMMM",
	        MMMMW => "'semana' W 'de' MMMM",
	        yM => "M/y",
	        yMd => "d/M/y",
	        yMEd => "EEE, d/M/y",
	        yMM => "M/y",
	        yMMM => "MMM y",
	        yMMMd => "d MMM y",
	        yMMMEd => "EEE, d MMM y",
	        yMMMM => "MMMM 'de' y",
	        yMMMMd => "d 'de' MMMM 'de' y",
	        yMMMMEd => "EEE, d 'de' MMMM 'de' y",
	        yQQQ => "QQQ y",
	        yQQQQ => "QQQQ 'de' y",
	        yw => "'semana' w 'de' Y",
	    },
        calendar => q{gregorian},
        code => q{es-005-valencia},
        date_at_time_format_full => q{EEEE, d 'de' MMMM 'de' y H:mm:ss (zzzz)},
        date_at_time_format_long => q{d 'de' MMMM 'de' y H:mm:ss z},
        date_at_time_format_medium => q{d MMM y H:mm:ss},
        date_at_time_format_short => q{d/M/yy H:mm},
        date_format_default => q{d MMM y},
        date_format_full => q{EEEE, d 'de' MMMM 'de' y},
        date_format_long => q{d 'de' MMMM 'de' y},
        date_format_medium => q{d MMM y},
        date_format_short => q{d/M/yy},
        date_formats => {
	        full => "EEEE, d 'de' MMMM 'de' y",
	        long => "d 'de' MMMM 'de' y",
	        medium => "d MMM y",
	        short => "d/M/yy",
	    },
        datetime_format => q{d MMM y, H:mm:ss},
        datetime_format_default => q{d MMM y, H:mm:ss},
        datetime_format_full => q{EEEE, d 'de' MMMM 'de' y, H:mm:ss (zzzz)},
        datetime_format_long => q{d 'de' MMMM 'de' y, H:mm:ss z},
        datetime_format_medium => q{d MMM y, H:mm:ss},
        datetime_format_short => q{d/M/yy, H:mm},
        day_format_abbreviated => ["lun", "mar", "mié", "jue", "vie", "sáb", "dom"],
        day_format_narrow => ["LU", "MA", "MI", "JU", "VI", "SA", "DO"],
        day_format_short => ["LU", "MA", "MI", "JU", "VI", "SA", "DO"],
        day_format_wide => ["lunes", "martes", "miércoles", "jueves", "viernes", "sábado", "domingo"],
        day_periods => {
	        evening1 => [qw( 12:00 20:00 )],
	        morning1 => [qw( 00:00 06:00 )],
	        morning2 => [qw( 06:00 12:00 )],
	        night1 => [qw( 20:00 24:00 )],
	        noon => [qw( 12:00 12:00 )],
	    },
        day_stand_alone_abbreviated => ["lun", "mar", "mié", "jue", "vie", "sáb", "dom"],
        day_stand_alone_narrow => ["L", "M", "X", "J", "V", "S", "D"],
        day_stand_alone_short => ["LU", "MA", "MI", "JU", "VI", "SA", "DO"],
        day_stand_alone_wide => ["lunes", "martes", "miércoles", "jueves", "viernes", "sábado", "domingo"],
        default_date_format_length => q{medium},
        default_time_format_length => q{medium},
        era_abbreviated => ["a. C.", "d. C."],
        era_narrow => ["a. C.", "d. C."],
        era_wide => ["antes de Cristo", "después de Cristo"],
        first_day_of_week => q{1},
        interval_formats => {
	        Gy => [qw( G y )],
	        GyM => [qw( G M y )],
	        GyMd => [qw( d G M y )],
	        GyMEd => [qw( d G M y )],
	        GyMMM => [qw( G M y )],
	        GyMMMd => [qw( d G M y )],
	        GyMMMEd => [qw( d G M y )],
	        H => ["H"],
	        h => [qw( a h )],
	        hm => [qw( a h m )],
	        Hm => [qw( H m )],
	        hmv => [qw( a h m )],
	        Hmv => [qw( H m )],
	        hv => [qw( a h )],
	        Hv => ["H"],
	        M => ["M"],
	        Md => [qw( d M )],
	        MEd => [qw( d M )],
	        MMM => ["M"],
	        MMMd => [qw( d M )],
	        MMMEd => [qw( d M )],
	        MMMMd => [qw( d M )],
	        MMMMEd => [qw( d M )],
	        yM => [qw( M y )],
	        yMd => [qw( d M y )],
	        yMEd => [qw( d M y )],
	        yMMM => [qw( M y )],
	        yMMMd => [qw( d M y )],
	        yMMMEd => [qw( d M y )],
	        yMMMM => [qw( M y )],
	        yMMMMd => [qw( d M y )],
	        yMMMMEd => [qw( d M y )],
	    },
        is_ltr => q{0},
        is_rtl => q{1},
        language => q{Spanish},
        language_code => q{es},
        locale => q{es-005-valencia},
        locale_number_system => ["latn", [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]],
        month_format_abbreviated => ["ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sept", "oct", "nov", "dic"],
        month_format_narrow => ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"],
        month_format_wide => ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"],
        month_stand_alone_abbreviated => ["M01", "M02", "M03", "M04", "M05", "M06", "M07", "M08", "M09", "M10", "M11", "M12"],
        month_stand_alone_narrow => ["E", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"],
        month_stand_alone_wide => ["M01", "M02", "M03", "M04", "M05", "M06", "M07", "M08", "M09", "M10", "M11", "M12"],
        name => q{Spanish},
        native_language => q{español},
        native_name => q{español},
        native_script => undef,
        native_territory => q{Sudamérica},
        native_variant => q{Valenciano},
        native_variants => ["Valenciano"],
        number_symbols => {
	        approximately => "~",
	        decimal => ",",
	        exponential => "E",
	        group => ".",
	        infinity => "∞",
	        list => ";",
	        minus => "-",
	        nan => "NaN",
	        per_mille => "‰",
	        percent => "%",
	        plus => "+",
	        superscript => "\xD7",
	        time_separator => ":",
	    },
        number_system => q{latn},
        number_systems => {
	        finance => undef,
	        native => "latn",
	        number_system => "latn",
	        traditional => undef,
	    },
        number_system_digits => ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"],
        prefers_24_hour_time => q{1},
        quarter_format_abbreviated => ["T1", "T2", "T3", "T4"],
        quarter_format_narrow => ["1.er trimestre", "2.º trimestre", "3.er trimestre", "4.º trimestre"],
        quarter_format_wide => ["1.er trimestre", "2.º trimestre", "3.er trimestre", "4.º trimestre"],
        quarter_stand_alone_abbreviated => ["T1", "T2", "T3", "T4"],
        quarter_stand_alone_narrow => ["T1", "T2", "T3", "T4"],
        quarter_stand_alone_wide => ["1.er trimestre", "2.º trimestre", "3.er trimestre", "4.º trimestre"],
        script => undef,
        script_code => undef,
        territory => q{South America},
        territory_code => q{005},
        territory_info => {
	        calendars => undef,
	        contains => undef,
	        currency => "EUR",
	        first_day => 1,
	        gdp => 2242000000000,
	        languages => [qw( es en ca gl eu ast ext an oc )],
	        literacy_percent => 97.7,
	        min_days => 4,
	        parent => "039",
	        population => 47280400,
	        status => "regular",
	        territory => "ES",
	        territory_id => 109,
	        weekend => undef,
	    },
        time_format_allowed => ["H", "h", "hB"],
        time_format_default => q{H:mm:ss},
        time_format_full => q{H:mm:ss (zzzz)},
        time_format_long => q{H:mm:ss z},
        time_format_medium => q{H:mm:ss},
        time_format_preferred => q{H},
        time_format_short => q{H:mm},
        time_formats => {
	        full => "H:mm:ss (zzzz)",
	        long => "H:mm:ss z",
	        medium => "H:mm:ss",
	        short => "H:mm",
	    },
        timezone_format_gmt => q{GMT{0}},
        timezone_format_gmt_zero => q{GMT},
        timezone_format_hour => ["+HH:mm", "-HH:mm"],
        timezone_format_region => q{hora de {0}},
        timezone_format_region_daylight => q{horario de verano de {0}},
        timezone_format_region_standard => q{horario estándar de {0}},
        variant => q{Valencian},
        variant_code => q{valencia},
        variants => ["valencia"],
    },
    {
        am_pm_abbreviated => ["午前", "午後"],
        am_pm_format_abbreviated => ["午前", "午後"],
        am_pm_format_narrow => ["午前", "午後"],
        am_pm_format_wide => ["午前", "午後"],
        am_pm_standalone_abbreviated => ["午前", "午後"],
        am_pm_standalone_narrow => ["午前", "午後"],
        am_pm_standalone_wide => ["午前", "午後"],
        available_formats => ["Bh", "Bhm", "Bhms", "d", "EBhm", "EBhms", "Ed", "EEEEd", "Ehm", "EHm", "Ehms", "EHms", "Gy", "GyMd", "GyMMM", "GyMMMd", "GyMMMEd", "GyMMMEEEEd", "h", "H", "hm", "Hm", "hms", "Hms", "hmsv", "Hmsv", "hmv", "Hmv", "M", "Md", "MEd", "MEEEEd", "MMM", "MMMd", "MMMEd", "MMMEEEEd", "MMMMd", "MMMMW", "y", "yM", "yMd", "yMEd", "yMEEEEd", "yMM", "yMMM", "yMMMd", "yMMMEd", "yMMMEEEEd", "yMMMM", "yQQQ", "yQQQQ", "yw"],
        available_format_patterns => {
	        Bh => "BK時",
	        Bhm => "BK:mm",
	        Bhms => "BK:mm:ss",
	        d => "d日",
	        EBhm => "BK:mm (E)",
	        EBhms => "BK:mm:ss (E)",
	        Ed => "d日(E)",
	        EEEEd => "d日EEEE",
	        EHm => "H:mm (E)",
	        Ehm => "aK:mm (E)",
	        EHms => "H:mm:ss (E)",
	        Ehms => "aK:mm:ss (E)",
	        Gy => "Gy年",
	        GyMd => "Gy/M/d",
	        GyMMM => "Gy年M月",
	        GyMMMd => "Gy年M月d日",
	        GyMMMEd => "Gy年M月d日(E)",
	        GyMMMEEEEd => "Gy年M月d日EEEE",
	        H => "H時",
	        h => "aK時",
	        hm => "aK:mm",
	        Hm => "H:mm",
	        Hms => "H:mm:ss",
	        hms => "aK:mm:ss",
	        hmsv => "aK:mm:ss v",
	        Hmsv => "H:mm:ss v",
	        hmv => "aK:mm v",
	        Hmv => "H:mm v",
	        M => "M月",
	        Md => "M/d",
	        MEd => "M/d(E)",
	        MEEEEd => "M/dEEEE",
	        MMM => "M月",
	        MMMd => "M月d日",
	        MMMEd => "M月d日(E)",
	        MMMEEEEd => "M月d日EEEE",
	        MMMMd => "M月d日",
	        MMMMW => "M月第W週",
	        y => "y年",
	        yM => "y/M",
	        yMd => "y/M/d",
	        yMEd => "y/M/d(E)",
	        yMEEEEd => "y/M/dEEEE",
	        yMM => "y/MM",
	        yMMM => "y年M月",
	        yMMMd => "y年M月d日",
	        yMMMEd => "y年M月d日(E)",
	        yMMMEEEEd => "y年M月d日EEEE",
	        yMMMM => "y年M月",
	        yQQQ => "y/QQQ",
	        yQQQQ => "y年QQQQ",
	        yw => "Y年第w週",
	    },
        calendar => q{gregorian},
        code => q{ja-Latn-fonipa-hepburn-heploc},
        date_at_time_format_full => q{y年M月d日EEEE H時mm分ss秒 zzzz},
        date_at_time_format_long => q{y年M月d日 H:mm:ss z},
        date_at_time_format_medium => q{y/MM/dd H:mm:ss},
        date_at_time_format_short => q{y/MM/dd H:mm},
        date_format_default => q{y/MM/dd},
        date_format_full => q{y年M月d日EEEE},
        date_format_long => q{y年M月d日},
        date_format_medium => q{y/MM/dd},
        date_format_short => q{y/MM/dd},
        date_formats => {
	        full => "y年M月d日EEEE",
	        long => "y年M月d日",
	        medium => "y/MM/dd",
	        short => "y/MM/dd",
	    },
        datetime_format => q{y/MM/dd H:mm:ss},
        datetime_format_default => q{y/MM/dd H:mm:ss},
        datetime_format_full => q{y年M月d日EEEE H時mm分ss秒 zzzz},
        datetime_format_long => q{y年M月d日 H:mm:ss z},
        datetime_format_medium => q{y/MM/dd H:mm:ss},
        datetime_format_short => q{y/MM/dd H:mm},
        day_format_abbreviated => ["月", "火", "水", "木", "金", "土", "日"],
        day_format_narrow => ["月", "火", "水", "木", "金", "土", "日"],
        day_format_short => ["月", "火", "水", "木", "金", "土", "日"],
        day_format_wide => ["月曜日", "火曜日", "水曜日", "木曜日", "金曜日", "土曜日", "日曜日"],
        day_periods => {
	        afternoon1 => [qw( 12:00 16:00 )],
	        evening1 => [qw( 16:00 19:00 )],
	        midnight => [qw( 00:00 00:00 )],
	        morning1 => [qw( 04:00 12:00 )],
	        night1 => [qw( 19:00 23:00 )],
	        night2 => [qw( 23:00 04:00 )],
	        noon => [qw( 12:00 12:00 )],
	    },
        day_stand_alone_abbreviated => ["月", "火", "水", "木", "金", "土", "日"],
        day_stand_alone_narrow => ["月", "火", "水", "木", "金", "土", "日"],
        day_stand_alone_short => ["月", "火", "水", "木", "金", "土", "日"],
        day_stand_alone_wide => ["月曜日", "火曜日", "水曜日", "木曜日", "金曜日", "土曜日", "日曜日"],
        default_date_format_length => q{medium},
        default_time_format_length => q{medium},
        era_abbreviated => ["紀元前", "西暦"],
        era_narrow => ["BC", "AD"],
        era_wide => ["紀元前", "西暦"],
        first_day_of_week => q{7},
        interval_formats => {
	        Bh => [qw( B h )],
	        Bhm => [qw( B h m )],
	        d => ["d"],
	        default => ["default"],
	        Gy => [qw( G y )],
	        GyM => [qw( G M y )],
	        GyMd => [qw( d G M y )],
	        GyMEd => [qw( d G M y )],
	        GyMMM => [qw( G M y )],
	        GyMMMd => [qw( d G M y )],
	        GyMMMEd => [qw( d G M y )],
	        H => ["H"],
	        h => [qw( a h )],
	        hm => [qw( a h m )],
	        Hm => [qw( H m )],
	        hmv => [qw( a h m )],
	        Hmv => [qw( H m )],
	        hv => [qw( a h )],
	        Hv => ["H"],
	        M => ["M"],
	        Md => [qw( d M )],
	        MEd => [qw( d M )],
	        MMM => ["M"],
	        MMMd => [qw( d M )],
	        MMMEd => [qw( d M )],
	        MMMM => ["M"],
	        y => ["y"],
	        yM => [qw( M y )],
	        yMd => [qw( d M y )],
	        yMEd => [qw( d M y )],
	        yMMM => [qw( M y )],
	        yMMMd => [qw( d M y )],
	        yMMMEd => [qw( d M y )],
	        yMMMM => [qw( M y )],
	    },
        is_ltr => q{0},
        is_rtl => q{1},
        language => q{Japanese},
        language_code => q{ja},
        locale => q{ja-Latn-fonipa-hepburn-heploc},
        locale_number_system => ["latn", [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]],
        month_format_abbreviated => ["1月", "2月", "3月", "4月", "5月", "6月", "7月", "8月", "9月", "10月", "11月", "12月"],
        month_format_narrow => ["1月", "2月", "3月", "4月", "5月", "6月", "7月", "8月", "9月", "10月", "11月", "12月"],
        month_format_wide => ["1月", "2月", "3月", "4月", "5月", "6月", "7月", "8月", "9月", "10月", "11月", "12月"],
        month_stand_alone_abbreviated => ["M01", "M02", "M03", "M04", "M05", "M06", "M07", "M08", "M09", "M10", "M11", "M12"],
        month_stand_alone_narrow => ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12"],
        month_stand_alone_wide => ["M01", "M02", "M03", "M04", "M05", "M06", "M07", "M08", "M09", "M10", "M11", "M12"],
        name => q{Japanese},
        native_language => q{日本語},
        native_name => q{日本語},
        native_script => q{ラテン文字},
        native_territory => undef,
        native_variant => q{国際音声記号},
        native_variants => ["国際音声記号", "ヘボン式ローマ字", ""],
        number_symbols => {
	        approximately => "約",
	        decimal => ".",
	        exponential => "E",
	        group => ",",
	        infinity => "∞",
	        list => ";",
	        minus => "-",
	        nan => "NaN",
	        per_mille => "‰",
	        percent => "%",
	        plus => "+",
	        superscript => "\xD7",
	        time_separator => ":",
	    },
        number_system => q{latn},
        number_systems => {
	        finance => "jpanfin",
	        native => undef,
	        number_system => undef,
	        traditional => "jpan",
	    },
        number_system_digits => ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"],
        prefers_24_hour_time => q{1},
        quarter_format_abbreviated => ["Q1", "Q2", "Q3", "Q4"],
        quarter_format_narrow => ["第1四半期", "第2四半期", "第3四半期", "第4四半期"],
        quarter_format_wide => ["第1四半期", "第2四半期", "第3四半期", "第4四半期"],
        quarter_stand_alone_abbreviated => ["Q1", "Q2", "Q3", "Q4"],
        quarter_stand_alone_narrow => ["Q1", "Q2", "Q3", "Q4"],
        quarter_stand_alone_wide => ["第1四半期", "第2四半期", "第3四半期", "第4四半期"],
        script => q{Latin},
        script_code => q{Latn},
        territory => undef,
        territory_code => undef,
        territory_info => {
	        calendars => [qw( gregorian japanese )],
	        contains => undef,
	        currency => "JPY",
	        first_day => 7,
	        gdp => 5761000000000,
	        languages => [qw( ja ryu ko )],
	        literacy_percent => 99,
	        min_days => undef,
	        parent => "030",
	        population => 123202000,
	        status => "regular",
	        territory => "JP",
	        territory_id => 159,
	        weekend => undef,
	    },
        time_format_allowed => ["H", "K", "h"],
        time_format_default => q{H:mm:ss},
        time_format_full => q{H時mm分ss秒 zzzz},
        time_format_long => q{H:mm:ss z},
        time_format_medium => q{H:mm:ss},
        time_format_preferred => q{H},
        time_format_short => q{H:mm},
        time_formats => {
	        full => "H時mm分ss秒 zzzz",
	        long => "H:mm:ss z",
	        medium => "H:mm:ss",
	        short => "H:mm",
	    },
        timezone_format_gmt => q{GMT{0}},
        timezone_format_gmt_zero => q{GMT},
        timezone_format_hour => ["+HH:mm", "-HH:mm"],
        timezone_format_region => q{{0}時間},
        timezone_format_region_daylight => q{{0}夏時間},
        timezone_format_region_standard => q{{0}標準時},
        variant => q{},
        variant_code => q{fonipa-hepburn-heploc},
        variants => ["fonipa", "hepburn", "heploc"],
    },
];

# NOTE: available formats data
my $available_formats = {
    en => {
        Bh => "h B",
        Bhm => "h:mm B",
        Bhms => "h:mm:ss B",
        d => "d",
        E => "ccc",
        EBhm => "E h:mm B",
        EBhms => "E h:mm:ss B",
        Ed => "d E",
        EHm => "E HH:mm",
        Ehm => "E h:mm a",
        Ehms => "E h:mm:ss a",
        EHms => "E HH:mm:ss",
        Gy => "y G",
        GyMd => "M/d/y G",
        GyMMM => "MMM y G",
        GyMMMd => "MMM d, y G",
        GyMMMEd => "E, MMM d, y G",
        H => "HH",
        h => "h a",
        Hm => "HH:mm",
        hm => "h:mm a",
        Hms => "HH:mm:ss",
        hms => "h:mm:ss a",
        hmsv => "h:mm:ss a v",
        Hmsv => "HH:mm:ss v",
        Hmv => "HH:mm v",
        hmv => "h:mm a v",
        M => "L",
        Md => "M/d",
        MEd => "E, M/d",
        MMM => "LLL",
        MMMd => "MMM d",
        MMMEd => "E, MMM d",
        MMMMd => "MMMM d",
        MMMMW => "'week' W 'of' MMMM",
        ms => "mm:ss",
        y => "y",
        yM => "M/y",
        yMd => "M/d/y",
        yMEd => "E, M/d/y",
        yMMM => "MMM y",
        yMMMd => "MMM d, y",
        yMMMEd => "E, MMM d, y",
        yMMMM => "MMMM y",
        yQQQ => "QQQ y",
        yQQQQ => "QQQQ y",
        yw => "'week' w 'of' Y",
    },
    "en-GB" => {
        GyMd => "dd/MM/y G",
        GyMMMEEEEd => "EEEE, d MMM y G",
        MEd => "E dd/MM",
        MMMEd => "E d MMM",
        MMMEEEEd => "EEEE d MMM",
        MMMMEEEEd => "EEEE d MMMM",
        yMMMEEEEd => "EEEE, d MMM y",
        yMMMMEEEEd => "EEEE, d MMMM y",
    },
    "es-005-valencia" => {
        Ed => "E d",
        EHm => "E, H:mm",
        Ehm => "E, h:mm a",
        Ehms => "E, h:mm:ss a",
        EHms => "E, H:mm:ss",
        Gy => "y G",
        GyMd => "d/M/y GGGGG",
        GyMMM => "MMM y G",
        GyMMMd => "d MMM y G",
        GyMMMEd => "E, d MMM y G",
        GyMMMM => "MMMM 'de' y G",
        GyMMMMd => "d 'de' MMMM 'de' y G",
        GyMMMMEd => "E, d 'de' MMMM 'de' y G",
        H => "H",
        h => "h a",
        Hm => "H:mm",
        hm => "h:mm a",
        Hms => "H:mm:ss",
        hms => "h:mm:ss a",
        hmsv => "h:mm:ss a v",
        Hmsv => "H:mm:ss v",
        hmsvvvv => "h:mm:ss a (vvvv)",
        Hmsvvvv => "H:mm:ss (vvvv)",
        Hmv => "H:mm v",
        hmv => "h:mm a v",
        Md => "d/M",
        MEd => "E, d/M",
        MMd => "d/M",
        MMdd => "d/M",
        MMMd => "d MMM",
        MMMEd => "E, d MMM",
        MMMMd => "d 'de' MMMM",
        MMMMEd => "E, d 'de' MMMM",
        MMMMW => "'semana' W 'de' MMMM",
        yM => "M/y",
        yMd => "d/M/y",
        yMEd => "EEE, d/M/y",
        yMM => "M/y",
        yMMM => "MMM y",
        yMMMd => "d MMM y",
        yMMMEd => "EEE, d MMM y",
        yMMMM => "MMMM 'de' y",
        yMMMMd => "d 'de' MMMM 'de' y",
        yMMMMEd => "EEE, d 'de' MMMM 'de' y",
        yQQQ => "QQQ y",
        yQQQQ => "QQQQ 'de' y",
        yw => "'semana' w 'de' Y",
    },
    "ja-Latn-fonipa-hepburn-heploc" => {
        Bh => "BK時",
        Bhm => "BK:mm",
        Bhms => "BK:mm:ss",
        d => "d日",
        EBhm => "BK:mm (E)",
        EBhms => "BK:mm:ss (E)",
        Ed => "d日(E)",
        EEEEd => "d日EEEE",
        Ehm => "aK:mm (E)",
        EHm => "H:mm (E)",
        EHms => "H:mm:ss (E)",
        Ehms => "aK:mm:ss (E)",
        Gy => "Gy年",
        GyMd => "Gy/M/d",
        GyMMM => "Gy年M月",
        GyMMMd => "Gy年M月d日",
        GyMMMEd => "Gy年M月d日(E)",
        GyMMMEEEEd => "Gy年M月d日EEEE",
        H => "H時",
        h => "aK時",
        Hm => "H:mm",
        hm => "aK:mm",
        Hms => "H:mm:ss",
        hms => "aK:mm:ss",
        hmsv => "aK:mm:ss v",
        Hmsv => "H:mm:ss v",
        Hmv => "H:mm v",
        hmv => "aK:mm v",
        M => "M月",
        Md => "M/d",
        MEd => "M/d(E)",
        MEEEEd => "M/dEEEE",
        MMM => "M月",
        MMMd => "M月d日",
        MMMEd => "M月d日(E)",
        MMMEEEEd => "M月d日EEEE",
        MMMMd => "M月d日",
        MMMMW => "M月第W週",
        y => "y年",
        yM => "y/M",
        yMd => "y/M/d",
        yMEd => "y/M/d(E)",
        yMEEEEd => "y/M/dEEEE",
        yMM => "y/MM",
        yMMM => "y年M月",
        yMMMd => "y年M月d日",
        yMMMEd => "y年M月d日(E)",
        yMMMEEEEd => "y年M月d日EEEE",
        yMMMM => "y年M月",
        yQQQ => "y/QQQ",
        yQQQQ => "y年QQQQ",
        yw => "Y年第w週",
    },
};

foreach my $def ( @$tests )
{
    my $locale = DateTime::Locale::FromCLDR->new( $def->{locale} );
    subtest $def->{locale} => sub
    {
        SKIP:
        {
            if( !defined( $locale ) )
            {
                diag( "Error instantiating DateTime::Locale::FromCLDR object for locale '$def->{locale}': ", DateTime::Locale::FromCLDR->error );
                skip( DateTime::Locale::FromCLDR->error, 1 );
            }
            foreach my $meth ( sort( keys( %$def ) ) )
            {
                my $ref = $locale->can( $meth );
                if( !$ref )
                {
                    fail( "The method '${meth}' is not supported by DateTime::Locale::FromCLDR" );
                    next;
                }
                my $val = $ref->( $locale );
                if( !defined( $val ) )
                {
                    is( $val, $def->{ $meth }, "${meth} -> undef" );
                }
                elsif( ref( $val ) eq 'HASH' )
                {
                    foreach my $k ( sort( keys( %$val ) ) )
                    {
                        if( ref( $val->{ $k } ) eq 'ARRAY' )
                        {
                            is_deeply( $val->{ $k }, $def->{ $meth }->{ $k }, "${meth} -> ${k} -> '" . ( defined( $def->{ $meth }->{ $k } ) ? join( "', '", @{$def->{ $meth }->{ $k }} ) : 'undef' ) . "'" );
                        }
                        else
                        {
                            is( $val->{ $k }, $def->{ $meth }->{ $k }, "${meth} -> ${k} -> '" . ( $def->{ $meth }->{ $k } // 'undef' ) . "'" );
                        }
                    }
                }
                elsif( ref( $val ) eq 'ARRAY' )
                {
                    local $" = ' ';
                    # is( "@$val", "@{$def->{$meth}}", "${meth} -> @{$def->{$meth}}" );
                    is_deeply( $val, $def->{$meth}, "${meth} -> " . dump_array( $def->{$meth} ) );
                }
            }
        };
        foreach my $format ( @{$def->{available_formats}} )
        {
            my $val = $locale->format_for( $format );
            if( !defined( $val ) &&
                $locale->error )
            {
                diag( "Error getting the available format pattern for locale $def->{locale} and format ID '${format}': ", $locale->error );
                fail( $locale->error );
                next;
            }
            is( $val, $available_formats->{ $def->{locale} }->{ $format }, "format_for( ${format} ) -> " . ( $available_formats->{ $def->{locale} }->{ $format } // 'undef' ) );
        }
    };
}

sub dump_array
{
    my $ref = shift( @_ );
    my @parts = ();
    foreach my $this ( @$ref )
    {
        if( ref( $this ) eq 'ARRAY' )
        {
            push( @parts, dump_array( $this ) );
        }
        else
        {
            push( @parts, '"' . $this . '"' );
        }
    }
    return( join( ', ', @parts ) );
}

done_testing();

__END__
