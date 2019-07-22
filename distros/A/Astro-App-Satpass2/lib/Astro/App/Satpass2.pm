package Astro::App::Satpass2;

use 5.008;

use strict;
use warnings;


use Astro::App::Satpass2::Locale qw{ __localize };
use Astro::App::Satpass2::Macro::Command;
use Astro::App::Satpass2::Macro::Code;
use Astro::App::Satpass2::ParseTime;
use Astro::App::Satpass2::Utils qw{
    :ref
    __arguments expand_tilde find_package_pod
    has_method instance load_package
    my_dist_config quoter
    __parse_class_and_args
};

use Astro::Coord::ECI 0.077;			# This needs at least 0.049.
use Astro::Coord::ECI::Moon 0.077;
use Astro::Coord::ECI::Star 0.077;
use Astro::Coord::ECI::Sun 0.077;
use Astro::Coord::ECI::TLE 0.077 qw{:constants}; # This needs at least 0.059.
use Astro::Coord::ECI::TLE::Set 0.077;
# The following includes @CARP_NOT.
use Astro::Coord::ECI::Utils 0.077 qw{ :all };	# This needs at least 0.077.

{
    local $@ = undef;
    use constant HAVE_TLE_IRIDIUM	=> eval {
	require Astro::Coord::ECI::TLE::Iridium;
	Astro::Coord::ECI::TLE::Iridium->VERSION( 0.077 );
	1;
    } || 0;
}

use Clone ();
use Cwd ();
use File::Glob qw{ :glob };
use File::HomeDir;
use File::Spec;
use File::Temp;
use Getopt::Long 2.33;
use IO::File 1.14;
use IO::Handle;
use POSIX qw{ floor };
use Scalar::Util 1.26 qw{ blessed isdual openhandle };
use Text::Abbrev;
use Text::ParseWords ();	# Used only for {level1} stuff.

use constant ASTRO_SPACETRACK_VERSION => 0.105;

BEGIN {
    eval {
	load_package( 'Time::y2038' )
	    and Time::y2038->import();
	1;
    }
	or do {
	    require Time::Local;
	    Time::Local->import();
	};
}

# The following is returned by method _attribute_value() when a
# non-existent attribute is specified. We can't use undef for this,
# because the attribute might really be undef.
use constant NULL	=> bless \( my $x = undef ), 'Null';
# The canonical way to see if $rslt actually contains the above is
# NULL_REF eq ref $rslt
use constant NULL_REF	=> ref NULL;

use constant SUN_CLASS_DEFAULT	=> 'Astro::Coord::ECI::Sun';

our $VERSION = '0.040';

# The following 'cute' code is so that we do not determine whether we
# actually have optional modules until we really need them, and yet do
# not repeat the process once it is done.

my $have_time_hires;
$have_time_hires = sub {
    my $value = load_package( 'Time::HiRes' );
    $have_time_hires = sub { return $value };
    return $value;
};

my $have_astro_spacetrack;
$have_astro_spacetrack = sub {
    my $value = load_package( 'Astro::SpaceTrack' ) && eval {
	Astro::SpaceTrack->VERSION( ASTRO_SPACETRACK_VERSION );
	1;
    };
    $have_astro_spacetrack = sub { $value };
    return $value;
};

my $default_geocoder;
$default_geocoder = sub {
    my $value =
	_can_use_geocoder( 'Astro::App::Satpass2::Geocode::OSM'
	);
    $default_geocoder = sub { return $value };
    return $value;
};

sub _can_use_geocoder {
    my ( $geocoder ) = @_;
    my $pkg = load_package( $geocoder )
	or return;
    load_package( $pkg->GEOCODER_CLASS() )
	or return;
    return $pkg;
}

my $interrupted = 'Interrupted by user.';

my %twilight_def = (
    civil => deg2rad (-6),
    nautical => deg2rad (-12),
    astronomical => deg2rad (-18),
);
my %twilight_abbr = abbrev (keys %twilight_def);

#	Individual commands are defined by subroutines of the same name,
#	and having the Verb attribute. You can specify additional
#	attributes if you need to. Following are descriptions of the
#	attributes used by  this script.
#
#	Configure(configurations)
#
#	The 'Configure' attribute specifies options to be passed to
#	Getopt::Long::Configure before the options are parsed. For
#	example, if a command wants to keep unrecognized options on the
#	command you would specify:
#	    sub foo : Configure(pass_through) Verb
#
#	Tokenize(options)
#
#	The 'Tokenize' attribute specifies tokenizatino options. These
#	can not take effect until fairly late in the parse when the
#	tokens are known. These options are parsed by Getopt::Long, and
#	the value of the attribute is a reference to the options hash
#	thus generated. Possible options are:
#	  -expand_tilde - Expand tildes in the tokens. For historical
#		reasons this is the default, but it can be negated by
#		specifying -noexpand_tilde. Tildes in redirect
#		specifications are always expanded.
#
#	Tweak(options)
#
#	The 'Tweak' attribute specifies miscellaneous tweaks to
#	subroutine usage. Possible options are:
#	  -unsatisfied - Execute even inside an unsatisfied if().
#		Subroutines with this attribute may have to be aware
#		that they are being called within the scope of an
#		unsatisfied if(). All interactive methods that must be
#		called even inside an unsatisfied if() MUST have this
#		attribute. These are begin() and end(), and anything
#		that might dispatch either of these. At the moment this
#		means if() and time().
#
#	Verb(options)
#
#	The 'Verb' attribute identifies the subroutine as representing a
#	cvsx command. If it has options, they should be specified inside
#	parentheses as a whitespace-separated list of option
#	specifications appropriate for Getopt::Long. For example:
#	    sub foo : Verb(bar baz=s)
#	specifies that 'foo' is a command, taking options -bar, and
#	-baz; the latter takes a string value.

{
    my (%attr, %want);
    BEGIN {
	my $hash = sub {
	    my ( $name, $arg, @legal ) = @_;
	    my $gol = Getopt::Long::Parser->new();
	    my %opt;
	    $gol->getoptionsfromarray(
		[ split qr{ \s+ }smx, $arg ],
		\%opt,
		@legal,
	    ) or do {
		require Carp;
		Carp::croak( "Bad $name option" );
	    };
	    return \%opt;
	};
	my $list = sub {
	    return [ split qr{ \s+ }smx, $_[0] ];
	};
	%want = (
	    Configure	=> $list,
	    Tokenize	=> sub {
		my ( $arg ) = @_;
		my $opt = $hash->( Tokenize => $arg,
		    qw{ expand_tilde! } );
		exists $opt->{expand_tilde}
		    or $opt->{expand_tilde} = 1;
		return $opt;
	    },
	    Tweak	=> sub {
		my ( $arg ) = @_;
		return $hash->( Tweak => $arg,
		    qw{ unsatisfied! } );
	    },
	    Verb	=> $list,
	);
    }

    sub FETCH_CODE_ATTRIBUTES {
	return $attr{$_[0]};
    }

    sub MODIFY_CODE_ATTRIBUTES {
	my ( undef, $code, @args ) = @_;	# $pkg unused
	my @rslt;
	foreach (@args) {
	    m{ ( [^(]* ) (?: [(] \s* (.*?) \s* [)] )? \z }smx or do {
		push @rslt, $_;
		next;
	    };
	    if ( my $hdlr = $want{$1} ) {
		$attr{$code}{$1} = $hdlr->( defined $2 ? $2 : '' );
	    } else {
		push @rslt, $_;
	    }
	}
	return @rslt;
    }

    sub __get_attr {
	my ( undef, $code, $name, $dflt ) = @_;	# $pkg unused
	defined $code
	    or return;
	defined $name
	    or return $attr{$code};
	exists $attr{$code}{$name}
	    and return $attr{$code}{$name};
	return $dflt;
    }
}

my %mutator = (
    almanac_horizon	=> \&_set_almanac_horizon,
    appulse => \&_set_angle,
    autoheight => \&_set_unmodified,
    backdate => \&_set_unmodified,
    background => \&_set_unmodified,
    continuation_prompt => \&_set_unmodified,
    country => \&_set_unmodified,
    date_format => \&_set_formatter_attribute,
    desired_equinox_dynamical => \&_set_formatter_attribute,
    debug => \&_set_unmodified,
    echo => \&_set_unmodified,
    edge_of_earths_shadow => \&_set_unmodified,
    ellipsoid => \&_set_ellipsoid,
    error_out => \&_set_unmodified,
    exact_event => \&_set_unmodified,
    execute_filter => \&_set_code_ref,	# Undocumented and unsupported
    explicit_macro_delete => \&_set_unmodified,
    extinction => \&_set_unmodified,
    filter => \&_set_unmodified,
    flare_mag_day => \&_set_unmodified,
    flare_mag_night => \&_set_unmodified,
    formatter => \&_set_formatter,
    geocoder => \&_set_geocoder,
    geometric => \&_set_unmodified,
    gmt => \&_set_formatter_attribute,
    height => \&_set_distance_meters,
    horizon => \&_set_angle,
    illum	=> \&_set_illum_class,
    latitude => \&_set_angle,
    local_coord => \&_set_formatter_attribute,
    location => \&_set_unmodified,
    longitude => \&_set_angle,
    model => \&_set_model,
    max_mirror_angle => \&_set_angle,
    pass_threshold => \&_set_angle_or_undef,
    pass_variant	=> \&_set_pass_variant,
    perltime => \&_set_time_parser_attribute,
    prompt => \&_set_unmodified,
    simbad_url => \&_set_unmodified,
    singleton => \&_set_unmodified,
    spacetrack => \&_set_spacetrack,
    stdout => \&_set_stdout,
    sun	=> \&_set_sun_class,		# Only in {level1}
    time_format => \&_set_formatter_attribute,
    time_formatter => \&_set_formatter_attribute,
    time_parser => \&_set_time_parser,
##    timing => \&_set_unmodified,
    twilight => \&_set_twilight,  # 'civil', 'nautical', 'astronomical'
				# (or a unique abbreviation thereof),
				# or degrees above (positive) or below
				# (negative) the geometric horizon.
    tz => \&_set_tz,
    verbose => \&_set_unmodified, # 0 = events only
				# 1 = whenever above horizon
				# 2 = anytime
    visible => \&_set_unmodified, # 1 = only if sun down & sat illuminated
    warning => \&_set_warner_attribute,	# True to warn/die; false to carp/croak.
    warn_on_empty => \&_set_unmodified,
    				# True to have list commands warn on
				# an empty list.
    webcmd => \&_set_webcmd,	# Command to spawn for web pages
);

my %accessor = (
    date_format => \&_get_formatter_attribute,
    desired_equinox_dynamical => \&_get_formatter_attribute,
    geocoder => \&_get_geocoder,
    gmt => \&_get_formatter_attribute,
    local_coord => \&_get_formatter_attribute,
    perltime => \&_get_time_parser_attribute,
    spacetrack => \&_get_spacetrack,
    time_format => \&_get_formatter_attribute,
    time_formatter	=> \&_get_formatter_attribute,
    tz => \&_get_time_parser_attribute,
    warning => \&_get_warner_attribute,
);

foreach ( keys %mutator, qw{ initfile } ) {
    $accessor{$_} ||= sub { return $_[0]->{$_[1]} };
}

my %shower = (
    date_format => \&_show_formatter_attribute,
    desired_equinox_dynamical => \&_show_formatter_attribute,
    formatter	=> \&_show_copyable,
    geocoder	=> \&_show_copyable,
    gmt => \&_show_formatter_attribute,
    local_coord => \&_show_formatter_attribute,
    pass_variant	=> \&_show_pass_variant,
    sun		=> \&_show_sun_class,	# only in {level1}
    time_parser => \&_show_copyable,
    time_format => \&_show_formatter_attribute,
    time_formatter	=> \&_show_formatter_attribute,
);
foreach ( keys %accessor ) { $shower{$_} ||= \&_show_unmodified }

#	Attributes which must be set programmatically (i.e. not
#	interactively or in the initialization file).

my %nointeractive = map {$_ => 1} qw{
    execute_filter
    spacetrack
    stdout
};

#	Initial object contents

my %static = (
    almanac_horizon	=> 0,
    appulse => 0,
    autoheight => 1,
    background => 1,
    backdate => 0,
    continuation_prompt => '> ',
    date_format => '%a %d-%b-%Y',
    debug => 0,
    echo => 0,
    edge_of_earths_shadow => 1,
    ellipsoid => Astro::Coord::ECI->get ('ellipsoid'),
    error_out => 0,
    exact_event => 1,
    execute_filter => sub { return 1 },	# Undocumented and unsupported
##  explicit_macro_delete => 1,			# Deprecated
    extinction => 1,
    filter => 0,
    flare_mag_day => -6,
    flare_mag_night => 0,
    formatter => 'Astro::App::Satpass2::Format::Template',	# Formatter class.
##  geocoder => $default_geocoder->(),	# Geocoder class set when accessed
    geometric => 1,
    height => undef,		# meters
#   initfile => undef,		# Set by init()
    horizon => 20,		# degrees
    illum	=> SUN_CLASS_DEFAULT,
    latitude => undef,		# degrees
    longitude => undef,		# degrees
    max_mirror_angle => HAVE_TLE_IRIDIUM ? rad2deg(
	Astro::Coord::ECI::TLE::Iridium->DEFAULT_MAX_MIRROR_ANGLE ) :
	undef,
    model => 'model',
#   pending => undef,		# Continued input line if it exists.
    pass_variant	=> PASS_VARIANT_NONE,
    perltime => 0,
    prompt => 'satpass2> ',
    simbad_url => 'simbad.u-strasbg.fr',
    singleton => 0,
#   spacetrack => undef,	# Astro::SpaceTrack object set when accessed
#   stdout => undef,		# Set to stdout in new().
    time_parser => 'Astro::App::Satpass2::ParseTime',	# Time parser class.
    twilight => 'civil',
    tz => $ENV{TZ},
    verbose => 0,
    visible => 1,
    warning => 0,
    warn_on_empty => 1,
    webcmd => ''
);

my %sky_class = (
    fold_case( 'Sun' ) => [ SUN_CLASS_DEFAULT, name => 'Sun' ],
    fold_case( 'Moon' ) => [ 'Astro::Coord::ECI::Moon', name => 'Moon' ],
#    # The shape of things to come -- maybe
#    # but commented out because Astro-App-Satpass2 does not depend on
#    # these
#    ( map { fold_case( $_ ) =>
#	"Astro::Coord::ECI::VSOP87D::$_" } qw{ Mercury Venus
#	Mars Jupiter Saturn Uranus Neptune } ),
);

sub new {
    my ( $class, %args ) = @_;
    ref $class and $class = ref $class;
    my $self = {};
    $self->{bodies} = [];
    $self->{macro} = {};
    $self->{sky} = [
	SUN_CLASS_DEFAULT->new (),
	Astro::Coord::ECI::Moon->new (),
    ];
    $self->{sky_class} = { %sky_class };
    $self->{_help_module} = {
	''	=> __PACKAGE__,
	eci => 'Astro::Coord::ECI',
	moon => 'Astro::Coord::ECI::Moon',
	set => 'Astro::Coord::ECI::TLE::Set',
	sun => SUN_CLASS_DEFAULT,
	spacetrack => 'Astro::SpaceTrack',
	star => 'Astro::Coord::ECI::Star',
	tle => 'Astro::Coord::ECI::TLE',
	utils => 'Astro::Coord::ECI::Utils',
    };
    HAVE_TLE_IRIDIUM
	and $self->{_help_module}{iridium} = 'Astro::Coord::ECI::TLE::Iridium';
    bless $self, $class;
    $self->_frame_push(initial => []);
    $self->set(stdout => select());

    foreach my $name ( keys %static ) {
	exists $args{$name} or $args{$name} = $static{$name};
    }

    $self->{_warner} = Astro::App::Satpass2::Warner->new(
	warning => delete $args{warning}
    );

    foreach my $name ( qw{ formatter time_parser } ) {
	$self->set( $name => delete $args{$name} );
    }

    $self->set( %args );

    return $self;
}

sub add {
    my ( $self, @bodies ) = @_;
    foreach my $body ( @bodies ) {
	embodies( $body, 'Astro::Coord::ECI::TLE' )
	    or $self->wail(
	    'Arguments must represent Astro::Coord::ECI::TLE objects' );
    }
    push @{ $self->{bodies} }, @bodies;
    return $self;
}

sub alias : Verb() {
    my ( undef, undef, @args ) = __arguments( @_ );	# Invocant, $opt unused

    if ( @args ) {
	Astro::Coord::ECI::TLE->alias( @args );
	return;
    } else {
	my $output;
	my %alias = Astro::Coord::ECI::TLE->alias();
	foreach my $key ( sort keys %alias ) {
	    $output .= join( ' ', 'alias', $key, $alias{$key} ) . "\n";
	}
	return $output;
    }
}

# Attributes must all be on one line to process correctly under Perl
# 5.8.8.
sub almanac : Verb( choose=s@ dump! horizon|rise|set! transit! twilight! quarter! ) {
    my ( $self, $opt, @args ) = __arguments( @_ );
    _apply_boolean_default(
	$opt, 0, qw{ horizon transit twilight quarter } );

    my $almanac_start = $self->__parse_time(
	shift @args, $self->_get_today_midnight());
    my $almanac_end = $self->__parse_time (shift @args || '+1');

    $almanac_start >= $almanac_end
	and $self->wail( 'End time must be after start time' );

#	Build an object representing our ground location.

    my $sta = $self->station();

    my @almanac;

#	Iterate through the background bodies, accumulating data or
#	complaining about the lack of an almanac() method as
#	appropriate.

    my @sky = $self->__choose( $opt->{choose}, $self->{sky} )
	or $self->wail( 'No bodies selected' );

    foreach my $body ( @sky ) {
	$body->can ('almanac') or do {
	    $self->whinge(
		ref $body, ' does not support the almanac method');
	    next;
	};
	$body->set (
	    station	=> $sta,
	    twilight	=> $self->{_twilight},
	);
	push @almanac, $body->almanac_hash(
	    $almanac_start, $almanac_end);
    }

    # Localize the event descriptions if appropriate.

    foreach my $event ( @almanac ) {
	$event->{almanac}{description} = __localize(
	    text	=> [ almanac => $event->{body}->get( 'name' ),
		$event->{almanac}{event}, $event->{almanac}{detail} ],
	    default	=> $event->{almanac}{description},
	    argument	=> $event->{body},
	);
    }

#	Sort the almanac data by date, and display the results.

    return $self->__format_data(
	almanac => [
	    sort { $a->{time} <=> $b->{time} }
	    grep { $opt->{$_->{almanac}{event}} }
	    @almanac
	], $opt );

}

sub begin : Verb() Tweak( -unsatisfied ) {
    my ( $self, $opt, @args ) = __arguments( @_ );
    $self->_frame_push(
	begin => @args ? \@args : $self->{frame}[-1]{args});
    $self->{frame}[-1]{level1} = $opt->{level1};
    return;
}

# -level1 is UNSUPPORTED and may be removed without warning. It is only
# there for me to screw around with.
BEGIN {
    $ENV{SATPASS2_LEVEL1}
	and __PACKAGE__->MODIFY_CODE_ATTRIBUTES(
	\&begin,
	'Verb( level1! )',
    );
}

sub cd : Verb() {
    my ( $self, undef, $dir ) = __arguments( @_ );	# $opt unused
    if (defined($dir)) {
	chdir $dir or $self->wail("Can not cd to $dir: $!");
    } else {
	chdir File::HomeDir->my_home()
	    or $self->wail("Can not cd to home: $!");
    }
    return;
}

sub choose : Verb( epoch=s ) {
    my ( $self, $opt, @args ) = __arguments( @_ );

    if ($opt->{epoch}) {
	my $epoch = $self->__parse_time($opt->{epoch});
	$self->{bodies} = [
	map {
	    $_->select($epoch);
	}
	$self->_aggregate( $self->{bodies} )
	];
    }
    if ( @args ) {
	my @bodies = @{ $self->__choose( \@args, $self->{bodies} ) }
	    or $self->wail( 'No bodies chosen' );
	@{ $self->{bodies} } = @bodies;
    }
    return;
}

sub clear : Verb() {
    my ( $self ) = __arguments( @_ );	# $opt, @args unused
    @{$self->{bodies}} = ();
    return;
}


sub dispatch {
    my ($self, $verb, @args) = @_;

    defined $verb or return;

    my $unsatisfied = $self->{_unsatisfied_if};

    if ( $self->{macro}{$verb} ) {
	$unsatisfied
	    and return;
	return $self->_macro( $verb, @args );
    }

    my $code;
    $verb =~ s/ \A core [.] //smx;
    $code = $self->can($verb)
	and $self->__get_attr($code, 'Verb')
	or $self->wail("Unknown interactive method '$verb'");

    my $rslt;
    $unsatisfied
	and not $self->__get_attr( $code, Tweak => {} )->{unsatisfied}
	or $rslt = $code->( $self, @args );

    defined $rslt
	and $rslt =~ s/ (?<! \n ) \z /\n/smx;

    foreach my $code (
	reverse @{ delete( $self->{frame}[-1]{post_dispatch} ) || [] }
    ) {
	my $append;
	defined( $append = $code->( $self ) )
	    and $rslt .= $append;
    }
    return $rslt;
}

{
    my %special = (
	begin	=> sub {
	    my ( $self, $verb ) = @_;
	    $self->_is_interactive()
		or $self->wail(
		"'begin' forbidden in non-interactive $verb()" );
	    return;
	},
	end	=> sub {
	    my ( $self, $verb ) = @_;
	    $self->wail( "'end' forbidden in $verb()" );
	},
    );

    sub _dispatch_check {
	my ( $self, $verb, $disp ) = @_;
	my $code = $special{$disp}
	    or return;
	return $code->( $self, $verb, $disp );
    }
}

sub drop : Verb() {
    my ( $self, undef, @args ) = __arguments( @_ );	# $opt unused

    @args
	or return;

    my @bodies = @{
	$self->__choose( { invert => 1 }, \@args, $self->{bodies} ) }
	or $self->wail( 'No bodies left' );

    @{ $self->{bodies} } = @bodies;

    return;
}

sub dump : method Verb() {	## no critic (ProhibitBuiltInHomonyms)
    my ( $self, undef, @arg ) = __arguments( @_ );	# $opt unused
    my @dump;
    @arg
	or push @dump, $self;
    local $self->{time_parser} = ref $self->{time_parser};
    foreach ( @arg ) {
	if ( ref ) {
	    push @dump, $_;
	} elsif ( 'twilight' eq $_ ) {
	    push @dump, { map { $_ => $self->{$_} } qw{ twilight _twilight } };
	} else {
	    push @dump, $self->__choose( [ $_ ], $self->{bodies} );
	    if ( defined( my $inx = $self->_find_in_sky( $_ ) ) ) {
		push @dump, $self->{sky}[$inx];
	    }
	}
    }
    return $self->_get_dumper()->( @dump );
}

sub echo : Verb( n! ) {
    my ( undef, $opt, @args ) = __arguments( @_ );	# Invocant unused
    my $output = join( ' ', @args );
    $opt->{n} or $output .= "\n";
    return $output;
}

sub end : Verb() Tweak( -unsatisfied ) {
    my ( $self ) = __arguments( @_ );	# $opt, @args unused

    $self->{frame}[-1]{type} eq 'begin'
	or $self->wail( 'End without begin' );
    $self->_frame_pop();
    return;
}

# Tokenize and execute one or more commands. Optionally (and
# unsupportedly) you can pass a code reference as the first argument.
# This code reference will be used to fetch commands when the arguments
# are exhausted. IF you pass your own code reference, we return after
# the first command, since the code reference is presumed to manage the
# input stream itself.
sub execute {
    my ($self, @args) = @_;
    my $accum;
    my $in;
    my $extern;
    if ( CODE_REF eq ref $args[0] ) {
	$extern = shift @args;
	$in = sub {
	    my ( $prompt ) = @_;
	    @args and return shift @args;
	    return $extern->( $prompt );
	};
    } else {
	$in = sub { return shift @args };
    }
    @args = map { split qr{ (?<= \n ) }smx, $_ } @args;
    while ( defined ( local $_ = $in->( $self->get( 'prompt' ) ) ) ) {
	$self->{echo} and $self->whinge($self->get( 'prompt' ), $_);
	m/ \A \s* [#] /smx and next;
	my $stdout = $self->{frame}[-1]{stdout};
	my ($args, $redirect) = $self->_tokenize(
	    { in => $in }, $_, $self->{frame}[-1]{args});
	# NOTICE
	#
	# The execute_filter attribute is undocumented and unsupported.
	# It exists only so I can scavenge the user's initialization
	# file for the (possible) Space Track username and password, to
	# be used in testing, without being subject to any other
	# undesired side effects, such as running a prediction and
	# exiting. If I change my mind on how or whether to do this,
	# execute_filter will be altered or retracted without warning,
	# much less a deprecation cycle. If you have a legitimate need
	# for this functionality, contact me.
	#
	# YOU HAVE BEEN WARNED.
	$self->{execute_filter}->( $self, $args ) or next;
	@{ $args } or next;
	if ($redirect->{'>'}) {
	    my ($mode, $name) = map {$redirect->{'>'}{$_}} qw{mode name};
	    my $fh = IO::File->new($name, $mode)
		or $self->wail("Unable to open $name: $!");
	    $stdout = $fh;
	}

	# {localout} is the output to be used for this command. It goes
	# in the frame stack because our command may start a new frame,
	# and _frame_push() needs to have a place to get the correct
	# output handle.

	my $frame_depth = $#{$self->{frame}};
	$self->{frame}[-1]{localout} = $stdout;

	my $output = $self->dispatch( @$args );

	$#{$self->{frame}} >= $frame_depth
	    and delete $self->{frame}[ $frame_depth ]{localout};

	$self->_execute_output( $output,
	    defined $stdout ? $stdout : \$accum );

	$extern and last;
    }
    return $accum;
}

#	$satpass2->_execute(...);
#
#	This subroutine calls $satpass2->execute() once for each
#	argument. The call is wrapped in an eval{}; if an exception
#	occurs the user is notified via warn.

sub _execute {
    my ($self, @args) = @_;
    my $in = CODE_REF eq ref $args[0] ? shift @args : sub { return shift
	@args };
    while ( @args ) {
	local $SIG{INT} = sub {die "\n$interrupted\n"};
	eval {
	    $self->execute( $in, shift @args );
	    1;
	} or warn $@;	# Not whinge, since presumably we already did.
    }
    return;
}

#	$satpass2->_execute_output( $output, $stdout );
#
#	If $output is defined, sends it to $stdout.

sub _execute_output {
    my ( undef, $output, $stdout ) = @_;	# Invocant unused
    defined $output or return;
    my $ref = ref $stdout;
    if ( !defined $stdout ) {
	return $output;
    } elsif ( SCALAR_REF eq $ref ) {
	$$stdout .= $output;
    } elsif ( CODE_REF eq $ref ) {
	$stdout->( $output );
    } elsif ( ARRAY_REF eq $ref ) {
	push @$stdout, split qr{ (?<=\n) }smx, $output;
    } else {
	$stdout->print( $output );
    }
    return;
}

sub exit : method Verb() {	## no critic (ProhibitBuiltInHomonyms)
    my ( $self ) = __arguments( @_ );	# $opt, @args unused

    $self->_frame_pop(1);	# Leave only the inital frame.

    eval {	## no critic (RequireCheckingReturnValueOfEval)
	no warnings qw{exiting};
	last SATPASS2_EXECUTE;
    };
    $self->whinge("$@Exiting Perl");
    exit;

}

sub export : Verb() {
    my ( $self, undef, $name, @args ) = __arguments( @_ );	# $opt unused
    if ($mutator{$name}) {
	@args and $self->set ($name, shift @args);
	$self->{exported}{$name} = 1;
    } else {
	@args or $self->wail( 'You must specify a value' );
	$self->{exported}{$name} = shift @args;
    }
    return;
}

# Attributes must all be on one line to process correctly under Perl
# 5.8.8.
sub flare : Verb( algorithm=s am! choose=s@ day! dump! pm! questionable|spare! quiet! tz|zone=s )
{
    my ( $self, $opt, @args ) = __arguments( @_ );
    HAVE_TLE_IRIDIUM
	or $self->wail( 'Astro::Coord::ECI::TLE::Iridium not available' );
    my $pass_start = $self->__parse_time (
	shift @args, $self->_get_today_noon());
    my $pass_end = $self->__parse_time (shift @args || '+7');
    $pass_start >= $pass_end
	and $self->wail( 'End time must be after start time' );
    my $sta = $self->station();

    my $max_mirror_angle = deg2rad( $self->{max_mirror_angle} );
    my $horizon = deg2rad ($self->{horizon});
    my $twilight = $self->{_twilight};
    my @flare_mag = ($self->{flare_mag_night}, $self->{flare_mag_day});
    my $zone = exists $opt->{tz} ? $opt->{tz} :
	$self->{formatter}->gmt() ? 0 :
	$self->{formatter}->tz() || undef;

    _apply_boolean_default(
	$opt, 0, qw{ am day pm } );

#	Decide which model to use.

    my $model = $self->{model};

#	Select only the bodies capable of flaring.

    my @active;
    foreach my $tle ( $self->_aggregate(
	    scalar $self->__choose( $opt->{choose}, $self->{bodies} )
	) )
    {
	$tle->can_flare( $opt->{questionable} ) or next;
	$tle->set (
	    algorithm	=> $opt->{algorithm} || 'fixed',
	    backdate	=> $self->{backdate},
	    edge_of_earths_shadow => $self->{edge_of_earths_shadow},
	    horizon	=> $horizon,
	    twilight	=> $twilight,
	    model	=> $model,
	    am		=> $opt->{am},
	    max_mirror_angle => $max_mirror_angle,
	    day		=> $opt->{day},
	    pm		=> $opt->{pm},
	    extinction	=> $self->{extinction},
	    station	=> $sta,
	    zone	=> $zone,
	);
	push @active, $tle;
    }
    @active or $self->wail( 'No bodies capable of flaring' );

    my @flares;
    foreach my $tle (@active) {
	eval {
	    push @flares, $tle->flare( $pass_start, $pass_end );
	    1;
	} or do {
	    $@ =~ m/ \Q$interrupted\E /smxo and $self->wail($@);
	    $opt->{quiet} or $self->whinge($@);
	};
    }

    return $self->__format_data(
	flare => [
	    sort { $a->{time} <=> $b->{time} }
	    grep { $_->{magnitude} <= $flare_mag[
	    ( $_->{type} eq 'day' ? 1 : 0 ) ] }
	    @flares
	], $opt );

}

sub formatter : Verb() {
    splice @_, ( HASH_REF eq ref $_[1] ? 2 : 1 ), 0, 'formatter';
    goto &_helper_handler;
}

sub geocode : Verb( debug! ) {
    my ( $self, $opt, $loc ) = __arguments( @_ );

    my $set_loc;
    if ( defined $loc ) {
	$set_loc = 1;
    } else {
	$loc = $self->get( 'location' );
    }

    my $geocoder = $self->_helper_get_object( 'geocoder' );

    my @rslt = $geocoder->geocode( $loc );

    my $output;
    if ( @rslt == 1 ) {
	$set_loc
	    and $self->set( location => $rslt[0]{description} );
	$self->set( map { $_ => $rslt[0]{$_} } qw{ latitude
	    longitude } );
	$output .= $self->show(
	    ( $set_loc ? 'location' : () ), qw{latitude longitude} );
	if ( $self->get( 'autoheight' ) ) {
	    $opt->{geocoding} = 1;
	    $output .= $self->_height_us($opt);
	}
    } else {
	foreach my $poi ( @rslt ) {
	    $output .= join ' ', map { $poi->{$_} } qw{ latitude
	    longitude description };
	    $output =~ s/ (?: \A | (?<! \n ) ) \z /\n/smx;
	}
    }
    return $output;
}

sub geodetic : Verb() {
    my ( $self, undef, $name, $lat, $lon, $alt ) = __arguments( @_ ); # $opt unused
    @_ == 5 or $self->wail( 'Want exactly four arguments' );
    my $body = Astro::Coord::ECI::TLE->new(
	name => $name,
	id => '',
	model => 'null',
    )->geodetic(
	deg2rad( $self->__parse_angle( $lat ) ),
	deg2rad( $self->__parse_angle( $lon ) ),
	$self->__parse_distance( $alt ),
    );
    push @{ $self->{bodies} }, $body;
    return;
}

sub get {
    my ($self, $name) = @_;
    $self->_attribute_exists( $name );
    $self->_deprecation_notice( attribute => $name );
    return $accessor{$name}->($self, $name);
}

sub height : Verb( debug! ) {
    return _height_us( __arguments( @_ ) );
}

sub _height_us {
    my ($self, $opt, @args) = @_;
    $self->_load_module ('Geo::WebService::Elevation::USGS');
    my $eq = Geo::WebService::Elevation::USGS->new(
	places => 2,	# Service returns unreasonable precision
	units => 'METERS',	# default for service is 'FEET'
	croak	=> 0,		# Handle our own errors
    );
    @args or push @args, $self->get('latitude'), $self->get('longitude');
    my $output;
    my ( $rslt ) = $eq->elevation(@args);
    if ( $eq->is_valid( $rslt ) ) {
	$self->set( height => $rslt->{Elevation} );
    } else {
	$opt->{geocoding}
	    or $self->wail( $eq->error() || 'No valid result found' );
	$self->set( height => 0 );
	$output .= "# Unable to obtain height. Setting to 0\n";
    }
    $output .= $self->show( 'height' );
    return $output;
}

sub help : Verb() {
    my ( $self, undef, $arg ) = __arguments( @_ );	# $opt unused
    defined $arg
	or $arg = '';
    defined $self->{_help_module}{$arg}
	and $arg = $self->{_help_module}{$arg};
    if ( my $cmd = $self->_get_browser_command() ) {
	my $kind = $arg =~ m/ - /smx ? 'release' : 'pod';
	$self->system( $cmd,
	    "https://metacpan.org/$kind/$arg" );
    } else {

	my $os_specific = "_help_$^O";
	if (__PACKAGE__->can ($os_specific)) {
	    return __PACKAGE__->$os_specific ();
	} elsif ( load_package( 'Pod::Usage' ) ) {
	    my @ha;
	    if ( defined( my $path = find_package_pod( $arg ) ) ) {
		push @ha, '-input' => $path;
	    }
	    my $stdout = $self->{frame}[-1]{localout};
	    if (openhandle $stdout && !-t $stdout) {
		push @ha, -output => $stdout;
	    }
	    Pod::Usage::pod2usage (
		-verbose => 2, -exitval => 'NOEXIT', @ha);
	} else {
	    # This should never happen, since Pod::Usage is core
	    # since 5.6. On the other hand we have not declared it
	    # as a dependency, and some downstream packagers seem to
	    # think they know more than the author what should be in
	    # a package.
	    return <<'EOD'
No help available; Pod::Usage can not be loaded.
EOD
	}
    }
    return;
}

# The call to this is generated dynamically above, and there is no way
# Perl::Critic can find it.
sub _help_MacOS {	## no critic (ProhibitUnusedPrivateSubroutines)
    return <<'EOD';

Normally, we would display the documentation for the satpass2
script here. But unfortunately this depends on the ability to
spawn the perldoc command, and we do not have this ability under
Mac OS 9 and earlier. You can find the same thing online at
https://metacpan.org/release/Astro-App-Satpass2

EOD
}

{
    # This hash specifies the specific grammar passed to
    # __infix_engine(). The keys are:
    # {done} optional; called when parse is complete.
    # {oper} defines operators. Values are hash refs with:
    #	{handler} code that handles operator;
    #	{validation} name of validation style (see {vld} below).
    # {vld} defines operator validation. There must be a key for each
    #	distinct value of {oper}{$name}{validation}.
    # NOTE WELL
    # Because if() has the Tweak( -unsatisfied ) attribute, any
    # operators that have side effects will need to be aware of whether
    # they are running inside an unsatisfied if().
    my %define = (
	done	=> sub {
	    # my ( $self, $def, $ctx, $tokens ) = @_;
	    my ( $self, undef, $ctx ) = @_;
	    @{ $ctx }
		and $self->wail( q<No 'then'> );;
	    return;
	},
	oper	=> {
	    '('	=> {
		handler	=> sub {
		    my ( $self, $def, $ctx, $tokens ) = @_;
		    my $want = delete $ctx->[-1]{want};
		    defined $want
			or $want = 1;
		    push @{ $ctx }, {
			want	=> $want,
			value	=> [],
		    };
		    $ctx->[-2]{shortcut}
			and $ctx->[1]{shortcut} = $ctx->[-2]{shortcut};
		    my $depth = @{ $ctx };
		    while ( $depth <= @{ $ctx } ) {
			$self->_infix_engine_dispatch( $def, $ctx, $tokens );
		    }
		    return;
		},
	    },
	    ')'	=> {
		handler	=> sub {
		    # my ( $self, $def, $ctx, $tokens ) = @_;
		    my ( $self, undef, $ctx ) = @_;
		    @{ $ctx }
			or $self->wail( 'Unpaired right parentheses' );
		    $ctx->[-1]{want} == @{ $ctx->[-1]{value} }
			or $self->wail(
			"Expected $ctx->[-1]{want} value(s), got " .
			scalar @{ $ctx->[-1]{value} } );
		    push @{ $ctx->[-2]{value} }, @{ $ctx->[-1]{value} };
		    pop @{ $ctx };
		    return;
		},
	    },
	    and	=> {
		handler	=> sub {
		    my ( $self, $def, $ctx, $tokens ) = @_;
		    $ctx->[-1]{value}[-1]
			or $ctx->[-1]{shortcut} = 1;
		    $self->_infix_engine_dispatch( $def, $ctx, $tokens );
		    # For some reason the following has to be done in
		    # two statements, or both operands remain on the
		    # stack.
		    my $ro = pop @{ $ctx->[-1]{value} };
		    $ctx->[-1]{value}[-1] &&= $ro
			unless delete $ctx->[-1]{shortcut};
		    return;
		},
		validation	=> 'infix',
	    },
	    attr	=> {
		handler	=> sub {
		    # my ( $self, $def, $ctx, $tokens ) = @_;
		    my ( $self, undef, $ctx, $tokens ) = @_;
		    my $attr = shift @{ $tokens };
		    my $val;
		    $ctx->[-1]{shortcut}
			or $val = $self->_attribute_value( $attr );
		    NULL_REF eq ref $val
			and $self->wail( "No such attribute as '$attr'" );
		    push @{ $ctx->[-1]{value} }, $val;
		    return;
		},
		validation	=> 'prefix',
	    },
	    env	=> {
		handler	=> sub {
		    # my ( $self, $def, $ctx, $tokens ) = @_;
		    my ( undef, undef, $ctx, $tokens ) = @_;
		    my $name = shift @{ $tokens };
		    my $val;
		    $ctx->[-1]{shortcut}
			or $val = $ENV{$name};
		    push @{ $ctx->[-1]{value} }, $val;
		    return;
		},
		validation	=> 'prefix',
	    },
	    loaded	=> {
		handler	=> sub {
		    # my ( $self, $def, $ctx, $tokens ) = @_;
		    my ( $self, undef, $ctx, $tokens ) = @_;
		    my $name = shift @{ $tokens };
		    my @loaded;
		    $ctx->[-1]{shortcut}
			or @loaded = $self->__choose(
			{ bodies	=> 1 },
			[ $name ],
		    );
		    push @{ $ctx->[-1]{value} }, scalar @loaded;
		    return;
		},
		validation	=> 'prefix',
	    },
	    not	=> {
		handler	=> sub {
		    my ( $self, $def, $ctx, $tokens ) = @_;
		    $self->_infix_engine_dispatch( $def, $ctx, $tokens );
		    $ctx->[-1]{value}[-1] = ! $ctx->[-1]{value}[-1];
		    return;
		},
		validation	=> 'prefix',
	    },
	    or	=> {
		handler	=> sub {
		    my ( $self, $def, $ctx, $tokens ) = @_;
		    $ctx->[-1]{value}[-1]
			and $ctx->[-1]{shortcut} = 1;
		    $self->_infix_engine_dispatch( $def, $ctx, $tokens );
		    # For some reason the following has to be done in
		    # two statements, or both operands remain on the
		    # stack.
		    my $ro = pop @{ $ctx->[-1]{value} };
		    $ctx->[-1]{value}[-1] ||= $ro
			unless delete $ctx->[-1]{shortcut};
		    return;
		},
		validation	=> 'infix',
	    },
	    os	=> {
		handler	=> sub {
		    # my ( $self, $def, $ctx, $tokens ) = @_;
		    my ( undef, undef, $ctx, $tokens ) = @_;
		    my $re = qr< \A \Q$^O\E \z >smxi;
		    my $rslt = 0;
		    my $name = shift @{ $tokens };
		    unless ( $ctx->[-1]{shortcut} ) {
			foreach my $os ( split qr< [|] >smx, $name ) {
			    $os =~ $re
				or next;
			    $rslt = 1;
			    last;
			}
		    }
		    push @{ $ctx->[-1]{value} }, $rslt;
		    return;
		},
		validation	=> 'prefix',
	    },
	    then	=> {
		handler	=> sub {
		    # my ( $self, $def, $ctx, $tokens ) = @_;
		    my ( $self, undef, $ctx, $tokens ) = @_;
		    1 == @{ $ctx }
			or $self->wail( 'Unclosed left parentheses' );
		    my $last = pop @{ $ctx };
		    my @arg = splice @{ $tokens }, 0
			or return;
		    $self->_dispatch_check( if => $arg[0] );
		    unless ( $last->{value}[-1] ) {
			$self->{_unsatisfied_if} = 1;
			$self->_add_post_dispatch( sub {
				my ( $self ) = @_;
				delete $self->{_unsatisfied_if};
				return;
			    },
			);
		    }
		    return $self->dispatch( @arg );
		},
		validation	=> 'infix',
	    },
	},
	vld	=> {
	    infix	=> sub {
		# my ( $self, $def, $ctx, $tkn, $tokens ) = @_;
		my ( $self, undef, $ctx, $tkn, $tokens ) = @_;
		@{ $ctx->[-1]{value} }
		    or $self->wail( "'$tkn' requires a left argument" );
		@{ $tokens }
		    or $self->wail( "'$tkn' requires a right argument" );
		return;
	    },
	    prefix	=> sub {
		# my ( $self, $def, $ctx, $tkn, $tokens ) = @_;
		my ( $self, undef, undef, $tkn, $tokens ) = @_;
		@{ $tokens }
		    or $self->wail( "'$tkn' requires an argument" );
		return;
	    },
	},
    );

    sub if : method Verb() Tweak( -unsatisfied ) {	## no critic (ProhibitBuiltInHomonyms)
	my ( $self, @args ) = @_;
	@args
	    or $self->wail( 'Arguments required' );
	my @ctx = ( {
		value	=> [],
	    } );
	return $self->__infix_engine( \%define, \@ctx, @args );
    }
}

sub init {
    my ( $self, @args ) = @_;

    my $opt = HASH_REF eq ref $args[0] ? shift @args : {};
    my $init_file = shift @args;

    $self->{initfile} = undef;

    foreach (
	defined $init_file ? (
	    sub {
		# A missing init file is only an error if it was
		# specified explicitly.
		-e $init_file
		    and not -d _
		    or $self->wail(
			"Initialization file $init_file not found, or is a directory"
		    );
		return ( $init_file, $opt->{level1} )
	    },
	) : (
	    sub { return $ENV{SATPASS2INI} },
	    sub { $self->initfile( { quiet => 1 } ) },
	    sub { return ( $ENV{SATPASSINI}, 1 ) },
	    \&_init_file_01,
	)
    ) {

	my ( $fn, $level1 ) = $_->($self);
	my $reader = $self->_file_reader( $fn, { optional => 1 } )
	    or next;
	$self->{initfile} = $fn;
	return $self->source( { level1 => $level1 }, $reader );

    }

    return;
}


sub initfile : Verb( create-directory! quiet! ) {
    my ( $self, $opt ) = __arguments( @_ );	# @args unused

    my $init_dir = my_dist_config(
	{ create => $opt->{'create-directory'} } );

    defined $init_dir
	or do {
	$opt->{quiet} and return;
	$self->wail(
	    'Init file directory not found' );
    };

    return File::Spec->catfile( $init_dir, 'satpass2rc' );
}

# This is a generalized infix expression engine. It does not implement
# operator precedence and is therefore very small. The arguments are:
#   - $self is the invocant, which must be an
#     Astro::App::Satpass2::Copier.
#   - $def is the hash that defines the grammar. This needs keys {oper}
#     and {validation}. Key {oper} defines operators, and needs key
#     {handler} to be a code reference, and {vld} to be the name of a
#     validation style, meaning a string that must be a key in the
#     {validation} sub-hash. The values in {validation} are code
#     references.
#   - $ctx is context for the operations and is not used by the engine
#     itself. See if() for an example.
#   - @tokens are the tokens to be evaluated by the engine.
sub __infix_engine {
    my ( $self, $def, $ctx, @tokens ) = @_;
    @tokens
	or $self->wail( 'Nothing to compute' );
    my $rslt;
    while ( @tokens ) {
	$rslt = $self->_infix_engine_dispatch( $def, $ctx, \@tokens );
    }
    $def->{done}
	and $def->{done}->( $self, $def, $ctx, \@tokens );
    return $rslt;
}

sub _infix_engine_dispatch {
    my ( $self, $def, $ctx, $tokens ) = @_;
    @{ $tokens }
	or return;
    my $tkn = shift @{ $tokens };
    my $info = $def->{oper}{$tkn}
	or $self->wail( "Unrecognized token '$tkn'" );
    $info->{validation}
	and $def->{vld}{ $info->{validation} }->(
	$self, $def, $ctx, $tkn, $tokens );
    return $info->{handler}->( $self, $def, $ctx, $tokens );
}

#	$file_name = _init_file_01()
#
#	This subroutine returns the first alternate init file name,
#	which is the standard name for the Astro-satpass 'satpass'
#	script. If called in list context it returns not only the name,
#	but a 1 to tell the caller this is a 'level1' file.

sub _init_file_01 {
    my $inifn = $^O eq 'MSWin32' || $^O eq 'VMS' || $^O eq 'MacOS' ?
	'satpass.ini' : '.satpass';
    my $inifile = $^O eq 'VMS' ? "SYS\$LOGIN:$inifn" :
	$^O eq 'MacOS' ? $inifn :
	$ENV{HOME} ? "$ENV{HOME}/$inifn" :
	$ENV{LOGDIR} ? "$ENV{LOGDIR}/$inifn" :
	$ENV{USERPROFILE} ? "$ENV{USERPROFILE}" : undef;
    return wantarray ? ( $inifile, 1 ) : $inifile;
}

sub list : Verb( choose=s@ ) {
    my ( $self, $opt, @args ) = __arguments( @_ );

    @args
	and not $opt->{choose}
	and $opt->{choose} = \@args;
    my @bodies = $self->__choose( $opt->{choose}, $self->{bodies} );

    @bodies
	and return $self->__format_data(
	    list => \@bodies, $opt );

    $self->{warn_on_empty}
	and $self->whinge( 'The observing list is empty' );

    return;
}

sub load : Verb( verbose! ) {
    my ( $self, $opt, @names ) = __arguments( @_ );
    @names or $self->wail( 'No file names specified' );

    my $attrs = {
	illum	=> $self->get( 'illum' ),
	model	=> $self->get( 'model' ),
	sun	=> $self->_sky_object( 'sun' ),
    };

    foreach my $fn ( @names ) {
	$opt->{verbose} and warn "Loading $fn\n";
	my $data = $self->_file_reader( $fn, { glob => 1 } );
	$self->__add_to_observing_list(
	    Astro::Coord::ECI::TLE->parse( $attrs, $data ) );
    }
    return;
}

sub localize : Verb( all|except! ) {
    my ( $self, $opt, @args ) = __arguments( @_ );

    foreach my $name ( @args ) {
	$self->_attribute_exists( $name );
    }

    if ( $opt->{all} ) {
	my %except = map { $_ => 1 } @args;
	@args = grep { ! $except{$_} } sort keys %mutator;
    }

    foreach my $name ( @args ) {
	$self->_localize( $name );
    }

    return;
}

sub _localize {
    my ( $self, $key ) = @_;

    my $val = exists $self->{$key} ?
	$self->{$key} :
	$self->get( $key );
    my $clone = ( blessed( $val ) && $val->can( 'clone' ) ) ?
	$val->clone() :
	ref $val ? Clone::clone( $val ) : $val;

    $self->{frame}[-1]{local}{$key} = $val;
    if ( exists $self->{$key} ) {
	$self->{$key} = $clone;
    } else {
	$self->set( $key => $clone );
    }

    return;
}

sub location : Verb( dump! ) {
    my ( $self, $opt ) = __arguments( @_ );
    return $self->__format_data(
	location => $self->station(), $opt );
}

{

    # TODO the %mac_cmd hash is only needed for level1 compatibility.
    # Once that goes away, it can too PROVIDED we also drop the
    # subcommand defaulting functionality.
    my %mac_cmd;
    {
	my $stb = __PACKAGE__ . '::';
	my @cmdnam;
	{
	    no strict qw{ refs };
	    foreach my $entry ( keys %{ $stb } ) {
		$entry =~ m/ \A _macro_ ( \w+ ) /smx
		    or next;
		# Strictly speaking I should make sure the {CODE} slot
		# is occupied here.
		push @cmdnam, $1;
	    }
	}
	my %abbr = abbrev(@cmdnam);
	foreach (keys %abbr) {
	    $mac_cmd{'-' . $_} = $abbr{$_};
	}
	foreach (@cmdnam) {
	    $mac_cmd{$_} = $_;
	}
    }

    # NOTE that we must not define command options here, but on the
    # individual _macro_* methods. Or at least we must not define any
    # command options here that get passed to the _macro_* methods.
    sub macro : Verb() {
	my ( $self, undef, @args ) = __arguments( @_ );	# $opt unused
	my $cmd;
	if (!@args) {
	    $cmd = 'brief';
	} elsif ($mac_cmd{$args[0]}) {
	    $cmd = $mac_cmd{shift @args};
	} elsif (@args > 1) {
	    $cmd = 'define';
	} else {
	    $cmd = 'list';
	}

	my $code = $self->can( "_macro_$cmd" )
	    or $self->wail( "Subcommand '$cmd' unknown" );
	return $code->( $self, @args );
    }

}

# Calls to the following _macro_... methods are generated dynamically
# above, so there is no way Perl::Critic can find them.
sub _macro_brief : Verb() {	## no critic (ProhibitUnusedPrivateSubroutines)
    my ( $self, undef, @args ) = __arguments( @_ );
    my $output;
    foreach my $name (sort @args ? @args : keys %{$self->{macro}}) {
	$self->{macro}{$name} and $output .= $name . "\n";
    }
    return $output;
}

sub _macro_define : Verb() {	## no critic (ProhibitUnusedPrivateSubroutines)
    my ( $self, undef, $name, @args ) = __arguments( @_ );
    my $output;
    defined $name
	or $self->wail( 'You must provide a name for the macro' );
    @args
	or $self->wail( 'You must provide a definition for the macro' );
    $name !~ m/ \W /smx
	and $name !~ m/ \A _ /smx
	or $self->wail("Invalid macro name '$name'");

    $self->{macro}{$name} =
	Astro::App::Satpass2::Macro::Command->new(
	    name	=> $name,
	    parent	=> $self,
	    def		=> [ _unescape( @args ) ],
	    generate	=> \&_macro_define_generator,
	    level1	=> $self->{frame}[-1]{level1},
	    warner	=> $self->{_warner},
	);
    return $output;
}

sub _macro_define_generator {
    my ( $self, @args ) = @_;
    my $output;
    foreach my $macro ( @args ) {
	$output .= "macro define $macro \\\n    " .
	    join( " \\\n    ", map { quoter( $_ ) } $self->def() ) .
	    "\n";
    }
    return $output;
}

sub _macro_delete : Verb() {	## no critic (ProhibitUnusedPrivateSubroutines)
    my ( $self, undef, @args ) = __arguments( @_ );
    my $output;
    foreach my $name (@args ? @args : keys %{$self->{macro}}) {
	delete $self->{macro}{$name};
    }
    return $output;
}

sub _macro_list : Verb() {	## no critic (ProhibitUnusedPrivateSubroutines)
    my ( $self, undef, @args ) = __arguments( @_ );
    my $output;
    foreach my $name (sort @args ? @args : keys %{$self->{macro}}) {
	$self->{macro}{$name}
	    or next;
	$output .= $self->{macro}{$name}->generator( $name );
    }
    return $output;
}

sub _macro_load : Verb( lib=s ) {	## no critic (ProhibitUnusedPrivateSubroutines)
    my ( $self, $opt, $name, @args ) = __arguments( @_ );
    my $output;
    defined $name
	or $self->wail( 'Must provide name of macro to load' );
    my %marg = (
	name	=> $name,
	parent	=> $self,
	generate	=> \&_macro_load_generator,
	warner	=> $self->{_warner},
    );
    exists $opt->{lib}
	and $marg{lib} = $opt->{lib};
    my $obj = $self->{_macro_load}{$name} ||=
	Astro::App::Satpass2::Macro::Code->new( %marg );
    foreach my $mn ( @args ? @args : $obj->implements() ) {
	$obj->implements( $mn, required => 1 )
	    and $self->{macro}{$mn} = $obj;
    }
    $obj->implements( 'after_load', required => 0 )
	and $output = $self->dispatch( after_load => $opt, $name, @args );
    return $output;
}

sub _macro_load_generator {
    my ( $self, @args ) = @_;
    my @preamble = qw{ macro load };
    if ( $self->has_lib() ) {
	push @preamble, '-lib', $self->lib();
	$self->relative()
	    and push @preamble, '-relative';
    }
    push @preamble, $self->name();
    my $output;
    foreach my $macro ( @args ) {
	$output .= quoter( @preamble, $macro ) . "\n";
    }
    return $output;
}

sub magnitude_table : Verb( name! reload! ) {
    my ( undef, undef, @args ) = __arguments( @_ );	# Invocant, $opt unused

    @args or @args = qw{show};

    my $verb = lc (shift (@args) || 'show');

    my $output;

    if ( $verb eq 'show' || $verb eq 'list' ) {

	my %data = Astro::Coord::ECI::TLE->magnitude_table( 'show', @args );

	foreach my $oid ( sort keys %data ) {
	    $output .= quoter( 'status', 'add', $oid, $data{$oid} )
		. "\n";
	}

    } else {
	Astro::Coord::ECI::TLE->magnitude_table( $verb, @args );
    }

    return $output;

}

# Attributes must all be on one line to process correctly under Perl
# 5.8.8.
sub pass : Verb( choose=s@ appulse! brightest|magnitude! chronological! dump! events! horizon|rise|set! illumination! quiet! transit|maximum|culmination! )
{
    my ( $self, $opt, @args ) = __arguments( @_ );

    _apply_boolean_default(
	$opt, 0, qw{ horizon illumination transit appulse } );
    my $pass_start = $self->__parse_time (
	shift @args, $self->_get_today_noon());
    my $pass_end = $self->__parse_time (shift @args || '+7');
    $pass_start >= $pass_end
	and $self->wail( 'End time must be after start time' );

    my $sta = $self->station();
    my @bodies = $self->__choose( $opt->{choose}, $self->{bodies} )
	or $self->wail( 'No bodies selected' );
    my $pass_step = shift @args || 60;

#	Decide which model to use.

    my $model = $self->{model};

    # Set the station for the objects in the sky.

    foreach my $body ( @{ $self->{sky} } ) {
	$body->set( station => $sta );
    }

#	Pick up horizon and appulse distance.

    my $horizon = deg2rad ($self->{horizon});
    my $appulse = deg2rad ($self->{appulse});
    my $pass_threshold = deg2rad( $self->{pass_threshold} );

    # In order that the interface not be completely rude, the interface
    # allows -brightest to specify that you want the 'brightest' event.
    # But this is controlled by the pass_variant attribute. So if
    # -brightest appears, the pass_variant from it; otherwise we default
    # -brightest from the pass_variant attribute.  We localize the
    # pass_variant attribute before modifying it, since the -brightest
    # option is to hold for this call only. We modify it (rather than
    # just passing a local copy to the bodies) because
    # Formatter::Template needs to know what it is, and modifying this
    # object is the obvious way to pass the information.
    local $self->{pass_variant} = $self->{pass_variant};
    if ( $opt->{brightest} ) {
	$self->{pass_variant} |= PASS_VARIANT_BRIGHTEST;
    } elsif ( exists $opt->{brightest} ) {
	$self->{pass_variant} &= ~ PASS_VARIANT_BRIGHTEST;
    } else {
	$opt->{brightest} = $self->{pass_variant} & PASS_VARIANT_BRIGHTEST;
    }
    my $pass_variant = $self->{pass_variant};

#	Foreach body to be modelled

    my @accumulate;	# For chronological output.
    foreach my $tle ( $self->_aggregate( \@bodies ) ) {

	{
	    my $mdl = $tle->get('inertial') ? $model :
		$tle->get('model');
	    $tle->set (
		appulse => $appulse,
		backdate => $self->{backdate},
		debug => $self->{debug},
		edge_of_earths_shadow => $self->{edge_of_earths_shadow},
		geometric => $self->{geometric},
		horizon => $horizon,
		interval => ( $self->{verbose} ? $pass_step : 0 ),
		model => $mdl,
		pass_threshold => $pass_threshold,
		pass_variant	=> $pass_variant,
		station	=> $sta,
		twilight => $self->{_twilight},
		visible => $self->{visible},
	    );
	}

	eval {
	    push @accumulate, $self->_pass_select_event( $opt, $tle->pass (
		$pass_start, $pass_end, $self->{sky} ) );
	    1;
	} or do {
	    $@ =~ m/ \Q$interrupted\E /smxo and $self->wail($@);
	    $opt->{quiet} or $self->whinge($@);
	};
    }

    my $template;

    if ( $opt->{events} ) {
	$template = 'pass_events';
    } else {
	$template = 'pass';
	$opt->{chronological}
	    and @accumulate = sort { $a->{time} <=> $b->{time} }
		@accumulate;
    }

    return $self->__format_data(
	$template => \@accumulate, $opt );
}

{
    my @selector;
    $selector[ PASS_EVENT_SHADOWED ]	= 'illumination';
    $selector[ PASS_EVENT_LIT ]		= 'illumination';
    $selector[ PASS_EVENT_DAY ]		= 'illumination';
    $selector[ PASS_EVENT_RISE ]	= 'horizon';
    $selector[ PASS_EVENT_MAX ]		= 'transit';
    $selector[ PASS_EVENT_SET ]		= 'horizon';
    $selector[ PASS_EVENT_APPULSE ]	= 'appulse';
    $selector[ PASS_EVENT_START ]	= 'horizon';
    $selector[ PASS_EVENT_END ]		= 'horizon';
    $selector[ PASS_EVENT_BRIGHTEST ]	= 'brightest';

    # Remove from the pass data any events that are not wanted. The
    # arguments are $self, the $opt hash reference that (among other
    # things) specifies the desired events, and the passes, each pass
    # being an argument. The modified passes are returned.
    sub _pass_select_event {
	my ( undef, $opt, @passes ) = @_;	# Invocant unused
	my @rslt;
	foreach my $pass ( @passes ) {
	    @{ $pass->{events} } = grep {
		_pass_select_event_code( $opt, $_->{event} )
		} @{ $pass->{events} }
		and push @rslt, $pass;
	}
	return @rslt
    }

    # Determine whether an event is to be reported for the pass. The
    # arguments are the $opt hash reference and the event code or name.
    # Anything that is not a dualvar and not an integer is accepted, on
    # the presumption that it is an ad-hoc event provided by some
    # subclass. The null event is always accepted on the presumption
    # that if the user did not want it he or she would not have asked
    # for it. Anything that is left is accepted or rejected based on the
    # option hash and the @selector array (defined above).
    sub _pass_select_event_code {
	my ( $opt, $event ) = @_;
	isdual( $event )
	    or $event !~ m/ \D /smx
	    or return 1;
	$event == PASS_EVENT_NONE
	    and return 1;
	return defined $selector[ $event ] && $opt->{ $selector[ $event ] };
    }
}

sub perl : Tokenize( -noexpand_tilde ) : Verb( eval! setup! ) {
    my ( $self, $opt, $file, @args ) = __arguments( @_ );
    defined $file
	or $self->wail( 'At least one argument is required' );
    $opt->{setup}
	and push @{ $self->{_perl} ||= [] }, [ $opt, $file, @args ];
    local @ARGV = ( $self, map { $self->expand_tilde( $_ ) } @args );
    $opt->{eval}
	or local $0 = $self->expand_tilde( $file );

    my $data = $opt->{eval} ?
	$file :
	$self->_file_reader( $file, { glob => 1 } );
    my $rslt = eval $data; ## no critic (BuiltinFunctions::ProhibitStringyEval)
    $@
	and $self->wail( "Failed to eval '$file': $@" );
    instance( $rslt, 'Astro::App::Satpass2' )
	or return $rslt;
    return;
}

sub phase : Verb( choose=s@ ) {
    my ( $self, $opt, @args ) = __arguments( @_ );

    my $time = $self->__parse_time (shift @args, time );

    my @sky = $self->__choose( $opt->{choose}, $self->{sky} )
	or $self->wail( 'No bodies selected' );
    return $self->__format_data(
	phase => [
	    map { { body => $_->universal( $time ), time => $time } }
	    grep { $_->can( 'phase' ) }
	    @sky
	], $opt );
}

sub position : Verb( choose=s@ questionable|spare! quiet! ) {
    my ( $self, $opt, $time ) = __arguments( @_ );

    if ( defined $time ) {
	$time = $self->__parse_time($time);
    } else {
	$time = time;
    }


#	Define the observing station.

    my $sta = $self->station();
    $sta->universal( $time );

    my @list = $self->__choose( { bodies => 1, sky => 1 },
	$opt->{choose} );

    my @good;
    my $horizon = deg2rad ($self->{horizon});
    foreach my $body (@list) {
	if ( $body->represents( 'Astro::Coord::ECI::TLE' ) ) {
	    $body->set (
		backdate => $self->{backdate},
		debug => $self->{debug},
		edge_of_earths_shadow => $self->{edge_of_earths_shadow},
		geometric => $self->{geometric},
		horizon => $horizon,
		station	=> $sta,
		twilight => $self->{_twilight},
	    );
	    $body->get('inertial')
		and $body->set( model => $self->{model} );
	}
	eval {
	    $body->universal ($time);
	    push @good, $body;
	    1;
	} or do {
	    $@ =~ m/ \Q$interrupted\E /smxo and $self->wail($@);
	    $opt->{quiet} or $self->whinge($@);
	};
    }

    return $self->__format_data(
	position => {
	    bodies		=> \@good,
	    questionable	=> $opt->{questionable},
	    station		=> $self->station()->universal(
		$time ),
	    time		=> $time,
	    twilight		=> $self->{_twilight},
	}, $opt );
}

sub pwd : Verb() {
    return Cwd::cwd() . "\n";
}

{
    my @quarter_name = map { "q$_" } 0 .. 3;

    sub quarters : Verb( choose=s@ dump! q0|new|spring! q1|first|summer!  q2|full|fall q3|last|winter ) {
	my ( $self, $opt, @args ) = __arguments( @_ );

	my $start = $self->__parse_time (
	    $args[0], $self->_get_today_midnight() );
	my $end = $self->__parse_time ($args[1] || '+30');

	_apply_boolean_default( $opt, 0, map { "q$_" } 0 .. 3 );

	my @sky = $self->__choose( $opt->{choose}, $self->{sky} )
	    or $self->wail( 'No bodies selected' );

	my @almanac;

	# Iterate over any background objects, accumulating all
	# quarter-phases of each until we get one after the end time. We
	# silently ignore bodies that do not support the next_quarter()
	# method.

	foreach my $body ( @sky ) {
	    next unless $body->can ('next_quarter_hash');
	    $body->universal ($start);

	    while (1) {
		my $hash = $body->next_quarter_hash();
		$hash->{time} > $end and last;
		$opt->{$quarter_name[$hash->{almanac}{detail}]}
		    or next;
		push @almanac, $hash;
	    }
	}

	# Localize the event descriptions if appropriate.

	foreach my $event ( @almanac ) {
	    $event->{almanac}{description} = __localize(
		text	=> [ almanac => $event->{body}->get( 'name' ),
		    $event->{almanac}{event}, $event->{almanac}{detail}
		],
		default	=> $event->{almanac}{description},
		argument	=> $event->{body},
	    );
	}

	# Sort and display the quarter-phase information.

	return $self->__format_data(
	    almanac => [
		sort { $a->{time} <=> $b->{time} }
		@almanac
	    ], $opt );

    }
}

{
    my $go;

    sub run {
	my ( $self, @args ) = @_;

	# We can be called statically. If we are, instantiate.
	ref $self or $self = $self->new(warning => 1);

	# Put all the I/O into UTF-8 mode.
	binmode STDIN, ':encoding(UTF-8)';
	binmode STDOUT, ':encoding(UTF-8)';
	binmode STDERR, ':encoding(UTF-8)';

	# If the undocumented first option is a code reference, use it to
	# get input.
	my $in;
	CODE_REF eq ref $args[0]
	    and $in = shift @args;

	# Parse the command options. -level1 is undocumented.
	my %opt;
	$go ||= Getopt::Long::Parser->new();
	$go->getoptionsfromarray(
	    \@args,
	    \%opt,
	    qw{
		echo! filter! gmt! help initialization_file|initfile=s
		level1! version
	    },
	)
	    or $self->wail( 'See the help method for valid options' );

	# If -version, do it and return.
	if ( $opt{version} ) {
	    print $self->version();
	    return;
	}

	# If -help, do it and return.
	if ( $opt{help} ) {
	    $self->help();
	    return;
	}

	# Get an input routine if we do not already have one.
	$in ||= $self->_get_readline();

	# Some options get processed before we initialize.
	foreach my $name ( qw{ echo filter } ) {
	    exists $opt{$name}
		and $self->set( $name => delete( $opt{$name} ) );
	}

	# Display the front matter if desired.
	(!$self->get('filter') && $self->_get_interactive())
	    and print $self->version();

	# Execute the initialization file.
	eval {
	    $self->_execute_output( $self->init(
		    { level1 => delete $opt{level1} },
		    delete $opt{initialization_file},
		), $self->get( 'stdout' ) );
	    1;
	} or warn $@;	# Not whinge, since presumably we already did.

	# The remaining options set the corresponding attributes.
	%opt and $self->set(%opt);

	# Execution loop. What exit() really does is a last on this.
    SATPASS2_EXECUTE:
	{
	    $self->_execute( @args );
	    while ( defined ( my $buffer = $in->( $self->get( 'prompt' ) ) ) ) {
		$self->_execute( $in, $buffer );
	    }
	}
	$self->_execute( q{echo ''} );	# The lazy way to be sure we
					    # have a newline before exit.
	return;
    }
}

sub save : Verb( changes! overwrite! ) {
    my ( $self, $opt, $fn ) = __arguments( @_ );

    defined $fn or $fn = $self->initfile( { 'create-directory' => 1 } );
    chomp $fn;	# because initfile() adds a newline for printing
    if ($fn ne '-' && -e $fn) {
	-f $fn or $self->wail(
	    "Can not overwrite $fn: not an ordinary file");
	$opt->{overwrite} or do {
	    my $rslt = $self->_get_readline()->(
		"File $fn exists. Overwrite [y/N]? ");
	    'y' eq lc substr($rslt, 0, 1)
		or return;
	};
    }
    my @show_opt;
    my $title = 'settings';
    if ($opt->{changes}) {
	push @show_opt, '-changes';
	$title = 'setting changes';
    }

    my $output = <<"EOD" .

# Astro::App::Satpass2 $title

EOD
	$self->show( @show_opt, qw{ -nodeprecated -noreadonly } ) .
	<<"EOD" . $self->macro('list');

# Astro::App::Satpass2 macros

EOD

    if ( $self->{_perl} ) {
	$output .= <<'EOD';

# Astro::App::Satpass2 setup

EOD
	foreach my $item ( @{ $self->{_perl} } ) {
	    my ( $opt, @arg ) = @{ $item };
	    my @cmd = ( 'perl' );
	    push @cmd, map { "-$_" } grep { $opt->{$_} } sort keys %{ $opt };
	    $output .= join ' ', quoter( @cmd, @arg );
	    $output .= "\n";
	}
    }

    foreach my $attribute ( qw{ formatter spacetrack time_parser } ) {
	my $obj = $self->get( $attribute ) or next;
	my $class = $obj->can( 'class_name_of_record' ) ?
	    $obj->class_name_of_record() :
	    ref $obj || $obj;
	$output .= <<"EOD" .

# $class $title

EOD
	( $self->$attribute( $opt, 'config' ) || "# none\n" );
    }

    $output .= $self->_save_sky( $opt );

    if ($fn ne '-') {
	my $fh = IO::File->new( $fn, '>:encoding(utf-8)')
	    or $self->wail("Unable to open $fn: $!");
	print { $fh } $output;
	$output = "$fn\n";
    }
    return $output;
}

# Formats the commands to reconstitute the sky. This is only called from
# save(), but it is a subroutine for organizational reasons.
sub _save_sky {
    my ( $self, $opt ) = @_;

    my $output = <<'EOD';

# Astro::App::Satpass2 sky

EOD

    foreach my $body ( sort keys %{ $self->{sky_class} } ) {
	$opt->{changes}
	    and $sky_class{$body}
	    and $sky_class{$body} eq $self->{sky_class}{$body}
	    and next;
	$output .= $self->_sky_class_components( $body ) . "\n";
    }
    foreach my $body ( sort keys ( %sky_class ) ) {
	$self->{sky_class}{$body}
	    or $output .= $self->_sky_class_components( $body ) . "\n";
    }

    my %exclude;
    if ( $opt->{changes} ) {
	%exclude = map { $_ => 1 }
	    SUN_CLASS_DEFAULT, 'Astro::Coord::ECI::Moon';
	foreach my $name ( qw{ sun moon } ) {
	    defined $self->_find_in_sky( $name )
		or $output .= "sky drop $name\n";
	}
    } else {
	$output .= "sky clear\n";
    }
    foreach my $body ( @{ $self->{sky} } ) {
	$exclude{ ref $body }
	    and next;
	$output .= _sky_list_body( $body );
    }

    return $output;
}

sub set : Verb() {
    my ( $self, undef, @args ) = __arguments( @_ );	# $opt unused

    while (@args) {
	my ( $name, $value ) = splice @args, 0, 2;
	$self->_attribute_exists( $name );
	if ( _is_interactive() ) {
	    $nointeractive{$name}
		and $self->wail(
		    "Attribute '$name' may not be set interactively");
	    defined $value and $value eq 'undef'
		and $value = undef;
	}
	if ( $mutator{$name} ) {
	    $self->_deprecation_notice( attribute => $name );
	    $mutator{$name}->($self, $name, $value);
	} else {
	    $self->wail("Read-only attribute '$name'");
	}
    }
    return;
}

sub _set_almanac_horizon {
    my ( $self, $name, $value ) = @_;
    my $eci = Astro::Coord::ECI->new();
    my $parsed = $self->__parse_angle( { accept => 1 }, $value );
    $eci->set( almanac_horizon => $parsed );	# To validate.
    my $internal = looks_like_number( $parsed ) ? deg2rad( $parsed ) :
    $parsed;
    $self->{"_$name"} = $internal;
    return( $self->{$name} = $parsed );
}

sub _set_angle {
    my ( $self, $name, $value ) = @_;
    return ( $self->{$name} = $self->__parse_angle( $value ) );
}

sub _set_angle_or_undef {
    my ( $self, $name, $value ) = @_;
    defined $value and 'undef' ne $value and goto &_set_angle;
    return ( $self->{$name} = undef );
}

sub _set_code_ref {
    CODE_REF eq ref $_[2]
	or $_[0]->wail( "Attribute $_[1] must be a code reference" );
    return( $_[0]{$_[1]} = $_[2] );
}

# Set an attribute whose value is an Astro::App::Satpass2::Copier object
# %arg is a hash of argument name/value pairs:
#    {name} is the required name of the attribute to set;
#    {value} is the required value of the attribute to set;
#    {class} is the optional class that the object must be;
#    {default} is the optional default value if the required value is
#        undef or '';
#    {undefined} is an optional value which, if true, permits the
#        attribute to be set to undef;
#    {nocopy} is an optional value which, if true, causes the old
#        object's attributes not to be copied to the new object;
#    {message} is an optional message to emit if the object can not be
#	instantiated;
#    {prefix} is an optional reference to an array of name prefixes to
#	try if the named module does not load.

sub _set_copyable {
    my ( $self, %arg ) = @_;
    my $old = $self->{$arg{name}};
    my $obj;
    if ( ref $arg{value} ) {
	blessed( $arg{value} )
	    or $self->wail( "$arg{name} may not be unblessed reference" );
	$obj = $arg{value};
	$obj->can( 'warner' )
	    and $obj->warner( $self->{_warner} );
    } else {
	if ( defined $arg{default} ) {
	    defined $arg{value}
		and '' ne $arg{value}
		or $arg{value} = $arg{default};
	}
	if ( ! defined $arg{value} || $arg{value} eq '' ) {
	    $arg{undefined}
		or $self->wail(
		"$arg{name} must be defined and not empty",
	    );
	    return ( $self->{$arg{name}} = $arg{value} = undef );
	}
	my ( $pkg, @args ) = $self->__parse_class_and_args( $arg{value} );
	my $cls = $self->load_package(
	    { fatal => 'wail' }, $pkg, @{ $arg{prefix} || [] } );
	not $cls->can( 'init' )
	    and _is_case_tolerant()
	    and $self->wail(
	    "$cls is missing methods. This can happen on a ",
	    'case-tolerant system if you specify the class ',
	    'name in the wrong case.' );
	$obj = $cls->new(
	    warner	=> $self->{_warner},
	    @args,
	)
	    or $self->wail( $arg{message} ||
	    "Can not instantiate object from '$arg{value}'" );
    }
    defined $arg{class}
	and not $obj->isa( $arg{class} )
	and $self->wail( "$arg{name} must be of class $arg{class}" );
    blessed( $old )
	and not $arg{nocopy}
	and $old->can( 'copy' )
	and $old->copy( $obj );
    $self->{$arg{name}} = $obj;
    return $arg{value};
}

sub _set_distance_meters {
    return ( $_[0]{$_[1]} = defined $_[2] ?
	( $_[0]->__parse_distance( $_[2], '0m' ) * 1000 ) : $_[2] );
}

sub _set_ellipsoid {
    my ($self, $name, $val) = @_;
    Astro::Coord::ECI->set (ellipsoid => $val);
    return ($self->{$name} = $val);
}

sub _set_formatter {
    my ( $self, $name, $val ) = @_;
    return $self->_set_copyable(
	name	=> $name,
	value	=> $val,
	message	=> 'Unknown formatter',
	default	=> 'Astro::App::Satpass2::Format::Template',
	prefix	=> [ 'Astro::App::Satpass2::Format' ]
    );
}

sub _set_formatter_attribute {
    my ( $self, $name, $val ) = @_;
    $self->get( 'formatter' )->$name( $val );
    return $val;
}

sub _set_geocoder {
    my ( $self, $name, $val ) = @_;
    return $self->_set_copyable(
	name	=> $name,
	value	=> $val,
	class	=> 'Astro::App::Satpass2::Geocode',
	message	=> 'Unknown formatter',
	default	=> $default_geocoder->(),
	undefined => 1,
	nocopy	=> 1,
	prefix	=> [ 'Astro::App::Satpass2::Geocode' ]
    );
}

sub _set_illum_class {
    my ( $self, $name, $class ) = @_;
    my $want_class = 'Astro::Coord::ECI';
    ref $class and $self->wail( "$name must not be a reference" );
    if ( defined $class ) {
	$self->load_package( { fatal => 'wail' }, $class );
	$class->isa( $want_class )
	    or $self->wail( "$name must be an $want_class" );
    } else {
	$class = $want_class;
    }
    $self->{$name} = $class;
    $self->{_help_module}{$name} = $class;
    foreach my $body ( @{ $self->{bodies} } ) {
	$body->set( $name => $class );
    }
    return;
}

sub _set_model {
    my ( $self, $name, $val ) = @_;
    Astro::Coord::ECI::TLE->is_valid_model( $val )
	or $self->wail(
	"'$val' is not a valid Astro::Coord::ECI::TLE model" );
    foreach my $body ( @{ $self->{bodies} } ) {
	$body->set( model => $val );
    }
    return ( $self->{$name} = $val );
}

{
    my %variant_def = (
	visible_events	=> PASS_VARIANT_VISIBLE_EVENTS,
	fake_max	=> PASS_VARIANT_FAKE_MAX,
	start_end	=> PASS_VARIANT_START_END,
	no_illumination	=> PASS_VARIANT_NO_ILLUMINATION,
	brightest	=> PASS_VARIANT_BRIGHTEST,
    );

    my @option_names;
    foreach my $key ( keys %variant_def ) {
	if ( $key =~ m/ _ /smx ) {
	    ( my $dashed = $key ) =~ s/ _ /-/smxg;
	    $key = "$key|$dashed";
	}
	push @option_names, "$key!";
    }

    my $go;

    sub _set_pass_variant {
	my ( $self, $name, $val ) = @_;
	if ( $val =~ m/ \A (?: 0 x? ) [0-9]* \z /smx ) {
	    $val = oct $val;
	} elsif ( $val !~ m/ \A [0-9]+ \z /smx ) {
	    my @args = split qr{ [^\w-] }smx, $val;
	    foreach ( @args ) {
		s/ \A (?! - ) /-/smx;
	    }
	    $go ||= Getopt::Long::Parser->new();
	    $val = $self->get( $name );
	    $go->getoptionsfromarray( \@args,
		none	=> sub { $val = PASS_VARIANT_NONE },
		map { $_ => sub {
			my ( $name, $value ) = @_;
			my $mask = $variant_def{$name};
			if ( $value ) {
			    $val |= $mask;
			} else {
			    $val &= ~ $mask;
			}
			return;
		    }
		} @option_names )
		or $self->wail( "Invalid $name value '$val'" );
	}
	return ( $self->{$name} = $val );
    }

    sub _show_pass_variant {
	my ( $self, $name ) = @_;
	my $val = $self->get( $name );
	my @options;
	foreach my $key ( keys %variant_def ) {
	    $val & $variant_def{$key}
		and push @options, "$key";
	}
	@options
	    or push @options, 'none';
	return ( set => $name, join ',', @options );
    }

    sub want_pass_variant {
	my ( $self, $variant ) = @_;
	$variant_def{$variant}
	    or $self->wail( "Invalid pass_variant name '$variant'" );
	my $val = $self->get( 'pass_variant' ) & $variant_def{$variant};
	return $val;
    }

}

sub _set_spacetrack {
    my ($self, $name, $val) = @_;
    if (defined $val) {
	instance($val, 'Astro::SpaceTrack')
	    or $self->wail("$name must be an Astro::SpaceTrack instance");
	my $version = $val->VERSION();
	$version =~ s/ _ //smxg;
	$version >= ASTRO_SPACETRACK_VERSION
	    or $self->wail("$name must be Astro::SpaceTrack version ",
	    ASTRO_SPACETRACK_VERSION, ' or greater' );
    }
    return ($self->{$name} = $val);
}

sub _set_stdout {
    my ($self, $name, $val) = @_;
    $self->{frame}
	and $self->{frame}[-1]{$name} = $val;
    return ($self->{$name} = $val);
}

sub _set_sun_class {
    my ( $self, $name, $val ) = @_;
    $self->_attribute_exists( $name );
    return $self->sky( class => $name, $val );
}

sub _set_time_parser {
    my ( $self, $name, $val ) = @_;

    if ( CODE_REF eq ref $val ) {
	$val = _set_time_parser_code( $val );
    } elsif ( my $macro = $self->{macro}{$val} ) {
	$val = _set_time_parser_code(
	    $macro->implements( $val, required => 1 ),
	    $val,
	);
    }

    return $self->_set_copyable(
	name	=> $name,
	value	=> $val,
	class	=> 'Astro::App::Satpass2::ParseTime',
	message	=> 'Unknown time parser',
	default	=> 'Astro::App::Satpass2::ParseTime',
	nocopy	=> 1,
	prefix	=> [ 'Astro::App::Satpass2::ParseTime' ],
    );
}

sub _set_time_parser_attribute {
    my ( $self, $name, $val ) = @_;
    defined $val and $val eq 'undef' and $val = undef;
    $self->{time_parser}->$name( $val );
    return $val;
}

sub _set_time_parser_code {
    my ( $code, $name ) = @_;
    require Astro::App::Satpass2::ParseTime::Code;
    my $obj = Astro::App::Satpass2::ParseTime::Code->new();
    return $obj->code( $code, $name );
}

_frame_pop_force_set ( 'twilight' );	# Force use of the set() method
					# in _frame_pop(), because we
					# need to set {_twilight} as
					# well.
sub _set_twilight {
    my ($self, $name, $val) = @_;
    if (my $key = $twilight_abbr{lc $val}) {
	$self->{$name} = $key;
	$self->{_twilight} = $twilight_def{$key};
    } else {
	my $angle = $self->__parse_angle( { accept => 1 }, $val );
	looks_like_number( $angle )
	    or $self->wail( 'Twilight must be number or known keyword' );
	$self->{$name} = $val;
	$self->{_twilight} = deg2rad ($angle);
    }
    return $val;
}

sub _set_tz {
    my ( $self, $name, $val ) = @_;
    $self->_set_formatter_attribute( $name, $val );
    $self->_set_time_parser_attribute( $name, $val );
    return $val;
}

sub _set_unmodified {
    return ($_[0]{$_[1]} = $_[2]);
}

sub _set_warner_attribute {
    my ( $self, $name, $val ) = @_;
    defined $val and $val eq 'undef' and $val = undef;
    $self->{_warner}->$name( $val );
    return $val;
}

sub _set_webcmd {
    my ($self, $name, $val) = @_;
    # TODO warn if $val is true but not '1'.
    if ( my $st = $self->get( 'spacetrack' ) ) {
	# TODO once spacetrack supports '1', just pass $val.
	$st->set( webcmd => $self->_get_browser_command( $val ) );
    }
    return ($self->{$name} = $val);
}

sub show : Verb( changes! deprecated! readonly! ) {
    my ( $self, $opt, @args ) = __arguments( @_ );

    foreach my $name ( qw{ deprecated readonly } ) {
	exists $opt->{$name} or $opt->{$name} = 1;
    }
    my $output;

    unless ( @args ) {
	foreach my $name ( sort keys %accessor ) {
	    $self->_attribute_exists( $name, query => 1 )
		or next;
	    $nointeractive{$name}
		and next;
	    exists $mutator{$name}
		or $opt->{readonly}
		or next;
	    my $depr;
	    ( $depr = $self->_deprecation_in_progress( attribute =>
		    $name ) )
		and ( not $opt->{deprecated} or $depr >= 3 )
		and next;
	    push @args, $name;
	}
    }

    foreach my $name (@args) {
	exists $shower{$name}
	    or $self->wail("No such attribute as '$name'");

	my @val = $shower{$name}->( $self, $name );
	if ( $opt->{changes} ) {
	    no warnings qw{ uninitialized };
	    $static{$name} eq $val[-1] and next;
	}

	exists $mutator{$name} or unshift @val, '#';
	$output .= quoter( @val ) . "\n";
    }
    return $output;
}

sub _show_copyable {
    my ( $self, $name ) = @_;
    my $obj = $self->get( $name );
    my $val = $obj->class_name_of_record();
    return ( 'set', $name, $val );
}

sub _show_formatter_attribute {
    my ( $self, $name ) = @_;
    my $val = $self->{formatter}->decode( $name );
    return ( qw{ formatter }, $name, $val );
}

sub _show_sun_class {
    my ( $self, $name ) = @_;
    $self->_attribute_exists( $name );
    return $self->_sky_class_components( $name );
}

sub _show_unmodified {
    my ($self, $name) = @_;
    my $val = $self->get( $name );
    return ( 'set', $name, $val );
}


# For proper motion, we need to convert arc seconds per year to degrees
# per second. Perl::Critic does not like 'use constant' because they do
# not interpolate, but they really do: "@{[SPY2DPS]}".

use constant SPY2DPS => 3600 * 365.24219 * SECSPERDAY;

# Given a body in the sky, encodes it in 'sky add' format
sub _sky_list_body {
    my ( $body ) = @_;
    if ( embodies( $body, 'Astro::Coord::ECI::TLE' ) ) {
	return sprintf "sky tle %s\n", quoter(
	    $body->get( 'tle' ) );
    } elsif ( $body->isa( 'Astro::Coord::ECI::Star' ) ) {
	my ( $ra, $dec, $rng, $pmra, $pmdec, $vr ) = $body->position();
	$rng /= PARSEC;
	$pmra = rad2deg( $pmra / 24 * 360 * cos( $ra ) ) * SPY2DPS;
	$pmdec = rad2deg( $pmdec ) * SPY2DPS;
	return sprintf
	    "sky add %s %s %7.3f %.2f %.4f %.5f %s\n",
	    quoter( $body->get( 'name' ) ), _rad2hms( $ra ),
	    rad2deg( $dec ), $rng, $pmra, $pmdec, $vr;
    } else {
	return sprintf "sky add %s\n", quoter( $body->get( 'name' ) );
    }
}

{
    my %go;

    my %handler = (
	list	=> sub {
	    my ( $self ) = @_;		# Arguments unused
	    my $output;
	    foreach my $body (
		map { $_->[1] }
		sort { $a->[0] cmp $b->[0] }
		map { [ lc( $_->get( 'name' ) || $_->get( 'id' ) ), $_ ] }
		@{$self->{sky}}
	    ) {
		$output .= _sky_list_body( $body );
	    }
	    unless (@{$self->{sky}}) {
		$self->{warn_on_empty}
		    and $self->whinge( 'The sky is empty' );
	    }
	    return $output;
	},
	add	=> sub {
	    my ( $self, @args ) = @_;
	    my $name = shift @args
		or $self->wail( 'You did not specify what to add' );
	    defined $self->_find_in_sky( $name )
		and return;
	    if ( my $obj = $self->_sky_object( $name, fatal => 0 ) ) {
		push @{ $self->{sky} }, $obj;
	    } else {
		@args >= 2
		    or $self->wail(
		    'You must give at least right ascension and declination' );
		my $ra = deg2rad( $self->__parse_angle( shift @args ) );
		my $dec = deg2rad( $self->__parse_angle( shift @args ) );
		my $rng = @args ?
		    $self->__parse_distance( shift @args, '1pc' ) :
		    10000 * PARSEC;
		my $pmra = @args ? do {
		    my $angle = shift @args;
		    $angle =~ s/ s \z //smxi
			or $angle *= 24 / 360 / cos( $ra );
		    deg2rad( $angle / SPY2DPS );
		} : 0;
		my $pmdec = @args ? deg2rad( shift( @args ) / SPY2DPS ) : 0;
		my $pmrec = @args ? shift @args : 0;
		push @{ $self->{sky} }, Astro::Coord::ECI::Star->new(
		    debug	=> $self->{debug},
		    name	=> $name,
		    sun		=> $self->_sky_object( 'sun' ),
		)->position( $ra, $dec, $rng, $pmra, $pmdec, $pmrec );
	    }
	    return;
	},
	class	=> sub {
	    my ( $self, @arg ) = @_;
	    $go{class} ||= Getopt::Long::Parser->new(
#		config	=> [ qw{ require_order } ],
	    );
	    my %opt;
	    if ( HASH_REF eq ref $arg[0] ) {
		%opt = %{ shift @arg };
	    } else {
		$go{class}->getoptionsfromarray(
		    \@arg, \%opt, qw{ add! delete! } )
		    or $self->wail( 'Invalid option' );
	    };
	    $opt{add}
		and $opt{delete}
		and $self->wail( 'May not specify both add and delete' );

	    if ( $opt{delete} ) {
		foreach my $name ( @arg ) {
		    $name =~ m/ \A sun \z /smxi
			and $self->wail( 'Can not remove Sun class' );
		    defined $self->_find_in_sky( $name )
			and $self->wail( 'Can not remove in-use class' );
		    delete $self->{sky_class}{ fold_case( $name ) };
		}
	    } elsif ( @arg < 2 ) {
		@arg
		    or @arg = sort keys %{ $self->{sky_class} };
		return join '', map {
		    $self->_sky_class_components( $_ ) . "\n" }
		    @arg;
	    } else {
		my ( $name, $class, @attr ) = @arg;
		$self->load_package( { fatal => 'wail' }, $class );
		my $want_class = $name =~ m/ \A sun \z /smxi ?
		    SUN_CLASS_DEFAULT :
		    'Astro::Coord::ECI';
		embodies( $class, $want_class )
		    or $self->wail(
		    "Must be a subclass of $want_class" );
		+{ @attr }->{name}
		    and $self->wail( 'May not specify name explicitly' );
		# name must be last, because _sky_class_components()
		# needs to recover it.
		push @attr, name => $name;
		my $obj = $class->new( @attr );	# To validate @attr
		my $folded_name = fold_case( $name );
		$self->{sky_class}{$folded_name} = [ $class, @attr ];
		$self->_replace_in_sky( $folded_name )
		    or $opt{add}
		    and push @{ $self->{sky} }, $obj;
		$self->{_help_module}{$folded_name} = $class;
		if ( $name =~ m/ \A sun \z /smxi ) {
		    foreach my $body (
			@{ $self->{bodies} }, @{ $self->{sky} }
		    ) {
			$body->set(
			    sun => $self->_sky_object( 'sun' ),
			);
		    }
		}
	    }

	    return;
	},
	clear	=> sub {
	    my ( $self ) = @_;		# Arguments unused
	    @{ $self->{sky} } = ();
	    return;
	},
	drop	=> sub {
	    my ( $self, @args ) = @_;
	    @args or $self->wail(
		'You must specify at least one name to drop' );
	    foreach my $name ( @args ) {
		$self->_drop_from_sky( $name );
	    }
	    return;
	},
	load	=> sub {	# Undocumented. That means I can revoke
				# at any time, without notice. If you
				# need this functionality, please
				# contact me.
	    my ( $self, @args ) = @_;
	    my $tle;
	    foreach my $fn ( @args ) {
		local $/ = undef;
		open my $fh, '<', $fn
		    or $self->wail( "Failed to open $fn: $!" );
		$tle .= <$fh>;
		close $fh;
	    }
	    return $self->_sky_tle( $tle );
	},
	lookup	=> sub {
	    my ( $self, @args ) = @_;
	    my $output;
	    my $name = shift @args;
	    defined $self->_find_in_sky( $name )
		and $self->wail( "Duplicate sky entry '$name'" );
	    my ($ra, $dec, $rng, $pmra, $pmdec, $pmrec) =
		$self->_simbad4 ($name);
	    $rng = sprintf '%.2f', $rng;
	    $output .= 'sky add ' . quoter ($name) .
		" $ra $dec $rng $pmra $pmdec $pmrec\n";
	    $ra = deg2rad ($self->__parse_angle ($ra));
	    my $body = Astro::Coord::ECI::Star->new(
		name	=> $name,
		sun	=> $self->_sky_object( 'sun' ),
	      );
	    $body->position ($ra, deg2rad ($self->__parse_angle ($dec)),
		$rng * PARSEC, deg2rad ($pmra * 24 / 360 / cos ($ra) / SPY2DPS),
		deg2rad ($pmdec / SPY2DPS), $pmrec);
	    push @{$self->{sky}}, $body;
	    return $output;
	},
	tle	=> \&_sky_tle,	# Undocumented. That means I can revoke
				# at any time, without notice. If you
				# need this functionality, please
				# contact me.
    );

    sub sky : Verb() {
	my ( $self, undef, @args ) = __arguments( @_ );	# $opt unused

	my $verb = lc ( shift @args || 'list' );

	if ( my $code = $handler{$verb} ) {
	    return $code->( $self, @args );
	} else {
	    $self->wail("'sky' subcommand '$verb' not known");
	}
	return;	# We can't get here, but Perl::Critic does not know this.
    }

}

# Given the name of a potential background object, return its
# definition. This is an array in list context, or a quoted string in
# scalar context.
sub _sky_class_components {
    my ( $self, $name ) = @_;
    my $info = $self->{sky_class}{ fold_case( $name ) }
	or $self->weep( "No class defined for $name" );
    my ( $class, @attr ) = @{ $info };
    # We rely on sky( class => $name, $class, ... ) keeping the name
    # last.
    $name = pop @attr;
    pop @attr;	# 'name';
    my @parts = ( qw{ sky class }, $name, $class, @attr );
    wantarray
	and return @parts;
    return join ' ', map { quoter( $_ ) } @parts;
}

# Given the name of a potential sky object, instantiate it. Named
# arguments are optional; the following are supported:
#   fatal = Whether failure to find the name is fatal. Default is true.
sub _sky_object {
    my ( $self, $name, %opt ) = @_;
    defined $opt{fatal}
	or $opt{fatal} = 1;
    if ( my $info = $self->{sky_class}{ fold_case( $name ) } ) {
	my ( $class, @attr ) = @{ $info };
	return $class->new( @attr );
    } elsif ( $opt{fatal} ) {
	$self->weep( "No class defined for $name" );
    }
    return;
}

sub _sky_tle {
    my ( $self, $tle ) = @_;
    my @bodies = Astro::Coord::ECI::TLE::Set->aggregate(
	Astro::Coord::ECI::TLE->parse( $tle ) );
    my %extant = map { $_->get( 'id' ) => 1 }
	grep { embodies( $_, 'Astro::Coord::ECI::TLE' ) }
	@{ $self->{sky} };
    foreach my $body ( @bodies ) {
	my $id = $body->get( 'id' );
	$extant{$id}
	    and $self->wail( "Duplicate sky entry $id" );
    }
    push @{ $self->{sky} }, @bodies;
    return sprintf "sky tle %s\n", quoter( $tle );
}

sub source : Verb( optional! ) {
    my ( $self, $opt, $src, @args ) = __arguments( @_ );

    my $output;
    my $reader = $self->_file_reader( $src, $opt )
	or return;

    my @level1_cache;
    my $level1_context = {};
    my $fetcher = $opt->{level1} ? sub {
	@level1_cache
	    and return shift @level1_cache;
	my $buffer = $reader->();
	@level1_cache = $self->_rewrite_level1_command(
	    $buffer, $level1_context );
	return shift @level1_cache;
    } : $reader;

    my $frames = $self->_frame_push( source => \@args );
    # Note that level1 is unsupported, and works only when the
    # options are passed as a hash. It will go away when support for
    # the original satpass script is dropped.
    $self->{frame}[-1]{level1} = $opt->{level1};
    my $err;
    my $ok = eval { while ( defined( my $input =  $fetcher->() ) ) {
	    if ( defined ( my $buffer = $self->execute( $fetcher,
			    $input ) ) ) {
		$output .= $buffer;
	    }
	}
	1;
    } or $err = $@;

    $self->_frame_pop( $frames );
    $ok or $self->whinge( $err );

    $opt->{level1} and $self->_rewrite_level1_macros();
    return $output;
}

{

    my %handler = (
	config	=> sub {
	    my ( $self, $obj, undef, $opt, @args ) = @_;	# $method unused
	    @args or @args = $obj->attribute_names();
	    my ( $rslt, @values, $virgin );
	    $opt->{changes}
		and $virgin = $self->_get_spacetrack_default();
	    foreach my $name ( @args ) {
		$rslt = $obj->get( $name );
		$rslt->is_success()
		    or return $rslt;
		my $value = $rslt->content();
		no warnings qw{ uninitialized };
		$opt->{changes}
		    and $value eq $virgin->getv( $name )
		    and next;
		push @values, [ $name, $value ];
	    }
	    if ( $opt->{raw} ) {
		$rslt->content( \@values );
	    } else {
		$opt->{raw} and return \@values;
		my $output = '';
		foreach ( @values ) {
		    $output .= quoter( qw{ spacetrack set }, @{ $_ } ) . "\n";
		}
		$rslt->content( $output );
	    }
	    return $rslt;
	},
	get	=> sub {
	    my ( undef, $obj, undef, $opt, @args ) = @_;	# Invocant, $method unused
	    my $rslt = $obj->get( @args );
	    $rslt->is_success
		and not $opt->{raw}
		and $rslt->content( scalar quoter(
		    qw{ spacetrack set }, $args[0], $rslt->content() ) );
	    return $rslt;
	},
	set	=> sub {
	    my ( undef, $obj, $method, undef, @args ) = @_;	# Invocant, $opt unused
	    return $obj->$method( @args );
	},
    );
    $handler{getv} = $handler{get};
    $handler{show} = $handler{config};
    $handler{spacetrack_query_v2} = $handler{set};

    my %suppress_output = map { $_ => 1 } '', 'set';

    # Attributes must all be on one line to process correctly under
    # 5.8.8.
    sub spacetrack : Verb( all! changes! descending! effective! end_epoch=s exclude=s last5! raw! rcs! status=s sort=s start_epoch=s tle! verbose! ) {
	my ( $self, $opt, $method, @args ) = __arguments( @_ );

	exists $opt->{raw}
	    or $opt->{raw} = ( ! _is_interactive() );

	my $verbose = delete $opt->{verbose};

	my $object = $self->_helper_get_object( 'spacetrack' );
	$method !~ m/ \A _ /smx and $object->can( $method )
	    or $handler{$method}
	    or $self->wail("No such spacetrack method as '$method'");

	$opt->{start_epoch}
	    and $opt->{start_epoch} = $self->__parse_time(
		$opt->{start_epoch} );
	$opt->{end_epoch}
	    and $opt->{end_epoch} = $self->__parse_time(
		$opt->{end_epoch} );

	my ( $rslt, @rest );
       	if ( $handler{$method} ) {
	    ( $rslt, @rest ) = $handler{$method}->(
		$self, $object, $method, $opt, @args );
	} else {
	    delete $opt->{raw};
	    ( $rslt, @rest ) = $object->$method( $opt, @args );
	}

	$rslt->is_success()
	    or $self->wail( $rslt->status_line() );

	my $output;
	my $content_type = $object->content_type || '';

	if ($content_type eq 'orbit') {

	    push @{$self->{bodies}},
		Astro::Coord::ECI::TLE->parse ($rslt->content);
	    $verbose
		and $output .= $rslt->content;

	} elsif ($content_type eq 'iridium-status') {

	    $self->_iridium_status( @rest );
	    $verbose
		and $output .= $rslt->content;

	} elsif ( ! $suppress_output{$content_type} || $verbose ) {

	    $output .= $rslt->content;

	}

	defined $output
	    and $output =~ s/ (?<! \n ) \z /\n/smx;
	return $output;
    }

}

sub st : Verb() {
    my ( $self, undef, $func, @args ) = __arguments( @_ );	# $opt unused

    $self->_deprecation_notice( method => 'st' );
    if ( 'localize' eq $func ) {
	my $st = $self->_helper_get_object( 'spacetrack' );
	foreach my $key (@args) {
	    exists $self->{frame}[-1]{spacetrack}{$key}
		or $self->{frame}[-1]{spacetrack}{$key} =
		$st->get ($key)->content
	}
    } else {
	goto &spacetrack;
    }
    return;
}

sub station {
    my ( $self ) = @_;

    defined $self->{height}
	and defined $self->{latitude}
	and defined $self->{longitude}
	or $self->wail( 'You must set height, latitude, and longitude' );

    return Astro::Coord::ECI->new (
	    almanac_horizon	=> $self->{_almanac_horizon},
	    horizon	=> $self->get( 'horizon' ),
	    id		=> 'station',
	    name	=> $self->{location} || '',
	    refraction	=> 1,
	)->geodetic (
	    deg2rad( $self->{latitude} ),
	    deg2rad( $self->{longitude} ),
	    $self->{height} / 1000
	);
}

# TODO I must have thought -reload would be good for something, but it
# appears I never implemented it.

sub status : Verb( name! reload! ) {
    my ( $self, $opt, @args ) = __arguments( @_ );

    @args or @args = qw{show};

    my $verb = lc (shift (@args) || 'show');

    if ( $verb eq 'iridium' ) {
	$self->_deprecation_notice( status => 'iridium', 'show' );
	$verb = 'show';
    }

    my $output;

    if ($verb eq 'add' || $verb eq 'drop') {

	Astro::Coord::ECI::TLE->status ($verb, @args);
	foreach my $tle (@{$self->{bodies}}) {
	    $tle->get ('id') == $args[0] and $tle->rebless ();
	}

    } elsif ($verb eq 'clear') {

	Astro::Coord::ECI::TLE->status ($verb, @args);
	foreach my $tle (@{$self->{bodies}}) {
	    $tle->rebless ();
	}

    } elsif ($verb eq 'show' || $verb eq 'list') {

	my @data = Astro::Coord::ECI::TLE->status( 'show', @args );
	@data = sort {$a->[3] cmp $b->[3]} @data if $opt->{name};
	$output .= '';	# Don't want it to be undef.

	my $encoder = ( HAVE_TLE_IRIDIUM &&
	    Astro::Coord::ECI::TLE::Iridium->can(
	    '__encode_operational_status' ) ) || sub { return $_[2] };

	foreach my $tle (@data) {
	    my $status = $encoder->( undef, status => $tle->[2] );
	    $output .= quoter( 'status', 'add',
		$tle->[0], $tle->[1], $status,
		$tle->[3], $tle->[4] ) . "\n";
	}

    } else {
	$output .= '';	# Don't want it to be undef.
	$output .= Astro::Coord::ECI::TLE->status ($verb, @args);
    }

    return $output;

}

sub system : method Verb() {	## no critic (ProhibitBuiltInHomonyms)
    my ( $self, undef, $verb, @args ) = __arguments( @_ );	# $opt unused

    @args = map {
	bsd_glob( $_, GLOB_NOCHECK | GLOB_BRACE | GLOB_QUOTE )
    } @args;
    my $stdout = $self->{frame}[-1]{localout};
    my @exported = keys %{ $self->{exported} };
    local @ENV{@exported} = map { $mutator{$_} ? $self->get( $_ ) :
	$self->{exported}{$_} } @exported;
    if ( defined $stdout && -t $stdout ) {
	CORE::system {$verb} $verb, @args;
	return;
    } else {
	$self->load_package( { fatal => 'wail' }, 'IPC::System::Simple' );
	return IPC::System::Simple::capturex( $verb, @args );
    }
}

sub time : method Verb() Tweak( -unsatisfied ) {	## no critic (ProhibitBuiltInHomonyms,RequireArgUnpacking)
    my ($self, @args) = map { ARRAY_REF eq ref $_ ? @{ $_ } : $_ } @_;
    $have_time_hires->() or $self->wail( 'Time::HiRes not available' );
    $self->_dispatch_check( time => $args[0] );
    my $start = Time::HiRes::time();
    # If we're inside an unsatisfied if() we do not do the timing,
    # because dispatch() is probably a no-op.
    $self->{_unsatisfied_if}
	or $self->_add_post_dispatch(
	sub {
	    return sprintf "%.3f seconds\n", Time::HiRes::time() - $start;
	},
    );
    return $self->dispatch( @args );
}

sub time_parser : Verb() {
    splice @_, ( HASH_REF eq ref $_[1] ? 2 : 1 ), 0, 'time_parser';
    goto &_helper_handler;
}

sub tle : Verb( :compute ) {
    my ( $self, $opt, @args ) = __arguments( @_ );
    @args
	and not $opt->{choose}
	and $opt->{choose} = \@args;

    my $bodies = $self->__choose( $opt->{choose}, $self->{bodies} );
    my $tplt_name = delete $opt->{_template};
    return $self->__format_data( $tplt_name => $bodies, $opt );
}

sub __tle_options {
    my ( $self, $opt ) = @_;
    my @lgl = qw{ choose=s@ };
    $opt->{_template} = 'tle';
    my $code = sub {
	my ( $name, $value ) = @_;
	$opt->{_template} = $value ? "tle_$name" : 'tle';
	return;
    };
    my $fmtr = $self->get( 'formatter' );
    if ( $fmtr->can( '__list_templates' ) ) {
	foreach ( $fmtr->__list_templates() ) {
	    m/ \A tle_ ( \w+ ) \z /smx
		or next;
	    push @lgl, "$1!", $code;
	}
    }
    return \@lgl;
}


sub unexport : Verb() {
    my ( $self, undef, @args ) = __arguments( @_ );	# $opt unused

    foreach my $name ( @args ) {
	delete $self->{exported}{$name};
    }
    return;
}


sub validate : Verb( quiet! ) {
    my ( $self, $opt, @args ) = __arguments( @_ );

    my $pass_start = $self->__parse_time (
	shift @args, $self->_get_today_noon());
    my $pass_end = $self->__parse_time (shift @args || '+7');
    $pass_start >= $pass_end
	and $self->wail( 'End time must be after start time' );

    @{ $self->{bodies} }
	or $self->wail( 'No bodies selected' );

#	Validate each body.

    my @valid;
    foreach my $tle ( $self->_aggregate( $self->{bodies} ) ) {
	$tle->validate( $opt, $pass_start, $pass_end )
	    and push @valid, $tle->members();
    }

    $self->{bodies} = \@valid;

    return;
}


sub version : Verb() {
    return <<"EOD";

@{[__PACKAGE__]} $VERSION - Satellite pass predictor
based on Astro::Coord::ECI @{[Astro::Coord::ECI->VERSION]}
Copyright (C) 2009-2019 by Thomas R. Wyant, III

EOD
}

########################################################################

#   $self->_add_post_dispatch( $code_ref );

#   Add a reference to code to be executed after the current interactive
#   method is dispatched. All such code is executed, in the reverse of
#   the order it was added. The only argument will be the invocant.
#   Because it is added to the current execution frame, if the
#   interactive method being dispatched is begin(), the code will be
#   executed after the corresponding end(). Code to make the execution
#   happen is, of course, in dispatch().
sub _add_post_dispatch {
    my ( $self, $code ) = @_;
    push @{ $self->{frame}[-1]{post_dispatch} ||= [] }, $code;
    return;
}

#	$self->_aggregate( $list_ref );

sub __add_to_observing_list {
    my ( $self, @args ) = @_;
    foreach my $body ( @args ) {
	embodies( $body, 'Astro::Coord::ECI::TLE' )
	    and next;
	my $id = $body->get( 'id' );
	defined $id
	    or $id = $body->get( 'name' );
	$self->wail( "Body $id is not a TLE" );
    }
    push @{ $self->{bodies} }, @args;
    return $self;
}

#	This is just a wrapper for
#	Astro::Coord::ECI::TLE::Set->aggregate.

sub _aggregate {
    my ( $self, $bodies ) = @_;
    local $Astro::Coord::ECI::TLE::Set::Singleton = $self->{singleton};
    return Astro::Coord::ECI::TLE::Set->aggregate ( @{ $bodies } );
}

#	_apply_boolean_default( \%opt, $invert, @keys );
#
#	This subroutine defaults a set of boolean options. The keys in
#	the set are specified in @keys, and the defined values are
#	inverted before the defaults are applied if $invert is true.
#	Nothing is returned.

sub _apply_boolean_default {
    my ( $opt, $invert, @keys ) = @_;
    my $found = 0;
    foreach my $key ( @keys ) {
	if ( exists $opt->{$key} ) {
	    $invert
		and $opt->{$key} = ( !  $opt->{$key} );
	    $found |= ( $opt->{$key} ? 2 : 1 );
	}
    }
    my $default = $found < 2;
    foreach my $key ( @keys ) {
	exists $opt->{$key}
	    or $opt->{$key} = $default;
    }
    return;
}

#	$self->_attribute_exists( $name, %arg );
#
#	This method returns true if an accessor for the given attribute
#	exists, and croaks otherwise.
#	Attributes in the %level1_attr hash fail unless in level1 mode
#	Named arguments:
#	  query: if true, returns false if attribute does not exist

{
    my %level1_attr = map { $_ => 1 } qw{ sun };

    sub _attribute_exists {
	my ( $self, $name, %arg ) = @_;
	exists $accessor{$name}
	    and ( ! $level1_attr{$name} || $self->{frame}[-1]{level1} )
	    and return $accessor{$name};
	$arg{query}
	    or $self->wail("No such attribute as '$name'");
	return;
    }
}

{

    my %spacetrack_attributes;
    $have_astro_spacetrack->()
	and %spacetrack_attributes = map { $_ => 1 }
	Astro::SpaceTrack->attribute_names();

    my %special = (
	formatter	=> sub {
	    my ( $obj, $attr ) = @_;
	    $obj->can( $attr )
		or return NULL;
	    return $obj->$attr();
	},
	spacetrack	=> sub {
	    my ( $obj, $attr ) = @_;
	    $spacetrack_attributes{$attr}
		or return NULL;
	    return $obj->getv( $attr );
	},
	time_parser	=> sub {
	    my ( $obj, $attr ) = @_;
	    $obj->can( $attr )
		or return NULL;
	    return $obj->$attr();
	},
    );

    # my $value = $self->_attribute_value( $name );
    #
    # Return an attribute value. If the attribute is 'formatter',
    # 'spacetrack' or 'time_parser' you can specify a dot and the name
    # of an attribute of the relevant object, e.g. spacetrack.username.
    # If the attribute does not exist you get back manifest constant
    # NULL, which is a reference to undef blessed into class 'Null'.
    sub _attribute_value {
	my ( $self, $name ) = @_;
	my ( $attr, $sub ) = split qr{ [.] }smx, $name, 2;
	$accessor{$attr}
	    or return NULL;
	my $rslt = $self->get( $attr );
	if ( defined $sub ) {
	    $rslt
		and my $code = $special{$attr}
		or return NULL;
	    $rslt = $code->( $rslt, $sub );
	}
	return $rslt;
    }
}

# Documented in POD

{
    my %chooser = (
        ''	=> sub {
	    my ( $sel ) = @_;
	    my @rslt;
	    foreach my $s ( split qr{ \s* , \s* }smx, $sel ) {
		if ( $s =~ m/ \D /smx || $s < 1000 ) {
		    my $re = qr{\Q$s\E}i;
		    push @rslt, sub {
			my ( $tle, $context ) = @_;
			$context->{name} ||= $tle->get( 'name' );
			defined $context->{name}
			    or return;
			return $context->{name} =~ $re;
		    };
		} else {
		    push @rslt, sub {
		        my ( $tle, $context ) = @_;
			$context->{id} ||= $tle->get( 'id' );
			return $context->{id} == $s;
		    };
		}
	    }
	    return @rslt;
	},
	CODE_REF()	=> sub {
	    my ( $sel ) = @_;
	    return $sel;
	},
	REGEXP_REF()	=> sub {
	    my ( $sel ) = @_;
	    return sub {
	        my ( $tle, $context ) = @_;
		$context->{name} ||= $tle->get( 'name' );
		return $context->{name} =~ $sel;
	    };
	},
    );

    sub __choose {
	my ( $self, @args ) = @_;
	my $opt = HASH_REF eq ref $args[0] ? shift @args : {};
	my $choice = shift @args;
	defined $choice
	    or $choice = [];
	ARRAY_REF eq ref $choice
	    or $self->weep( 'Choice invalid' );
	my @rslt;
	my @selector;
	foreach my $sel ( @{ $choice } ) {
	    my $ref = ref $sel;
	    my $code = $chooser{$ref}
	    or $self->weep( "$ref not supported as chooser" );
	    push @selector, $code->( $sel );
	}

	$opt->{bodies}
	    and push @args,
		$self->_aggregate( $self->{bodies} );
	$opt->{sky}
	    and push @args, $self->{sky};

	@args = map { ARRAY_REF eq ref $_ ? @{ $_ } : $_ } @args;

	not @selector
	    and return wantarray ? @args : \@args;

	foreach my $tle ( @args ) {
	    ARRAY_REF eq ref $tle
		and $self->weep( 'Schwartzian-transform objects not supported' );

	    my $match = $opt->{invert};
	    my $context = {};
	    foreach my $sel ( @selector ) {
		$sel->( $tle, $context )
		    or next;
		$match = !$match;
		last;
	    }

	    $match and push @rslt, $tle;
	}

	return wantarray ? @rslt : \@rslt;
    }

}



#	$self->_deprecation_notice( $type, $name );
#
#	This method centralizes deprecation. Type is 'attribute' or
#	'method'. Deprecation is driven of the %deprecate hash. Values
#	are:
#	    false - no warning
#	    1 - warn on first use
#	    2 - warn on each use
#	    3 - die on each use.
#
#	$self->_deprecation_in_progress( $type, $name )
#
#	This method returns true if the deprecation is in progress. In
#	fact it returns the deprecation level.

{

    my %deprecate = (
	attribute => {
	    country	=> 0,
	    date_format	=> 0,
	    desired_equinox_dynamical	=> 0,
	    explicit_macro_delete	=> 0,
	    gmt		=> 0,
	    local_coord	=> 0,
	    perltime	=> 0,
	    time_format	=> 0,
	    tz		=> 0,
	},
	method => {
	    st		=> 0,
	},
	status	=> {
	    iridium	=> 3,
	},
    );

    sub _deprecation_notice {
	my ( $self, $type, $name, $repl ) = @_;
	$deprecate{$type} or return;
	$deprecate{$type}{$name} or return;
	my $msg = sprintf 'The %s %s is %s', $name, $type,
	    $deprecate{$type}{$name} > 2 ? 'removed' : 'deprecated';
	defined $repl
	    and $msg .= "; use $repl instead";
	$deprecate{$type}{$name} >= 3
	    and $self->wail( $msg );
	warnings::enabled( 'deprecated' )
	    and $self->whinge( $msg );
	$deprecate{$type}{$name} == 1
	    and $deprecate{$type}{$name} = 0;
	return;
    }

    sub _deprecation_in_progress {
	my ( undef, $type, $name ) = @_;	# Invocant unused
	$deprecate{$type} or return;
	return $deprecate{$type}{$name};
    }

}

# my ( $obj ) = $self->_drop_from_sky( $name );
# The return is an array containing the dropped body, or nothing if the
# body was not found.
sub _drop_from_sky {
    my ( $self, $name ) = @_;
    defined( my $inx = $self->_find_in_sky( $name ) )
	or return;
    return splice @{ $self->{sky} }, $inx, 1;
}

#	$code = $self->_file_reader( $file, \%opt );
#
#	This method returns a code snippet that returns the contents of
#	the file one line at a time. The $file can be any of:
#
#	* An open handle
#	* A URL (if LWP::UserAgent can be loaded)
#	* A file name
#	* A scalar reference
#	* An array reference
#	* A code reference, which is returned unmodified
#
#	The code snippet will return undef at end-of-file.
#
#	The following keys in %opt are recognized:
#	{encoding} specifies the encoding of the file. How this is used
#	    on the $file argument as follows:
#	    * An open handle -- unused
#	    * A URL ----------- unused (encoding taken from HTTP::Response)
#	    * A file name ----- used (default is utf-8)
#	    * A scalar ref ---- used (default is un-encoded)
#	    * An array ref ---- unused
#	    * A code ref ------ unused
#	{glob} causes the contents of the file to be returned, rather
#	    than a reader.
#	{optional} causes the code to simply return on an error, rather
#	    than failing.

sub _file_reader {
    my ( $self, $file, $opt ) = @_;

    if ( openhandle( $file ) ) {
	$opt->{glob}
	    or return sub { return scalar <$file> };
	local $/ = undef;
	return scalar <$file>;
    }

    my $ref = ref $file;
    my $code = $self->can( "_file_reader_$ref" )
	or $self->wail( sprintf "Opening a $ref ref is unsupported" );

    goto &$code;
}

# Most of the following are called using '$self->can(
# "_file_reader_$ref" )', and there is no way a static analysis tool can
# find such calls. So we just have to exempt them from Perl::Critic

sub _file_reader_ {	## no critic (ProhibitUnusedPrivateSubroutines)
    my ( $self, $file, $opt ) = @_;

    defined $file
	and chomp $file;

    if ( ! defined $file || ! ref $file &&  '' eq $file ) {
	$opt->{optional} and return;
	$self->wail( 'Defined file required' );
    }

    if ( $self->_file_reader__validate_url( $file ) ) {
	my $ua = LWP::UserAgent->new();
	my $resp = $ua->get( $file );
	$resp->is_success()
	    or do {
	    $opt->{optional} and return;
	    $self->wail( "Failed to retrieve $file: ",
		$resp->status_line() );
	};
	$opt->{glob} and return $resp->decoded_content();
	$opt = { %{ $opt }, encoding => $resp->content_charset() };
	return $self->_file_reader(
	    \( scalar $resp->content() ),
	    $opt,
	);
    } else {
	my $encoding = $opt->{encoding} || 'utf-8';
	my $fh = IO::File->new(
	    $self->expand_tilde( $file ),
	    "<:encoding($encoding)",
	) or do {
	    $opt->{optional} and return;
	    $self->wail( "Failed to open $file: $!" );
	};
	$opt->{glob}
	    or return sub { return scalar <$fh> };
	local $/ = undef;
	return scalar <$fh>;
    }
}

sub _file_reader__validate_url {
    my ( undef, $url ) = @_;		# Invocant unused

    load_package( 'LWP::UserAgent' )
	or return;

    load_package( 'URI' )
	or return;

    load_package( 'LWP::Protocol' )
	or return;

    my $obj = URI->new( $url )
	or return;
    $obj->can( 'authority' )
	or return 1;

    defined( my $scheme = $obj->scheme() )
	or return;
    LWP::Protocol::implementor( $scheme )
	or return;

    return 1;
}

sub _file_reader_ARRAY {	## no critic (ProhibitUnusedPrivateSubroutines)
    my ( undef, $file, $opt ) = @_;	# Invocant unused

    my $inx = 0;
    $opt->{glob}
	or return sub { return $file->[$inx++] };
    my $buffer;
    foreach ( @{ $file } ) {
	$buffer .= $_;
	$buffer =~ m/ \n \z /smx
	    or $buffer .= "\n";
    }
    return $buffer;
}

sub _file_reader_CODE {		## no critic (ProhibitUnusedPrivateSubroutines)
    my ( undef, $file, $opt ) = @_;	# Invocant unused
    $opt->{glob}
	or return $file;
    my $buffer;
    local $_;
    while ( defined( $_ = $file->() ) ) {
	$buffer .= $_;
	$buffer =~ m/ \n \z /smx
	    or $buffer .= "\n";
    }
    return $buffer;
}

sub _file_reader_SCALAR {	## no critic (ProhibitUnusedPrivateSubroutines)
    my ( $self, $file, $opt ) = @_;

    $opt->{glob}
	and return ${ $file };
    my $mode = $opt->{encoding} ? "<:encoding($opt->{encoding})" : '<';

    my $fh = IO::File->new( $file, $mode )	# Needs IO::File 1.14.
	or $self->wail( "Failed to open SCALAR ref: $!" );

    return sub { return scalar <$fh> };
}

# $inx = $self->_find_in_sky( $name )
# The return is the index of the named body in @{ $self->{sky} }, or
# undef if it is not present. 'Sun' and 'Moon' are special cases;
# everything else is presumed to be found by name.
sub _find_in_sky {
    my ( $self, $name ) = @_;

    my $re = qr/ \A \Q$name\E \z /smxi;
    foreach my $inx ( 0 .. $#{ $self->{sky} } ) {
	$self->{sky}[$inx]->get( 'name' ) =~ $re
	    and return $inx;
    }
    return;
}

# Documented in POD

sub __format_data {
    my ( $self, $action, $data, $opt ) = @_;
    return $self->_get_formatter_object( $opt )->format(
	sp	=> $self,
	template => $action,
	data => $data
    );
}

#	$frames = $satpass2->_frame_push($type, \@args);
#
#	This method pushes a context frame on the stack. The $type
#	describes the frame, and goes in the frame's {type} entry, but
#	is currently unused. The \@args entry goes in the {args} key,
#	and is the basis of argument expansion. The return is the number
#	of frames that were on the stack _BEFORE_ the now-current frame
#	was added to the stack. This gets passed to _frame_pop() to
#	restore the context stack to its status before the current frame
#	was added.

sub _frame_push {
    my $self = shift;
    my $type = shift;
    my $args = shift || [];
    my $frames = scalar @{$self->{frame} ||= []};
    my $stdout;
    @{$self->{frame}}
	and $stdout = exists $self->{frame}[-1]{localout} ?
	    $self->{frame}[-1]{localout} :
	    $self->{frame}[-1]{stdout};
####    defined $stdout or $stdout = select();
    my ( undef, $filename, $line ) = caller;
    push @{$self->{frame}}, {
	type => $type,
	args => $args,
	define => {},		# Macro defaults done with :=
	local => {},
	localout => undef,	# Output for statement.
	macro => {},
	pushed_by => "$filename line $line",
	spacetrack => {},
	stdout => $stdout,
    };
    return $frames;
}

#	$satpass2->_frame_pop($frames);
#	$satpass2->_frame_pop($type => $frames);
#	$satpass2->_frame_pop();
#
#	This method pops context frames off the stack until there are
#	$frames frames left. The optional $type argument is currently
#	unused, but was intended for type checking should that become
#	necessary. The zero-argument call pops one frame off the stack.
#	An exception is thrown if there are no frames left to pop. After
#	all required frames are popped, an exception is thrown if the
#	pop was done with a continued input line pending.

{

    my %force_set;	# If true, the named attribute is set with the
			# set() method even if a hash key of the same
			# name exists. This is set with
			# _frame_pop_force_set(), typically where the
			# mutator is defined.

    sub _frame_pop {
	my ($self, @args) = @_;
##	my $type = @args > 1 ? shift @args : undef;
	@args > 1 and shift @args;	# Currently unused
	my $frames = @args ? shift @args : @{$self->{frame}} - 1;
	while (@{$self->{frame}} > $frames) {
	    my $frame = pop @{$self->{frame}}
		or $self->weep( 'No frame to pop' );
	    my $local = $frame->{local} || {};
	    foreach my $name ( keys %{ $local } ) {
		my $value = $local->{$name};
		if ( exists $self->{$name} && !$force_set{$name} ) {
		    $self->{$name} = $value;
		} else {
		    $self->set( $name, $value );
		}
	    }
	    foreach my $key (qw{macro}) {
		my $info = $frame->{$key} || {};
		foreach my $name ( keys %{ $info } ) {
		    $self->{$key}{$name} = $info->{ $name };
		}
	    }
	    ($frame->{spacetrack} && %{$frame->{spacetrack}})
		and $self->_get_spacetrack()->set(%{$frame->{spacetrack}});
	}
	if (delete $self->{pending}) {
	    $self->wail('Input ended on continued line');
	}
	return;
    }

    # Force use of the set() method even if there is an attribute of the
    # same name.
    sub _frame_pop_force_set {
	foreach my $name ( @_ ) {
	    $force_set{$name} = 1;
	}
	return;
    }
}

sub _get_browser_command {
    my ( $self, $val ) = @_;
    defined $val
	or $val = $self->{webcmd};
    defined $val
	and '' ne $val
	or return $val;
    '1' eq $val
	or return $val;
    require Browser::Open;
    return Browser::Open::open_browser_cmd();
}

#	$dumper = $self->_get_dumper();
#
#	This method returns a reference to code that can be used to dump
#	data. The first time it is called it goes through a list of
#	possible classes, and uses the first one it can load, dying if
#	it can not load any of them. After the first successful call, it
#	simply returns the cached dumper.

{
    my $dumper;
    my %kode = (
	'Data::Dumper' => sub {
	    local $Data::Dumper::Terse = 1;
	    Data::Dumper::Dumper(@_);
	},
    );
    sub _get_dumper {
	my ($self) = @_;
	my %dmpr;
	my @mod;
	return $dumper ||= do {
	    foreach (qw{YAML::Dump Data::Dumper::Dumper}) {
		my ($module, $routine) = m/ (.*) :: (.*) /smx;
		push @mod, $module;
		$dmpr{$module} = $routine;
	    }
	    my $mod = $self->_load_module(@mod);
	    $kode{$mod} || $mod->can($dmpr{$mod});
	};
    }
}

#	$fmt = $satpass2->_get_dumper_object();
#
#	Gets a dumper object. This object must conform to the
#	Astro::App::Satpass2::Format interface.

{

    my $dumper;

    sub _get_dumper_object {
	return ( $dumper ||= do {
		require Astro::App::Satpass2::Format::Dump;
		Astro::App::Satpass2::Format::Dump->new();
	    }
	);
    }

}

#	$fmt = $satpass2->_get_formatter_object( $opt );
#
#	Gets the Astro::App::Satpass2::Format object. If $opt->{dump} is true,
#	returns a dumper object; otherwise returns the currently-set
#	formatter object.


sub _get_formatter_object {
    my ( $self, $opt ) = @_;
    $opt ||= {};
    return ( $opt && $opt->{dump} ) ? $self->_get_dumper_object() :
	$self->get( 'formatter' );
}

sub _get_formatter_attribute {
    my ( $self, $name ) = @_;
    return $self->get( 'formatter' )->$name();
}

#	$st = $satpass2->_get_geocoder()

#	Gets the geocoder object, instantiating it if
#	necesary.

sub _get_geocoder {
    my ( $self ) = @_;
    if ( ! exists $self->{geocoder} ) {
	my ( $class, $obj );
	$class = $default_geocoder->()
	    and $obj = $class->new();
	$self->{geocoder} = $obj;
    }
    return $self->{geocoder};
}

#	$boolean = $satpass2->_get_interactive();
#
#	This method returns true if the script is running interactively,
#	and false otherwise. Currently, it returns the results of -t
#	STDIN.

sub _get_interactive {
    return -t STDIN;
}

#	$code = $satpass2->_get_readline();
#
#	Returns code to read input. The code takes an argument which
#	will be used as a prompt if one is needed. What is actually
#	returned is:
#
#	If $satpass2->_get_interactive() is false, the returned code
#	just reads standard in. Otherwise,
#
#	if Term::ReadLine can be loaded, a Term::ReadLine object is
#	instantiated if need be, and the returned code calls
#	Term::ReadLine->readline($_[0]) and returns whatever that gives
#	you. Otherwise,
#
#	Otherwise the returned code writes its argument to STDERR and
#	reads STDIN.
#
#	Note that the return from this subroutine may or may not be
#	chomped.

{
    my $rl;

    sub _get_readline {
	my ($self) = @_;
	# The Perl::Critic recommendation is IO::Interactive, but that
	# fiddles with STDOUT. We want STDIN, because we want to behave
	# differently if STDIN is a pipe, but not if STDOUT is a pipe.
	# We're still missing the *ARGV logic, but that's OK too, since
	# we use the contents of @ARGV as commands, not as file names.
	return do {
	    my $buffer = '';
	    if ($self->_get_interactive()) {
		eval {
		    load_package( 'Term::ReadLine' )
			or return;
		    $rl ||= Term::ReadLine->new('satpass2');
		    sub {
			defined $buffer or return $buffer;
			return ( $buffer = $rl->readline($_[0]) );
		    }
		} || sub {
		    defined $buffer or return $buffer;
		    print STDERR $_[0];
		    return (
			$buffer = <STDIN>	## no critic (ProhibitExplicitStdin)
		    );
		};
	    } else {
		sub {
		    defined $buffer or return $buffer;
		    return (
			$buffer = <STDIN>	## no critic (ProhibitExplicitStdin)
		    );
		};
	    }
	};
    }
}

sub _get_time_parser_attribute {
    my ( $self, $name ) = @_;
    return $self->{time_parser}->$name();
}

#	$st = $satpass2->_get_spacetrack()

#	Gets the Astro::SpaceTrack object, instantiating it if
#	necesary.

sub _get_spacetrack {
    my ( $self ) = @_;
    exists $self->{spacetrack}
	or $self->{spacetrack} = $self->_get_spacetrack_default();
    return $self->{spacetrack};
}

#	$st = $satpass2->_get_spacetrack_default();
#
#	Returns a new Astro::SpaceTrack object, initialized with this
#	object's webcmd, and with its filter attribute set to 1 and its
#	iridium_status_format set to 'kelso'.

sub _get_spacetrack_default {
    my ( $self ) = @_;
    $have_astro_spacetrack->()
	or return;
    return Astro::SpaceTrack->new (
	webcmd => $self->{webcmd},
	filter => 1,
	iridium_status_format => 'kelso',
    );
}

sub _get_today_midnight {
    my $self = shift;
    my $gmt = $self->get( 'formatter' )->gmt();
    my @time = $gmt ? gmtime() : localtime();
    $time[0] = $time[1] = $time[2] = 0;
    return $gmt ? time_gm(@time) : time_local(@time);
}

sub _get_today_noon {
    my $self = shift;
    my $gmt = $self->get( 'formatter' )->gmt();
    my @time = $gmt ? gmtime() : localtime();
    $time[0] = $time[1] = 0;
    $time[2] = 12;
    return $gmt ? time_gm(@time) : time_local(@time);
}

sub _get_warner_attribute {
    my ( $self, $name ) = @_;
    return $self->{_warner}->$name();
}

sub _helper_get_object {
    my ( $self, $attribute ) = @_;
    my $object = $self->get( $attribute )
	or $self->wail( "No $attribute object available" );
    return $object;
}

{

    my %parse_input = (
	formatter	=> {
	    desired_equinox_dynamical => sub {
		my ( $self, undef, @args ) = @_;	# $opt unused
		if ( $args[0] ) {
		    $args[0] = $self->__parse_time( $args[0], 0 );
		}
		return @args;
	    },
	    format	=> sub {
		my ( $self, $opt, $template, @args ) = @_;
		$opt->{raw} = 1;
		return (
		    arg	=> \@args,
		    sp	=> $self,
		    template	=> $template,
		);
	    },
	},
	time_parser	=> {
	    base	=> sub {
		my ( $self, undef, @args ) = @_;	# $opt unused
		if ( @args && defined $args[0] ) {
		    $args[0] = $self->__parse_time( $args[0], time );
		}
		return @args;
	    }
	},
    );

    sub _helper_handler : Verb( changes! raw! ) {
	my ( $self, $opt, $name, $method, @args ) = __arguments( @_ );

	exists $opt->{raw}
	    or $opt->{raw} = ( ! _is_interactive() );

	defined $method
	    or $self->wail( 'No method name specified' );

	'config' eq $method
	    and return $self->_helper_config_handler( $name => $opt );

	my $object = $self->_helper_get_object( $name );
	$method !~ m/ \A _ /smx and $object->can( $method )
	    or $self->wail("No such $name method as '$method'");

	@args
	    and $parse_input{$name}
	    and $parse_input{$name}{$method}
	    and @args = $parse_input{$name}{$method}->( $self, $opt, @args );
	delete $opt->{raw}
	    and return $object->$method( @args );
	my @rslt = $object->decode( $method, @args );

	instance( $rslt[0], ref $object ) and return;
	ref $rslt[0] and return $rslt[0];
	return quoter( $name, $method, @rslt ) . "\n";
    }
}

sub _helper_config_handler {
    my ( $self, $name, $opt ) = @_;
    my $object = $self->_helper_get_object( $name );
    my $rslt = $object->config(
	changes	=> $opt->{changes},
	decode	=> ! $opt->{raw},
    );
    $opt->{raw} and return $rslt;
    my $output = '';
    foreach my $item ( @{ $rslt } ) {
	$output .= quoter( $name, @{ $item } ) . "\n";
    }
    return $output;
}

#	$satpass2->_iridium_status(\@status)

#	Updates the status of all Iridium satellites from the given
#	array, which is compatible with the second item returned by
#	Astro::SpaceTrack->iridium_status(). If no argument is passed,
#	the status is retrieved using Astro::SpaceTrack->iridium_status()

sub _iridium_status {
    my ($self, $status) = @_;
    unless ($status) {
	my $st = $self->_get_spacetrack();
	(my $rslt, $status) = $st->iridium_status;
	$rslt->is_success or $self->wail($rslt->status_line);
    }

    if ( ARRAY_REF eq ref $status ) {
	Astro::Coord::ECI::TLE->status (clear => 'iridium');
	foreach (@$status) {
	    Astro::Coord::ECI::TLE->status (add => $_->[0], iridium =>
		$_->[4], $_->[1], $_->[3]);
	}
    } else {
	$self->weep(
	    'Portable status not passed, and unavailable from Astro::SpaceTrack'
	);
    }

    foreach my $tle (@{$self->{bodies}}) {
	$tle->rebless ();
    }

    return;

}

# _is_case_tolerant()
# Returns true if the OS supports case-tolerant file names. Yes, I know
# it's the file system that is important, but I don't have access to
# that level of detail.
{
    my %os = map { $_ => 1 } qw{ darwin };

    sub _is_case_tolerant {
	exists $os{$^O}
	    and return $os{$^O};
	return File::Spec->case_tolerant();
    }
}

#	_is_interactive()
#
#	Returns true if the dispatch() method is above us on the call
#	stack, otherwise returns false.

use constant INTERACTIVE_CALLER => __PACKAGE__ . '::dispatch';
sub _is_interactive {
    my $level = 0;
    while ( my @info = caller( $level ) ) {
	INTERACTIVE_CALLER eq $info[3]
	    and return $level;
	$level++;
    }
    return;
}

#	$self->_load_module ($module_name)

#	Loads the module if it has not yet been loaded. Dies if it
#	can not be loaded.

{	# Begin local symbol block

    my %version;
    BEGIN {
	%version = (
	    'Astro::SpaceTrack' => ASTRO_SPACETRACK_VERSION,
	);
    }

    sub _load_module {
	my ($self, @module) = @_;
	ARRAY_REF eq ref $module[0]
	    and @module = @{$module[0]};
	@module or $self->weep( 'No module specified' );
	my @probs;
	foreach my $module (@module) {
	    load_package ($module) or do {
		push @probs, "$module needed";
		next;
	    };
	    my $modver;
	    ($version{$module} && ($modver = $module->VERSION)) and do {
		$modver =~ s/_//g;
		$modver < $version{$module} and do {
		    push @probs,
		    "$module version $version{$module} needed";
		    next;
		};
	    };
	    return $module;
	}
	{
	    my $inx = 1;
	    while (my @clr = caller($inx++)) {
		$clr[3] eq '(eval)' and next;
		my @raw = split '::', $clr[3];
		substr ($raw[-1], 0, 1) eq '_' and next;
		push @probs, "for method $raw[-1]";
		last;
	    }
	}
	my $pfx = 'Error -';
	$self->wail(map {my $x = "$pfx $_\n"; $pfx = ' ' x 7; $x} @probs);
	return;	# Can't get here, but Perl::Critic does not know this.
    }

}	# end local symbol block.

#	$output = $self->_macro($name,@args)
#
#	Execute the named macro. The @args are of course optional.

sub _macro {
    my ($self, $name, @args) = @_;
    $self->{macro}{$name} or $self->wail("No such macro as '$name'");
    my $frames = $self->_frame_push(macro => [@args]);
    my $macro = $self->{frame}[-1]{macro}{$name} =
	delete $self->{macro}{$name};
    my $output;
    my $err;
    my $ok = eval {
	$output = $macro->execute( $name, @args );
	1;
    } or $err = $@;
    $self->_frame_pop($frames);
    $ok or $self->wail($err);
    return $output;
}

#	$angle = _parse_angle_parts ( @parts );
#
#	Joins parts of angles into an angle.
#	The @parts array is array references describing the parts in
#	decreasing significance, with [0] being the value, and [1] being
#	the number in the next larger part. For the first piece, [1]
#	should be the number in an entire circle.

sub _parse_angle_parts {
    my @parts = @_;
    my $angle = 0;
    my $circle = 1;
    my $places;
    foreach ( @parts ) {
	my ( $part, $size ) = @{ $_ };
	defined $part or last;
	$circle *= $size;
	$angle = $angle * $size + $part;
	$places = $part =~ m/ [.] ( [0-9]+ ) /smx ? length $1 : 0;
    }
    $angle *= 360 / $circle;
    if ( my $mag = sprintf '%d', $circle / 360 ) {
	$places += length $mag;
    }
    return sprintf( '%.*f', $places, $angle ) + 0;
}

# Documented in POD

sub __parse_angle {
    my ( $self, @args ) = @_;
    my $opt = HASH_REF eq ref $args[0] ? shift @args : {};
    my ( $angle ) = @args;
    defined $angle or return;

    if ( $angle =~ m/ : /smx ) {

	my ($h, $m, $s) = split ':', $angle;
	return _parse_angle_parts(
	    [ $h => 24 ],
	    [ $m => 60 ],
	    [ $s => 60 ],
	);

    } elsif ( $angle =~
	m{ \A ( [-+] )? ( [0-9]* ) d
	    ( [0-9]* (?: [.] [0-9]* )? ) (?: m
	    ( [0-9]* (?: [.] [0-9]* )? ) s? )? \z
	}smxi ) {
	my ( $sgn, $deg, $min, $sec ) = ( $1, $2, $3, $4 );
	$angle = _parse_angle_parts(
	    [ $deg => 360 ],
	    [ $min => 60 ],
	    [ $sec => 60 ],
	);
	$sgn and '-' eq $sgn and return -$angle;
	return $angle;
    }

    $opt->{accept}
	or looks_like_number( $angle )
	or $self->wail( "Invalid angle '$angle'" );

    return $angle;
}

# Documented in POD
{
    my %units = (
	au => AU,
	ft => 0.0003048,
	km => 1,
	ly => LIGHTYEAR,
	m => .001,
	mi => 1.609344,
	pc => PARSEC,
    );

    sub __parse_distance {
	my ($self, $string, $dfdist) = @_;
	defined $dfdist or $dfdist = 'km';
	my $dfunits = $dfdist =~ s/ ( [[:alpha:]]+ ) \z //smx ? $1 : 'km';
	my $units = lc (
	    $string =~ s/ \s* ( [[:alpha:]]+ ) \z //smx ? $1 : $dfunits );
	$units{$units}
	    or $self->wail( "Units of '$units' are unknown" );
	$string ne '' or $string = $dfdist;
	looks_like_number ($string)
	    or $self->wail( "'$string' is not a number" );
	return $string * $units{$units};
    }
}

# Documented in POD

sub __parse_time {
    my ($self, $time, $default) = @_;
    my $pt = $self->{time_parser};
    if ( defined( my $time = $pt->parse( $time, $default ) ) ) {
	return $time;
    }
    $self->wail( "Invalid time '$time'" );
    return;
}


#	Reset the last time set. This is called from __arguments() in
#	::Utils if the invocant is an Astro::App::Satpass2.

sub __parse_time_reset {
    my ( $self ) = @_;
    defined ( my $pt = $self->{time_parser} )
	or return;
    $pt->reset();
    return;
}

#	$string = _rad2hms ($angle)

#	Converts the given angle in radians to hours, minutes, and
#	seconds (of right ascension, presumably)

sub _rad2hms {
    my $sec = shift;
    $sec *= 12 / PI;
    my $hr = floor( $sec );
    $sec = ( $sec - $hr ) * 60;
    my $min = floor( $sec );
    $sec = ( $sec - $min ) * 60;
    my $rslt = sprintf '%2d:%02d:%02d', $hr, $min, floor( $sec + .5 );
    return $rslt;
}

#	$line = $self->_read_continuation( $in, $error_message );
#
#	Acquire a line from $in, which must be a code reference taking
#	the prompt as an argument. If $in is not a code reference, or if
#	it returns undef, we wail() with the error message.  Otherwise
#	we return the line read. I expect this to be used only by
#	_tokenize().

sub _read_continuation {
    my ( $self, $in, $error ) = @_;
    $in and defined( my $more = $in->(
	    my $prompt = $self->get( 'continuation_prompt' ) ) )
	or do {
	    $error or return;
	    ref $error eq CODE_REF
		and return $error->();
	    $self->wail( $error );
	};
    $self->{echo} and $self->whinge( $prompt, $more );
    $more =~ m/ \n \z /smx or $more .= "\n";
    return $more;
}

# my ( $obj ) = $self->_replace_in_sky( $name );
# This is restricted to objects constructed via {sky_class}.
# The return is an array containing the replaced body, or nothing if
# the body was not found.
sub _replace_in_sky {
    my ( $self, $name, $class ) = @_;
    ( $class ||= $self->{sky_class}{ fold_case( $name ) } )
	or $self->weep( "Can not replace $name; no class defined" );
    defined( my $inx = $self->_find_in_sky( $name ) )
	or return;
    return splice @{ $self->{sky} }, $inx, $inx + 1, $self->_sky_object(
	$name );
}

#	$self->_rewrite_level1_command( $buffer, $context );
#
#	This method rewrites a level1 command to its current form. The
#	arguments are the buffer containing the command, and an
#	initially-empty hash reference, which the method will use to
#	preserve context across lines of command. NOTE that more than
#	one rewritten command may be returned (e.g. 'almanac' into
#	( 'location', 'almanac' ).

{

    my %level1_map = (
	almanac	=> sub {
	    return ( 'location', $_[0] );
	},
	flare	=> sub {
	    local $_ = $_[0];
	    s/ (?<= \s ) - ( am|pm|day ) \b /-no$1/sxmg;
	    return $_;
	},
	pass	=> sub {
	    return ( 'location', $_[0] );
	},
    );

    my %level1_requote = (
	# In a macro definition:
	macro	=> {
	    # In single-quoted strings,
	    q{'}	=> sub {
		# escaped interpolations and double quotes may be
		# unescaped,
		s{ (?: \A | (?<! \\ ) ) ( (?: \\\\ )* ) \\ ( [\@\$\"] )
		}{$1$2}sxmg;
		# and the string remains single-quoted.
		$_ = qq{'$_'};
		return;
	    },
	    # In double-quoted strings,
	    q{"}	=> sub {
		# escaped interpolations and double quotes may be
		# unescaped,
		s{ (?: \A | (?<! \\ ) ) ( (?: \\\\ )* ) \\ ( [\@\$\"] )
		}{$1$2}sxmg;
		# unescaped single quotes become double quotes,
		s/ (?: \A | (?<! \\ ) ) ( (?: \\\\ )* ) ' /$1"/sxmg;
		# and the string becomes single-quoted.
		$_ = qq{'$_'};
		return;
	    },
	},
	# Anywhere else
	''	=> {
	    # In single-quoted strings,
	    q{'}	=> sub {
		# unescaped double quotes must be escaped,
		s/ (?: \A | (?<! \\ ) ) ( (?: \\\\ )* ) " /$1\\"/sxmg;
		# escaped single quotes may be unescaped,
		s/ (?: \A | (?<! \\ ) ) ( (?: \\\\ )* ) \\ ' /$1'/sxmg;
		# and the string becomes double-quoted.
		$_ = qq{"$_"};
		return;
	    },
	    # In double-quoted strings,
	    q{"}	=> sub {
		# no changes need to be made.
		$_ = qq{"$_"};
		return;
	    },
	},
    );

    sub _rewrite_level1_command {
	my ( undef, $buffer, $context ) = @_;	# Invocant unused

	my $command = delete $context->{command};

	defined $buffer
	    or return $buffer;
	$buffer =~ m/ \A \s* \z /sxm
	    and return $buffer;
	$buffer =~ s/ \A \s* [#] 2 [#] \s* //sxm
	    and return $buffer;
	$buffer =~ m/ \A \s* [#] /sxm
	    and return $buffer;

	if ( ! defined $command ) {
	    $buffer =~ m/ \A \s* ( \w+ ) /sxm
		or return $buffer;
	    $command = $1;
	}
	my $append = '';
	$buffer =~ s/ ( \s* \\? \n ) //sxm
	    and $append = $1;
	$append =~ m/ \\ /sxm
	    and $context->{command} = $command;

	my $handler = $level1_requote{$command} || $level1_requote{''};
	my ( $this_quote, $start_pos );
	while ( $buffer =~ m/ (?: \A | (?<! \\ ) ) (?: \\\\ )* ( ['"] ) /sxmg
	) {
	    if ( ! defined $start_pos ) {
		$start_pos = $+[0] - 1;
		$this_quote = $1;
	    } elsif ( $1 eq $this_quote ) {
		my $length = $+[0] - $start_pos;
		local $_ = substr $buffer, $start_pos + 1, $length - 2;
		$handler->{$this_quote}->();
		substr $buffer, $start_pos, $length, $_;
		pos( $buffer ) = $start_pos + length $_;
		$start_pos = undef;
	    }
	}

	my $code = $level1_map{$command}
	    or return $buffer . $append;

	my @rslt = $code->( $buffer );
	$rslt[-1] .= $append;
	return @rslt;

    }
}

#	$self->_rewrite_level1_macros();
#
#	This method rewrites all macros defined by a satpass
#	initialization file (as opposed to a satpass2 initialization
#	file) to be satpass2-compatible. It also clears the level1 flag
#	so that the satpass-compatible functionality is not invoked.
#
#	Specifically it:
#	* Inserts a 'location' command before 'almanac' and 'pass';
#	* Changes the senses of the -am, -day, and -pm options in
#	  'flare';
#	* Removes delegated attributes from 'localize', replacing them
#	  with a localization of the helper object.
#
#	This method goes away when the satpass functionality does.

{
    my %helper_map = (
	date_format	=> {
	    helper	=> 'formatter',		# Helper obj attr. Req'd.
	},
	desired_equinox_dynamical	=> {
	    helper	=> 'formatter',
	},
	gmt		=> {
	    helper	=> 'formatter',
	},
	local_coord	=> {
	    helper	=> 'formatter',
	},
	time_format	=> {
	    helper	=> 'formatter',
	},
    );

    my %filter = (
	almanac	=> sub {
	    my ( undef, $line ) = @_;		# $verb unused
	    return ( 'location', $line );
	},
	flare	=> sub {
	    my ( undef, $line ) = @_;		# $verb unused
	    $line =~ s/ (?<= \s ) - (am|day|pm) \b /-no$1/smx;
	    return $line;
	},
	localize	=> sub {
	    my ( undef, $line ) = @_;		# $verb unused
	    my @things = split qr{ \s+ }smx, $line;
	    my @output;
	    my %duplicate;
	    foreach my $token ( @things ) {
		$helper_map{$token}
		    and $token = $helper_map{$token}{helper};
		$duplicate{$token}++ or push @output, $token;
	    }
	    return join ' ', @output;
	},
	pass	=> sub {
	    my ( undef, $line ) = @_;		# $verb unused
	    return ( 'location', $line );
	},
	set	=> sub {
	    my ( undef, $line ) = @_;		# $verb unused
	    my @output = [ 'fubar' ];	# Prime the pump.
	    my @input = Text::ParseWords::quotewords( qr{ \s+ }smx, 1,
		$line );
	    shift @input;
	    while ( @input ) {
		my ( $attr, $val ) = splice @input, 0, 2;
		if ( my $helper = $helper_map{$attr} ) {
		    push @output, [ $helper->{helper},
			# not quoter( $val ) here, because presumably it
			# is already quoted if it needs to be.
			$helper->{attribute} || $attr, $val ];
		} else {
		    'set' eq $output[-1][0]
			or push @output, [ 'set' ];
		    # not quoter( $val ) here, because presumably it is
		    # already quoted if it needs to be.
		    push @{ $output[-1] }, $attr, $val;
		}
	    }
	    shift @output;	# Get rid of the pump priming.
	    return ( map { join ' ', @{ $_ } } @output );
	},
	st	=> sub {
	    my ( undef, $line ) = @_;		# $verb unused
	    m/ \A \s* st \s+ localize \b /smx
		and return $line;
	    $line =~ s/ \b st \b /spacetrack/smx;
	    return $line;
	},
	show	=> sub {
	    my ( undef, $line ) = @_;		# $verb unused
	    my @output = [ 'fubar' ];
	    my @input = split qr{ \s+ }smx, $line;
	    shift @input;
	    foreach my $attr ( @input ) {
		if ( my $helper = $helper_map{$attr} ) {
		    push @output, [ $helper->{helper},
			$helper->{attribute} || $attr ];
		} else {
		    'show' eq $output[-1][0]
			or push @output, [ 'show' ];
		    push @{ $output[-1] }, $attr;
		}
	    }
	    shift @output;
	    return ( map { join ' ', @{ $_ } } @output );
	},
    );

    # Called by macro object's __level1_rewrite().
    sub __rewrite_level1_macro_def {
	my ( $self, $name, $args ) = @_;

	my ( $rewrote, @rslt );
	foreach ( @{ $args } ) {
	    if ( m/ ( \S+ ) /smx
		    and ( not $self->{macro}{$1}
			or $1 eq $name )
		    and my $code = $filter{$1} ) {
		push @rslt, $code->( $1, $_ );
		$rewrote++;
	    } else {
		push @rslt, $_;
	    }
	}

	return $rewrote ? \@rslt : $args;
    }

    sub _rewrite_level1_macros {
	my ( $self ) = @_;

	foreach my $macro ( values %{ $self->{macro} } ) {
	    $macro->__level1_rewrite();
	}

	return;
    }
}

#	@coordinates = $self->_simbad4 ($query)

#	Look up the given star in the SIMBAD catalog. This assumes
#	SIMBAD 4.

#	We die on any error.

sub _simbad4 {
    my $self = shift;
    $self->_load_module ('Astro::SIMBAD::Client');
    my $query = shift;
    my $simbad = Astro::SIMBAD::Client->new (
	format => {txt => 'FORMAT_TXT_SIMPLE_BASIC'},
	parser => {
	    script	=> 'Parse_TXT_Simple',
	    txt		=> 'Parse_TXT_Simple',
	},
	server => $self->{simbad_url},
	type => 'txt',
    );
    # I prefer script() to query() these days because the former does
    # not require SOAP::Lite, which seems to be getting flakier as time
    # goes on.
    # TODO get rid of $fmt =~ s/// once I massage
    # FORMAT_TXT_SIMPLE_BASIC in Astro::SIMBAD::Client
#   my @rslt = $simbad->query (id => $query)
    my $fmt = Astro::SIMBAD::Client->FORMAT_TXT_SIMPLE_BASIC();
    $fmt =~ s/ \n //smxg;
    my @rslt = $simbad->script( <<"EOD" )
format obj "$fmt"
query id $query
EOD
	or $self->wail("No entry found for $query");
    @rslt > 1
	and $self->wail("More than one entry found for $query");
    @rslt = map {$rslt[0]{$_} eq '~' ? 0 : $rslt[0]{$_} || 0} qw{
	ra dec plx pmra pmdec radial};
    ($rslt[0] && $rslt[1])
	or $self->wail("No position returned by $query");
    $rslt[2] = $rslt[2] ? 1000 / $rslt[2] : 10000;
    $rslt[3] and $rslt[3] /= 1000;
    $rslt[4] and $rslt[4] /= 1000;
    return wantarray ? @rslt : join ' ', @rslt;
}

#	@result = _unescape( @args );
#
#	Remove back slash escapes. Nothing fancy is done here; in
#	particular, '\n' does not become a new line, it becomes "n".

sub _unescape {
    my ( @args ) = @_;
    foreach ( @args ) {
	s/ \\ (.) /$1/smxg;
    }
    return @args;
}

#	($tokens, $redirect) = $self->_tokenize(
#		{option => $value}, $buffer, [$arg0 ...]);
#
#	This method tokenizes the buffer. The options hash may be
#	omitted, in which case the $buffer to be tokenized is the first
#	argument. After the buffer is an optional reference to an array
#	of arguments to be substituted in.
#
#	This method attempts to parse and tokenize the buffer in a way
#	similar to the bash shell. That is, parameters are interpolated
#	inside double quotes but not single quotes, tilde expansion
#	takes place unless quoted, and spaces delimit tokens only when
#	occurring outside quotes.
#
#	The back slash character ('\') is an escape character. Inside
#	single quotes only the back slash itself and a single quote may
#	be escaped. Otherwise, anything can be escaped.
#
#	The returns are a reference to an array of tokens found, and a
#	reference to a hash of redirections found. This hash will have
#	zero or more of the keys '>' (standard output redirection) and
#	'<' (standard input redirection. The value of each key will be a
#	reference to a hash containing keys 'mode' ('>' or '>>' for
#	output, '<' or '<<' for input) and 'name' (normally the file
#	name).
#
#	The recognized options are:
#
#	    single => 1
#		causes the buffer to be interpreted as a single token.
#
#	    noredirect => 1
#		causes redirects to be illegal.
#
#	If noredirect is specified, only the $tokens reference is
#	returned. If noredirect and single are both specified, the
#	parsed and interpolated token is returned.
#
#	If interpolation is being done, an unescaped dollar sign
#	introduces the interpolation. This works pretty much the same
#	way as under bash: if the first character after the dollar sign
#	is a left curly bracket, everything to the corresponding right
#	curly bracked specifies the interpolation; if not, the rule is
#	that word characters specify the interpolation.
#
#	A number (i.e. $1) specifies interpolation of an argument.
#	Arguments are numbered starting at 1.
#
#	Otherwise, if the interpolation names an attribute, the value of
#	that attribute is interpolated in, otherwise the named
#	environment variable is interpolated in.
#
#	Most of the fancier forms of interpolation are suported. In the
#	following, word is expanded by recursively calling _tokenize
#	with options {single => 1, noredirect => 1}. But unlike bash, we
#	make no distinction between unset or null. The ':' can be
#	omitted before the '-', '=', '?' or '+', but it does not change
#	the functionality.
#
#	${parameter:-word} causes the given word to be substituted if
#	the parameter is undefined.
#
#	${parameter:=word} is the same as above, but also causes the
#	word to be assigned to the parameter if it is unassigned. Unlike
#	bash, this assignment takes place on positional parameters. If
#	done on an attribute or environment variable, it causes that
#	attribute or environment variable to be set to the given value.
#
#	${parameter:?word} causes the parse to fail with the error
#	'word' if the parameter is undefined.
#
#	${parameter:+word} causes the value of the given word to be used
#	if the parameter is defined, otherwise '' is used.
#
#	${parameter:offset} and ${parameter:offset:length} take
#	substrings of the parameter value. The offset and length must be
#	numeric.

{

    # Special variables.
    # Calling sequence: $special{$name}->(\@args, $relquote)
    my %special = (
	'0' => sub { return $0 },
	'#' => sub { return scalar @{ $_[0] } },
##	'*' => sub { return join ' ', @{ $_[0] } },
##	'@' => sub { return $_[1] ? join( ' ', @{ $_[0] } ) : $_[0] },
	'*' => sub { return $_[1] ? join( ' ', @{ $_[0] } ) : $_[0] },
	'@' => sub { return $_[0] },
	'$' => sub { return $$ },
	'_' => sub { return $^X },
    );

    # Leading punctuation that is equivalent to a method.
    my %command_equivalent = (
	'.'	=> 'source',
	'!' => 'system',
    );
    my $command_equiv_re = do {
	my $keys = join '', sort keys %command_equivalent;
	qr{ [$keys] }smx;
    };

    my %escape = (
	t	=> "\t",
	n	=> "\n",
	r	=> "\r",
	f	=> "\f",
	b	=> "\b",
	a	=> "\a",
	e	=> "\e",
    );

    sub _tokenize {
	my ($self, @parms) = @_;
	my $opt = HASH_REF eq ref $parms[0] ? shift @parms : {};
	my $in = $opt->{in};
	my $buffer = shift @parms;
	$buffer =~ m/ \n \z /smx or $buffer .= "\n";
	my $args = shift @parms || [];
	my @rslt = ( {} );
	my $absquote;	# True if inside ''
	my $relquote;	# True if inside "" (and not in '')
	my $len = length $buffer;
	my $inx = 0;

	# Because I'm not smart enough to do all this with a regular
	# expression, I take the brute force approach and iterate
	# through the buffer to be tokenized. It's a 'while' rather than
	# a 'for' or 'foreach' because that way I get to muck around
	# with the current position inside the loop.

	while ($inx < $len) {
	    my $char = substr $buffer, $inx++, 1;

	    # If we're inside single quotes, the only escapable
	    # characters are single quote and back slash, and all
	    # characters until the next unescaped single quote go into
	    # the current token

	    if ( $absquote ) {
		if ( $char eq '\\' ) {
		    if ( (my $next = substr $buffer, $inx, 1) =~
			m/ ['\\] /smx ) {
			$inx++;
			$rslt[-1]{token} .= $next;
		    } else {
			$rslt[-1]{token} .= $char;
		    }
		} elsif ( $char eq q{'} ) {
		    $absquote = undef;
		} else {
		    $rslt[-1]{token} .= $char;
		    if ( $inx >= $len ) {
			$buffer .= $self->_read_continuation( $in,
			    'Unclosed single quote' );
			$len = length $buffer;
		    }
		}

	    # If we have a backslash, it escapes the next character,
	    # which goes on the current token no matter what it is.

	    } elsif ( $char eq '\\' ) {
		my $next = substr $buffer, $inx++, 1;
		if ( $inx >= $len ) {	# At end of line
		    if ( $relquote ) {	# Inside ""
			$buffer .= $self->_read_continuation( $in,
			    'Unclosed double quote' );
		    } else {		# Between tokens
			$buffer .= $self->_read_continuation( $in,
			    'Dangling continuation' );
			$opt->{single} or push @rslt, {};	# New token
		    }
		    $len = length $buffer;
		} elsif ( $relquote ) {
		    $rslt[-1]{token} .= $escape{$next} || $next;
		} else {
		    $rslt[-1]{token} .= $next;
		}

	    # If we have a single quote and we're not inside double
	    # quotes, we go into absolute quote mode. We also append an
	    # empty string to the current token to force its value to be
	    # defined; otherwise empty quotes do not generate tokens.

	    } elsif ($char eq q{'} && !$relquote) {
		$rslt[-1]{token} .= '';	# Empty string, to force defined.
		$absquote++;

	    # If we have a double quote, we toggle relative quote mode.
	    # We also append an empty string to the current tokens for
	    # the reasons discussed above.

	    } elsif ($char eq '"') {
		$rslt[-1]{token} .= '';	# Empty string, to force defined.
		$relquote = !$relquote;

	    # If we have a whitespace character and we're not inside
	    # quotes and not in single-token mode, we start a new token.
	    # It is possible that we generate redundant tokens this way,
	    # but the unused ones are eliminated later.

	    } elsif ($char =~ m/ \s /smx && !$relquote && !$opt->{single}) {
		push @rslt, {};

	    # If we have a dollar sign, it introduces parameter
	    # substitution, a non trivial endeavor.

	    } elsif ( $char eq '$' && $inx < $len ) {
		my $name = substr $buffer, $inx++, 1;
		my $brkt;

		# Names beginning with brackets are special. We note the
		# fact and scan for the matching close bracket, throwing
		# an exception if we do not have one.

		if ($name eq '{' && $inx < $len) {
		    $brkt = 1;
		    $name = '';
		    my $nest = 1;
		    while ($inx < $len) {
			$char = substr $buffer, $inx++, 1;
			if ($char eq '{') {
			    $nest++;
			} elsif ($char eq '}') {
			    --$nest or last;
			}
			$name .= $char;
		    }
		    $char eq '}'
			or $self->wail('Missing right curly bracket');

		# If the name begins with an alpha or an underscore, we
		# simply append any word ('\w') characters to it. If it
		# the word characters are immediately followed by a dot
		# and more word characters we grab them too, and advance
		# the current location past whatever we grabbed. The dot
		# syntax is in aid of accessing attributes of
		# attributes (e.g. $formatter.time_format)

		} elsif ( $name =~ m/ \A [[:alpha:]_] \z /smx ) {
		    pos( $buffer ) = $inx;
		    if ( $buffer =~ m/ \G ( \w* (?: [.] \w+ )? ) /smxgc ) {
			$name .= $1;
			$inx += length $1;
		    }
		}

		# Only bracketed names can be indirected, and then only
		# if the first character is a bang.

		my ($indirect, $value);
		$brkt and $indirect = $name =~ s/ \A ! //smx;

		# If we find a colon and/or one of the other cabbalistic
		# characters, we need to do some default processing.

		if ($name =~ m/ (.*?) ( [:]? [\-\+\=\?] | [:] ) (.*) /smx) {
		    my ($name, $flag, $rest) = ($1, $2, $3);

		    # First we do indirection if that was required.

		    $indirect
			and $name = $self->_tokenize_var(
			    $name, $args, $relquote, $indirect);

		    # Next we find out whether we have an honest-to-God
		    # colon, since that might specify substring
		    # processing.

##		    my $colon = $flag =~ s/ \A : //smx ? ':' : '';
		    $flag =~ s/ \A : //smx;

		    # We run the stuff after the first cabbalistic
		    # character through the tokenizer, since further
		    # expansion is possible here.

		    my $mod = _tokenize(
			$self,
			{ single => 1, noredirect => 1, in => $in },
			$rest, $args);
		    chomp $mod;	# Don't want trailing \n here.

		    # At long last we get the actual value of the
		    # variable. This will be either undef, a scalar, or
		    # a list reference.

		    $value = $self->_tokenize_var(
			$name, $args, $relquote);

		    # The value is logically defined if it is a scalar
		    # and not undef, or if it is an array reference and
		    # the array is not empty.

		    my $defined = ref $value ? @$value : defined $value;

		    # The '+' cabbalistic sign replaces the value of the
		    # variable if it is logically defined.

		    if ($flag eq '+') {
			$value = $defined ? $mod : '';

		    # If the variable is defined, only substring
		    # processing is possible. This actually is
		    # implemented as slice processing if the value is an
		    # array reference.

		    } elsif ($defined) {
			if ($flag eq '') {
			    my @pos = split ':', $mod, 2;
			    foreach ( @pos ) {
				s/ \A \s+ //smx;
			    }
			    @pos > 2
				and $self->wail(
				'Substring expansion has extra arguments' );
			    foreach ( @pos ) {
				m/ \A [-+]? [0-9]+ \z /smx
				    or $self->wail(
				    'Substring expansion argument non-numeric'
				);
			    }
			    if (ref $value) {
				if (@pos > 1) {
				    $pos[1] += $pos[0] - 1;
				} else {
				    $pos[1] = $#$args;
				}
				$pos[1] > $#$value and $pos[1] = $#$value;
				$value = [@$value[$pos[0] .. $pos[1]]];
			    } else {
				# We want to disable warnings if we slop
				# outside the string.
				no warnings qw{substr};
				$value = @pos == 1 ? substr $value, $pos[0] :
				    substr $value, $pos[0], $pos[1];
			    }
			}

		    # If the cabbalistic sign is '-', we supply the
		    # remainder of the specification as the default.

		    } elsif ($flag eq '-') {
			$value = $mod;

		    # If the cabbalistic sign is '=', we supply the
		    # remainder of the specification as the default. We
		    # also set the variable to the value, for future
		    # use. Note that special variables may not be set,
		    # and result in an exception.

		    } elsif ($flag eq '=') {
			$value = $mod;
			if ( $special{$name} || $name !~ m/ \D /smx ) {
			    $self->wail("Cannot assign to \$$name");
##			} elsif ($name !~ m/\D/) {
##			    $args->[$name - 1] = $value;
			} elsif (exists $mutator{$name}) {
			    $self->set($name => $value);
			} else {
			    $self->{frame}[-1]{define}{$name} = $value;
			}

		    # If the cabbalistic sign is '?', we throw an
		    # exception with the remainder of the specification
		    # as the text.

		    } elsif ($flag eq '?') {
			$self->wail($mod);

		    # If there is no cabbalistic sign at all, we fell
		    # through here trying to do substring expansion on
		    # an undefined variable. Since Bash allows this, we
		    # will to, though with misgivings.

		    } elsif ( $flag eq '' ) {
			$value = '';

		    # Given the way the parser works, the above should
		    # have exhausted all possibilities. But being a
		    # cautious programmer ...

		    } else {
			$self->weep(
			    "\$flag = '$flag'. This should not happen"
			);
		    }

		# Without any cabbalistic signs, variable expansion is
		# easy. We perform the indirection if needed, and then
		# grab the value of the variable, which still can be
		# undef, a scalar, or an array reference.

		} else {
		    $indirect
			and $name = $self->_tokenize_var(
			$name, $args, $relquote, $indirect);
		    $value = $self->_tokenize_var(
			$name, $args, $relquote);
		}

		# For simplicity in what follows, make the value into an
		# array reference.
		ref $value
		    or $value = defined $value ? [ $value ] : [];

		# Do word splitting on the value, unless we are inside
		# quotes.
		$relquote
		    or $value = [ map { split qr{ \s+ }smx } @{ $value } ];

		# If we have a value, append each element to the current
		# token, and then create a new token for the next
		# element. The last element's empty token gets
		# discarded, since we may need to append more data to
		# the last element (e.g.  "$@ foo").
		if ( @{ $value } ) {
		    foreach ( @$value ) {
			$rslt[-1]{token} .= $_;
			push @rslt, {};
		    }
		    pop @rslt;
		}


		# Here ends the variable expansion code.

	    # If the character is an angle bracket or a pipe, we have a
	    # redirect specification. This always starts a new token. We
	    # flag the token as a redirect, stuff all matching
	    # characters into the mode (throwing an exception if there
	    # are too many), consume any trailing spaces, and set the
	    # token value to the empty string to prevent executing this
	    # code again when we hit the first character of the file
	    # name. Note that redirect tokens always get tilde
	    # expansion.

	    } elsif ( $char =~ m/ [<>|] /smx ) {
		push @rslt, {
		    redirect => 1,
		    type => ($char eq '<' ? '<' : '>'),
		    mode => ($char eq '|' ? '|-' : $char),
		    expand => ($char ne '|')
		};
		while ($inx < $len) {
		    my $next = substr $buffer, $inx++, 1;
		    $next =~ m/ \s /smx and next;
		    if ($next eq $char) {
			$rslt[-1]{mode} .= $next;
			length $rslt[-1]{mode} > 2
			    and $self->wail(
			    "Syntax error near $rslt[-1]{mode}");
		    } else {
			--$inx;
			$rslt[-1]{token} = '';
			last;
		    }
		}
		if ( '<<' eq $rslt[-1]{mode} ) {	# Heredoc
		    delete $rslt[-1]{redirect};
		    delete $rslt[-1]{type};
		    delete $rslt[-1]{mode};
		    my $quote = '';
		    while ( $inx < $len ) {
			my $next = substr $buffer, $inx++, 1;
			if ( $next =~ m/ \s /smx ) {
			    $quote or last;
			    $rslt[-1]{token} .= $next;
			} else {
			    '' eq $rslt[-1]{token}
				and $next =~ m/ ['"] /smx
				and $quote = $next
				or $rslt[-1]{token} .= $next;
			    $quote
				and $next eq $quote
				and $rslt[-1]{token} ne ''
				and last;
			}
		    }
		    $quote and $rslt[-1]{token} =~ s/ . \z //sxm;
		    my $terminator = $rslt[-1]{token};
		    my $look_for = $terminator . "\n";
		    $rslt[-1]{token} = '';
		    $rslt[-1]{expand} = $quote ne q<'>;
		    while ( 1 ) {
			my $buffer = $self->_read_continuation( $in,
			    "Here doc terminator $terminator not found" );
			$buffer eq $look_for and last;
			$rslt[-1]{token} .= $buffer;
		    }
		    if ( $quote ne q<'> ) {
			$rslt[-1]{token} = _tokenize(
			    $self,
			    { single => 1, noredirect => 1, in => $in },
			    $rslt[-1]{token}, $args
			);
		    }
		    push @rslt, {};	# New token
		}

	    # If the token already exists at this point, the current
	    # character, whatever it is, is simply appended to it.

	    } elsif (exists $rslt[-1]{token} || $relquote) {
		$rslt[-1]{token} .= $char;

	    # If the character is a tilde, we flag the token for tilde
	    # expansion.

	    } elsif ($char eq '~') {
		$rslt[-1]{tilde}++;
		$rslt[-1]{token} .= $char;

	    # If the character is a hash mark, it means a comment. Bail
	    # out of the loop.
	    } elsif ( $char eq '#' ) {
		last;

	    # Else we just put it in the token.
	    } else {
		$rslt[-1]{token} .= $char;
	    }

	    # If we're at the end of the buffer but we're inside quotes,
	    # we need to read another line.
	    if ( $inx >= $len && ( $absquote || $relquote ) ) {
		$buffer .= $self->_read_continuation( $in,
		    $absquote ? 'Unclosed single quote' :
			'Unclosed double quote'
		);
		$len = length $buffer;
	    }

	}

	# We have run through the entire string to be tokenized. If
	# there are unclosed quotes of either sort, we declare an error
	# here. This should actually not happen, since we allow
	# multi-line quotes, and if we have run out of input we catch it
	# above.

	$absquote and $self->wail( 'Unclosed terminal single quote' );
	$relquote and $self->wail( 'Unclosed terminal double quote' );

	# Replace leading punctuation with the corresponding method.

	shift @rslt
	    while @rslt && ! defined $rslt[0]{token};
	if ( defined $rslt[0]{token} and
		$rslt[0]{token} =~ s/ \A ( $command_equiv_re ) //smx ) {
	    if ( $rslt[0]{token} eq '' ) {
		$rslt[0]{token} = $command_equivalent{$1};
	    } elsif ( $opt->{single} ) {
		$rslt[0]{token} = join ' ', $command_equivalent{$1},
		    $rslt[0]{token};
	    } else {
		unshift @rslt, {
		    token	=> $command_equivalent{$1},
		};
	    }
	}

	# Go through our prospective tokens, keeping only those that
	# were actually defined, and shuffling the redirects off into
	# the redirect hash.

	my (@tokens, %redir);
	my $expand_tildes = 1;
	if ( defined $rslt[0]{token}
		and my $kode = $self->can( $rslt[0]{token} ) ) {
	    if ( my $hash = $self->__get_attr( $kode, 'Tokenize' ) ) {
		$expand_tildes = $hash->{expand_tilde};
	    }
	}
	foreach (@rslt) {
	    exists $_->{token} or next;
	    if ($_->{redirect}) {
		if ( $_->{mode} eq '<' ) {
		    push @tokens, $self->_file_reader(
			$_->{token}, { glob => 1 } );
		} else {
		    my $type = $_->{type};
		    $redir{$type} = {
			mode => $_->{mode},
			name => ($_->{expand} ?
			    $self->expand_tilde($_->{token}) :
			    $_->{token}),
		    };
		}
	    } elsif ( $expand_tildes && $_->{tilde} ) {
		push @tokens, $self->expand_tilde( $_->{token} );
	    } else {
		push @tokens, $_->{token};
	    }
	}

	# With the {single} and {noredirect} options both asserted,
	# there is only one token, so we return it directly.

	($opt->{single} && $opt->{noredirect}) and return $tokens[0];

	# With the {noredirect} option asserted, we just return a
	# reference to the tokens found.

	$opt->{noredirect} and return \@tokens;

	# Otherwise we return a list, with a reference to the token list
	# as the first element, and a reference to the redirect hash as
	# the second element.

	return (\@tokens, \%redir);
    }

    # Retrieve the value of a variable.
    sub _tokenize_var {
	my ($self, $name, $args, $relquote, $indirect) = @_;

	defined $name and $name ne ''
	    or return $indirect ? '' : undef;

	$special{$name} and do {
	    my $val = $special{$name}->($args, $relquote);
	    return ($indirect && ref $val) ? '' : $val;
	};

	$name !~ m/ \D /smx
	    and return $args->[$name - 1];

	my $value = $self->_attribute_value( $name );
	NULL_REF eq ref $value
	    or return $value;

	exists $self->{exported}{$name}
	    and return $self->{exported}{$name};

	defined $ENV{$name}
	    and return $ENV{$name};

	foreach my $frame ( reverse @{ $self->{frame} } ) {
	    defined $frame->{define}{$name}
		and return $frame->{define}{$name};
	}

	return;
    }
}


#	$self->wail(...)
#
#	Either die or croak with the arguments, depending on the value
#	of the 'warning' attribute. If we die, a trailing period and
#	newline are provided if necessary. If we croak, any trailing
#	punctuation and newline are stripped.

sub wail {
    my ($self, @args) = @_;
    $self->{_warner}->wail( @args );
    return;	# We can't hit this, but Perl::Critic does not know that.
}

#	$self->weep(...)
#
#	Die with a stack dump (Carp::confess).

sub weep {
    my ($self, @args) = @_;
    $self->{_warner}->weep( @args );
    return;	# We can't hit this, but Perl::Critic does not know that.
}

#	$self->whinge(...)
#
#	Either warn or carp with the arguments, depending on the value
#	of the 'warn' attribute. If we warn, a trailing period and
#	newline are provided if necessary. If we carp, any trailing
#	punctuation and newline are stripped.

sub whinge {
    my ($self, @args) = @_;
    $self->{_warner}->whinge( @args );
    return;
}

1;

__END__

=head1 NAME

Astro::App::Satpass2 - Forecast satellite visibility.

=head1 SYNOPSIS

 use Astro::App::Satpass2;
 # Instantiate and set our location
 my $satpass2 = Astro::App::Satpass2->new(
     location => '1600 Pennsylvania Ave, Washington DC',
     latitude => 38.898748,    # degrees
     longitude => -77.037684,  # degrees
     height => 16.68,          # meters
 );
 # Acquire ISS data from NASA
 $satpass2->spacetrack( qw{ spaceflight -all } );
 # Display our location
 $satpass2->location();
 # Display visible ISS passes over our location
 $satpass2->pass();

Or equivalently, from the F<satpass2> script which is installed with
this package,

 $ satpass2
          ... front matter displayed here ...
 satpass2> # set our location
 satpass2> set location '1600 Pennsylvania Ave, Washington DC'
 satpass2> set latitude 38.898748 longitude -77.037684
 satpass2> set height 16.68
 satpass2> # Acquire ISS data from NASA
 satpass2> spacetrack spaceflight -all
 satpass2> # Display our location
 satpass2> location
 satpass2> # Display visible ISS passes over our location
 satpass2> pass
 satpass2> # Guess what
 satpass2> exit

The script is implemented in terms of the L<run()|/run> method. Blank
lines and comments are ignored. The first token in the line is the
method name, and subsequent tokens are arguments to that method. See
L<run()|/run> for the details of that method, and L</TOKENIZING> for
details of the tokenizer. Finally, see L<initfile()|/initfile> for where
to put your initialization file, which is just a script that gets
executed every time you invoke the L<run()|/run> method.

If you want to be interactive, simply

 use Astro::App::Satpass2;
 Astro::App::Satpass2->run(@ARGV);

which is essentially the content of the F<satpass2> script.  In this
last case, the user will be prompted for commands once the commands in
@ARGV are used up, unless those commands include 'exit'.

=head1 NOTICE

Geocoding using TomTom has been dropped as of version 0.024.
The old, undocumented interface has been dropped, and the new one
requires an API key.

The eventual plan is to retire the F<satpass> script in favor of this
package, and to rename the satpass-less F<Astro-satpass> distribution to
F<Astro-Coord-ECI>.

=head1 OVERVIEW

This class implements an application to predict satellite visibility and
related phenomena. It is a mostly-compatible rewrite and eventual
replacement of the F<satpass> script in distribution C<Astro-satpass>,
aimed at making it easier to test, and removing some of the odder cruft
that has accumulated in the F<satpass> script.

The easiest way to make use of this class is via the bundled F<satpass2>
script, which simply calls the L<run()|/run> method.
L<Astro::App::Satpass2::TUTORIAL|Astro::App::Satpass2::TUTORIAL> covers
getting started with this script. If you do nothing else, see the
tutorial on setting up an initialization file, since the L<satpass2>
script will be much more easy to use if you configure some things up
front.

You can also instantiate an C<Astro::App::Satpass2> object yourself and
access all its functionality programmatically. If you are doing this you
may still want to consult the
L<TUTORIAL|Astro::App::Satpass2::TUTORIAL>, because the F<satpass2>
commands correspond directly to C<Astro::App::Satpass2> methods.

=head1 Optional Modules

An attempt has been made to keep the requirements of this module
reasonably modest. But there are a number of optional modules which, if
installed, give you increased functionality. If you do not install these
initially and find you want the added functionality, you can always
install them later. The optional modules are:

=over

=item L<Astro::SIMBAD::Client|Astro::SIMBAD::Client>

This module looks up the positions of astronomical bodies in the SIMBAD
database at L<http://simbad.u-strasbg.fr/>. This is only used by the
C<lookup> subcommand of the L<sky()|/sky> method.

=item L<Astro::SpaceTrack|Astro::SpaceTrack>

This module retrieves satellite orbital elements from various sources.
Since you have to have these to predict satellite positions, this is the
least optional of the optional modules. Without it, you would have to
download orbital elements some other way and then use the
L<load()|/load> method to import them into C<Astro::App::Satpass2>.

=item L<Date::Manip|Date::Manip>

This module is a very flexible (and very large) time parser. If it is
installed, C<Astro::App::Satpass2> will use it to parse times. If it is
not available a home-grown ISO-8601-ish parser will be used. There are
really three options here:

* If you have Perl 5.10 or above, you have the full functionality of
L<Date::Manip|Date::Manip>.

* If you a Perl before 5.10, you can (as of this writing) install the
latest L<Date::Manip|Date::Manip>, but you will be using the version 5
back end, which may not support summer time (a.k.a. daylight saving
time) and may have other deficiencies versus the current release.

* The home-grown parser is
L<Astro::App::Satpass2::ParseTime::ISO86O1|Astro::App::Satpass2::ParseTime::ISO8601>.
This does not support summer time, nor time zones other than the user's
default time and GMT. Dates and times must be specified as numeric
year-month-day hour:minute:second, though there is some flexibility on
punctuation, and as a convenience you can use C<yesterday>, C<today>, or
C<tomorrow> in lieu of the C<year-month-day>.

=item L<DateTime|DateTime> and L<DateTime::TimeZone|DateTime::TimeZone>

If both of these are available, C<Astro::App::Satpass2> will use them to
format dates. If they are not, it will use C<POSIX::strftime>. If you
are using C<POSIX::strftime>, time zones other than the default time
zone and GMT are not supported, though if you set the L<tz|/tz>
attribute C<Astro::App::Satpass2> will place its value in C<$ENV{TZ}>
before calling C<strftime()> in case the underlying code pays attention
to this.

If you have L<DateTime|DateTime> and
L<DateTime::TimeZone|DateTime::TimeZone> installed,
C<Astro::App::Satpass2> will let you use C<Cldr> time formats if you
like, instead of C<strftime> formats.

=item L<Geo::Coder::OSM|Geo::Coder::OSM>

This module is used by the Open Street Map geocoder for the
L<geocode()|/geocode> method. If you are not interested in using the
L<geocode()|/geocode> method you do not need this module.

=item L<Geo::WebService::Elevation::USGS|Geo::WebService::Elevation::USGS>

This module is only used by the L<height()|/height> method, or
indirectly by the L<geocode()|/geocode> method. If you are not
interested in these you do not need this module.

=item L<LWP::UserAgent|LWP::UserAgent>

This module is only used directly if you are specifying URLs as input
(see L</SPECIFYING INPUT DATA>). It is implied, though, by a number of
the other optional modules.

=item L<LWP::Protocol|LWP::Protocol>

This module is only used directly if you are specifying URLs as input
(see L</SPECIFYING INPUT DATA>). It is implied, though, by a number of
the other optional modules.

=item L<Time::HiRes|Time::HiRes>

This module is only used by the L<time()|/time> method. If you are not
interested in finding out how long things take to run, you do not need
this module.

=item L<Time::y2038|Time::y2038>

This module is only needed if you are interested in times outside the
range of times representable in your Perl. This was typically 1970
through 2038 in 32-bit Perls before Perl 5.12. In Perl 5.12 the Y2038
bug was fixed, and a much wider range of times is available. You may
also find that a wider range of times is available in 64-bit Perls.

At least some versions of L<Time::y2038|Time::y2038> have had trouble on
Windows-derived systems, including Cygwin. I<Caveat user.>

=item L<URI|URI>

This module is only used directly if you are specifying URLs as input
(see L</SPECIFYING INPUT DATA>). It is implied, though, by a number of
the other optional modules, including L<LWP::UserAgent|LWP::UserAgent>.

=back

=head1 METHODS

Most methods simply correspond to commands in the C<satpass2> script,
and the arguments correspond to arguments in the script. Such methods
will be identified in the following as 'interactive methods.'

An interactive method call is one that is made via the
L<dispatch()|/dispatch> method, however called, and includes methods
called via L<execute()|/execute> or L<run()|/run> (i.e. F<satpass2>
scripts).

When the documentation specifies that an interactive method takes
options, they may be specified either as command-style options or as a
hash.

If options are specified command-style, the option name must be preceded
by a dash, and may be abbreviated. Option arguments are either specified
as a separate argument or appended to the option name.

If options are specified in a hash, a reference to the hash must be the
first argument to the method. The hash keys are the option names (in
full, but without leading dashes), and the hash values are the values of
the options.

For example, hypothetical method C<foo()> may be called with boolean
option C<bar> and string option C<baz> in any of the following ways:

 $satpass2->foo( '-bar', -baz => 'burfle' );
 $satpass2->foo( '-bar', '-baz=burfle' );
 $satpass2->foo( { bar => 1, baz => 'burfle' } );

For ease of use with templating systems such as F<Template-Toolkit> most
interactive methods flatten array references in their argument list. The
only exception is the C<set()> method, which may need to receive an
array reference as the value of an attribute.

A few methods are used for manipulating the C<Astro::App::Satpass2> object
itself, or for doing things not available to the C<satpass2> script.
These are identified as 'non-interactive methods.'

When the documentation says 'nothing is returned', this means the
subroutine returns with a C<return> statement without an argument, which
returns C<undef> in scalar context, and an empty list in list context.

=head2 new

 $satpass2 = Astro::Satpass2->new();

This non-interactive method instantiates a new Astro::Satpass2 object.
Any arguments are passed to the L<set()|/set> method.

=head2 add

 $satpass2->add( @bodies );

This non-interactive method adds its arguments to the observing list.
An exception is raised if any argument does not represent an
L<Astro::Coord::ECI::TLE|Astro::Coord::ECI::TLE> object.

The invocant is returned.

=head2 alias

 $output = $satpass2->alias();
 satpass2> alias

This interactive method just wraps the
L<Astro::Coord::ECI::TLE|Astro::Coord::ECI::TLE> C<alias()> method,
which returns the known class name aliases. The output is zero or more
lines of text, each line giving an alias and its equivalent class.

If arguments are given, they should be pairs of aliases and class names,
and will add to or replace the currently-known aliases. If the class
name is false in the Perl sense (i.e. '', 0, or undef) the alias, if it
exists, is deleted.

=head2 almanac

 $output = $satpass2->almanac(...);
 satpass2> almanac

This interactive method returns almanac data for the current location.
This consists of all data returned by the C<almanac()> method for all
objects in the sky which support this method.

It takes up to two arguments, which represent start time and end time.
The default start time is midnight of the current day in the local time
zone, or in GMT if the L</gmt> attribute is true. The default end time
is a day after the current start time. See L</SPECIFYING TIMES> for how
to specify times.

The following options are recognized:

 -choose chooses objects to report;
 -dump produces debugging output;
 -horizon produces rise/set times;
 -quarter produces quarter events;
 -rise is a synonym for -horizon;
 -set is a synonym for -horizon;
 -transit reports transit across zenith or (sometimes) nadir;
 -twilight reports begin/end of twilight.

Option C<-dump> is unsupported in the sense that the author makes no
commitments as to what it does, nor does he commit not to change or
remove it without notice.

Option C<-choose> chooses which objects to report. It takes as an
argument the names of one or more bodies (case-insensitive), separated
by commas, and it can be specified multiple times. If C<-choose> is not
specified, all objects in the sky are reported.

The other options specify what output to produce. If none are specified,
all are turned on by default. If only negated options are specified
(e.g. -noquarter), unspecified options are asserted by default.
Otherwise unspecified options are considered to be negated.

B<Note well> that unlike the F<satpass> script, the output from this
method does not normally include location. The location is included only
if the command is issued from a F<satpass> initialization file (as
opposed to an C<Astro::App::Satpass2> initialization file), or from a macro
defined in a F<satpass> initialization file. This functionality will be
revoked when support for the F<satpass> script is dropped.

=head2 begin

 $satpass2->begin();
 satpass2> begin

This interactive method begins a localization block, which extends to
the corresponding L<end()|/end> or to the end of the source file or
macro. Nothing is returned.

=head2 cd

 $satpass2->cd();
 satpass2> cd

This interactive method changes to the users' home directory, or to the
given directory if one is specified as an argument. Tilde expansion is
done on the argument if appropriate. Nothing is returned.

B<Caveat:> I get a test failure in the no-argument case under FreeBSD
6.2. The failure is because C<< File::HomeDir->my_home() >> thinks the
user's home directory is F</home/foo>, but when I do a C<chdir()> to
that directory, C<< Cwd::cwd >> reports that I am in F</usr/home/foo>.
All the other CPAN testers are running 9.0, and under this the test
passes. So I am unsure of the extent to which this is a problem. If this
turns out to be a problem for you, I am willing to fix it, but will
probably need some guidance on what is actually going on. In the
meantime I have had F<t/whole_app.t> make the test for this a C<TODO>
under FreeBSD before 7.0.

=head2 choose

 $satpass2->choose( 25544, 'hst' )
 satpass2> choose 25544 hst

This interactive method drops from the observing list any objects that
do not meet the given selection criteria. Numbers greater than 999 are
taken to represent OID numbers, and compared to each object's 'id'
attribute.  Anything else is made into a regular expression and matched
to the object's 'name' attribute.

The following options may be specified:

 -epoch to select the best item for the given epoch.

Nothing is returned.

An exception is raised if the operation would leave the observing list
empty.

=head2 clear

 $satpass2->clear();
 satpass2> clear

This interactive method clears the observing list. It takes no
arguments. Nothing is returned.

=head2 dispatch

 $output = $satpass2->dispatch( 'flare', 'today 12:00:00', '+1' );

This non-interactive method takes as its arguments the name of an
interactive method and its arguments, calls the method, and returns
whatever the method calls.

Any method executed via this method is considered to have been executed
interactively.

=head2 drop

 $satpass2->drop( 25544, 'hst' );
 satpass2> drop 25544 hst

This interactive method inverts the sense of L<choose()|/choose>,
removing from the observing list all bodies that match the selection
criteria.

Nothing is returned.

An exception is raised if the operation would leave the observing list
empty.

=head2 dump

 $output = $satpass2->dump();
 satpass2> dump

This interactive method is unsupported, and is used for debugging
purposes. It may disappear, or its functionality change, without notice.

Currently it loads a dumper class (either some C<YAML> module or
C<Data::Dumper>) and returns a dump of the C<Astro::App::Satpass2> object.

=head2 echo

 $output = $satpass2->echo( 'Hello, sailor!' );
 satpass2> echo 'Hello, sailor!'

This interactive method joins its arguments with spaces, appends a
newline, and returns the result. It is so named because it is
anticipated that the caller will print the result.

The following option may be specified:

 -n to suppress the newline at the end of the echoed text.

=head2 end

 $satpass2->end();
 satpass2> end

This interactive method ends a localization block. Nothing is returned.
It is an error to have an end without a corresponding L<begin()|/begin>.

=head2 execute

 $output = $satpass2->execute( <<'EOD' );
 spacetrack set direct 1
 spacetrack celestrak stations
 choose iss
 pass 'today 12:00:00' +7
 EOD

This non-interactive method takes as its arguments lines of text. The
arguments are split on C<\n>. Each line is tokenized (see L</TOKENIZING>
for the details), output redirection is performed, and the tokens are
passed to L<dispatch()|/dispatch> for execution.  Exceptions raised by
L<dispatch()|/dispatch> or the methods it calls will not be trapped.

The output of L<dispatch()|/dispatch> is sent to whatever output is
selected. If no output at all is selected (that is, if the C<stdout>
attribute is C<undef> and no output redirection was specified) the
output will be returned.  Otherwise undef will be returned.

Blank lines, and lines beginning with '#' (comments) are ignored.

=head2 exit

 $satpass2->exit();
 satpass2> exit

This interactive method is used to unwind the context stack and
terminate execution. If executed in a block labeled SATPASS2_EXECUTE
(as in the L</run> method for example), it does a 'last' on that block.
Otherwise it displays a warning to STDERR and exits Perl. Nothing is
returned.

=head2 export

 $satpass2->export( $name [, $value] );
 satpass2> export name [ value ]

This interactive method exports the value of the named attribute to an
environment variable having the same name. If the optional value
argument is passed, the value of the attribute is set.

If the named attribute does not exist, an environment variable of the
given name is created, and assigned the given value, which in this case
is not optional.

Either way, nothing is returned.

Once an attribute has been exported, the environment variable tracks
changes in the value of the attribute. This includes not only explicit
changes, but those made as a result of leaving a localization block.

=head2 flare

 $output = $satpass2->flare( 'today 18:00', '+1' );
 satpass2> flare 'today 18:00' +1

This interactive method predicts flares from any bodies in the observing
list capable of flaring. The optional arguments are the start time of
the prediction (defaulting to the current day at noon) and the end time
of the prediction (defaulting to C<'+7'>). See L</SPECIFYING TIMES> for
how to specify times.

The following options are available:

C<-am> displays morning flares -- that is, those after midnight but
before morning twilight. This can be negated by specifying C<-noam>.

C<-choose> chooses bodies from the observing list. It works the same way
as the choose method, but does not alter the observing list. You can
specify multiple bodies by specifying -choose multiple times, or by
separating your choices with commas. If -choose is not specified, the
whole observing list is used.

C<-day> displays daytime flares -- that is, those between morning
twilight and evening twilight. This can be negated by specifying
C<-noday>.

C<-pm> displays evening flares -- that is, those between evening twilight
and midnight. This can be negated by specifying C<-nopm>.

C<-questionable> requests that satellites whose status is questionable
(i.e. 'S') be included. Typically these are spares, or moving between
planes. You may use C<-spare> as a synonym for this.

C<-quiet> suppresses any errors generated by running the orbital model.
These are typically from obsolete data, and/or decayed satellites.
Bodies that produce errors will not be included in the output.

C<-tz=zone> allows you to specify an explicit time zone for the
C<-pm>/C<-am> determination. If you do not specify this, it relies on
the C<formatter> C<gmt> and C<tz> settings, in that order.

C<-zone=zone> is a synonym for C<-tz=zone>.

B<Note well> that the sense of the C<-am>, C<-day>, and C<-pm> options
is opposite to that in the F<satpass> script. However, if they are used
in a F<satpass> initialization script, or in a macro defined in a
F<satpass> initialization script, the F<satpass> sense of these options
will be used, and they will be inverted internally to the
C<Astro::App::Satpass2> sense. This F<satpass> compatibility will be retracted
when the F<satpass> script is retired.

Once the C<-am>, C<-day>, and C<-pm> options have their C<Astro::App::Satpass2>
sense, unspecified options are defaulted to false if any of these
options is asserted, or true otherwise. For example, specifying C<-noam>
has the same effect as specifying C<-day -pm>, and specifying none of
the three options is the same as specifying C<-am -day -pm>.

=head2 formatter

 $satpass2->formatter( date_format => '%d-%b-%Y' );
 satpass2> formatter date_format %d-%b-%Y
 
 say $satpass2->formatter( 'date_format' );
 satpass2> formatter date_format

This interactive method takes as its arguments the name of a method, and
any arguments to be passed to that method. This method is called on the
object which is stored in the
L<formatter attribute|/formatter attribute>, and any results returned.
Normally it will be used to configure the formatter object. See the
documentation on the formatter class in use for further details.

When calling formatter methods via this method (as opposed to retrieving
the formatter method with C<get( 'formatter' )> and then calling the
methods directly on the formatter object) there are a couple cases in
which the input is transformed:

=over

=item desired_equinox_dynamical

The argument, if any, is parsed using the time parser.

=item format

The following arguments are passed to
L<Astro::App::Satpass2::Format::Template|Astro::App::Satpass2::Format::Template>
L<format()|Astro::App::Satpass2::Format::Template/format>:

 sp       => the invocant of this method;
 template => the first argument to this method;
 arg      => [ all arguments after the first ].

An example may help:

 my $output = $self->formatter( format => qw{ foo bar baz } )

is equivalent to

 my $fmtr = $self->get( 'formatter' );
 my $output = $fmtr->format(
     template => 'foo',
     arg      => [ qw{ bar baz } ],
     sp       => $self,
 );

=back

This method takes the following options:

=over

=item -changes

This option is only useful with the formatter's
L<config()|Astro::App::Satpass2::Format/config> method. It causes
this method to return only changes from the default. It can be negated
by prefixing C<no>.

The default is C<-nochanges>.

=item -raw

This option causes the method to return whatever the underlying method
call returned. If negated (as C<-noraw>), the return is formatted for
text display.

The default is C<-noraw> if called interactively, and C<-raw> otherwise.

=back

=head2 geocode

 $output = $satpass2->geocode('1600 Pennsylvania Ave, Washington DC');
 satpass2> geocode '1600 Pennsylvania Ave, Washington DC'

This interactive method looks up its argument using the currently-set
L<geocoder|/geocoder>. It will fail if no geocoder is set.

If exactly one match is found, the location, latitude, and longitude
attributes are set accordingly.

If exactly one match is found and the L<autoheight|/autoheight>
attribute is true, the L<height()|/height> method will be called on the
resultant position. This operation may fail if the location is outside
the USA.

The argument can be defaulted, in which case the current location
attribute is looked up.

The results of the lookup are returned.

=head2 geodetic

 $satpass2->geodetic( $name, $latitude, $longitude, $elevation );
 satpass2> geodetic name latitude longitude elevation

This interactive method adds a geodetic position to the observing list.
The arguments are the name of the object, the latitude and longitude of
the object (in degrees by default, see L</SPECIFYING ANGLES> for
details), and the height of the object (in kilometers by default, see
L</SPECIFYING DISTANCES> for details) above the current ellipsoid (WGS84
by default). Nothing is returned.

The motivation was to try to judge the observability of those Wallops
Island cloud studies. The L</pass> method will not report on these, but
the L</position> method will.

=head2 get

 $value = $satpass2->get( $name );

This non-interactive method returns the value of the given attribute.
See L<show()|/show> for the corresponding interactive method.

=head2 height

 $output = $satpass2->height( $latitude, $longitude );
 satpass2> height latitude longitude

This interactive method queries the USGS online database for the height
of the ground above sea level at the given latitude and longitude. If
these were not specified, they default to the current settings of the
L</latitude> and L</longitude> attributes.

If the query succeeds, this method returns the 'set' command necessary
to set the height to the retrieved value.

This method will fail if the
L<Geo::WebService::Elevation::USGS|Geo::WebService::Elevation::USGS>
module can not be loaded.

=head2 help

 $output =  $satpass2->help(...)
 satpass2> help

This interactive method can be used to get usage help. Without
arguments, it displays the documentation for this class (hint: you are
reading this now). You can get documentation for other Perl modules by
specifying their names. For convenience, there are abbreviations for
some modules, as follows:

 eci -------- Astro::Coord::ECI
 iridium ---- Astro::Coord::ECI::TLE::Iridium
 moon ------- Astro::Coord::ECI::Moon
 sun -------- Astro::Coord::ECI::Sun
 spacetrack - Astro::SpaceTrack
 star ------- Astro::Coord::ECI::Star
 tle -------- Astro::Coord::ECI::TLE
 utils ------ Astro::Coord::ECI::Utils

The C<iridium> help is available only if
L<Astro::Coord::ECI::TLE::Iridium|Astro::Coord::ECI::TLE::Iridium> can
be loaded.

The viewer is whatever is the default for your system.

Under Mac OS 9 or below, this method simply returns an apology, since
L<Pod::Usage|Pod::Usage> appears not to work there.

If you set the L<webcmd|/webcmd> attribute properly, this method will
launch a web browser displaying the desired documentation from
L<https://metacpan.org>.

In any case, nothing is returned.

=head2 if

 $output = $satpass2->if(
     qw{ env FUBAR then echo FUBAR is defined } );
 satpass2> if env FUBAR then echo FUBAR is defined

This interactive method performs a test, and executes the specified
method if the test is true. The test is an infix expression, with prefix
operators binding more tightly than infix operators, but otherwise all
operators having the same precedence. You can use parentheses to group
operations.

The method name after C<'then'> may not be C<'end'>.

The method name after C<'then'> may be C<'begin'> only if C<if()> was
called interactively. If you do this and the C<if()> is not satisfied,
nothing called interactively will be executed until after the
corresponding interactive call to L<end()|/end> (or whenever the frame
created by the C<begin()> is popped off the stack, which may be the end
of a macro or source file.) Non-interactive methods will still be
executed. See L<METHODS|/METHODS> above for what it means to be called
interactively.

For example (assuming OID 99999 is not loaded)

 $satpass2->dispatch( qw{ if loaded 99999 then begin } );
 
 # The following will do nothing because the above if()
 # was not satisfied.
 $satpass2->dispatch( qw{ echo hello there } );
 
 # The following will be executed even though the if()
 # was not satisfied, because it is not being routed
 # through dispatch()
 $satpass2->spacetrack( retrieve => 25544 );
 
 # The following ends the scope of the if()
 $satpass2->execute( qw{ end } );
 
 # The following will be executed because we are no longer
 # in the scope of the unsatisfied if().
 $satpass2->execute( qw{ echo we are back } );

The following operators and functions are implemented:

=over

=item and

This infix operator computes the Boolean C<and> of its operands. This
operator shortcuts; if the first operand is false the second operand is
not evaluated.

=item attr

This prefix operator computes the value of the attribute specified by
its operand. If the operand is C<'formatter'>, C<'spacetrack'> or
C<'time_parser'>, you can follow the attribute name by a dot and the
name of an attribute of the specified object, for example
C<'spacetrack.username'>.

An attempt to access a non-existent attribute will result in an
exception.

B<Note> that L<Astro::SpaceTrack|Astro::SpaceTrack> is an optional
module. If it is not installed we can not determine which attributes are
valid, so the results of trying to access any spacetrack attribute
result in an exception. If you wish to share the same configuration
among installations that may or may not have
L<Astro::SpaceTrack|Astro::SpaceTrack> installed, you can guard against
the exception by using something like

 if attr spacetrack and attr spacetrack.username ...

=item env

This prefix operator computes the value of the environment variable
named as its operand.

=item loaded

This prefix operator computes the number of loaded bodies chosen by its
operand, which can be a comma-delimited list of values like those taken
by the C<choose()|/choose> method.

=item not

This prefix operator computes the Boolean negation of its operand.

=item or

This infix operator computes the Boolean C<or> of its operands. This
operator shortcuts; if the first operand is true the second operand is
not evaluated.

=item os

This prefix operator is true if and only if the Perl script is running
under the operating system named in its operand, as determined by a
case-insensitive match against C<$^O>.

You can specify multiple operating systems by separating the names with
the pipe character (C<'|'>). If you do this the operator is true if
C<$^O> matches any one of the names. If using this interactively, you
will need to quote the operand or escape the pipes to hide them from the
command line tokenizer. For example:

 satpass2> if os 'mswin32|dos|os2' then echo DOS-ish

=item then

This infix operator causes everything to the right of it to be executed
if the left operand was true. The first token to the right must be the
name of a method.

=back

This was actually implemented just so I could share the configuration
file between operating systems. The problem I was addressing was that
the pinentry program in the MacPorts version of GnuPG does not seem to
work nicely when you log in over ssh. With the above functionality, my
configuration file could contain the lines

 if not ( os darwin and env SSH_CONNECTION ) then \
     spacetrack set identity 1
 if not attr spacetrack.username then \
     echo You will need to set your spacetrack identity manually.

=head2 init

 $output = $satpass2->init();

This non-interactive method computes the name of the initialization
file, and executes it if it is present. The output (if any) is the
output of the individual commands executed by the initialization file.

If you pass a defined value as an argument, that value will be taken as
a file name, and that file will be executed if possible.  That is, this
method's functionality becomes the same as source(), but without the
possibility of passing the '-optional' option. It is an error if a file
name is specified and that file does not exist.

If you do not pass a defined value as an argument, the following files
are checked for, and the first one found is executed:

 - The file specified by the SATPASS2INI environment variable;
 - The file returned by the initfile interactive method;
 - The file specified by the SATPASSINI environment variable;
 - The file used by the satpass script.

If none of these is found, this method returns nothing.

If the initialization file is for F<satpass> rather than
C<Astro::App::Satpass2>, any commands issued in it will be interpreted
in their F<satpass> meaning, to the extent possible. Also, an attempt
will be made to rewrite the commands in any macros defined into their
C<Astro::App::Satpass2> equivalents. This rewriting is a purely textual
operation, and you may want to verify your macro definitions.

As a side effect, the name of the file actually used is stored in the
L</initfile attribute>. This is cleared if the initialization file was
not found.

This method uses a generic input mechanism, and can initialize from a
number of sources. See L</SPECIFYING INPUT DATA> for the details.

=head2 initfile

 $output = $satpass2->initfile();
 satpass2> initfile

This interactive method simply returns the name of the default
initialization file, which is heavily OS-specific. This method is
actually used to find the default initialization file, but it is exposed
to give an easy way for the user to figure out where this code expects
to find the initialization file. See also the L<init() method|/init> for
other places initialization files may be found, and the
L<initfile attribute>,
which records the name of the actual file loaded by the last call to
L<init()|/init>,

The initialization file is always named F<satpass2rc>. It is located in
the directory specified by

 File::HomeDir->my_dist_config( 'Astro-App-Satpass2' )

Unfortunately, this method returns C<undef> unless the directory
actually exists, and is sketchily documented. As of this writing, though
(February 2011), the F<Astro-App-Satpass2/> directory will be found in
directory F<Perl/> in your documents directory, or in directory
C<.perl/> if L<File::HomeDir|File::HomeDir> thinks your documents
directory is your home directory. The exception is on FreeDesktop.org
systems (e.g. Linux), where the F<Perl/> directory is found by default
in C<.config/> under your home directory.

There are two options to this method:

* C<-create-directory> causes the directory for the initialization file
to be created;

* C<-quiet> suppresses the exception which is normally thrown if the
directory for the initialization file is not found, and
C<-create-directory> was not asserted, and instead causes the method to
simply return.

=head2 list

 $output = $satpass2->list(...);
 satpass2> list

This interactive method returns a listing of all bodies in the observing
list. If the observing list is empty and the L</warn_on_empty> attribute
is true, a warning is issued.

The C<-choose> option may be used to select which bodies are listed.
This selects bodies to list just like the L<choose()|/choose> method,
but the observing list is unaffected. To choose multiple bodies, either
specify the option multiple times, separate the choices with commas, or
both.

If the C<-choose> option is not present but arguments are given, they
are made into a C<-choose> specification. Thus,

 satpass2> list hst

is equivalent to

 satpass2> list -choose hst

but

 satpass2> list -choose hst iss

will only list C<'hst'>.

=head2 load

 $satpass2->load( $filename, ... );
 satpass2> load filename

This interactive method does glob and bracket expansion on its arguments
(which have already been tilde-expanded by the tokenizer) by running
them through L<File::Glob::bsd_glob()|File::Glob>. The
resultant files are assumed to contain orbital elements which are loaded
into the observing list. An exception is thrown if no files remain after
the glob operation, or if any file can not be opened.

The C<-verbose> option causes each file name to be listed to C<STDERR>
before the file is processed.

Nothing is returned.

This method uses a generic input mechanism, and can load data from a
number of sources. See L</SPECIFYING INPUT DATA> for the details.

=head2 localize

 $satpass2->localize( qw{ formatter horizon } );
 satpass2> localize formatter horizon
 
 $satpass2->localize( { all => 1 } );
 satpass2> localize -all
 
 $satpass2->localize( { except => 1 }, qw{ formatter horizon } );
 satpass2> localize -except formatter horizon

This interactive method localizes the values of the attributes given in
the argument list to the current macro, source file, or begin block.
Nested macros or source files will see the changes, but commands outside
the scope of the localization will not. The arguments must be the names
of valid attributes. Attempts to localize a value more than once in the
same scope will be ignored. Nothing is returned.

The C<-except> option causes the argument list to be used as an
exception list, and all attributes except those in the argument list are
localized. You can use C<-all> as a synonym for C<-except>; it may look
more natural when there are no arguments.

=head2 location

 $output = $satpass2->location();
 satpass2> location

This interactive method returns the current location.

=head2 macro

 $output = $satpass2->macro( $subcommand, $arg ...);
 satpass2> macro subcommand arg ...

This interactive method manipulates macros. The following subcommands
are available:

 'brief' lists the names of defined macros;
 'list' lists the definitions of macros;
 'delete' deletes macros;
 'define' defines a command macro;
 'load' loads a code macro.

For semi-compatibility backward, each of these except C<'load'> can be
specified with a leading dash (e.g. '-delete'). With the leading dash
specified, subcommands can be abbreviated as long as the abbreviation is
unique.  For example, '-del' is equivalent to 'delete', but 'del' is
not. This compatibility functionality will go away when support for
compatibility with the F<satpass> script does.

If no arguments at all are provided to C<macro()>, 'brief' is assumed.

If a single argument is provided that does not match a subcommand name,
'list' is assumed.

If more than one argument is provided, and the first does not match a
subcommand name, 'define' is assumed.

The first argument of the 'define' subcommand is the macro name, and
subsequent arguments are the commands that make up that macro. For
example, 'say' can be defined in terms of 'echo' by

 $satpass2->macro( define => say => 'echo $@' );

The first argument of the C<'load'> subcommand is the name of a Perl
module (e.g. C<My::Macros>) that implements one or more code macros.
Subsequent arguments, if any, are the names of macros to load from the
module. If no subsequent arguments are given, all macros defined by the
macro are loaded.

By default, the F<lib/> subdirectory of the user's configuration
directory is added to C<@INC> before the code macro is loaded. The
C<-lib> option can be used to specify a different directory.

Code macros are experimental. See
L<Astro::App::Satpass2::TUTORIAL|Astro::App::Satpass2::TUTORIAL> for how
to write one.

For subcommands other than C<'define'> and C<'load'>, the arguments are
macro names.

The C<brief> and C<list> subcommands return their documented output. The
C<delete> and C<define> subcommands return nothing.

Macros can be called programmatically via the L<dispatch()|/dispatch>
method.

=head2 magnitude_table

 $output = $satpass2->magnitude_table( $subcommand, ... );
 satpass2> magnitude_table subcommand ...

This interactive method manipulates the satellite magnitude table. This
provides intrinsic magnitudes for satellites loaded via the
L<load()|/load> method. The arguments are a subcommand (defaulting to
'show'), and possibly further arguments that depend on that subcommand.
Briefly, the valid subcommands are:

C<add> - adds a body's magnitude to the table, possibly replacing an existing
entry. The arguments are OID and intrinsic magnitude, the latter defined
as the magnitude at range 1000 kilometers when half illuminated.

C<adjust> - If an argument is given, provides an adjustment to the
magnitude table data when loading TLE data. This adjustment, in
magnitudes, is added to whatever value is in the table. If no argument
is given, returns the current adjustment.

C<clear> - clears the magnitude table.

C<drop> - drops an entry from the magnitude table. The argument is the OID.

C<list> - a synonym for C<show>.

C<magnitude> - Load the magnitude table from a hash (not available
interactively). The loaded data replace whatever was there before.

C<molczan> - Load the magnitude table from a Molczan-format data file.
The loaded data replace whatever was there before.

C<molczan> - Load the magnitude table from a Quicksat-format data file.
The loaded data replace whatever was there before.

C<show> - displays the magnitude table, formatted as a series of
C<'magnitude_table add'> commands.

This method is really just a front-end for the
L<Astro::Coord::ECI::TLE|Astro::Coord::ECI::TLE> C<magnitude_table()>
method. See the documentation for that for more details.

=head2 pass

 $output = $satpass2->pass( 'today 12:00:00', '+7' );
 satpass2> pass 'today 12:00:00' +7

This interactive method computes and returns the visible passes of any
bodies in the observing list. The optional arguments are the start time of
the prediction (defaulting to the current day at noon) and the end time
of the prediction (defaulting to C<'+7'>). See L</SPECIFYING TIMES> for
how to specify times.

The following options are available:

C<-appulse> selects appulses for display. It can be negated by
specifying C<-noappulse>, though a more efficient way to not get
appulses is to clear the sky.

C<-brightest> specifies (rather than selecting) that the moment the
satellite is brightest should be calculated. If specified, this modifies
the corresponding L<pass_variant|/pass_variant> bit for the duration of
the call. If not specified, it defaults to the value of the
corresponding C<pass_variant> bit. Formatters may display magnitude if
the corresponding C<pass_variant> bit is set, but need not do so.

C<-choose> chooses bodies from the observing list to report on. Multiple
bodies can be chosen either by providing a comma-delimited list as an
argument, specifying C<-choose> multiple times, or both. The choice is
made in the same way as by the L<choose()|/choose> method, but the
observing list is not affected.

C<-chronological> causes the output to be in chronological order by
pass. If this option is not asserted (or is explicitly negated using
C<-nochronological>) the order is by satellite, though it remains
chronological for a particular satellite.

C<-dump> is a debugging tool. It is unsupported in the sense that the
author reserves the right to change or revoke its functionality without
notice.

C<-events> causes the output to be individual events rather than passes.
These events will be displayed in chronological order irrespective of
satellite. The C<-chronological> option is not needed for this.

C<-horizon> selects the satellite rise and set for display. Synonyms are
C<-rise> and C<-set> -- that is C<-rise> selects both rise and set, as
does C<-set>. This can be negated by specifying C<-nohorizon>,
C<-norise>, or C<-noset>.

C<-illumination> selects passage of the satellite into or out of the
Earth's shadow for display. This can be negated by specifying
C<-noillumination>.

C<-magnitude> is a synonym for C<-brightest>. See the documentation to
that option (above) for more information.

C<-quiet> suppresses any errors generated by running the orbital model.
These are typically from obsolete data, and/or decayed satellites.
Bodies that produce errors will not be included in the output.

C<-transit> selects the satellite transit across the meridian for
display. Synonyms are C<-maximum> and C<-culmination>. These can be
negated by specifying C<-notransit>, C<-nomaximum>, or
C<-noculmination>.

The C<-appulse>, C<-horizon>, C<-illumination> and C<-transit> options
(and their synonyms) specify what output to produce. If none are
specified, all are turned on by default. If only negated options are
specified (e.g. -noappulse), unspecified options are asserted by
default. Otherwise, unspecified options are considered to be negated.

B<Note well> that unlike the F<satpass> script, the output from this
method does not normally include location. The location is included only
if the command is issued from a F<satpass> initialization file (as
opposed to an C<Astro::App::Satpass2> initialization file, or from a macro
defined in a F<satpass> initialization file. This functionality will be
revoked when support for the F<satpass> script is dropped.

=head2 perl

 $output = $satpass2->perl( $perl_file );
 satpass2> perl perl_file

This interactive method runs the given Perl file using the C<do>
built-in. The file is entered with C<$ARGV[0]> set to a reference to the
invocant, and subsequent C<@ARGV> entries set to the arguments, if any.
The return is the result of the last statement in the file unless the
file returns an instance of C<Astro::App::Satpass2>, in which case
nothing is returned.

If you provide the option C<-eval>, the argument is passed to the
C<eval> built-in instead.

If you provide the option C<-setup>, you are identifying the Perl as
containing set-up code. This does not cause the method to function any
differently, but it does cause it to record the arguments so that the
L<save()|/save> method will emit the invocation into a setup file. Both
the file name and the arguments will be preserved without tilde
expansion.

=head2 phase

 $output = $satpass2->phase();
 satpass2> phase

This interactive method computes and returns the phase of any bodies in
the sky which support this. The optional argument is the time of the
prediction (defaulting to the current time). See L</SPECIFYING TIMES>
for how to specify times.

=head2 position

 $output = $satpass2->position(...);
 satpass2> position ...

This interactive method computes and returns the positions of all bodies
in the observing list and in the sky. For bodies on the observing list
that can flare, flare status is displayed for all sources of flares on
the body.

There is one argument, which is the time for the computation, which
defaults to the current time.

The following options may be specified:

C<-choose=choice> selects bodies to display. This can be specified
multiple times to select multiple bodies, or the C<choice> argument can
be a comma-separated list of things to choose, or both. The choices are
implemented in exactly the same way as for the L<choose()|/choose>
method, but the observing list is not affected, and the choice is
applied to objects in the sky as well.

C<-questionable> causes flare data to be provided on bodies whose
ability to produce predictable flares is questionable.

C<-quiet> suppresses any errors generated by running the orbital model.
These are typically from obsolete data, and/or decayed satellites.
Bodies that produce errors will not be included in the output.

C<-spare> is a synonym for C<-questionable>.

The C<endtime> and C<interval> arguments and the C<-realtime> option,
which were present in the original F<satpass> script, have been
retracted. If you need any of these, please contact the author.

=head2 pwd

 $output = $satpass2->pwd();
 satpass2> pwd

This interactive method simply returns the name of the current working
directory, terminated with a C<"\n">.

=head2 quarters

 $output = $satpass2->quarters($start_time, $end_time, ...);
 satpass2> quarters start_time end_time ...

This interactive method computes and returns the quarters for any
objects in the sky that have this functionality.

It takes up to two arguments, which are the start and end time covered.
The start time defaults to midnight of the current day in the local time
zone, or GMT if the L</gmt> attribute is true. The end time defaults to
30 days after the start time. See L</SPECIFYING TIMES> for how to
specify times.

The following options are available:

=over

=item -choose

 -choose moon

This option selects the body whose quarters are to be computed. It can
be specified multiple times to select multiple bodies. If omitted, all
bodies in the sky are selected. Note that in any event bodies that do
not support the C<next_quarter_hash()> method are skipped.

=item -dump

This option produces debugging output. It should be considered a
troubleshooting tool, which may change or disappear without notice.

=item -q0, or -new, or -spring

This option causes the time of the zeroth quarter to be displayed. The
synonyms are appropriate to the Moon and Sun respectively. See below for
how this is defaulted.

=item -q1, or -first, or -summer

This option causes the time of the first quarter to be displayed. The
synonyms are appropriate to the Moon and Sun respectively. See below for
how this is defaulted.

=item -q2, or -full, or -fall

This option causes the time of the second quarter to be displayed. The
synonyms are appropriate to the Moon and Sun respectively. See below for
how this is defaulted.

=item -q3, or -last, or -winter

This option causes the time of the third quarter to be displayed. The
synonyms are appropriate to the Moon and Sun respectively. See below for
how this is defaulted.

=back

The C<-q0>, C<-q1>, C<-q2>, and C<-q3> options (and their synonyms) are
defaulted as a group. If none of the group is specified, all are
asserted by default. If none is asserted but at least one is negated
(e.g. C<-nonew>), all unspecified members of the group are asserted by
default. If at least one member of the group is asserted, all
unspecified members are negated by default.

=head2 run

 Astro::App::Satpass2->run(...);

This non-interactive method runs the application. The arguments are the
options and commands to be passed to the application.

The valid options are:

 -echo to turn on command echoing;
 -filter to suppress banner text;
 -gmt to output time in GMT;
 -initfile name of the initialization file to use;
 -version to display the output of version() and return.

The -filter option defaults to true if STDIN is not a terminal.

The steps in running the application are:

1) If the first argument is a code reference, it is pulled off the
argument list and used for input. Otherwise default input code is
generated as described later.

2) The arguments are parsed as though they are a command line.

3) If the input is from a terminal and the -filter option was not
specified, a banner is printed.

4) The initialization file is located and run. If you specified an
initialization file via the C<-initfile> option, you will be warned if
it was not found. If the initialization file contains the C<exit>
command, it will be executed, and the run will end at this step.

5) Any remaining options corresponding to attribute values (currently
only C<-gmt>) are applied.

6) Any remaining arguments after removing all options are assumed to be
commands, and passed to the L<execute()|/execute> method. If one of
these is the C<exit> command, the run will end at this step.

7) Further commands are read as described below.

By default, commands come from C<STDIN>, but any commands passed as
arguments are executed first. How commands are read from C<STDIN>
depends on a number of factors. If C<STDIN> is a terminal and
Term::ReadLine can be loaded, a Term::ReadLine object is instantiated
and used to read input.  If C<STDIN> is a terminal and Term::ReadLine
can not be loaded, the prompt is printed to C<STDERR> and C<STDIN> is
read.  If C<STDIN> is not a terminal, it is read.

The default command acquisition behavior can be changed by passing, as
the first argument, a code reference. This should refer to a subroutine
that expects the prompt as its only argument, and returns the next
input. This code should return C<undef> to indicate a logical
end-of-file.

The exit command causes the method to return.

This method can also be called on an Astro::App::Satpass2 object. For example:

 use Astro::App::Satpass2;
 my $app = Astro::App::Satpass2->new(
     prompt => 'Your wish is my command: '
 );
 $app->run();

=head2 save

 $satpass2->save( $file_name );
 satpass2> save file_name

This interactive method saves your current settings to the named file.
If no file is named, they are saved to the default configuration file.
If the file already exists, you will be prompted unless you specified
the C<-overwrite> option. Nothing is returned.

File name F<-> is special, and causes output to go wherever standard
output is being sent.

This method saves all attribute values of the C<Astro::App::Satpass2> object,
all attributes of the L<Astro::SpaceTrack|Astro::SpaceTrack> object
being used to retrieve TLE data, and all defined macros. If you
overwrite a configuration file, any other contents of the file will be
lost.

The following options are allowed:

C<-changes> causes only changes from the default attributes to be
written to the output file.

C<-overwrite> causes the output file to overwrite an existing file of
the same name (if any) without getting confirmation from the user.

=head2 set

 $satpass2->set($name => $value ...);
 satpass2> set name value ...

This interactive method sets the values of the given
L<attributes|/ATTRIBUTES>. More than one attribute can be set at a time.
Nothing is returned.

When this method is being executed interactively (i.e. via the
L</dispatch> method, as opposed to being called directly as a method),
certain attributes may not be set. Also, the literal C<'undef'> is taken
to represent the undefined value.

=head2 show

 $output = $satpass2->show( $name, ... );
 satpass2> show name ...

This interactive method returns the values of the given attributes,
formatted as 'set' commands. If no arguments are given, the values of
all non-deprecated attributes that may be set interactively are
returned.

If you specify the C<-changes> option, only those values that have been
changed from the default are returned.

=head2 sky

 $output = $satpass2->sky( $subcommand ...);
 satpass2> sky subcommand ...

This interactive method manipulates the background objects. The
$subcommand argument determines what manipulation is done, and the
interpretation of subsequent arguments depends on this. The
interpretation of the subcommand names is not case-sensitive. If no
subcommand is given, 'list' is assumed.

The possible subcommands are:

=head3 add

This subcommand adds an object to the background. The first argument is
the name of the object. If the case-insensitive name of the object
appears in the sky class list (see below) it is instantiated and added.
Otherwise the name is assumed to be the name of a star, and its
coordinates must be given, in the following order: right ascension (in
either degrees or hours, minutes, and seconds), declination (in
degrees), range (optionally with units of meters ('m'), kilometers
('km'), astronomical units ('au'), light years ('ly'), or parsecs ('pc',
the default) appended), proper motion in right ascension and declination
(in degrees per year) and in recession (in kilometers per second). All
but right ascension and declination may be omitted. It is an error to
attempt to add an object which is already listed among the background
objects. Nothing is returned.

=head3 class

This subcommand maintains the classes of background objects. It takes
the following subcommand-specific options:

=over

=item -add

If this Boolean option is asserted, the object is added to the sky once
it is successfully defined.

You may not specify both C<-add> and C<-delete> on the same command.

=item -delete

If this Boolean option is asserted, the arguments are the
case-insensitive names of class definitions to remove. The definition
for the Sun can not be removed, and any class actually instantiated in
the sky can not be removed. Nothing is returned.

You may not specify both C<-add> and C<-delete> on the same command.

=back

Options can be specified either command-line style (with leading dashes
or double dashes, as documented above) or as an optional hash reference
appearing immediately after the subcommand name. In the latter case
option names must be specified in full.

Unless the C<-delete> option is specified (see above), the arguments are
the case-preserved name of the object being defined, the name of the
class that implements it, and optional attribute values (specified as
name/value pairs). You may not specify the C<name> attribute, because
this is derived from the first argument. This information is added to
the known object definitions, replacing the previous definition if any.
Nothing is returned.

If only a name is specified, the definition of that name is returned,
formatted as a C<'sky class'> command. If no arguments at all are
specified, all defined classes are returned.

=head3 clear

This subcommand clears all background objects. It takes no arguments.
Nothing is returned.

=head3 drop

This subcommand removes background objects. The arguments are the names
of the background objects to be removed, or portions thereof. They are
made into a case-insensitive regular expression to perform the removal.
Nothing is returned.

=head3 list

This subcommand returns a string containing a list of the background
objects, in the format of the 'sky add' commands needed to re-create
them. If no subcommand at all is given, 'list' is assumed.

=head3 lookup

This subcommand takes as its argument a name, looks that name up in the
University of Strasbourg's SIMBAD database, and adds the object to the
background. An error occurs if the object can not be found. This
subcommand will fail if the
L<Astro::SIMBAD::Client|Astro::SIMBAD::Client> module can not be loaded.
Nothing is returned.

=head2 source

 $output = $satpass2->source( $file_name );
 satpass2> source file_name

This interactive method takes commands from the given file and runs
them. The concatenated output is returned.

Normally an exception is thrown if the file can not be opened. If the
C<-optional> option is specified, open failures cause the method to
return C<undef>.

This method uses a generic input mechanism, and can load files from a
number of sources. See L</SPECIFYING INPUT DATA> for the details.

=head2 spacetrack

 $satpass2->spacetrack( set => username => 'yehudi' );
 satpass2> spacetrack set username yehudi
 
 say $satpass2->spacetrack( get => 'username' );
 satpass2> spacetrack get username

This interactive method takes as its arguments the name of a method, and
any arguments to be passed to that method. This method is called on the
object which is stored in the L<spacetrack attribute|/spacetrack
attribute>, and any results returned. Normally it will be used to
configure the spacetrack object. See the
L<Astro::SpaceTrack|Astro::SpaceTrack> documentation for further
details.

If the L<Astro::SpaceTrack|Astro::SpaceTrack> method returns
orbital elements, those elements are added to C<Astro::App::Satpass2>'s
internal list.

Similarly, if the L<Astro::SpaceTrack|Astro::SpaceTrack> method returns
Iridium status information, this will replace the built-in status.

In addition to the actual L<Astro::SpaceTrack|Astro::SpaceTrack>
methods, this method emulates methods which it would be useful (to
C<Astro::App::Satpass2> for L<Astro::SpaceTrack|Astro::SpaceTrack> to
have. These are:

=over

=item show

This can be used to display multiple
L<Astro::SpaceTrack|Astro::SpaceTrack> attributes. If no attribute names
are provided, all attributes are displayed. If C<-changes> is specified,
only changed attributes are displayed.

=item config

This is really just an alias for C<show>, provided for consistency with
the formatter and time parser objects.

=back

This method takes the following options:

=over

=item -changes

This option is only useful with the C<config> and C<show> emulated
methods, as discussed above. It causes these to return only changes from
the default. It can be negated by prefixing C<no>.

The default is C<-nochanges>.

=item -raw

This option causes the method to return whatever the underlying method
call returned. Where the underlying method returns an
L<HTTP::Response|HTTP::Response> object, the content of that object is
returned. If negated (as C<-noraw>), the return is formatted for text
display.

The default is C<-noraw> if called interactively, and C<-raw> otherwise.

=back

=head2 st

 $output = $satpass2->st( $method ...);
 satpass2> st method ...

This interactive method is deprecated in favor of the
L<spacetrack()|/spacetrack> method. If you don't like all the
typing that implies in interactive mode, you can define 'st' as a
macro:

 satpass2> macro define st 'spacetrack "$@"'

This interactive method calls L<Astro::SpaceTrack|Astro::SpaceTrack>
(which must be installed) to load satellite data. The arguments are the
L<Astro::SpaceTrack|Astro::SpaceTrack> method name and any arguments to
that method. As special cases, 'show' is made equivalent to 'get', 'get'
will display all attribute values if called without a value, and
'localize' will localize attribute values to a block. The return is
whatever the method returns.

The following options are allowed on any retrieval:

 -all specifies the retrieval of all manned spaceflight elements;
 -descending specifies the return of data in descending order;
 -last5 specifies the return of the last 5 elements;
 -end specifies the end time for the data to be fetched;
 -start specifies the start time for the data to be fetched;
 -sort specifies the type of sort to do on the data;
 -verbose gets output for normally-silent functions.

All options except for -verbose are specific to
L<Astro::SpaceTrack|Astro::SpaceTrack>, and are silently ignored unless
relevant to the method being called.

The following options are allowed on the 'get' or 'show' commands:

 -changes reports only changes from the defaults used by Astro::App::Satpass2.

This method will fail if the L<Astro::SpaceTrack|Astro::SpaceTrack>
module can not be loaded.

=head2 status

 $output = $satpass2->status( $subcommand, ... );
 satpass2> status subcommand ...

This interactive method manipulates the satellite status cache. This
currently only covers Iridium satellites. The arguments are a subcommand
(defaulting to 'show'), and possibly further arguments that depend on
that subcommand.  Briefly, the valid subcommands are:

C<add> - adds a body to the status table, possibly replacing an existing
entry. The arguments are OID, type, status, name, and comment. The type
would typically be 'iridium', and status typically '+' (operational),
'S' (spare), or '-' (failed). Name and comment default to empty.

C<clear> - clears the status table. You can specify a type, and only
that type would be cleared, but currently there is only one type.

C<drop> - drops an entry from the status table. The argument is the OID.

C<iridium> - dropped in favor of C<show>, to remain compatible with
F<satpass> version 0.050. An exception will be thrown if this subcommand
is used.

C<list> - a synonym for C<show>.

C<show> - displays the status table, formatted as a series of 'status
add' commands.

There are two options:

-name specifies that the data for the C<show> subcommand be displayed in
order by name. It is allowed but ignored on any other subcommand.

This method is really just a front-end for the
L<Astro::Coord::ECI::TLE|Astro::Coord::ECI::TLE> C<status()> method. See
the documentation for that for more details.

=head2 station

 my $sta = $satpass2->station();

This non-interactive method manufactures and returns an
L<Astro::Coord::ECI|Astro::Coord::ECI> object representing the observer
from the current values of the latitude, longitude and height
attributes. It throws an exception if any of the relevant attributes are
not defined.

=head2 system

 $output = $satpass2->system(...);
 satpass2> system ...
 satpass2> !...

This interactive method does glob and bracket expansion on its arguments
(which have already been tilde-expanded by the tokenizer) by running
them through L<File::Glob::bsd_glob()|File::Glob>, and executes
them as a command on the system. Since tokenizing is done by
Astro::App::Satpass2, there is no shell processing, and the quoting rules are
those of Astro::App::Satpass2, not those of the underlying operating system.

If the L</stdout> attribute is a terminal, output goes directly to the
terminal, thus making things like 'less' possible. Otherwise output is
captured and returned.

=head2 time

 $output = $satpass2->time( $method ...);
 satpass2> time method ...

This interactive method times the given method. The arguments are the
name of an interactive method and the arguments to that method. The
return is whatever the called method returns. The timings are written to
standard error.

You can only time the L<begin()|/begin> method if C<time()> is called
interactively. If you do this, the timing will include everything
through the corresponding interactive call to L<end()|/end> (or whenever
the frame created by the C<begin()> is popped off the stack, which may
be the end of a macro or source file.) See L<METHODS|/METHODS> above
fore what it means to be called interactively.

You can not time the L<end()|/end> method.

This method will fail if the L<Time::HiRes|Time::HiRes> module can not
be loaded.

=head2 time_parser

 $satpass2->time_parser( zone => 'MST7MDT' );
 satpass2> time_parser zone MST7MDT
 
 say $satpass2->time_parser( 'zone' );
 satpass2> time_parser zone

This interactive method takes as its arguments the name of a method, and
any arguments to be passed to that method. This method is called on the
object which is stored in the L<time_parser attribute|/time_parser
attribute>, and any results returned. Normally it will be used to
configure the time parser object. See the documentation on the time
parser class in use for further details.

This method takes the following options:

=over

=item -changes

This option is only useful with the time_parser's
L<config()|Astro::App::Satpass2::Format/config> method. It causes
this method to return only changes from the default. It can be negated
by prefixing C<no>.

The default is C<-nochanges>.

=item -raw

This option causes the method to return whatever the underlying method
call returned. If negated (as C<-noraw>), the the return is formatted
for text display.

The default is C<-noraw> if called interactively, and C<-raw> otherwise.

=back

=head2 tle

 $output = $satpass2->tle(...);
 satpass2> tle ...

This interactive method returns the actual TLE data for the observing
list. If any arguments are passed, they select the items to be
displayed, in the same way that L</choose> does, though in this case the
contents of the observing list are unaffected.

The following options are allowed:

 -choose explicitly chooses the bodies to display. The
     contents of the observing list are unaffected, and
     arguments are ignored.
 -verbose produces an expanded list, with data labeled.

Actually, the presence of any template whose name begins with C<'tle_'>
causes the trailing part of the name to be valid as an option selecting
that template. For example, loading F<eg/tle_json.tt> as template
C<'tle_json'> makes C<-json> a valid option that uses template
C<'tle_json'> to format the TLE.

The template selector options can be negated by prefixing C<'no'> to the
option name (e.g. C<-noverbose>). Negating the option specifies template
C<'tle'>, the default.

If more than one template selector option is specified, the rightmost
one riles. For example, given template C<'tle_json'>,

 satpass2> tle -verbose -json

uses template C<'tle_json'> to display the output.

=head2 unexport

 $satpass2->unexport( $name, ... );
 satpass2> unexport name ...

This interactive method undoes the effects of L<export()|/export>.
Unlike that method, multiple things can be unexported with a single
call. It is not an error to unexport something that was never exported.

=head2 validate

 $satpass2->validate( $options, $start_time, $end_time );
 satpass2> validate [ options ] start_time end_time

This interactive method validates the current observing list in the
given time range by performing position calculations at relevant times
in the range.

The only valid option is

 -quiet - suppress output of validation failures.

The start time defaults to noon of the current day; the end time
defaults to seven days after the start time.

This method really just wraps the C<validate()> methods in either
L<Astro::Coord::ECI::TLE|Astro::Coord::ECI::TLE>, or
L<Astro::Coord::ECI::TLE::Set|Astro::Coord::ECI::TLE::Set>, as
appropriate.

=head2 version

 $output = $satpass2->version();
 satpass2> version

This interactive method simply returns C<Astro::App::Satpass2> version
information.

=head2 wail

 $satpass2->wail( 'Something went wrong' );

This non-interactive method is simply a wrapper for our
C<Astro::App::Satpass2::Warner> object's C<wail()> method, which
corresponds more or less to C<Carp::croak()>.

=head2 want_pass_variant

 $satpass2->want_pass_variant( 'brightest' );

This convenience method returns a true value if the given pass variant
is in effect, and false otherwise. The argument must be exactly one of the valid
variant names documented for the L<pass_variant|/pass_variant>
attribute, and must not be C<'none'>.

=head2 weep

 $satpass2->weep( 'Something went very wrong' );

This non-interactive method is simply a wrapper for our
C<Astro::App::Satpass2::Warner> object's C<weep()> method, which
corresponds more or less to C<Carp::confess()>.

=head2 whinge

 $satpass2->whinge( 'Something went a little wrong' );

This non-interactive method is simply a wrapper for our
C<Astro::App::Satpass2::Warner> object's C<whinge()> method, which
corresponds more or less to C<Carp::carp()>.

=head2 __add_to_observing_list( @bodies );

This method is exposed for the use of code macros, and is unsupported
until such time as code macros themselves are.

This method adds the given bodies to the observing list. All must
represent L<Astro::Coord::ECI::TLE|Astro::Coord::ECI::TLE> objects, or
an exception will be thrown and none will be added to the observing
list.

=head2 __choose

 $chosen = $self->__choose( \%opt, \@choice, @list )
 @chosen = $self->__choose( \%opt, \@choice, @list )

This method is exposed for the use of code macros, and is unsupported
until such time as code macros themselves are.

This method filters the list of bodies provided in C<@list> according to
the criteria in C<@choice> (possibly modified by the options in C<%opt>,
and returns all matching bodies. If called in scalar context, it returns
a reference to an array containing all matching bodies.

Argument C<\%opt> is optional, and defaults to an empty hash. If
present, it specifies modifiers for the choice operation. The supported
options are:

=over

=item invert

If specified as a true value, it inverts the sense of the match; that
is, the return is everything B<not> selected by the C<\@choice>
argument.

=item bodies

If specified as a true value, all currently-loaded orbiting bodies (that
is, all objects displayed by

 satpass2> list

)will be aggregated and appended to the C<@list>.

=item sky

If specified as a true value, all currently-loaded background objects
(that is, objects displayed by

 satpass2> sky list

) will be appended to the C<@list>.

=back

The C<\@choice> argument specifies things to choose from the C<@list>.
It must be specified, but may be specified as C<undef>. If C<\@choice> is
C<undef> or a reference to an empty array, the entire contents of
C<@list> are returned. Otherwise all objects in C<@list> that match any
item in C<@choice> are returned -- unless C<invert> is in effect, in
which case all objects in C<@list> that match no item in C<@choice> are
returned.

The contents of C<@choice> are interpreted as follows:

=over

=item strings

Strings are split on commas, and the resultant pieces used as though
they were specified separately. Numbers greater than C<999> are assumed
to be OIDs, and select objects having that value of the C<'id'>
attribute of each item in C<@list>. Anything else is made into an
unanchored regular expression and matched to the value of the C<'name'>
attribute of each item in C<@list>.

=item Regexp objects

These are matched against the value of the C<'name'> attribute of each
item in C<@list>.

=back

The C<@list> argument is actually optional, though if it is omitted
nothing interesting happens unless the C<bodies> or C<sky> options (or
both) are specified.

The C<@list> argument is expected to contain C<Astro::Coord::ECI>
objects (or, of course, C<Astro::Coord::ECI::TLE::Set> objects), or
references to arrays of such objects. Any array references are flattened
into C<@list> before processing.

=head2 __format_data

 $text = $satpass2->__format_data( $template, $data, $opt );

This method is exposed for the use of code macros, and is unsupported
until such time as code macros themselves are.

This method expects a C<Template-Toolkit> C<$template> name, the
C<$data> to be formatted by the template, and an optional C<$opt> hash
reference. If the {dump} key in $opt is true, the C<$data> are formatted
using a dumper template, otherwise they are formatted by the current
Template object. The C<$data> are the data used by the template,
typically (though not necessarily) an array reference.

=head2 __parse_angle

 $angle = $satpass2->__parse_angle( $string );

This method is exposed for the use of code macros, and is unsupported
until such time as code macros themselves are.

This method parses the C<$string> as an angle in degrees,
hours:minutes:seconds of right ascension, or degreesDminutesMsecondsS of
arc, and returns the angle in degrees. If C<$string> is C<undef>, we
simply return. An exception is thrown if the C<$string> can not be
parsed.

A reference to an options hash can be passed before the C<$string>
argument. The supported options are:

=over

=item accept

If this is true (in the perl sense) anything not parsed as an angle is
simply returned. In this case the caller is responsible for being sure
the return is valid.

=back

=head2 __parse_distance

 $distance = $self->__parse_distance( $string, $default_units );

This method is exposed for the use of code macros, and is unsupported
until such time as code macros themselves are.

This method parses the C<$string> as a distance, applying the
C<$default_units> if no units are specified, and returns the distance in
kilometers.

The C<$string> is presumed to be a magnitude and optional appended
units. Supported units are:

 au - astronomical units
 ft - feet
 km - kilometers
 ly - light years
 m -- metars
 mi - miles
 pc - parsecs

Specified units are converted to lower case before use.

=head2 __parse_time

 $time = $satpass2->__parse_time( $string, $default );

This method is exposed for the use of code macros, and is unsupported
until such time as code macros themselves are.

This method parses the C<$string> as a time and returns the time. If
C<$string> is false (in the Perl sense) we return C<$default>.

If C<$string> begins with a C<'+'> or C<'-'>, it is assumed to be
an offset in C<days hours:minutes:seconds> from the last
explicitly-specified time. Otherwise it is handed to C<Date::Manip> for
parsing. Invalid times result in an exception.

Epoch times can be specified either by prefixing C<'epoch '> or by
passing a reference to the value.

=head1 ATTRIBUTES

The Astro::App::Satpass2 object has a number of attributes to configure its
operation. In general:

Attributes that represent angles are in degrees, but may be set in other
representations (e.g. degrees, minutes, and seconds). See L</SPECIFYING
ANGLES> for more detail.

Boolean (i.e. true/false) attributes are set by convention to 1 for
true, or 0 for false. The evaluation rules are those of Perl itself:
0, '', and the undefined value are false, and everything else is true.

There are a few attributes whose names duplicate the names of methods.
These will be identified as attributes, for the sake of internal links.
For example, L</appulse>, but L</height attribute>.

The attributes are:

=head2 appulse

This numeric attribute specifies the maximum angle reportable by the
L</pass> method between the orbiting body and any of the background
objects. If the body passes closer than this, the closest point will
appear as an event in the pass. The intent is to capture transits or
near approaches.

If this attribute is set to 0, no check for close approaches to
background objects will be made.

See L</SPECIFYING ANGLES> for ways to specify an angle. This attribute
is returned in decimal degrees.

The initial setting is 0.

=head2 autoheight

This boolean attribute determines whether the L</geocode> method
attempts to acquire the height of the location above sea level.  It does
this only if the parameter is true and the geocoding returns exactly one
location. You may wish to turn this off (i.e. set it to 0) if the USGS
elevation service is being balky.

The default is 1 (i.e. true).

=head2 backdate

This boolean attribute determines whether the L</pass> method will
attempt to use orbital elements before their effective date. It is
actually simply propagated to the C<backdate> attribute of the
individual TLE objects, and so takes effect on a per-object basis. If it
is false, the L</pass> method will silently move the start of the pass
prediction to the effective date of the data if the specified pass start
is earlier than the effective date of the data.

The default is 0 (i.e. false). This is different from the old F<satpass>
script, which defaulted it to true.

=head2 background

This boolean attribute determines whether the location of the background
body is displayed when the L</appulse> logic detects an appulse.

The default is 1 (i.e. true).

=head2 continuation_prompt

This string attribute specifies the string used to prompt for
continuations of lines.

The default is C<< '> ' >>.

=head2 country

This attribute is ignored and deprecated.

This string attribute determines the default country for the L</geocode>
and L</height> methods. The intent is that it be an ISO 3166
two-character country code. At the moment it does nothing useful since
there is currently only one source for L</geocode> and L</height> data.

See L<https://www.iso.org/iso-3166-country-codes.html>
for the current list of country codes. Note that these are B<not>
always the same as the corresponding top-level geographic domain names
(e.g. Great Britain is 'GB' in ISO 3166 but for historical reasons has
both 'gb' and 'uk' as top-level geographic domain name).

The country codes are case-insensitive, since they will be converted to
lower case for use.

The default is 'us'.

=head2 date_format

This string attribute is deprecated. It is provided for backward
compatibility with the F<satpass> script. The preferred way to
manipulate this is either directly on the formatter object (if you set
it yourself and retained a reference), or via the
L<formatter()|/formatter> method, e.g.:

 $satpass2->get( 'formatter' )->date_format( '%d-%b-%Y' );
 satpass2> formatter date_format '%d-%b-%Y'

This attribute allows access to and manipulation of the formatter
object's L<date_format|Astro::App::Satpass2::Format/date_format> attribute.
This is normally used as a C<strftime (3)> format to format a date. See
the L<date_format|Astro::App::Satpass2::Format/date_format> documentation for
the default. See the documentation of the actual formatter class being
used for what it does.

This string attribute specifies the format used to display
dates. Documentation of the C<strftime (3)> subroutine may be found at
L<http://www.openbsd.org/cgi-bin/man.cgi?query=strftime&apropos=0&sektion=0&manpath=OpenBSD+Current&arch=i386&format=html>,
among other places.

The above is a long URL, and may be split across multiple lines. More
than that, the formatter may have inserted a hyphen at the break, which
needs to be taken out to make the URL good. I<Caveat user.>

=head2 debug

This numeric attribute turns on debugging output. The only supported
value is 0. The author makes no representation of what will happen if a
non-zero value is set, not does he promise that the behavior for a given
non-zero value will not change from release to release.

The default is 0.

=head2 desired_equinox_dynamical

This string attribute is deprecated. It is provided for backward
compatibility with the F<satpass> script. The preferred way to
manipulate this is either directly on the formatter object, or via the
L<formatter()|/formatter> method.

This attribute allows access to and manipulation of the formatter
object's
L<desired_equinox_dynamical|Astro::App::Satpass2::Format/desired_equinox_dynamical>
attribute. This is normally used to specify the desired equinox for
inertial coordinates. See the
L<desired_equinox_dynamical|Astro::App::Satpass2::Format/desired_equinox_dynamical>
documentation for the default. See the documentation of the actual
formatter class being used for what it does.

Note that while the wrapped attribute is a number, this class treats it
as a string. This results in a certain lack of orthogonality among the
behaviors of the L</set>, L</get>, and L</show> methods.

The L</set> method runs its input through the time parser object's
L<parse_time|Astro::App::Satpass2::ParseTime/parse> method. Since that expects
to parse a string of some sort, you can not (unfortunately) pass in a
Perl time. See the L<Astro::App::Satpass2::ParseTime|Astro::App::Satpass2::ParseTime>
documentation for the details.

The L</get> method simply returns a Perl time.

The L</show> method formats the value of the attribute in a way that can
(hopefully!) be parsed by any of the time parsers supplied with this
package.

=head2 echo attribute

This boolean attribute causes commands that did not come from the
keyboard to be echoed. Set it to a non-zero value to watch your scripts
run, or to debug your macros, since the echo takes place B<after>
parameter substitution has occurred.

The default is 0.

=head2 edge_of_earths_shadow

This numeric attribute specifies the offset in elevation of the edge of
the Earth's shadow from the center of the illuminating body (typically
the Sun) as seen from a body in space. The offset is in units of the
apparent radius of the illuminating body, so that setting it to C<1>
specifies the edge of the umbra, C<-1> specifies the edge of the
penumbra, and C<0> specifies the middle of the penumbra. This attribute
corresponds to the same-named L<Astro::Coord::ECI|Astro::Coord::ECI>
attribute.

The default is 1 (i.e. edge of umbra).

=head2 ellipsoid

This string attribute specifies the name of the reference ellipsoid to
be used to model the shape of the earth. Any reference ellipsoid
supported by see L<Astro::Coord::ECI|Astro::Coord::ECI> may be used.

The default is 'WGS84'.

=head2 error_out

This boolean attribute specifies the behavior on encountering an error.

If this attribute is true, all macros, source files, etc are aborted on
an error, and control is returned to the caller, or to the L<run()|/run>
method if that is where we came from. If standard in is not a terminal,
we exit.

If this attribute is false, errors are reported, but otherwise ignored.

The default is 0 (i.e. false).

=head2 exact_event

This boolean attribute specifies whether the L</pass> method should
compute visibility events (rise, set, max, into or out of shadow,
beginning or end of twilight) to the nearest second. If false, such
events are reported to the step size specified when the L</pass> method
was called.

The default is 1 (i.e. true).

=head2 explicit_macro_delete

This boolean attribute is ignored and deprecated. It exists because the
F<satpass> script required it to deal with a change in the functionality
of the C<macro> command.

The default is 1 (i.e. true).

=head2 extinction

This boolean attribute specifies whether magnitude estimates take
atmospheric extinction into account. It should be set true if you are
interested in measured brightness, and false if you are interested in
estimating magnitudes versus nearby stars.

The default is 1 (i.e. true).

=head2 filter

Setting this boolean attribute true suppresses the front matter that is
normally output by the L<run()|/run> method if standard input is a
terminal. If standard input is not a terminal, the front matter is not
provided anyway.

The default is undef (i.e. false).

=head2 flare_mag_day

This numeric attribute specifies the limiting magnitude for the flare
calculation for flares that occur during the day. For this purpose, it
is considered to be day if the elevation of the Sun is above the
L<twilight|/twilight> attribute.

The default is -6.

=head2 flare_mag_night

This numeric attribute specifies the limiting magnitude for the flare
calculation for flares that occur during the night. For this purpose, it
is considered to be night if the elevation of the Sun is below the
L<twilight|/twilight> attribute.

The default is 0.

=head2 formatter attribute

This attribute specifies the class to be used to format output. You can
set it to either the actual formatter object, or to the name of the
class to use. In the latter case, an object of the appropriate class
will be instantiated, so C<get( 'formatter' )> always returns an object.
A call to C<show( 'formatter' )>, however, will always show the class
name.

When setting the formatter to a class name, the leading
C<'Astro::App::Satpass2::Format::'> may be omitted.

Minimal constraints on the formatter class are imposed, but while it
need not be a subclass of
L<Astro::App::Satpass2::Format|Astro::App::Satpass2::Format>, it B<must>
conform to that class' interface.

The default is
L<Astro::App::Satpass2::Format::Template|Astro::App::Satpass2::Format::Template>.

=head2 geocoder

This attribute specifies which geocoding service can be used. It takes
as its value any subclass of
L<Astro::App::Satpass2::Geocode|Astro::App::Satpass2::Geocode> -- either
an actual instantiated object or a class name. If the class name is
specified, the leading C<Astro::App::Satpass2::Geocode::> can be
omitted.

As of version 0.031_001, support for
C<Geo::Coder::Geocoder::US> has been retracted, so the default is
L<Astro::App::Satpass2::Geocode::OSM|Astro::App::Satpass2::Geocode::OSM>.
The problem with C<Geo::Coder::Geocoder::US> was the disappearance of
the underlying web side, leading to the retraction of that module.

=head2 geometric

This boolean attribute specifies whether satellite rise and set should
be computed versus the geometric horizon or the effective horizon
specified by the L</horizon> attribute. If true, the computation is
versus the geometric horizon (elevation 0 degrees). If false, it is
versus whatever the L</horizon> attribute specifies.

The default is 1 (i.e. true).

=head2 gmt

This boolean attribute is deprecated. It is provided for backward
compatibility with the F<satpass> script. The preferred way to
manipulate this is either directly on the formatter object, or via the
L<formatter()|/formatter> method.

This attribute allows access to and manipulation of the formatter
object's L<gmt|Astro::App::Satpass2::Format/gmt> attribute. This is normally
used to specify whether time is displayed in local or Greenwich Mean
Time (a.k.a. Universal Time).  See the L<gmt|Astro::App::Satpass2::Format/gmt>
documentation for the default. See the documentation of the actual
formatter class being used for what it does.

The default will normally be 0 (i.e. false).

=head2 height attribute

This numeric attribute specifies the height of the observer above mean
sea level, in meters. To specify in different units, see L</SPECIFYING
DISTANCES>. The L<get()|/get> method returns meters.

There is no default; you must specify a value.

=head2 horizon

This numeric attribute specifies the minimum elevation a body must
attain to be considered visible, in degrees. If the L</geometric>
attribute is false, the rise and set of the satellite are computed
versus this setting also.

See L</SPECIFYING ANGLES> for ways to specify an angle. This attribute
is returned in decimal degrees.

The default is 20 degrees.

=head2 initfile attribute

This string attribute records the name of the file actually used by the
most recent L<init()|/init> call. It will be C<undef> if L<init()|/init>
has not been called, or if the most recent L<init()|/init> call did not
execute a file.

This attribute may not be set.

The default is C<undef>.

=head2 illum

This string specifies the name of the class to be used for the
L<Astro::Coord::ECI::TLE|Astro::Coord::ECI::TLE> C<illum> attribute. If
you specify C<undef> you get the default.

The default is L<Astro::Coord::ECI::Sun|Astro::Coord::ECI::Sun>.

Note: I am less than happy about the implementation of this attribute.
Be alert for changes.  If I decide to revoke the above implementation
completely there will be notice, and if at all possible a deprecation
process.

=head2 latitude

This numeric attribute specifies the latitude of the observer in degrees
north of the Equator. If your observing location is south of the
Equator, specify a negative number.

See L</SPECIFYING ANGLES> for ways to specify an angle. This attribute
is returned in decimal degrees.

There is no default; you must specify a value.

=head2 local_coord

This string attribute is deprecated. It is provided for backward
compatibility with the F<satpass> script. The preferred way to
manipulate this is either directly on the formatter object, or via the
L<formatter()|/formatter> method.

This string attribute allows access to and manipulation of the formatter
object's L<local_coord|Astro::App::Satpass2::Format/local_coord> attribute.
This is normally used to specify the desired coordinates displayed by
the L</flare>, L</pass>, and L</position> methods. See the
L<Astro::App::Satpass2::Format local_coord|Astro::App::Satpass2::Format/local_coord>
documentation for the default. See the documentation of the actual
formatter class being used for what it does.

The formatter class should implement the following values:

'az_rng' - displays azimuth and range;

'azel' - displays elevation and azimuth;

'azel_rng' - displays elevation, azimuth, and range;

'equatorial' - displays right ascension and declination;

'equatorial_rng' - displays right ascension, declination, and range;

undef - displays the default ('azel_rng').

The default is undef.

=head2 location attribute

This string attribute contains a text description of the observer's
location.  This is not used internally, but if it is not empty it will
be displayed by the L</location> method.

There is no default; the attribute is undefined unless you supply a
value.

=head2 longitude

This numeric attribute specifies the longitude of the observer in
degrees east of Greenwich, England.  If your observing location is west
of Greenwich (as it would be if you live in North or South America),
specify a negative number.

See L</SPECIFYING ANGLES> for ways to specify an angle. This attribute
is returned in decimal degrees.

There is no default; you must specify a value.

=head2 max_mirror_angle

This numeric attribute specifies the maximum mirror angle for an Iridium
flare, in degrees. This is the angle subtended by the observer and the
reflection of the Sun as seen from the satellite. See the
L<Astro::Coord::ECI::TLE::Iridium|Astro::Coord::ECI::TLE::Iridium>
documentation for more detail. You should not normally need to modify
this value.

The default is the same as for
L<Astro::Coord::ECI::TLE::Iridium|Astro::Coord::ECI::TLE::Iridium>.
Again, see that documentation for more detail.

If L<Astro::Coord::ECI::TLE::Iridium|Astro::Coord::ECI::TLE::Iridium>
can not be loaded, the default is C<undef>.

=head2 model

This string attribute specifies the model to be used to predict the
satellite position. This is used to set the
L<Astro::Coord::ECI::TLE|Astro::Coord::ECI::TLE> model attribute, and
the valid values are the same as for that package. An attempt to set an
invalid model will result in an exception.

The default is 'model', which specifies whatever model is favored.

=head2 pass_threshold

This numeric attribute specifies the number of degrees of elevation
above the horizon a pass has to reach before it is reported. If visible
passes are desired, it must be visible above that elevation.  This
attribute corresponds to the same-named
L<Astro::Coord::ECI|Astro::Coord::ECI> attribute.

=head2 pass_variant

This attribute specifies the C<pass_variant> value to set when doing a
C<pass()> computation. It can be set to a number or a string consisting
of one or more of the following strings, which are equivalent to the
given C<Astro::Coord::ECI::TLE> manifest constants:

    visible_events   => PASS_VARIANT_VISIBLE_EVENTS
    fake_max         => PASS_VARIANT_FAKE_MAX
    start_end        => PASS_VARIANT_START_END
    no_illumination  => PASS_VARIANT_NO_ILLUMINATION
    brightest        => PASS_VARIANT_BRIGHTEST
    none             => PASS_VARIANT_NONE

If more than one value from the above table is specified, they can be
punctuated by any character that is not a word or a dash. They can also
be abbreviated uniquely, the underscores can be specified as dashes, and
they can be preceded by a dash, as though they were options.

When you specify a string value, the derived bits will be set in the
attribute value, or cleared if the name is preceded by C<'no'>. The
exception is C<'none'>, which clears all variant bits when it is
encountered.

For example,

 satpass2> # Note quotes in next line
 satpass2> set pass_variant 'none brightest fake-max'
 satpass2> show pass_variant
 set pass_variant brightest,fake_max
 satpass2> set pass_variant nofake
 satpass2> show pass_variant
 set pass_variant brightest
 satpass2> set pass_variant nobrightest
 satpass2> show pass_variant
 set pass_variant none

=head2 perltime

This boolean attribute is deprecated. It is provided for backward
compatibility with the F<satpass> script. The preferred way to
manipulate this is either directly on the formatter object, or via the
L<time_parser()|/time_parser> method.

This boolean attribute allows access to and manipulation of the time
parser object's L<perltime|Astro::App::Satpass2::ParseTime/perltime>
attribute.  This is normally used (if at all) to specify that the Perl
time built-ins be used to construct the parsed time. See the
L<perltime|Astro::App::Satpass2::ParseTime/perltime> documentation for
the default. See the documentation of the actual time parser class being
used for what it does.

This attribute was originally introduced because versions of
L<Date::Manip|Date::Manip> prior to 6.0 did not properly handle the
transition from standard time to summer time. Of those time parsers
distributed with this package, only
L<Astro::App::Satpass2::ParseTime::Date::Manip::v5|Astro::App::Satpass2::ParseTime::Date::Manip::v5>
uses this attribute.

The default will normally be 0 (i.e. false).

=head2 prompt

This string attribute specifies the string used to prompt for commands.

The default is C<< 'satpass2> ' >>.

=head2 simbad_url

This string attribute does not, strictly speaking, specify a URL, but
does specify the server to use to perform SIMBAD lookups (see the
'lookup' subcommand of the L</sky> method). Currently-legal values are
C<'simbad.u-strasbg.fr'> (the original site) and C<'simbad.harvard.edu'>
(Harvard University's mirror).

The default is C<'simbad.u-strasbg.fr'>.

=head2 singleton

If this boolean attribute is true, the script uses
L<Astro::Coord::ECI::TLE::Set|Astro::Coord::ECI::TLE::Set> objects to
represent all bodies. If false, the set object is used only if the
observing list contains more than one instance of a given NORAD ID. This
is really only useful for testing purposes.

Use of the L<Astro::Coord::ECI::TLE::Set|Astro::Coord::ECI::TLE::Set>
object causes calculations to take about 15% longer.

The default is 0 (i.e. false).

=head2 spacetrack attribute

This attribute is the L<Astro::SpaceTrack|Astro::SpaceTrack> object used
by the L<spacetrack()|/spacetrack> method. You must set it to an
L<Astro::SpaceTrack|Astro::SpaceTrack> object, or to undef to clear the
attribute. If no L<Astro::SpaceTrack|Astro::SpaceTrack> object has been
explicitly set, the L<spacetrack()|/spacetrack> method will attempt to
load L<Astro::SpaceTrack|Astro::SpaceTrack> and set this attribute
itself. If it succeeds, this object will be available to the L</get>
method.

This attribute may only be manipulated programmatically; it may not be
gotten or set via the L</dispatch> method, and therefore not by the
F<satpass2> script.

The default is undef.

=head2 stdout

This attribute determines what the L</execute> method does with its
output. The possible values are interpreted as follows:

C<undef> - the output is returned;

scalar reference - the output is appended to the scalar;

code reference - the code is called, with the output as its argument;

array reference - the output is split after newlines, and the result
pushed onto the array;

anything else - the print() method is called on the attribute value,
with the output as its argument.

This attribute may only be manipulated programmatically; it may not be
gotten or set via the L</dispatch> method, and therefore not by the
F<satpass2> script.

The default is the C<STDOUT> file handle.

=head2 time_format

This string attribute is deprecated. It is provided for backward
compatibility with the F<satpass> script. The preferred way to
manipulate this is either directly on the formatter object, or via the
L<formatter()|/formatter> method.

This attribute allows access to and manipulation of the formatter
object's L<time_format|Astro::App::Satpass2::Format/time_format>
attribute.  This is normally used as a C<strftime(3)> format to format a
time. See the L<time_format|Astro::App::Satpass2::Format/time_format>
documentation for the default. See the documentation of the actual
formatter class being used for what it does.

The formatter class, if it makes use of this attribute at all, should
interpret the value of this attribute as a C<strftime(3)> format.

This string attribute specifies the strftime(3) format used to display
times.  Documentation of the C<strftime(3)> subroutine may be found at
L<http://www.openbsd.org/cgi-bin/man.cgi?query=strftime&apropos=0&sektion=0&manpath=OpenBSD+Current&arch=i386&format=html>,
among  other places.

The above is a long URL, and may be split across multiple lines. More
than that, the formatter may have inserted a hyphen at the break, which
needs to be taken out to make the URL good. I<Caveat user.>

=head2 time_parser attribute

This attribute specifies the class to be used to parse times.  You can
set it to either the actual parser object, or to the name of the class
to use. In the latter case, an object of the appropriate class will be
instantiated, so C<get( 'time_parser' )> always returns an object.  A
call to C<show( 'time_parser' )>, however, will always show the class
name.

When setting this attribute to a class name, the leading
C<'Astro::App::Satpass2::ParseTime::'> can be omitted.

The time parser must be a subclass of
L<Astro::App::Satpass2::ParseTime|Astro::App::Satpass2::ParseTime>.

The default is C<'Astro::App::Satpass2::ParseTime'>, which actually returns one
of its subclasses, preferring the one that uses
L<Date::Manip|Date::Manip>. If L<Date::Manip|Date::Manip> is not
installed, you get
L<Astro::App::Satpass2::ParseTime::ISO8601|Astro::App::Satpass2::ParseTime::ISO8601>,
which is a home-grown parser for ISO-8601-ish times, and maybe better
than nothing.

=head2 twilight

This attribute specifies the elevation of the Sun at which day becomes
night or vice versa, in degrees. B<This will normally be a negative
number>, since a positive number says the Sun is above the horizon.

The words C<'civil'>, C<'nautical'>, or C<'astronomical'> are also
acceptable, as is any unique abbreviation of these words. They specify
-6, -12, and -18 degrees respectively.

See L</SPECIFYING ANGLES> for ways to specify an angle. This parameter
is displayed in decimal degrees, unless C<'civil'>, C<'nautical'>, or
C<'astronomical'> was specified.

The default is C<'civil'>.

=head2 tz

This string attribute is deprecated. It is provided for backward
compatibility with the F<satpass> script. The preferred way to
manipulate this is either directly on the time parser and formatter
objects, or via the L<formatter()|/formatter> and
L<time_parser()|/time_parser> methods on the relevant objects.

This string attribute specifies both the default time zone for date
parsing and the time zone for formatting of local times. This
overloading exists for historical reasons, but will change in the
future.  At any event it takes effect to the extent the date parser and
formatter objects support it.

If you are running under Mac OS 9 or less, or under VMS, you may have to
set this. Otherwise, you normally should not bother unless you are
deliberately doing input or producing output for a time zone other than
either your own, or GMT.

=head2 verbose

This boolean attribute specifies whether the L</pass> method should give
the position of the satellite every step that it is above the horizon.
If false, only rise, set, max, into or out of shadow, and the beginning
or end of twilight are displayed.

The default is 0 (i.e. false).

=head2 visible

This boolean attribute specifies whether the L</pass> method should
report only visible passes (if true) or all passes (if false). A pass is
considered to have occurred if the satellite, at some point in its path,
had an elevation above the horizon greater than the L<horizon|/horizon>
attribute.  A pass is considered visible if it is after the end of
evening twilight or before the beginning of morning twilight for the
observer (i.e. "it's dark"), but the satellite is illuminated by the
Sun.

The default is 1 (i.e. true).

=head2 warning

This boolean attribute specifies whether warnings and errors are
reported via C<carp> and C<croak>, or via C<warn> and C<die>. If true,
you get C<warn> and C<die>, if false C<carp> and C<croak>. This is set
true in the object instantiated by the L<run()|/run> method.

The default is 0 (i.e. false).

=head2 warn_on_empty

This boolean attribute specifies whether the L<list()|/list> interactive
method warns on an empty list. If false, you just get nothing back from
it.

The default is 1 (i.e. true).

=head2 webcmd

This string attribute specifies the system command to spawn to display a
web page. If not the empty string, the L<help|/help> method uses it to
display L<https://metacpan.org/release/Astro-App-Satpass2>. Mac OS
X users will find C<'open'> a useful setting, and Windows users will
find C<'start'> useful.

This functionality was added on speculation, since there is no good way
to test it in the initial release of the package.

As of version 0.035_01, a value of C<'1'> causes
L<Browser::Open|Browser::Open> to be loaded, and the web command is
taken from it. All other true values are deprecated, on the following
schedule:

=over

=item 2018-11-01: First use of deprecated value will warn;

=item 2019-05-01: All uses of deprecated value will warn;

=item 2019-11-01: Any use of deprecated value is fatal;

=item 2020-05-01: Attribute is treated as Boolean.

=back

The above schedule may be extended based on what other changes are
needed, but will not be compressed.

The default is C<''> (i.e. the empty string), which leaves the
functionality disabled.

=head1 SPECIFYING ANGLES

This class accepts angle input in the following formats:

* Decimal degrees.

* Hours, minutes, and seconds, specified as C<hours:minutes:seconds>.
You would typically only use this for right ascension. You may specify
fractional seconds, or fractional minutes for that matter.

* Degrees, minutes, and seconds, specified as
C<degreesDminutesMsecondsS>.  The letters may be specified in either
case, and trailing letters may be omitted. You may specify fractional
seconds, or fractional minutes for that matter.

Examples:

 23.4 specifies 23.4 degrees.
 1:22.3 specifies an hour and 22.3 minutes
 12d33m5 specifies 12 degrees 33 minutes 5 seconds

Right ascension is always positive. Declination and latitude are
positive for north, negative for south. Longitude is positive for east,
negative for west.

=head1 SPECIFYING DISTANCES

This class accepts distances in a number of units, which are specified
by appending them to the magnitude of the distance. The default unit is
usually C<km> (kilometers), but for the L</height attribute> it is C<m>
(meters). The following units are recognized:

 au - astronomical units;
 ft - feet;
 km - kilometers;
 ly - light years;
 m -- meters;
 mi - statute miles;
 pc - parsecs.

=head1 SPECIFYING TIMES

This class (or, more properly, the modules it is based on) does not, at
this point, do anything fancy with times. It simply handles them as Perl
scalars, with the limitations that that implies.

Times may be specified absolutely, or relative to the previous absolute
time, or to the time the object was instantiated if no absolute time has
been specified.

=head2 Absolute time

Any time string not beginning with '+' or '-' is assumed to be an
absolute time, and is fed to one of the
L<Astro::App::Satpass2::ParseTime|Astro::App::Satpass2::ParseTime>
modules for parsing. What is legal here depends on which parser is in
use. If you have L<Date::Manip|Date::Manip>, you will get a parser based
on that module, with all the functionality that implies. If
L<Date::Manip|Date::Manip> is not installed, you get
L<Astro::App::Satpass2::ParseTime::ISO8601|Astro::App::Satpass2::ParseTime::ISO8601>,
which parses a subset of the ISO 8601 times, as a fall-back.

L<Date::Manip|Date::Manip> has at least some support for locales, so
check the L<Date::Manip|Date::Manip> documentation before you assume you
must enter dates in English. The ISO 8601 format is all-numeric.

=head2 Epoch time

Epoch time can be specified directly, bypassing the time parser. There
are two ways to do this:

* Prefix the string C<'epoch '> to the epoch time;

* Pass a reference to the epoch time.

=head2 Relative time

A relative time is specified by '+' or '-' and an integer number of
days. The number of days must immediately follow the sign. Optionally, a
number of hours, minutes, and seconds may be specified by placing
whitespace after the day number, followed by hours:minutes:seconds. If
you choose not to specify seconds, omit the trailing colon as well. The
same applies if you choose not to specify minutes. For example:

+7 specifies 7 days after the last-specified time.

'+7 12' specifies 7 days and 12 hours after the last-specified time.

If a relative time is specified as the first time argument to a method,
it is relative to the most-recently-specified absolute or epoch time,
even if that time was specified by default. Relative times in subsequent
arguments to the same method are relative to the previously-specified
time, whether absolute, epoch or relative. For example:

 $satpass2->almanac( '', '+5' );

establishes the most-recently-specified time as 'today midnight', and
does an almanac for 5 days from that time. If the next method call is

 $satpass2->almanac( '+5', '+3' );

this produces almanac output for three days, starting 5 days after
'today midnight'.

=head1 SPECIFYING INPUT DATA

Some of the methods of this class (currently L<init()|/init>,
L<load()|/load> and L<source()|/source>) read data and do something with
it. These data can be specified in a number of ways:

=over

=item * As a file name;

=item * As a URL if L<LWP::UserAgent|LWP::UserAgent> is installed;

=item * As a scalar reference;

=item * As an array reference;

=item * As a code reference.

The code reference is expected to return a line each time it is called,
and C<undef> when the data are exhausted.

Obviously, the specifications that involve references are not available
to a user of the F<satpass2> script.

=back

=head1 TOKENIZING

When this class is used via the L<run()|/run> or L<execute()|/execute>
methods, method names and arguments are derived by tokenizing lines of
text. No attempt has been made to provide full shell-style tokenization
with all the bells and whistles, but such features as do exist are based
on C<bash(1)>. The tokenization rules are:

The line is broken into tokens on spaces, unless the spaces are quoted
or escaped as described below.

A back slash (C<\>) escapes the next character, turning a meta-character
into a normal one. Lines can be continued by placing the back slash at
the end of the line.

Single quotes (C<''>) cause everything inside them to be taken as a
single token, and almost anything inside them to be taken as a literal.
Unlike C<bash(1)>, but like C<perl(1)>, the back slash is recognized,
but its only use is to escape a single quote or another back slash.

Double quotes (C<"">) cause everything inside them to be taken as a
single token. Unlike single quotes, all meta-characters except single
quotes are recognized inside double quotes.

The dollar sign (C<$>) introduces an interpolation. If the first
character after the dollar sign is not a left curly bracket, that
character and any following word characters name the thing to be
interpolated, which may be one of the following things.

=over

=item One of the following special variables.

 0 - The name of the Perl script ($0);
 # - The number of positional arguments;
 * - All arguments, but joined by white space inside double
     quotes;
 @ - All arguments as individual tokens, even inside double
     quotes;
 $ - The process ID;
 _ - The name of the Perl executable ($^X).

=item An argument, specified by its number, starting from 1.

=item An L<attribute|/ATTRIBUTES> name.

If the attribute is C<'formatter'>, C<'spacetrack'>, or C<'time_parser'>
the attribute name can be followed by a dot (C<'.'>) and the name of an
attribute of the resultant object.

=item An environment variable.

=back

If the interpolation can be more than one of the things on the above
list, the first thing actually encountered will be used. For example,
C<$horizon> will interpolate the value of the C<horizon|/horizon>
attribute, even in the presence of an environment variable named
C<'horizon'>.

The interpolated value will be split on white space into multiple tokens
unless the interpolation takes place inside double quotes.

The name of the thing to be interpolated can be enclosed in curly
brackets if needed to delimit it from following text. This also allows
the substitution of text for the argument, as follows:

C<${parameter:-text}> causes the given text to be substituted if the
parameter is undefined.

C<${parameter:=text}> is the same as above, but also causes the text to
be assigned to the parameter if it is unassigned. Like C<bash(1)>, this
assignment can not take place on numbered parameters or special
variables. If done on an attribute or environment variable, it causes
that attribute or environment variable to be set to the given value.

C<${parameter:?text}> causes the parse to fail with the error 'text' if
the parameter is undefined.

C<${parameter:+text}> causes the value of the given text to be used if
the parameter is defined, otherwise '' is used.

C<${parameter:offset}> and C<${parameter:offset:length}> take substrings
of the parameter value. The offset and length must be numeric.

Note that token expansion takes place inside curly brackets.

An exclamation mark (C<!>) in front of the name of an interpolated
parameter introduces a level of indirection, B<provided> it occurs
inside curly brackets. That is, if environment variable C<FOO> is
defined as C<'BAR'>, and environment variable C<BAR> is defined as
C<'BAZ'>, then C<${!FOO}> interpolates C<'BAZ'>.  Only one level of
indirection is supported.

One of the angle bracket characters (C<< < >> or C<< > >>) or the
vertical bar character (C<|>) introduce a redirection specification
(and, incidentally, a new token). Anything after the meta-characters in
the same token is taken to be the file or program name.

The only redirections that actually work are C<< > >> (output
redirection) and C<<< >> >>> (output redirection with append).  The
C<< < >> and C<<< << >>> look like input redirections but are not, at
least not in the sense of making data appear on standard in. The first
is replaced by the contents of the given file or URL. The second works
like a Perl here document, and interpolates unless the here document
terminator is enclosed in single quotes.

B<Caveat:> redirection tests fail under MSWin32 -- or at least they did
until I bypassed them under that operating system. I do not know if this
is a failure of the redirection mechanism or a problem with the test. I
suspect the latter, but will welcome evidence of the former.

Any unquoted token or redirection file name which begins with a tilde
(C<~>) has tilde expansion performed on everything up to the first slash
(C</>), or the end of the token, B<provided> the operating system
supports this.  The empty username is expanded using C<getpwuid()> if
this is supported, or various possibly-OS-specific environment variables
if not. Non-empty user names are expanded if C<getpwnam()> is supported
B<and> the user actually exists; otherwise an exception is raised. Tilde
expansion is not done inside quotes (either single or double), even if
the tilde is the first character. This is consistent with C<bash(1)>.

As special cases of tilde expansion, C<~.> expands to the current
directory, and C<~~> expands to the configuration directory. The
expansion of C<~~> will throw an exception if the configuration
directory does not exist.

Wild card expansion is never performed by the tokenizer. If an
individual method does wild card expansion on its arguments, this will
be noted in its documentation.

=head1 DIFFERENCES FROM SATPASS

The functionality provided by this package is similar, but not
identical, to the functionality provided by the F<satpass> script
included in package F<Astro-satpass>. Compatibility has been retained
unless there appeared to be a pressing reason to make a change, but this
rewrite has also provided an opportunity to rethink some things that
appeared to need rethinking.

The following differences from F<satpass> are known to exist:

=head2 Tokenization

In the C<satpass> script, all quotes interpolated, but in this package
only C<"> interpolates.

Assigning a new value to an undefined positional parameter is no longer
allowed. The F<satpass> script allowed C<${1:=Foo}>, but this package
does not. The idea was to be consistent with C<bash(1)>.

Here documents are now supported.

=head2 Added commands/methods

Some methods have been added which do not appear as commands in
F<satpass>. Those methods, and the reason for their addition, are:

=over

=item add

Added in version 0.021.

=item begin, end

The restructuring involved in the rewrite made it possible to have
explicit localization blocks, which I kind of wanted all along.

=item location

It was decided to have an explicit method to display the location,
rather than have certain methods (e.g. C<pass()>) display it, and others
(e.g. C<flare()>) not. In other words, I decided I was not smart enough
to know when a user would want the location displayed.

=item if

Added in version 0.032.

=item pwd

This seems to go with C<cd()>.

=item time

The F<satpass> script had a C<-time> option whenever I wanted to time
something. The architecture of this package made it simpler to just have
a separate interactive method.

=back

=head2 Deprecated commands

Some commands are deprecated, but will remain for backward compatibility
until support for C<satpass> is dropped. After this happens, they will
be put through a deprecation cycle and disappear.

=over

=item st

This command/method is deprecated in favor of the
L<spacetrack()|/spacetrack> command/method.  It will remain until
support for the F<satpass> script is dropped, and then be put through a
deprecation cycle and removed.

People using the 'st' command interactively can define 'st' as a macro:

 satpass2> macro define st 'spacetrack "$@"'

Note that the elimination of this command/method leaves you no way to
localize individual attributes of the L<spacetrack|/spacetrack>
attribute. You can still localize the whole object, though. Please
contact me if you need the removed functionality.

=back

=head2 Dropped commands

Some commands that appear in the F<satpass> script have been dropped,
for various reasons. The commands, and the reasons for eliminating them,
are given below.

=over

=item check_version

This command was originally added because I wanted to split the
F<satpass> script off from L<Astro::Coord::ECI|Astro::Coord::ECI>, but
CPAN does not detect changes in scripts.

It was dropped because the F<satpass2> script is trivial. Added
functionality will (almost always) go in C<Astro::App::Satpass2>, and
changes there will be detected by the C<cpan>, C<cpanp>, or C<cpanm>
scripts.

=item store, retrieve

These were added on a whim, and I have never even come close to using
them. If you have a need for them please contact me.

=item times

This was added because I was working on a way to extend the time range
and wanted a way to check the code. This work was stalled, and the
L<Time::y2038|Time::y2038> module and Perl 5.12 both appear to make it
obsolete anyway.

=back

=head2 Modified commands/methods

Some commands that appear in the F<satpass> script have been modified.
The commands, and the reasons for their modification, appear below.

=over

=item almanac

The location of the observing station is no longer emitted as part of
the output; an explicit C<location()> is needed. I decided that I was
not really smart enough to know when the user would want this output.

Until support for the F<satpass> script is dropped, though, output from
this command will still include the location if the command is issued
from a F<satpass> initialization file (as opposed to an
C<Astro::App::Satpass2> initialization file), or from a macro defined in
a F<satpass> initialization file.

=item flare

The sense of the C<-am>, C<-day>, and C<-pm> options is reversed from
the sense in F<satpass>. That is, in F<satpass>, C<-am> meant not to
display morning flares, whereas in C<Astro::App::Satpass2>, C<-am> means
not to display morning flares, and C<-noam> means to display them. I
personally found the F<satpass> functionality confusing.

In order to ease the transition to C<Astro::App::Satpass2>, these
options will be taken in their F<satpass> sense (and inverted to their
new sense before use) if the C<flare> command is used in a F<satpass>
initialization file, or in a macro defined in a F<satpass>
initialization file. There is no supported way to get the F<satpass>
behavior when using the C<flare> command in any other environment, or
when calling the C<flare()> method. This functionality will be revoked
when support for F<satpass> is dropped.

=item geocode

Geocoding is handled by external modules, typically those that B<do not>
require the registration of an application key. A wrapper class has been
provided for L<Geo::Coder::OSM|Geo::Coder::OSM>. The names of the
wrapper classes are (so far) derived from the names of the wrapped
classes by C<s/\AGeo::Coder::/Astro::App::Satpass2::Geocode::/>, and the
constant prefix on the wrapper name may be omitted when setting the
geocoder.

=item pass

The location of the observing station is no longer emitted as part of
the output; an explicit C<location()> is needed. I decided that I was
not really smart enough to know when the user would want this output.

Until support for the F<satpass> script is dropped, though, output from
this command will still include the location if the command is issued
from a F<satpass> initialization file (as opposed to an C<Astro::App::Satpass2>
initialization file), or from a macro defined in a F<satpass>
initialization file.

=item position

The method generates position information for a single time. The
F<satpass> time range and C<-realtime> functions have been
revoked. This function was added when I had vague dreams of figuring out
how to drive a telescope off the output, but so far those dreams are
unrealized, and I can think of no other use for the functionality. The
rewritten output mechanism is not capable of actually displaying output
in realtime, and handling multiple times in a system that separates
formatting from computation appeared to be too difficult to tackle
without an incentive.

=back

=head2 Dropped attributes

=over

=item simbad_version

This attribute was used to select the version of the SIMBAD protocol to
use to access L<http://simbad.u-strasbg.fr/>. Since only version 4 is
currently supported, and this has been the default in F<satpass> for
some time, this attribute is eliminated.

=back

=head2 Modified attributes

=over

=item backdate

This attribute defaults to false (i.e. 0). In the F<satpass> script, it
defaulted to true.

=item country

This attribute existed to support selection of geocoding servers, but
since geocoding is now done with plug-in modules, this attribute is
ignored.  This attribute will be dropped when support for F<satpass> is
dropped.

=item date_format

This attribute is deprecated. It is properly an attribute of
L<Astro::App::Satpass2::Format|Astro::App::Satpass2::Format>, and is
implemented as a wrapper for that class' C<date_format> attribute. It
will be dropped when support for F<satpass> is dropped.

=item desired_equinox_dynamical

This attribute is deprecated. It is properly an attribute of
L<Astro::App::Satpass2::Format|Astro::App::Satpass2::Format>, and is
implemented as a wrapper for that class' C<desired_equinox_dynamical>
attribute. It will be dropped when support for F<satpass> is dropped.

=item explicit_macro_delete

This attribute is ignored and deprecated, since the C<Astro::App::Satpass2>
macro() functionality always requires an explicit C<delete> to delete a
macro. This attribute will be dropped when support for F<satpass> is

=item gmt

This attribute is deprecated. It is properly an attribute of
L<Astro::App::Satpass2::Format|Astro::App::Satpass2::Format>, and is
implemented as a wrapper for that class' C<gmt> attribute. It will be
dropped when support for F<satpass> is dropped.

=item local_coord

This attribute is deprecated. It is properly an attribute of
L<Astro::App::Satpass2::Format|Astro::App::Satpass2::Format>, and is
implemented as a wrapper for that class' C<local_coord> attribute. It
will be dropped when support for F<satpass> is dropped.

=item time_format

This attribute is deprecated. It is properly an attribute of
L<Astro::App::Satpass2::Format|Astro::App::Satpass2::Format>, and is
implemented as a wrapper for that class' C<time_format> attribute. It
will be dropped when support for F<satpass> is dropped.

=item twilight

The F<satpass> mutator forced the sign to be negative. The
C<Astro::App::Satpass2> mutator does not. Note that a positive setting
means the Sun is above the horizon.

=item tz

This attribute is deprecated. It is properly an attribute of
C<Astro::App::Satpass2::Format|Astro::App::Satpass2::Format> and
C<Astro::App::Satpass2::ParseTime|Astro::App::Satpass2::ParseTime>.
These should not have been combined because there is no way to ensure
that the packages underlying each of these takes the same time zone
specifications.

=back

=head1 ENVIRONMENT VARIABLES

C<SATPASS2INI> can be used to specify an initialization file to use in
lieu of the default. This can still be overridden by the
C<-initialization_file> command option.

C<SATPASSINI> will be used in a last-ditch effort to find an
initialization file, if C<-initialization_file> is not specified,
C<SATPASS2INI> does not exist, and the initialization file was not found
in its default location.

=head1 BUGS

Bugs can be reported to the author by mail, or through
L<http://rt.cpan.org/>.

=head1 AUTHOR

Thomas R. Wyant, III (F<wyant at cpan dot org>)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2019 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

TIGER/LineE<reg> is a registered trademark of the U.S. Census Bureau.

=cut

# ex: set textwidth=72 :
