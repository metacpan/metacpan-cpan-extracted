package Date::ManipX::Almanac::Date;

use 5.010;

use strict;
use warnings;

use Astro::Coord::ECI 0.119;	# For clone() to work.
use Astro::Coord::ECI::Utils 0.119 qw{ TWOPI };
use Carp;
use Date::Manip::Date;
use Module::Load ();
use Scalar::Util ();
use Text::ParseWords ();

our $VERSION = '0.003';

use constant DEFAULT_TWILIGHT	=> 'civil';
use constant REF_ARRAY	=> ref [];
use constant REF_HASH	=> ref {};
use constant METERS_PER_KILOMETER	=> 1000;

sub new {
    my ( $class, @args ) = @_;
    return $class->_new( new => @args );
}

sub _new {
    my ( $class, $new_method, @args ) = @_;

    my @config;
    if ( @args && REF_ARRAY eq ref $args[-1] ) {
	@config = @{ pop @args };
	state $method_map = {
	    new	=> 'new_config',
	};
	$new_method = $method_map->{$new_method} // $new_method;
    }

    my ( $dmd, $from );
    if ( ref $class ) {
	$from = $class;
	$dmd = $class->dmd()->$new_method();
    } elsif ( Scalar::Util::blessed( $args[0] ) ) {
	$from = shift @args;
	$dmd = Date::Manip::Date->$new_method(
	    $from->isa( __PACKAGE__ ) ? $from->dmd() : $from
	);
    } else {
	$dmd = Date::Manip::Date->$new_method();
    }

    my $self = bless {
	dmd	=> $dmd,
    }, ref $class || $class;

    $self->_init_almanac( $from );

    @config
	and $self->config( @config );

    $self->get_config( 'sky' )
	or $self->_config_almanac_default_sky();
    defined $self->get_config( 'twilight' )
	or $self->_config_almanac_var_twilight(
	    twilight => DEFAULT_TWILIGHT );

    @args
	and $self->parse( @args );

    return $self;
}

sub new_config {
    my ( $class, @args ) = @_;
    return $class->_new( new_config => @args );
}

sub new_date {
    my ( $class, @args ) = @_;
    # return $class->_new( new_date => @args );
    return $class->new( @args );
}

sub calc {
   my ( $self, $obj, @args ) = @_;
   Scalar::Util::blessed( $obj )
       and $obj->isa( __PACKAGE__ )
       and $obj = $obj->dmd();
   return $self->dmd()->calc( $obj, @args );
}

sub cmp : method {	## no critic (ProhibitBuiltinHomonyms)
   my ( $self, $date ) = @_;
   $date->isa( __PACKAGE__ )
       and $date = $date->dmd();
   return $self->dmd()->cmp( $date );
}

sub config {
    my ( $self, @arg ) = @_;

    delete $self->{err};

    while ( @arg ) {
	my ( $name, $val ) = splice @arg, 0, 2;

	state $config = {
	    almanacconfigfile	=> \&_config_almanac_config_file,
	    defaults	=> \&_config_almanac_default,
	    elevation	=> \&_config_almanac_var_elevation,
	    language	=> \&_config_almanac_var_language,
	    latitude	=> \&_config_almanac_var_latitude,
	    location	=> \&_config_almanac_var_location,
	    longitude	=> \&_config_almanac_var_longitude,
	    name	=> \&_config_almanac_var_name,
	    sky		=> \&_config_almanac_var_sky,
	    twilight	=> \&_config_almanac_var_twilight,
	};

	if ( my $code = $config->{ lc $name } ) {
	    $code->( $self, $name, $val );
	} else {
	    $self->dmd()->config( $name, $val );
	}
    }

    return;
}

sub dmd {
    my ( $self ) = @_;
    return $self->{dmd};
}

sub err {
    my ( $self ) = @_;
    return $self->{err} // $self->dmd()->err();
}

sub get_config {
    my ( $self, @arg ) = @_;
    delete $self->{err};
    my @rslt;

    foreach my $name ( @arg ) {
	state $mine = { map { $_ => 1 } qw{
	    elevation latitude location longitude name sky twilight } };
	if ( $mine->{$name} ) {
	    my $code = $self->can( "_get_config_$name" ) || sub {
		$_[0]{config}{$name} };
	    push @rslt, scalar $code->( $self );
	} else {
	    push @rslt, $self->dmd()->get_config( $name );
	}
    }

    return 1 == @rslt ? $rslt[0] : @rslt;
}

sub input {
    my ( $self ) = @_;
    return $self->{input};
}

sub list_events {
   my ( $self, @args ) = @_;
   Scalar::Util::blessed( $args[0] )
       and $args[0]->isa( __PACKAGE__ )
       and $args[0] = $args[0]->dmd();
   return $self->dmd()->list_events( @args );
}

sub parse {
    my ( $self, $string ) = @_;
    my ( $idate, @event ) = $self->__parse_pre( $string );
    return $self->dmd()->parse( $idate ) || $self->__parse_post( @event );
}

sub parse_time {
    my ( $self, $string ) = @_;
    my ( $idate, @event ) = $self->__parse_pre( $string );
    return $self->dmd()->parse_time( $idate ) || $self->__parse_post( @event );
}

sub _config_almanac_config_file {
    # my ( $self, $name, $fn ) = @_;
    my ( $self, undef, $fn ) = @_;
    open my $fh, '<:encoding(utf-8)', $fn	## no critic (RequireBriefOpen)
	or do {
	warn "ERROR: [almanac_config_file] unable to open file $fn: $!";
	return 1;
    };
    my $config_file_processed;
    local $_ = undef;	# while (<>) ... does not localize $_.
    while ( <$fh> ) {
	m/ \S /smx
	    or next;
	m/ \A \s* [#] /smx
	    and next;
	s/ \A \s+ //smx;
	s/ \s+ \z //smx;
	my ( $name, $val ) = split qr< \s* = \s* >smx, $_, 2;
	if ( m/ \A [*] ( .* ) /smx ) {
	    # TODO retire exception for *almanac once I'm fully to new
	    # config file structure.
	    state $allow = { map { $_ => 1 } qw{ almanac } };
	    unless ( $allow->{ lc $1 } ) {
		warn "WARNING: [almanac_config_file] section '$_' ",
		    "not allowed in AlmanacConfigFile $fn line $.\n";
		last;
	    }
	} else {
	    if ( $name =~ m/ \A ConfigFile \z /smxi ) {
		$config_file_processed = 1;
	    } elsif ( $config_file_processed ) {
		warn "Config item '$name' after ConfigFile in $fn line $.\n";
	    }
	    $self->config( $name, $val );
	}
    }
    close $fh;
    return;
}

sub _config_almanac_default {
    my ( $self, $name, $val ) = @_;
    %{ $self->{config} } = ();
    delete $self->{lang};
    my $rslt = $self->dmd()->config( $name, $val ) ||
	$self->_update_language() ||
	$self->_config_almanac_default_sky() ||
	$self->_config_almanac_var_twilight( twilight => DEFAULT_TWILIGHT );
    return $rslt;
}

sub _config_almanac_default_sky {
    my ( $self ) = @_;
    return $self->_config_almanac_var_sky( sky => [ qw{
	    Astro::Coord::ECI::Sun
	    Astro::Coord::ECI::Moon
	    } ],
    );
}

sub _config_almanac_var_language {
    my ( $self, $name, $val ) = @_;
    my $rslt;
    $rslt = $self->dmd()->config( $name, $val )
	and return $rslt;

    # FIXME Doing ourselves after the embedded DMD object can result in
    # an inconsistency if DMD supports a language but we do not. But I
    # see no way to avoid this in all cases, because the embedded object
    # may have been configured in some way (such as a configuration
    # file) that we can't intercept.
    return $self->_update_language();
}

sub _update_language {
    my ( $self ) = @_;
    my $lang = lc $self->get_config( 'language' );

    exists $self->{lang}
	and $lang eq $self->{lang}
	and return 0;

    my $mod = __load_language( $lang )
	or return 1;

    $self->{lang}{lang}			= $lang;
    $self->{lang}{mod}			= $mod;
    delete $self->{lang}{obj};

    return 0;
}

# We isolate this so we can hook it to something different during
# testing if need be.
sub __load_language {
    my ( $lang ) = @_;

    my $module = "Date::ManipX::Almanac::Lang::\L$lang";
    local $@ = undef;
    eval {
	Module::Load::load( $module );
	1;
    } and return $module;
    warn "ERROR: [language] invalid: $lang\n";
    return 0;
}

sub _config_almanac_var_twilight {
    my ( $self, $name, $val ) = @_;

    my $set_val;
    if ( defined $val ) {
	if ( Astro::Coord::ECI::Utils::looks_like_number( $val ) ) {
	    $set_val = - Astro::Coord::ECI::Utils::deg2rad( abs $val );
	} else {
	    defined( $set_val = $self->_get_twilight_qual( $val ) )
		or return $self->_my_config_err(
		"Do not recognize '$val' twilight" );
	}
    }

    $self->{config}{twilight} = $val;
    $self->{config}{_twilight} = $set_val;
    $self->{config}{location}
	and $self->{config}{location}->set( $name => $set_val );

    return;
}

sub _config_var_is_eci {
    my ( undef, undef, $val ) = @_;
    ref $val
	and Scalar::Util::blessed( $val )
	and $val->isa( 'Astro::Coord::ECI' )
	or return;
    return $val;
}

# This ought to be in Astro::Coord::ECI::Utils
sub _hms2rad {
    my ( $hms ) = @_;
    my ( $hr, $min, $sec ) = split qr < : >smx, $hms;
    $_ ||= 0 for $sec, $min, $hr;
    return TWOPI * ( ( ( $sec / 60 ) + $min ) / 60 + $hr ) / 24;
}

sub _config_var_is_eci_class {
    my ( $self, $name, $val ) = @_;
    my $rslt;
    $rslt = $self->_config_var_is_eci( $name, $val )
	and return $rslt;
    if ( ! ref $val ) {
	my ( $class, @arg ) = Text::ParseWords::shellwords( $val );
	Module::Load::load( $class );
	state $factory = {
	    'Astro::Coord::ECI::Star'	=> sub {
		my ( $name, $ra, $decl, $rng ) = @_;
		return Astro::Coord::ECI::Star->new(
		    name	=> $name,
		)->position(
		    _hms2rad( $ra ),
		    Astro::Coord::ECI::Utils::deg2rad( $decl ),
		    $rng,
		);
	    },
	};
	my $code = $factory->{$class} || sub { $class->new() };
	my $obj = $code->( @arg );
	if ( $rslt = $self->_config_var_is_eci( $name, $obj ) ) {
	    return $rslt;
	}
    }
    $self->_my_config_err(
	"$val must be an Astro::Coord::ECI object or class" );
    return;
}

sub _config_almanac_var_elevation {
    my ( $self, $name, $val ) = @_;
    if ( defined $val &&
	Astro::Coord::ECI::Utils::looks_like_number( $val ) ) {
	$self->{config}{$name} = $val;
	delete $self->{config}{location};
	return;
    } else {
	return $self->_my_config_err( "\u$name must be a number" );
    }
}

sub _config_almanac_var_latitude {
    my ( $self, $name, $val ) = @_;
    if ( defined $val &&
	Astro::Coord::ECI::Utils::looks_like_number( $val ) &&
	$val >= -90 && $val <= 90 ) {
	$self->{config}{$name} = $val;
	delete $self->{config}{location};
	return;
    } else {
	return $self->_my_config_err(
	    "\u$name must be a number between -90 and 90 degrees" );
    }
}

sub _config_almanac_var_location {
    my ( $self, $name, $val ) = @_;
    my $loc;
    if ( ! defined $val ) {
	$loc = undef;
	delete @{ $self->{config} }{
	    qw{ elevation latitude longitude name } };
    } else {
	$loc = $self->_config_var_is_eci_class( $name, $val )
	    or return 1;
	my ( $lat, $lon, $ele ) = $loc->geodetic();
	$self->{config}{elevation} = $ele * METERS_PER_KILOMETER;
	$self->{config}{latitude} = Astro::Coord::ECI::Utils::rad2deg( $lat );
	$self->{config}{longitude} = Astro::Coord::ECI::Utils::rad2deg( $lon );
	$self->{config}{name} = $loc->get( 'name' );
    }

    defined $self->{config}{_twilight}
	and defined $loc
	and $loc->set( twilight => $self->{config}{_twilight} );
    $_->set( station => $loc ) for @{ $self->{config}{sky} || [] };
    $self->{config}{location} = $loc;

    # NOTE we do this because when the Lang object initializes itself it
    # consults the first sky object's station attribute (set above) to
    # figure out whether it is in the Northern or Southern hemisphere.
    # The object will be re-created when we actually try to perform a
    # parse.
    delete $self->{lang}{obj};

    return;
}

sub _config_almanac_var_longitude {
    my ( $self, $name, $val ) = @_;
    if ( defined $val &&
	Astro::Coord::ECI::Utils::looks_like_number( $val ) &&
	$val >= -180 && $val <= 180 ) {
	$self->{config}{$name} = $val;
	delete $self->{config}{location};
	return;
    } else {
	return $self->_my_config_err(
	    "\u$name must be a number between -180 and 180 degrees" );
    }
}

sub _config_almanac_var_name {
    my ( $self, $name, $val ) = @_;
    if ( defined $val ) {
	$self->{config}{$name} = $val;
    } else {
	delete $self->{config}{$name};
    }
    delete $self->{config}{location};
    return;
}

sub _config_almanac_var_sky {
    my ( $self, $name, $values ) = @_;

    my @sky;
    unless ( ref $values ) {
	if ( defined( $values ) && $values ne '' ) {
	    $values = [ $values ];
	    @sky = @{ $self->{config}{sky} || [] };
	} else {
	    $values = [];
	    @{ $self->{config}{sky} } = ();
	}
    }

    foreach my $val ( @{ $values } ) {
	my $body = $self->_config_var_is_eci_class( $name, $val )
	    or return 1;
	push @sky, $body;
	if ( my $loc = $self->_get_config_location() ) {
	    $sky[-1]->set( station => $loc );
	}
    }

    @{ $self->{config}{sky} } = @sky;

    # NOTE we do this to force re-creation of the Lang object, which
    # then picks up the new sky.
    delete $self->{lang}{obj};

    return;
}

sub _get_config_location {
    my ( $self ) = @_;
    my $cfg = $self->{config}
	or return;
    $cfg->{location}
	and return $cfg->{location};
    defined $cfg->{latitude}
	and defined $cfg->{longitude}
	or return;
    my $loc = Astro::Coord::ECI->new();
    defined $cfg->{name}
	and $loc->set( name => $cfg->{name} );
    defined $cfg->{_twilight}
	and $loc->set( twilight => $cfg->{_twilight} );
    $loc->geodetic(
	Astro::Coord::ECI::Utils::deg2rad( $cfg->{latitude} ),
	Astro::Coord::ECI::Utils::deg2rad( $cfg->{longitude} ),
	( $cfg->{elevation} || 0 ) / METERS_PER_KILOMETER,
    );
    $_->set( station => $loc ) for @{ $self->{config}{sky} || [] };

    # NOTE we do this because when the Lang object initializes itself it
    # consults the first sky object's station attribute (set above) to
    # figure out whether it is in the Northern or Southern hemisphere.
    # The object will be re-created when we actually try to perform a
    # parse.
    delete $self->{lang}{obj};

    return( $cfg->{location} = $loc );
}

sub _get_twilight_qual {
    my ( undef, $qual ) = @_;	# Invocant not used
    defined $qual
	or return $qual;
    state $twi_name = {
	civil		=> Astro::Coord::ECI::Utils::deg2rad( -6 ),
	nautical	=> Astro::Coord::ECI::Utils::deg2rad( -12 ),
	astronomical	=> Astro::Coord::ECI::Utils::deg2rad( -18 ),
    };
    return $twi_name->{ lc $qual };
}

sub _init_almanac {
    my ( $self, $from ) = @_;
    if ( Scalar::Util::blessed( $from ) && $from->isa( __PACKAGE__ ) ) {
	state $cfg_var = [ qw{ language location sky twilight } ];
	my %cfg;
	@cfg{ @{ $cfg_var } } = $from->get_config( @{ $cfg_var } );
	# We clone because these objects have state.
	# TODO this requires at least 0.118_01.
	@{ $cfg{sky} } = map { $_->clone() } @{ $cfg{sky} };
	$self->config( %cfg );
    } else {
	$self->_init_almanac_language( 1 );
	if ( my $lang = $self->get_config( 'language' ) ) {
	    $self->_config_almanac_var_language( language => $lang );
	}
	%{ $self->{config} } = ();
    }
    return;
}

sub _init_almanac_language {
    my ( $self, $force ) = @_;

    not $force
	and exists $self->{lang}
	and return;

    $self->{lang}		= {};

    return;
}

sub _my_config_err {
    my ( undef, $err ) = @_;
    warn "ERROR: [config_var] $err\n";
    return 1;
}

sub __parse_pre {
    my ( $self, $string ) = @_;
    wantarray
	or confess 'Bug - __parse_pre() must be called in list context';
    delete $self->{err};
    $self->{input} = $string;
    @{ $self->{config}{sky} || [] }
	or return $string;

    $self->{lang}{obj} ||= $self->{lang}{mod}->__new(
	sky		=> $self->{config}{sky},
    );
    return $self->{lang}{obj}->__parse_pre( $string );
}

sub __parse_post {
    my ( $self, $body, $event, undef ) = @_;
    defined $body
	and defined $event
	or return;

    $self->_get_config_location()
	or return $self->_set_err( "[parse] Location not configured" );

    my $code = $self->can( "__parse_post__$event" )
	or confess "Bug - event $event not implemented";

    # TODO support for systems that do not use this epoch.
    $body->universal( $self->secs_since_1970_GMT() );

    goto $code;
}

sub _set_err {
    my ( $self, $err ) = @_;

    $self->{err} = $err;
    return 1;
}

sub __parse_post__horizon {
    my ( $self, $body, undef, $detail ) = @_;

    my $almanac_horizon = $body->get( 'station' )->get(
	'almanac_horizon' );

    my ( $time, $which );
    while ( 1 ) {
	( $time, $which ) = $body->next_elevation( $almanac_horizon, 1 );
	$which == $detail
	    and last;
    }

    $self->secs_since_1970_GMT( $time );

    return;
}

sub __parse_post__meridian {
    my ( $self, $body, undef, $detail ) = @_;

    my ( $time, $which );
    while ( 1 ) {
	( $time, $which ) = $body->next_meridian();
	$which == $detail
	    and last;
    }

    $self->secs_since_1970_GMT( $time );

    return;
}

sub __parse_post__quarter {
    my ( $self, $body, undef, $detail ) = @_;

    my $time = $body->next_quarter( $detail );

    $self->secs_since_1970_GMT( $time );

    return;
}

sub __parse_post__twilight {
    my ( $self, $body, undef, $detail, $qual ) = @_;

    my $station = $body->get( 'station' );
    my $twilight = $station->get( 'almanac_horizon' ) + (
	$self->_get_twilight_qual( $qual ) // $station->get( 'twilight' ) );

    my ( $time, $which );
    while ( 1 ) {
	( $time, $which ) = $body->next_elevation( $twilight, 0 );
	$which == $detail
	    and last;
    }

    $self->secs_since_1970_GMT( $time );

    return;
}

# Implemented as a subroutine so I can authortest for changes. This was
# the list as of Date::Manip::Date version 6.85. The list is generated
# by tools/dmd_public_interface.
sub __date_manip_date_public_interface {
    return ( qw{
	base
	calc
	cmp
	complete
	config
	convert
	err
	get_config
	holiday
	input
	is_business_day
	is_date
	is_delta
	is_recur
	list_events
	list_holidays
	nearest_business_day
	new
	new_config
	new_date
	new_delta
	new_recur
	next
	next_business_day
	parse
	parse_date
	parse_format
	parse_time
	prev
	prev_business_day
	printf
	secs_since_1970_GMT
	set
	tz
	value
	version
	week_of_year
    } );
}

{
    local $@ = undef;
    *_my_set_subname = eval {
	require Sub::Util;
	Sub::Util->can( 'set_subname' );
    } || sub { $_[1] };
}

foreach my $method ( __date_manip_date_public_interface() ) {
    __PACKAGE__->can( $method )
	and next;
    Date::Manip::Date->can( $method )
	or next;
    no strict qw{ refs };
    *$method = _my_set_subname( $method => sub {
	    my ( $self, @arg ) = @_;
	    return $self->dmd()->$method( @arg );
	},
    );
}

1;

__END__

=head1 NAME

Date::ManipX::Almanac::Date - Methods for working with almanac dates

=head1 SYNOPSIS

 use Date::ManipX::Almanac::Date
 
 my $dmad = Date::ManipX::Almanac::Date->new();
 $dmad->config(
   latitude  =>  38.8987,     # Degrees; south is negative
   longitude => -77.0377,     # Degrees; west is negative
   elevation =>  17,          # Meters, defaults to 0
   name      =>  'White House', # Optional
 );
 $dmad->parse( 'sunrise today' );
 $dmad->printf( 'Sunrise on %d-%b-%Y is %H:%M:%S' );

=head1 DESCRIPTION

This Perl module implements a version of
L<Date::Manip::Date|Date::Manip::Date> that can parse a selection of
almanac events. These are implemented using the relevant
L<Astro::Coord::ECI|Astro::Coord::ECI> classes.

This module is B<not> an actual subclass of
L<Date::Manip::Date|Date::Manip::Date>, but holds a C<Date::Manip::Date>
object to perform a lot of the heavy lifting, and implements all its
public methods, usually by delegating directly to C<Date::Manip::Date>.
This implementation was chosen because various portions of the
C<Date::Manip::Date> interface want an honest-to-God
C<Date::Manip::Date> object, not a subclass. The decision to implement
this way may be revisited if the situation warrants.

In the meantime, be aware that if you are doing something like
instantiating a L<Date::Manip::TZ|Date::Manip::TZ> from this object, you
will have to use C<< $dmad->dmd() >>, not C<$dmad>.

B<Note> that most almanac calculations are for a specific point on the
Earth's surface. It would be nice to default this via the computer's
geolocation API, but for at least the immediate future you must specify
it explicitly. Failure to do this will result in an exception from
L<parse()|/parse> or L<parse_time()|/parse_time> if an almanac event was
actually specified.

The functional interface to L<Date::Manip::Date|Date::Manip::Date> is
not implemented. Neither is L<Date::Manip::DM5|Date::Manip::DM5>
functionality.

=head1 METHODS

This class provides the following public methods which are either in
addition to those provided by L<Date::Manip::Date|Date::Manip::Date> or
provide additional functionality. Any C<Date::Manip::Date> methods not
mentioned below should Just Work.

=head2 new

 my $dmad = Date::ManipX::Almanac::Date->new();

The arguments are the same as the L<Date::Manip::Date|Date::Manip::Date>
C<new()> arguments, but L<CONFIGURATION|/CONFIGURATION> items specific
to this class are supported.

=head2 new_date

 my $dmad_2 = $dmad->new_date();

The arguments are the same as the L<Date::Manip::Date|Date::Manip::Date>
C<new_date()> arguments, but L<CONFIGURATION|/CONFIGURATION> items
specific to this class are supported.

=head2 new_config

 my $dmad = Date::ManipX::Almanac::Date->new_config();

The arguments are the same as the L<Date::Manip::Date|Date::Manip::Date>
C<new_config()> arguments, but L<CONFIGURATION|/CONFIGURATION> items
specific to this class are supported.

=head2 calc

If the first argument is a C<Date::ManipX::Almanac::Date> object, it is
replaced by the underlying C<Date::Manip::Date> object.

=head2 cmp

If the first argument is a C<Date::ManipX::Almanac::Date> object, it is
replaced by the underlying C<Date::Manip::Date> object.

=head2 config

 my $err = $dmad->config( ... );

All L<Date::Manip::Date|Date::Manip::Date> arguments are supported, plus
those described under L<CONFIGURATION|/CONFIGURATION>, below.

=head2 dmd

 my $dmd = $dmad->dmd();

This method returns the underlying
L<Date::Manip::Date|Date::Manip::Date> object.

=head2 err

This method returns a description of the most-recent error, or a false
value if there is none. Errors detected in this package trump those in
L<Date::Manip::Date|Date::Manip::Date>.

=head2 get_config

 my @config = $dmad->get_config( ... );

All L<Date::Manip::Date|Date::Manip::Date> arguments are supported, plus
those described under L<CONFIGURATION|/CONFIGURATION>, below.

=head2 parse

 my $err = $dmad->parse( 'today sunset' );

All L<Date::Manip::Date|Date::Manip::Date> strings are supported, plus
those described under
L<ALMANAC EVENTS|Date::ManipX::Almanac::Lang/ALMANAC EVENTS> in
L<Date::ManipX::Almanac::Lang|Date::ManipX::Almanac::Lang>.

=head2 parse_time

 my $err = $dmad->parse_time( 'sunset' );

All L<Date::Manip::Date|Date::Manip::Date> strings are supported, plus
those described under
L<ALMANAC EVENTS|Date::ManipX::Almanac::Lang/ALMANAC EVENTS> in
L<Date::ManipX::Almanac::Lang|Date::ManipX::Almanac::Lang>.

=head1 CONFIGURATION

This class uses the L<Date::Manip|Date::Manip> C<config()> interface,
but adds or modifies the following configuration items:

=head2 AlmanacConfigFile

This specifies a configuration file. This is formatted like a
L<Date::Manip|Date::Manip> file, but can not have sections or any of the
configuration items allowed in them. A L<Date::Manip|Date::Manip>-style
section definition is treated as end-of-file, with a warning. This means
you can not use C<AlmanacConfigFile> to define holidays or events.

On the other hand, it can have any configuration items valid for this
class, plus any valid in the top section of a L<Date::Manip|Date::Manip>
configuration file.

Specifically, you can include other configuration files, via either
C<AlmanacConfigFile> or C<ConfigFile>. Files included by C<ConfigFile>
can include anything a L<Date::Manip|Date::Manip> config file can
(including event and holiday sections), but nothing specific to
L<Date::ManipX::Almanac|Date::ManipX::Almanac>.

=head2 ConfigFile

This only modifies the embedded L<Date::Manip::Date|Date::Manip::Date>
object, though after all the dust settles the language of the embedded
object is retrieved.

B<Caveat:> It appears to be a restriction in
L<Date::Manip::Date|Date::Manip::Date> that if you configure (at least)
L<Language|/Language> after configuring a C<ConfigFile>, any events
and/or holidays configured by the nested file will not be retained. This
makes sense when you think about it, because if you configure

 December 25 = Christmas

and then change the language to Spanish, you still can't say
C<'mediodia Navidad'> unless you load a new holiday definition that
supports this.

=head2 Defaults

In addition to its action on the superclass, this clears the location,
and populates the sky with
L<Astro::Coord::ECI::Sun|Astro::Coord::ECI::Sun> and
L<Astro::Coord::ECI::Moon|Astro::Coord::ECI::Moon>.

=head2 Elevation

This specifies the elevation of the location, in meters above sea level.

=head2 Latitude

This specifies the latitude of the location, in degrees north (positive)
or south (negative) of the Equator.

=head2 Language

In addition to its action on the superclass, this loads the almanac
event definitions for the specified language. B<Note> that this will
fail unless a L<Date::ManipX::Almanac::Lang|Date::ManipX::Almanac::Lang>
subclass has been implemented for the language.

=head2 Location

This specifies the location for which to compute the almanac. This can
be specified as an L<Astro::Coord::ECI|Astro::Coord::ECI> object, or
C<undef> to clear the location. Setting or clearing this also sets or
clears L<Elevation|/Elevation>, L<Latitude|/Latitude>,
L<Longitude|/Longitude>, and L<Name|/Name>.

=head2 Longitude

This specifies the longitude of the location, in degrees east (positive)
or west (negative) of Greenwich.

=head2 Name

This specifies the name of the location. The name is used for display
only, and is optional.

=head2 Sky

This can be specified as:

=over

=item * C<undef> or the empty string (C<''> ).

The previously-configured sky is cleared.

=item * An L<Astro::Coord::ECI|Astro::Coord::ECI> object (or subclass).

This is appended to the configured objects in the sky.

=item * The name of an L<Astro::Coord::ECI|Astro::Coord::ECI> class.

This class is instantiated, and the resultant object appended to the
configured objects in the sky.

In general, you can only usefully specify objects this way if they can
be instantiated by a call to C<new()>, without arguments.

But there is a special case for
L<Astro::Coord::ECI::Star|Astro::Coord::ECI::Star>. These can be
specified by appending name, right ascension (in h:m:s), declination (in
degrees), and optionally range in parsecs. The appended fields are
parsed using C<Text::ParseWords::shellwords()>, so star names containing
spaces can be either quoted (e.g. C<'Deneb Algedi'>) or
reverse-solidus-escaped (e.g. C<Cor\ Caroli>).

=item * A reference to an array of the above

The contents of the array B<replace> the previously-configured sky.

=back

=head2 Twilight

This specifies how far the Sun is below the horizon at the beginning or
end of twilight. You can specify this in degrees, or as one of the
following strings for convenience: C<'civil'> (6 degrees); C<'nautical'>
(12 degrees); or C<'astronomical'> (18 degrees).

The default is civil twilight.

=head1 SEE ALSO

L<Date::Manip::Date|Date::Manip::Date>.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Date-ManipX-Astro-Base>,
L<https://github.com/trwyant/perl-Date-ManipX-Astro-Base/issues/>, or in
electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2021-2022 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
