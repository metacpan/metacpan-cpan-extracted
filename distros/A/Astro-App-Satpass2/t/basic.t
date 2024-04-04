package main;

use strict;
use warnings;

use Test2::V0;
use Test2::Plugin::BailOnFail;
use Test2::Tools::LoadModule ':more';

use lib 'inc';

use My::Module::Test::App qw{ dependencies_table setup_app_mocker };

delete $ENV{TZ};

my @copier_methods =
    qw{ attribute_names clone copy create_attribute_methods init warner };

my @format_methods = ( @copier_methods, qw{
    config date_format desired_equinox_dynamical decode format gmt
    local_coord provider time_format time_formatter tz
} );

my @format_time_methods = ( @copier_methods,
    qw{ new format_datetime format_datetime_width gmt tz } );

my @geocode_methods = ( @copier_methods,
    qw{ geocode geocoder } );

my @parse_time_methods = ( @copier_methods,
    qw{ new base config delegate decode parse parse_time_absolute reset
    tz use_perltime } );

diag $_ for dependencies_table();

defined $ENV{TZ}
    and diag "\$ENV{TZ} is '$ENV{TZ}'";

require_ok 'Astro::App::Satpass2::Utils';

{
    can_ok 'Astro::App::Satpass2::Utils', qw{ __parse_class_and_args };

    my $code = Astro::App::Satpass2::Utils->can(
	'__parse_class_and_args' );

    is [ $code->( undef, 'Fubar' ) ], [ 'Fubar' ],
	q<__parse_class_and_args( 'Fubar' )>;

    is [ $code->( undef, 'Fu::Bar,baz=burfle' ) ],
	[ qw{ Fu::Bar baz burfle } ],
	q<__parse_class_and_args( 'Fu::Bar,baz=burfle' )>;

    is [ $code->( undef, 'Fu::Bar,baz=burfle=buzz' ) ],
	[ qw{ Fu::Bar baz burfle=buzz } ],
	q<__parse_class_and_args( 'Fu::Bar,baz=burfle=buzz' )>;

    {
	no warnings qw{ qw };

	is [ $code->( undef, 'Fu::Bar,baz=bur\\,fle' ) ],
	    [ qw{ Fu::Bar baz bur,fle } ],
	    q<__parse_class_and_args( 'Fu::Bar,baz=bur\\,fle' )>;

	is [ $code->( undef, 'Fu::Bar,baz="bur,fle"' ) ],
	    [ qw{ Fu::Bar baz bur,fle } ],
	    q<__parse_class_and_args( 'Fu::Bar,baz="bur,fle"' )>;
    }

}

require_ok 'Astro::App::Satpass2::Locale';

require_ok 'Astro::App::Satpass2::Locale::C';

require_ok 'Astro::App::Satpass2::Warner';

can_ok 'Astro::App::Satpass2::Warner',
    qw{ new wail warning weep whinge };

require_ok 'Astro::App::Satpass2::Copier';

can_ok 'Astro::App::Satpass2::Copier', @copier_methods;

require_ok 'Astro::App::Satpass2::Macro';

require_ok 'Astro::App::Satpass2::Macro::Command';

isa_ok 'Astro::App::Satpass2::Macro::Command',
    'Astro::App::Satpass2::Macro';

require_ok 'Astro::App::Satpass2::Macro::Code';

isa_ok 'Astro::App::Satpass2::Macro::Code',
    'Astro::App::Satpass2::Macro';

require_ok 'Astro::App::Satpass2::FormatTime';

isa_ok 'Astro::App::Satpass2::FormatTime', 'Astro::App::Satpass2::Copier';

can_ok 'Astro::App::Satpass2::FormatTime', @format_time_methods;

require_ok 'Astro::App::Satpass2::FormatTime::POSIX::Strftime';


isa_ok 'Astro::App::Satpass2::FormatTime::POSIX::Strftime',
    'Astro::App::Satpass2::FormatTime';

can_ok 'Astro::App::Satpass2::FormatTime::POSIX::Strftime',
    @format_time_methods;

instantiate( 'Astro::App::Satpass2::FormatTime::POSIX::Strftime' );

SKIP: {

    my $tests = 11;

    eval {
	require DateTime;
	require DateTime::TimeZone;
	1;
    } or skip 'DateTime and/or DateTime::TimeZone not available', $tests;

    require_ok 'Astro::App::Satpass2::FormatTime::DateTime';

    isa_ok 'Astro::App::Satpass2::FormatTime::DateTime',
	'Astro::App::Satpass2::FormatTime';

    can_ok 'Astro::App::Satpass2::FormatTime::DateTime',
	@format_time_methods;

    require_ok 'Astro::App::Satpass2::FormatTime::DateTime::Strftime';

    isa_ok 'Astro::App::Satpass2::FormatTime::DateTime::Strftime',
	'Astro::App::Satpass2::FormatTime::DateTime';

    can_ok 'Astro::App::Satpass2::FormatTime::DateTime::Strftime',
	@format_time_methods;

    instantiate( 'Astro::App::Satpass2::FormatTime::DateTime::Strftime' );

    require_ok 'Astro::App::Satpass2::FormatTime::DateTime::Cldr';

    isa_ok 'Astro::App::Satpass2::FormatTime::DateTime::Cldr',
	'Astro::App::Satpass2::FormatTime::DateTime';

    can_ok 'Astro::App::Satpass2::FormatTime::DateTime::Cldr',
	@format_time_methods;

    instantiate( 'Astro::App::Satpass2::FormatTime::DateTime::Cldr' );

}

instantiate( 'Astro::App::Satpass2::FormatTime' );

require_ok 'Astro::App::Satpass2::FormatValue';

can_ok 'Astro::App::Satpass2::FormatValue', qw{
    almanac altitude angle apoapsis apogee appulse argument_of_perigee
    ascending_node azimuth b_star_drag bodies body center classification
    clone date declination deg2rad earth eccentricity effective_date
    element_number elevation embodies ephemeris_type epoch event
    events first_derivative fixed_width floor fraction_lit has_method
    illumination inclination inertial instance international
    is_valid_title_gravity julianday latitude local_coord longitude
    magnitude maidenhead max mean_anomaly mean_motion min mma
    more_title_lines name new oid operational periapsis perigee
    period phase rad2deg range reflections reftype reset_title_lines
    revolutions_at_epoch right_ascension second_derivative semimajor
    semiminor station status time title_gravity tle type
};

instantiate( 'Astro::App::Satpass2::FormatValue' );

require_ok 'Astro::App::Satpass2::ParseTime';

isa_ok 'Astro::App::Satpass2::ParseTime', 'Astro::App::Satpass2::Copier';

can_ok 'Astro::App::Satpass2::ParseTime', @parse_time_methods;

require_ok 'Astro::App::Satpass2::ParseTime::Code';

isa_ok 'Astro::App::Satpass2::ParseTime::Code',
    'Astro::App::Satpass2::ParseTime';

can_ok 'Astro::App::Satpass2::ParseTime::Code',
    @parse_time_methods;

is eval { Astro::App::Satpass2::ParseTime::Code->delegate() },	## no critic (RequireCheckingReturnValueOfEval)
    'Astro::App::Satpass2::ParseTime::Code',
    'Code delegate is Astro::App::Satpass2::ParseTime::Code';

require_ok 'Astro::App::Satpass2::ParseTime::Date::Manip';

can_ok 'Astro::App::Satpass2::ParseTime::Date::Manip', @parse_time_methods;

my $date_manip_delegate = Astro::App::Satpass2::Utils::__date_manip_backend();
defined $date_manip_delegate
    and $date_manip_delegate =
	"Astro::App::Satpass2::ParseTime::Date::Manip::v$date_manip_delegate";

is eval { Astro::App::Satpass2::ParseTime::Date::Manip->delegate() },	## no critic (RequireCheckingReturnValueOfEval)
    $date_manip_delegate,
    'Date::Manip delegate is ' . (
	defined $date_manip_delegate ? $date_manip_delegate : 'undef' )
;

require_ok 'Astro::App::Satpass2::ParseTime::Date::Manip::v5';

isa_ok 'Astro::App::Satpass2::ParseTime::Date::Manip::v5',
    'Astro::App::Satpass2::ParseTime';

can_ok 'Astro::App::Satpass2::ParseTime::Date::Manip::v5',
    @parse_time_methods;

require_ok 'Astro::App::Satpass2::ParseTime::Date::Manip::v6';

isa_ok 'Astro::App::Satpass2::ParseTime::Date::Manip::v6',
    'Astro::App::Satpass2::ParseTime';

can_ok 'Astro::App::Satpass2::ParseTime::Date::Manip::v6',
    @parse_time_methods;

require_ok 'Astro::App::Satpass2::ParseTime::ISO8601';

isa_ok 'Astro::App::Satpass2::ParseTime::ISO8601',
    'Astro::App::Satpass2::ParseTime';

can_ok 'Astro::App::Satpass2::ParseTime::ISO8601',
    @parse_time_methods;

is eval { Astro::App::Satpass2::ParseTime::ISO8601->delegate() },	## no critic (RequireCheckingReturnValueOfEval)
    'Astro::App::Satpass2::ParseTime::ISO8601',
    'ISO8601 delegate is Astro::App::Satpass2::ParseTime::ISO8601';

SKIP: {

    my $tests = 1;

    $date_manip_delegate
	or skip 'Unable to load Date::Manip', $tests;

    instantiate( 'Astro::App::Satpass2::ParseTime',
	class => 'Astro::App::Satpass2::ParseTime::Date::Manip',
	$date_manip_delegate );
}

instantiate( 'Astro::App::Satpass2::ParseTime',
    class => 'Astro::App::Satpass2::ParseTime::ISO8601',
    'Astro::App::Satpass2::ParseTime::ISO8601' );

{

    my $want_class = $date_manip_delegate ||
	'Astro::App::Satpass2::ParseTime::ISO8601';

    instantiate( 'Astro::App::Satpass2::ParseTime', $want_class );

    instantiate( 'Astro::App::Satpass2::ParseTime',
	class => 'Astro::App::Satpass2::ParseTime::Date::Manip,
	    Astro::App::Satpass2::ParseTime::ISO8601',
	$want_class );

    instantiate( 'Astro::App::Satpass2::ParseTime',
	class => 'Date::Manip,ISO8601',
	$want_class );

    instantiate( 'Astro::App::Satpass2::ParseTime',
        class => 'ISO8601,Date::Manip',
	'Astro::App::Satpass2::ParseTime::ISO8601' );

}

require_ok 'Astro::App::Satpass2::Geocode';

can_ok 'Astro::App::Satpass2::Geocode', @geocode_methods;

SKIP: {
    my $tests = 3;

    eval {
	require Geo::Coder::OSM;
	1;
    } or skip 'Unable to load Geo::Coder::OSM', $tests;

    require_ok 'Astro::App::Satpass2::Geocode::OSM';

    can_ok 'Astro::App::Satpass2::Geocode::OSM', @geocode_methods;

    instantiate( 'Astro::App::Satpass2::Geocode::OSM' );
}

require_ok 'Astro::App::Satpass2';

can_ok 'Astro::App::Satpass2', qw{
    new alias almanac begin cd choose clear dispatch drop dump echo end
    execute exit export flare formatter geocode geodetic get height help
    init initfile list load localize location macro pass phase position
    pwd quarters run save set show sky source spacetrack st status
    system time time_parser tle unexport validate version
};

instantiate( 'Astro::App::Satpass2' );

{
    my $mocker = setup_app_mocker;
    my $app;
    my $exception = dies {
	$app = Astro::App::Satpass2->new();
    };
    is $exception, undef, 'Can instantiate Astro::App::Satpass2';

    require_ok 'Astro::App::Satpass2::Format';

    isa_ok 'Astro::App::Satpass2::Format', 'Astro::App::Satpass2::Copier';

    can_ok 'Astro::App::Satpass2::Format', @format_methods;

    require_ok 'Astro::App::Satpass2::Format::Dump';

    isa_ok 'Astro::App::Satpass2::Format::Dump', 'Astro::App::Satpass2::Format';

    instantiate(
	'Astro::App::Satpass2::Format::Dump',
	parent	=> $app,
	'Astro::App::Satpass2::Format',
    );

    can_ok 'Astro::App::Satpass2::Format::Dump', @format_methods;

    require_ok 'Astro::App::Satpass2::Wrap::Array';

    can_ok 'Astro::App::Satpass2::Wrap::Array', qw{ new dereference };

    instantiate( 'Astro::App::Satpass2::Wrap::Array', [],
	'Astro::App::Satpass2::Wrap::Array' );

    require_ok 'Astro::App::Satpass2::Format::Template';

    isa_ok 'Astro::App::Satpass2::Format::Template',
	'Astro::App::Satpass2::Format';

    can_ok 'Astro::App::Satpass2::Format', @format_methods;

    instantiate(
	'Astro::App::Satpass2::Format::Template',
	parent	=> $app,
	'Astro::App::Satpass2::Format',
    );
}

done_testing;

sub instantiate {
    my ( $class, @args ) = @_;
    my $want = @args ? pop @args : $class;
    if ( my $obj = eval { $class->new( @args ) } ) {
	@_ = ( $obj, $want );
	goto &isa_ok;
    } else {
	@_ = ( "Can't instantiate $class: $@" );
	goto &fail;
    }
}

1;

# ex: set textwidth=72 :
