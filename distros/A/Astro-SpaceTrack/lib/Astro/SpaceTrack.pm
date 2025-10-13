=head1 NAME

Astro::SpaceTrack - Retrieve orbital data from www.space-track.org.

=head1 SYNOPSIS

 my $st = Astro::SpaceTrack->new (username => $me,
     password => $secret, with_name => 1) or die;
 my $rslt = $st->spacetrack ('special');
 print $rslt->is_success ? $rslt->content :
     $rslt->status_line;

or

 $ SpaceTrack
 
 (some banner text gets printed here)
 
 SpaceTrack> set username me password secret
 OK
 SpaceTrack> set with_name 1
 OK
 SpaceTrack> spacetrack special >special.txt
 SpaceTrack> celestrak visual >visual.txt
 SpaceTrack> exit

In either of the above, username and password entry can be omitted if
you have installed L<Config::Identity|Config::Identity>, created an
L<IDENTITY FILE|/IDENTITY FILE> (see below) containing these values, and
set the C<identity> attribute to a true value.  You probably
want to encrypt the identity file, if you have C<gpg2> and C<gpg-agent>.

In practice, it is probably not useful to retrieve data from any source
more often than once every four hours, and in fact daily usually
suffices.

=head1 LEGAL NOTICE

The following two paragraphs are quoted from the Space Track web site.

Due to existing National Security Restrictions pertaining to access of
and use of U.S. Government-provided information and data, all users
accessing this web site must be an approved registered user to access
data on this site.

By logging in to the site, you accept and agree to the terms of the
User Agreement specified in
L<https://www.space-track.org/documentation#/user_agree>.

You should consult the above link for the full text of the user
agreement before using this software to retrieve content from the Space
Track web site.

=head1 FUNCTIONAL NOTICES

=head2 CELESTRAK API

The Celestrak web site, L<https://celestrak.org/>, is in transition from
being simply a file based repository of TLEs to an API-based service
providing orbital elements in a number of formats. The C<celestrak()>
and C<celestrak_supplemental()> methods will track this, growing new
arguments as needed.

=head2 DEPRECATION NOTICE: IRIDIUM STATUS

As of version 0.137, Iridium status format C<'mccants'> is fully
deprecated, and will result in an exception.

As of version 0.143, any access of attribute
C<url_iridium_status_mccants> is fatal.

As of version 0.169, any use of attribute C<url_iridium_status_kelso> is
fatal. See below for why my normal deprecation procedure was violated.

As of version 0.164 support for Iridium Classic satellites is being
deprecated and removed. All testing of the iridium_status() method is
halted as of version 0.164. As of version 0.167, the first use of the
iridium_status() method will produce a warning. After a further six
months all uses will warn, and after a further six months use of this
method will be fatal. Related attributes and manifest constants will be
deprecated on the same schedule.

Contrary to my normal deprecation procedure (such as it is), the
Celestrak Iridium catalog is fully deprecated as of version 0.169, and
will result in a fatal exception. This jump from non-deprecated to fully
deprecated was triggered by the removal of the Iridium catalog (as
opposed to Iridium NEXT) from the Celestrak web site May 8 2025.

As of version 0.169, B<any> functionality relating to Iridium status
will warn on the first use. This includes the C<BODY_STATUS_*> manifest
constants, which as of 0.169 are no longer manifest constants but simple
subroutines so that they B<can> warn on the first use.

=head1 DESCRIPTION

This package retrieves orbital data from the Space Track web site
L<https://www.space-track.org> and several others. You must register and
get a user name and password before you can get data from Space Track.

Other methods (C<celestrak()>, C<amsat()>, ...) have
been added to access other repositories of orbital data, and in general
these do not require a Space Track username and password.

Nothing is exported by default, but the shell method/subroutine
and the BODY_STATUS constants (see C<iridium_status()>)
can be exported if you so desire.

Most methods return an HTTP::Response object. See the individual
method document for details. Methods which return orbital data on
success add a 'Pragma: spacetrack-type = orbit' header to the
HTTP::Response object if the request succeeds, and a 'Pragma:
spacetrack-source =' header to specify what source the data came from.

=head2 Methods

The following methods should be considered public:

=over 4

=cut

package Astro::SpaceTrack;

use 5.006002;

use strict;
use warnings;

use Exporter;

our @ISA = qw{ Exporter };

our $VERSION = '0.171';
our @EXPORT_OK = qw{
    shell

    BODY_STATUS_IS_OPERATIONAL
    BODY_STATUS_IS_SPARE
    BODY_STATUS_IS_TUMBLING
    BODY_STATUS_IS_DECAYED

    ARRAY_REF
    CODE_REF
    HASH_REF

    };
our %EXPORT_TAGS = (
    ref		=> [ grep { m/ _REF \z /smx } @EXPORT_OK ],
    status	=> [ grep { m/ \A BODY_STATUS_IS_ /smx } @EXPORT_OK ],
);

use Carp ();
use Getopt::Long 2.39;
use HTTP::Date ();
use HTTP::Request;
use HTTP::Response;
use HTTP::Status qw{
    HTTP_PAYMENT_REQUIRED
    HTTP_BAD_REQUEST
    HTTP_NOT_FOUND
    HTTP_I_AM_A_TEAPOT
    HTTP_INTERNAL_SERVER_ERROR
    HTTP_NOT_ACCEPTABLE
    HTTP_NOT_MODIFIED
    HTTP_OK
    HTTP_PRECONDITION_FAILED
    HTTP_UNAUTHORIZED
    HTTP_INTERNAL_SERVER_ERROR
};
use IO::File;
use IO::Uncompress::Unzip ();
use JSON qw{};
use List::Util ();
use LWP::UserAgent;	# Not in the base.
use POSIX ();
use Scalar::Util 1.07 ();
use Text::ParseWords ();
use Time::Local ();
use URI qw{};
# use URI::Escape qw{};

# Number of OIDs to retrieve at once. This is a global variable so I can
# play with it, but it is neither documented nor supported, and I
# reserve the right to change it or delete it without notice.
our $RETRIEVAL_SIZE = $ENV{SPACETRACK_RETRIEVAL_SIZE};
defined $RETRIEVAL_SIZE or $RETRIEVAL_SIZE = 200;

use constant COPACETIC => 'OK';
use constant BAD_SPACETRACK_RESPONSE =>
	'Unable to parse SpaceTrack response';
use constant INVALID_CATALOG =>
	'Catalog name %s invalid. Legal names are %s.';
use constant LAPSED_FUNDING => 'Funding lapsed.';
use constant LOGIN_FAILED => 'Login failed';
use constant NO_CREDENTIALS => 'Username or password not specified.';
use constant NO_CAT_ID => 'No catalog IDs specified.';
use constant NO_OBJ_NAME => 'No object name specified.';
use constant NO_RECORDS => 'No records found.';

use constant SESSION_PATH => '/';

use constant DEFAULT_SPACE_TRACK_REST_SEARCH_CLASS => 'satcat';
use constant DEFAULT_SPACE_TRACK_VERSION => 2;

# dump_headers constants.
use constant DUMP_NONE => 0;		# No dump
use constant DUMP_TRACE => 0x01;	# Logic trace
use constant DUMP_REQUEST => 0x02;	# Request content
use constant DUMP_DRY_RUN => 0x04;	# Do not execute request
use constant DUMP_COOKIE => 0x08;	# Dump cookies.
use constant DUMP_RESPONSE => 0x10;	# Dump response.
use constant DUMP_TRUNCATED => 0x20;	# Dump with truncated content

my @dump_options;
foreach my $key ( sort keys %Astro::SpaceTrack:: ) {
    $key =~ s/ \A DUMP_ //smx
	or next;
    push @dump_options, lc $key;
}

# Manifest constants for reference types
use constant ARRAY_REF	=> ref [];
use constant CODE_REF	=> ref sub {};
use constant HASH_REF	=> ref {};

# These are the Space Track version 1 retrieve Getopt::Long option
# specifications, and the descriptions of each option. These need to
# survive the retirement of Version 1 as a separate entity because I
# emulated them in the celestrak() method. I'm _NOT_
# emulating the options added in version 2 because they require parsing
# the TLE.
use constant CLASSIC_RETRIEVE_OPTIONS => [
    descending => '(direction of sort)',
    'end_epoch=s' => 'date',
    last5 => '(ignored if -start_epoch or -end_epoch specified)',
    'sort=s' =>
	"type ('catnum' or 'epoch', with 'catnum' the default)",
    'start_epoch=s' => 'date',
];

use constant CELESTRAK_API_OPTIONS	=> [
    'query=s',	'query type',
    'format=s',	'data format',
];

use constant CELESTRAK_OPTIONS	=> [
    # @{ CLASSIC_RETRIEVE_OPTIONS() },	# TODO deprecate and remove
    @{ CELESTRAK_API_OPTIONS() },
];

use constant CELESTRAK_SUPPLEMENTAL_VALID_QUERY => {
    map { $_ => 1 } qw{ CATNR INTDES SOURCE NAME SPECIAL FILE } };

use constant CELESTRAK_VALID_QUERY => {
    map { $_ => 1 } qw{ CATNR INTDES GROUP NAME SPECIAL } };

our $COMPLETION_APP;	# A hack.

my %catalogs = (	# Catalog names (and other info) for each source.
    celestrak => {
	'last-30-days' => {name => "Last 30 Days' Launches"},
	stations => {name => 'International Space Station'},
	visual => {name => '100 (or so) brightest'},
	active => { name => 'Active Satellites' },
	analyst => { name => 'Analyst Satellites' },
	weather => {name => 'Weather'},
	noaa => {name => 'NOAA'},
	goes => {name => 'GOES'},
	resource => {name => 'Earth Resources'},
	sarsat => {name => 'Search and Rescue (SARSAT)'},
	dmc => {name => 'Disaster Monitoring'},
	tdrss => {name => 'Tracking and Data Relay Satellite System (TDRSS)'},
	geo => {name => 'Geostationary'},
	intelsat => {name => 'Intelsat'},
	# Removed May 8 2025
	# gorizont => {name => 'Gorizont'},
	# Removed May 8 2025
	# raduga => {name => 'Raduga'},
	# Removed May 8 2025
	# molniya => {name => 'Molniya'},
	# Removed May 8 2025
	# iridium => {name => 'Iridium'},
	'iridium-NEXT' => { name => 'Iridium NEXT' },
	ses	=> { name => 'SES communication satellites' },
	orbcomm => {name => 'Orbcomm'},
	globalstar => {name => 'Globalstar'},
	amateur => {name => 'Amateur Radio'},
	'x-comm' => {name => 'Experimental Communications'},
	'other-comm' => {name => 'Other communications'},
	'gps-ops' => {name => 'GPS Operational'},
	'glo-ops' => {name => 'Glonass Operational'},
	galileo => {name => 'Galileo'},
	sbas => {name =>
	    'Satellite-Based Augmentation System (WAAS/EGNOS/MSAS)'},
	nnss => {name => 'Navy Navigation Satellite System (NNSS)'},
	musson => {name => 'Russian LEO Navigation'},
	science => {name => 'Space and Earth Science'},
	geodetic => {name => 'Geodetic'},
	engineering => {name => 'Engineering'},
	education => {name => 'Education'},
	military => {name => 'Miscellaneous Military'},
	radar => {name => 'Radar Calibration'},
	cubesat => {name => 'CubeSats'},
	other => {name => 'Other'},
	beidou => { name => 'Beidou navigational satellites' },
	argos	=> { name => 'ARGOS Data Collection System' },
	planet	=> { name => 'Planet Labs (Rapideye, Flock)' },
	spire	=> { name => 'Spire Global (Lemur weather and ship tracking)' },
	satnogs	=> { name => 'SatNOGS' },
	starlink	=> { name => 'Starlink' },
	oneweb		=> { name => 'OneWeb' },
	# Removed May 8 2025
	# swarm		=> { name => 'Swarm' },
	gnss		=> { name => 'GNSS navigational satellites' },
	'1982-092'	=> {
	    name	=> 'Russian ASAT Test Debris (COSMOS 1408)',
	    note	=> q/'cosmos-1408-debris' as of April 26 2024/,
	    ignore	=> 1,	# Ignore in xt/author/celestrak_datasets.t
	},
	'cosmos-1408-debris'	=> {
	    name =>	'Russian ASAT Test Debris (COSMOS 1408)',
	},
	'1999-025'	=> {
	    name	=> 'Fengyun 1C debris',
	    note	=> q/'fengyun-1c-debris' as of April 26 2024/,
	    ignore	=> 1,	# Ignore in xt/author/celestrak_datasets.t
	},
	'fengyun-1c-debris'	=> {
	    name	=> 'Fengyun 1C debris',
	},
	'cosmos-2251-debris' => { name => 'Cosmos 2251 debris' },
	'iridium-33-debris' => { name => 'Iridium 33 debris' },
	'2012-044'	=> {
	    name	=> 'BREEZE-M R/B Breakup (2012-044C)',
	    note => 'Fetchable as of November 16 2021, but not on web page',
	    ignore	=> 1,	# Ignore in xt/author/celestrak_datasets.t
	},
	# Removed 2022-05-12
	# '2019-006'	=> { name => 'Indian ASAT Test Debris' },
	eutelsat	=> { name => 'Eutelsat' },
	kuiper		=> { name => 'Kuiper' },
	telesat		=> { name => 'Telesat' },
	hulianwang	=> { name => 'Hulianwang' },
	qianfan		=> { name => 'Qianfan' },
    },
    celestrak_supplemental => {
	# Removed 2024-12-27
	# Added back 2024-12-29
	ast		=> {
	    name	=> 'AST Space Mobile',
	    rms		=> 1,
	    match	=> 1,
	},
	# Removed 2024-12-27
	# Added back 2024-12-29
	cpf		=> {
	    name	=> 'CPF (no match data)',
	    # source	=> 'CPF',
	    rms		=> 1,
	},
	# Removed 2024-12-27
	# Added back 2024-12-29
	css		=> {
	    name	=> 'CSS (no match data)',
	    rms		=> 1,
	},
	gps		=> {
	    name	=> 'GPS Operational',
	    # source	=> 'GPS-A',
	    rms		=> 1,
	    match	=> 1,
	},
	glonass		=> {
	    name	=> 'GLONASS Operational',
	    # source	=> 'GLONASS-RE',
	    rms		=> 1,
	    match	=> 1,
	},
	iridium		=> {
	    name	=> 'Iridium Next',
	    # source	=> 'Iridium-E',
	    rms		=> 1,
	    match	=> 1,
	},
	# Removed 2024-12-27
	# Added back 2024-12-29
	iss		=> {
	    name	=> 'ISS (from NASA, no match data)',
	    # source	=> 'ISS-E',
	    rms		=> 1,
	},
	# Removed 2024-01-12
	#meteosat	=> {
	#    name	=> 'METEOSAT',
	#    # source	=> 'METEOSAT-SV',
	#    rms		=> 1,
	#    match	=> 1,
	#},
	intelsat	=> {
	    name	=> 'Intelsat',
	    # source	=> 'Intelsat-11P',
	    rms		=> 1,
	    match	=> 1,
	},
	# Removed 2024-12-27
	# Added back 2024-12-29
	kuiper		=> {
	    name	=> 'Project Kuiper (Amazon; no match data)',
	    rms		=> 1,
	},
	oneweb		=> {
	    name	=> 'OneWeb',
	    # source	=> 'OneWeb-E',
	    rms		=> 1,
	    match	=> 1,
	},
	# Removed 2024-12-25
	# Added back 2025-07-28, with RMS and match data
	orbcomm		=> {
	    name	=> 'Orbcomm (no RMS or match data)',
	    # source	=> 'Orbcomm-TLE',
	    rms		=> 1,
	    match	=> 1,
	},
	planet		=> {
	    name	=> 'Planet (no, not Mercury etc)',
	    # source	=> 'Planet-E',
	    rms		=> 1,
	    match	=> 1,
	},
	# Removed 2024-04-26
	# Added back 2024-05-23
	ses		=> {
	    name	=> 'SES',
	    # source	=> 'SES-11P',
	    rms		=> 1,
	    match	=> 1,
	},
	starlink	=> {
	    name	=> 'Starlink',
	    # source	=> 'SpaceX-E',
	    rms		=> 1,
	    match	=> 1,
	},
	telesat		=> {
	    name	=> 'Telesat',
	    # source	=> 'Telesat-E',
	    rms		=> 1,
	    match	=> 1,
	},
    },
    iridium_status => {
	kelso => {name => 'Celestrak (Kelso)'},
	mccants => {name => 'McCants'},
	sladen => {name => 'Sladen'},
	spacetrack	=> { name => 'SpaceTrack' },
    },
    mccants	=> {
	classified	=> {
	    name	=> 'Classified TLE file',
	    member	=> undef,	# classfd.tle
	    spacetrack_type	=> 'orbit',
	    url		=> 'https://www.mmccants.org/tles/classfd.zip',
	},
	integrated	=> {
	    name	=> 'Integrated TLE file',
	    member	=> undef,	# inttles.tle
	    spacetrack_type	=> 'orbit',
	    url		=> 'https://www.mmccants.org/tles/inttles.zip',
	},
	mcnames	=> {
	    name	=> 'Molczan-format magnitude file',
	    member	=> undef,	# mcnames
	    spacetrack_type	=> 'molczan',
	    url		=> 'https://www.mmccants.org/tles/mcnames.zip',
	},
	quicksat	=> {
	    name	=> 'Quicksat-format magnitude file',
	    member	=> undef,	# qs.mag
	    spacetrack_type	=> 'quicksat',
	    url		=> 'https://www.mmccants.org/programs/qsmag.zip',
	},
	# Removed 2024-12-29.
	#rcs	=> {
	#    name	=> 'McCants-format RCS data (404 2024-04-27)',
	#    member	=> undef,	# rcs
	#    spacetrack_type	=> 'rcs.mccants',
	#    url		=> 'https://www.mmccants.org/catalogs/rcs.zip',
	#},
	vsnames	=> {
	    name	=> 'Molczan-format magnitude file (visual only)',
	    member	=> undef,	# vsnames
	    spacetrack_type	=> 'molczan',
	    url		=> 'https://www.mmccants.org/tles/vsnames.zip',
	},
    },
    spacetrack => [	# Numbered by space_track_version
	undef,	# No interface version 0
	undef,	# No interface version 1 any more
	{	# Interface version 2 (REST)
	    full => {
		name	=> 'Full catalog',
		# We have to go through satcat to eliminate bodies that
		# are not on orbit, since tle_latest includes bodies
		# decayed in the last two years or so
#		satcat	=> {},
		tle	=> {
		    EPOCH	=> '>now-30',
		},
#		number	=> 1,
	    },
	    payloads	=> {
		name	=> 'All payloads',
		satcat	=> {
		    OBJECT_TYPE	=> 'PAYLOAD',
		},
	    },
	    geosynchronous => {		# GEO
		name	=> 'Geosynchronous satellites',
#		number	=> 3,
		# We have to go through satcat to eliminate bodies that
		# are not on orbit, since tle_latest includes bodies
		# decayed in the last two years or so
#		satcat	=> {
#		    PERIOD	=> '1425.6--1454.4'
#		},
		# Note that the v2 interface specimen query is
		#   PERIOD 1430--1450.
		# The v1 definition is
		#   MEAN_MOTION 0.99--1.01
		#   ECCENTRICITY <0.01
#		tle	=> {
#		    ECCENTRICITY	=> '<0.01',
##		    MEAN_MOTION		=> '0.99--1.01',
#		},
		tle	=> {
		    ECCENTRICITY	=> '<0.01',
		    EPOCH		=> '>now-30',
		    MEAN_MOTION		=> '0.99--1.01',
		    OBJECT_TYPE		=> 'payload',
		},
	    },
	    medium_earth_orbit => {	# MEO
		name	=> 'Medium Earth Orbit',
		tle	=> {
		    ECCENTRICITY	=> '<0.25',
		    EPOCH		=> '>now-30',
		    # The web page says '600 minutes <= Period <= 800
		    # minutes', but the query is in terms of mean
		    # motion.
		    MEAN_MOTION		=> '1.8--2.30',
		    OBJECT_TYPE		=> 'payload',
		},
	    },
	    low_earth_orbit => {	# LEO
		name	=> 'Low Earth Orbit',
		tle	=> {
		    ECCENTRICITY	=> '<0.25',
		    EPOCH		=> '>now-30',
		    MEAN_MOTION		=> '>11.25',
		    OBJECT_TYPE		=> 'payload',
		},
	    },
	    highly_elliptical_orbit => {	# HEO
		name	=> 'Highly Elliptical Orbit',
		tle	=> {
		    ECCENTRICITY	=> '>0.25',
		    EPOCH		=> '>now-30',
		    OBJECT_TYPE		=> 'payload',
		},
	    },
	    navigation => {
		name => 'Navigation satellites',
		favorite	=> 'Navigation',
		tle => {
		    EPOCH	=> '>now-30',
		},
#		number => 5,
	    },
	    weather => {
		name => 'Weather satellites',
		favorite	=> 'Weather',
		tle => {
		    EPOCH	=> '>now-30',
		},
#		number => 7,
	    },
	    iridium => {
		name	=> 'Iridium satellites',
		tle => {
		    EPOCH	=> '>now-30',
		    OBJECT_NAME	=> 'iridium~~',
		    OBJECT_TYPE	=> 'payload',
		},
#		number	=> 9,
	    },
	    orbcomm	=> {
		name	=> 'OrbComm satellites',
		tle	=> {
		    EPOCH	=> '>now-30',
		    OBJECT_NAME	=> 'ORBCOMM~~,VESSELSAT~~',
		    OBJECT_TYPE	=> 'payload',
		},
#		number	=> 11,
	    },
	    globalstar => {
		name	=> 'Globalstar satellites',
		tle	=> {
		    EPOCH	=> '>now-30',
		    OBJECT_NAME	=> 'globalstar~~',
		    OBJECT_TYPE	=> 'payload',
		},
#		number	=> 13,
	    },
	    intelsat => {
		name	=> 'Intelsat satellites',
		tle	=> {
		    EPOCH	=> '>now-30',
		    OBJECT_NAME	=> 'intelsat~~',
		    OBJECT_TYPE	=> 'payload',
		},
#		number	=> 15,
	    },
	    inmarsat => {
		name	=> 'Inmarsat satellites',
		tle	=> {
		    EPOCH	=> '>now-30',
		    OBJECT_NAME	=> 'inmarsat~~',
		    OBJECT_TYPE	=> 'payload',
		},
#		number	=> 17,
	    },
	    amateur => {
		favorite	=> 'Amateur',
		name => 'Amateur Radio satellites',
		tle => {
		    EPOCH	=> '>now-30',
		},
#		number => 19,
	    },
	    visible => {
		favorite	=> 'Visible',
		name => 'Visible satellites',
		tle => {
		    EPOCH	=> '>now-30',
		},
#		number => 21,
	    },
	    special => {
		favorite	=> 'Special_interest',
		name => 'Special interest satellites',
		tle => {
		    EPOCH	=> '>now-30',
		},
#		number => 23,
	    },
	    bright_geosynchronous => {
		favorite	=> 'brightgeo',
		name => 'Bright Geosynchronous satellites',
		tle => {
		    EPOCH	=> '>now-30',
		},
	    },
	    human_spaceflight => {
		favorite	=> 'human_spaceflight',
		name => 'Human Spaceflight',
		tle => {
		    EPOCH	=> '>now-30',
		},
	    },
	    well_tracked_objects	=> {
		name	=> 'Well-Tracked Objects',
		satcat	=> {
		    COUNTRY	=> 'UNKN',
		    SITE	=> 'UNKN',
		},
	    },
	},
    ],
);

my %mutator = (	# Mutators for the various attributes.
    addendum => \&_mutate_attrib,		# Addendum to banner text.
    banner => \&_mutate_attrib,
    cookie_expires => \&_mutate_spacetrack_interface,
    cookie_name => \&_mutate_spacetrack_interface,
    domain_space_track => \&_mutate_spacetrack_interface,
    dump_headers => \&_mutate_dump_headers,	# Dump all HTTP headers. Undocumented and unsupported.
    fallback => \&_mutate_attrib,
    filter => \&_mutate_attrib,
    identity	=> \&_mutate_identity,
    iridium_status_format => \&_mutate_iridium_status_format,
    max_range => \&_mutate_number,
    password => \&_mutate_authen,
    pretty => \&_mutate_attrib,
    prompt	=> \&_mutate_attrib,
    scheme_space_track => \&_mutate_attrib,
    session_cookie => \&_mutate_spacetrack_interface,
    space_track_version => \&_mutate_space_track_version,
    url_iridium_status_kelso => \&_mutate_attrib,
    url_iridium_status_mccants => \&_mutate_attrib,
    url_iridium_status_sladen => \&_mutate_attrib,
    username => \&_mutate_authen,
    verbose => \&_mutate_attrib,
    verify_hostname => \&_mutate_verify_hostname,
    webcmd => \&_mutate_attrib,
    with_name => \&_mutate_attrib,
);

my %accessor = (
    cookie_expires	=> \&_access_spacetrack_interface,
    cookie_name		=> \&_access_spacetrack_interface,
    domain_space_track	=> \&_access_spacetrack_interface,
    session_cookie	=> \&_access_spacetrack_interface,
);
foreach my $key ( keys %mutator ) {
    exists $accessor{$key}
	or $accessor{$key} = sub {
	    $_[0]->_deprecation_notice( attribute => $_[1] );
	    return $_[0]->{$_[1]};
	};
}

# Maybe I really want a cookie_file attribute, which is used to do
# $self->{agent}->cookie_jar ({file => $self->{cookie_file}, autosave => 1}).
# We'll want to use a false attribute value to pass an empty hash. Going to
# this may imply modification of the new () method where the cookie_jar is
# defaulted and the session cookie's age is initialized.


=item $st = Astro::SpaceTrack->new ( ... )

=for html <a name="new"></a>

This method instantiates a new Space-Track accessor object. If any
arguments are passed, the C<set()> method is called on the new object,
and passed the arguments given.

For both historical and operational reasons, this method can get the
C<username> and C<password> values from multiple locations. It uses the
first defined value it finds in the following list:

=over

=item a value explicitly specified as an argument to C<new()>;

=item a value from the L<IDENTITY FILE|/IDENTITY FILE>, if the
C<identity> attribute is explicitly specified as true and
L<Config::Identity|Config::Identity> is installed;

=item a value from environment variable C<SPACETRACK_USER> if that has a
non-empty value;

=item a value from the L<IDENTITY FILE|/IDENTITY FILE>, if the
C<identity> attribute defaulted to true and
L<Config::Identity|Config::Identity> s installed;

=item a value from environment variable C<SPACETRACK_OPT>.

=back

The reason for preferring C<SPACETRACK_USER> over an identity file value
taken by default is that I have found that under Mac OS X an SSH session
does not have access to the system keyring, and
L<Config::Identity|Config::Identity> provides no other way to specify
the passphrase used to decrypt the private key. I concluded that if the
user explicitly requested an identity that it should be preferred to
anything from the environment, but that, for SSH access to be usable, I
needed to provide a source of username and password that would be taken
before the L<IDENTITY FILE|/IDENTITY FILE> was tried by default.

Proxies are taken from the environment if defined. See the ENVIRONMENT
section of the Perl LWP documentation for more information on how to
set these up.

=cut

sub new {
    my ( $class, %arg ) = @_;
    $class = ref $class if ref $class;

    my $self = {
	banner => 1,	# shell () displays banner if true.
	dump_headers => DUMP_NONE,	# No dumping.
	fallback => 0,	# Do not fall back if primary source offline
	filter => 0,	# Filter mode.
	iridium_status_format => 'kelso',
	max_range => 500,	# Sanity limit on range size.
	password => undef,	# Login password.
	pretty => 0,		# Pretty-format content
	prompt => 'SpaceTrack> ',
	scheme_space_track => 'https',
	_space_track_interface	=> [
	    undef,	# No such thing as version 0
	    undef,	# Interface version 1 retured.
	    {	# Interface version 2
		# This interface does not seem to put an expiration time
		# on the cookie. But the docs say it's only good for a
		# couple hours, so we need this so we can fudge
		# something in when the time comes.
		cookie_expires		=> 0,
		cookie_name		=> 'chocolatechip',
		domain_space_track	=> 'www.space-track.org',
		session_cookie		=> undef,
	    },
	],
	space_track_version	=> DEFAULT_SPACE_TRACK_VERSION,
	url_iridium_status_kelso =>
	    'https://celestrak.org/SpaceTrack/query/iridium.txt',
	url_iridium_status_sladen =>
	    'http://www.rod.sladen.org.uk/iridium.htm',
	username => undef,	# Login username.
	verbose => undef,	# Verbose error messages for catalogs.
	verify_hostname => 1,	# Don't verify host names by default.
	webcmd => undef,	# Command to get web help.
	with_name => undef,	# True to retrieve three-line element sets.
    };
    bless $self, $class;

    $self->set( identity	=> delete $arg{identity} );

    $ENV{SPACETRACK_OPT} and
	$self->set (grep {defined $_} split '\s+', $ENV{SPACETRACK_OPT});

    # TODO this makes no sense - the first branch of the if() can never
    # be executed because I already deleted $arg{identity}. But I do not
    # want to execute the SPACETRACK_USER code willy-nilly -- maybe warn
    # if identity is 1 and I don't have both a username and a password.
    if ( defined( my $id = delete $arg{identity} ) ) {
	$self->set( identity => $id );
    } elsif ( $ENV{SPACETRACK_USER} ) {
	my ($user, $pass) = split qr{ [:/] }smx, $ENV{SPACETRACK_USER}, 2;
	'' ne $user
	    and '' ne $pass
	    or $user = $pass = undef;
	$self->set (username => $user, password => $pass);
    } else {
	$self->set( identity => undef );
    }

    defined $ENV{SPACETRACK_VERIFY_HOSTNAME}
	and $self->set( verify_hostname =>
	$ENV{SPACETRACK_VERIFY_HOSTNAME} );

    keys %arg
	and $self->set( %arg );

    return $self;
}

=for html <a name="amsat"></a>

=item $resp = $st->amsat ()

B<Note> that this method is non-functional as of September 8 2025
(probably earlier), because Amsat has gone to a "humans-only" policy for
their web site. It will be put through the usual deprecation cycle and
removed.

This method downloads current orbital elements from the Radio Amateur
Satellite Corporation's web page, L<https://www.amsat.org/>. This lists
satellites of interest to radio amateurs, and appears to be updated
weekly.

No Space Track account is needed to access this data. As of version
0.150 the setting of the 'with_name' attribute is honored.

You can specify options as either command-type options (e.g.
C<< amsat( '-file', 'foo.dat' ) >>) or as a leading hash reference (e.g.
C<< amsat( { file => 'foo.dat' } ) >>). If you specify the hash
reference, option names must be specified in full, without the leading
'-', and the argument list will not be parsed for command-type options.
If you specify command-type options, they may be abbreviated, as long as
the abbreviation is unique. Errors in either sort result in an exception
being thrown.

The legal options are:

 -file
   specifies the name of the cache file. If the data
   on line are newer than the modification date of
   the cache file, the cache file will be updated.
   Otherwise the data will be returned from the file.
   Either way the content of the file and the content
   of the returned HTTP::Response object end up the
   same.

On a successful return, the response object will contain headers

 Pragma: spacetrack-type = orbit
 Pragma: spacetrack-source = amsat

These can be accessed by C<< $st->content_type( $resp ) >> and
C<< $st->content_source( $resp ) >> respectively.

If the C<file> option was passed, the following additional header will
be provided:

 Pragma: spacetrack-cache-hit = (either true or false)

This can be accessed by the C<cache_hit()> method. If this pragma is
true, the C<Last-Modified> header of the response will contain the
modification time of the file.

This method is a web page scraper. Any change in the location of the
web page will break this method.

=cut

# Called dynamically
sub _amsat_opts {	## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
    return [
	'file=s'	=> 'Name of cache file',
    ];
}

sub amsat {
    my ( $self, @args ) = @_;

    $self->_deprecation_notice( 'amsat' );

    ( my $opt, @args ) = _parse_args( @args );

    return $self->_get_from_net(
	%{ $opt },
	# url	=> 'http://www.amsat.org/amsat/ftp/keps/current/nasabare.txt',
	url	=> 'https://www.amsat.org/tle/current/nasabare.txt',
	post_process	=> sub {
	    my ( $self, $resp ) = @_;
	    unless ( $self->{with_name} ) {
		my @content = split qr{ \015? \012 }smx,
		    $resp->content();
		@content % 3
		    and return HTTP::Response->new(
		    HTTP_PRECONDITION_FAILED,
		    'Response does not contain a multiple of 3 lines' );
		my $ct = '';
		while ( @content ) {
		    shift @content;
		    $ct .= join '', map { "$_\n" } splice @content, 0, 2;
		}
		$resp->content( $ct );
	    }
	    '' eq $resp->content()
		and return HTTP::Response->new(
		HTTP_PRECONDITION_FAILED, NO_CAT_ID );
	    return $resp;
	},
	spacetrack_type	=> 'orbit',
    );
}

=for html <a name="attribute_names"></a>

=item @names = $st->attribute_names

This method returns a list of legal attribute names.

=cut

sub attribute_names {
    my ( $self ) = @_;
    my @keys = grep { ! {
	    url_iridium_status_mccants	=> 1,
	}->{$_} } sort keys %mutator;
    ref $self
	or return wantarray ? @keys : \@keys;
    my $space_track_version = $self->getv( 'space_track_version' );
    my @names = grep {
	$mutator{$_} == \&_mutate_spacetrack_interface ?
	exists $self->{_space_track_interface}[$space_track_version]{$_}
	: 1
    } @keys;
    return wantarray ? @names : \@names;
}


=for html <a name="banner"></a>

=item $resp = $st->banner ();

This method is a convenience/nuisance: it simply returns a fake
HTTP::Response with standard banner text. It's really just for the
benefit of the shell method.

=cut

{
    my $perl_version;

    sub banner {
	my $self = shift;
	$perl_version ||= do {
	    $] >= 5.01 ? $^V : do {
		require Config;
		'v' . $Config::Config{version};	## no critic (ProhibitPackageVars)
	    }
	};
	my $url = $self->_make_space_track_base_url();
	return HTTP::Response->new (HTTP_OK, undef, undef, <<"EOD");

@{[__PACKAGE__]} version $VERSION
Perl $perl_version under $^O

This package acquires satellite orbital elements and other data from a
variety of web sites. It is your responsibility to abide by the terms of
use of the individual web sites. In particular, to acquire data from
Space Track ($url/) you must register and
get a username and password, and you may not make the data available to
a third party without prior permission from Space Track.

Copyright 2005-2022 by T. R. Wyant (wyant at cpan dot org).

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.
@{[$self->{addendum} || '']}
EOD
    }

}

=for html <a name="box_score"></a>

=item $resp = $st->box_score ();

This method returns an HTTP::Response object. If the request succeeds,
the content of the object will be the SATCAT Satellite Box Score
information in the desired format. If the desired format is C<'legacy'>
or C<'json'> and the method is called in list context, the second
returned item will be a reference to an array containing the parsed
data.

This method takes the following options, specified either command-style
or as a hash reference.

C<-format> specifies the desired format of the retrieved data. Possible
values are C<'xml'>, C<'json'>, C<'html'>, C<'csv'>, and C<'legacy'>,
which is the default. The legacy format is tab-delimited text, such as
was returned by the version 1 interface.

C<-json> specifies JSON format. If you specify both C<-json> and
C<-format> you will get an exception unless you specify C<-format=json>.

This method requires a Space Track username and password. It implicitly
calls the C<login()> method if the session cookie is missing or expired.
If C<login()> fails, you will get the HTTP::Response from C<login()>.

If this method succeeds, the response will contain headers

 Pragma: spacetrack-type = box_score
 Pragma: spacetrack-source = spacetrack

There are no arguments.

=cut

{

    my @fields = qw{ SPADOC_CD
	ORBITAL_PAYLOAD_COUNT ORBITAL_ROCKET_BODY_COUNT
	    ORBITAL_DEBRIS_COUNT ORBITAL_TOTAL_COUNT
	DECAYED_PAYLOAD_COUNT DECAYED_ROCKET_BODY_COUNT
	    DECAYED_DEBRIS_COUNT DECAYED_TOTAL_COUNT
	COUNTRY_TOTAL
	};

    my @head = (
	[ '', 'Objects in Orbit', 'Decayed Objects' ],
	[ 'Country/Organization',
	    'Payload', 'Rocket Body', 'Debris', 'Total',
	    'Payload', 'Rocket Body', 'Debris', 'Total',
	    'Grand Total',
	],
    );

    # Called dynamically
    sub _box_score_opts {	## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
	return [
	    'json!'	=> 'Return data in JSON format',
	    'format=s'	=> 'Specify return format',
	];
    }

    sub box_score {
	my ( $self, @args ) = @_;

	( my $opt, @args ) = _parse_args( @args );
	my $format = _retrieval_format( box_score => $opt );

	my $resp = $self->spacetrack_query_v2( qw{
	    basicspacedata query class boxscore },
	    format	=> $format,
	    qw{ predicates all },
	);
	$resp->is_success()
	    or return $resp;

	$self->_add_pragmata($resp,
	    'spacetrack-type' => 'box_score',
	    'spacetrack-source' => 'spacetrack',
	    'spacetrack-interface' => 2,
	);

	'json' eq $format
	    or return $resp;

	my $data;

	if ( ! $opt->{json} ) {

	    $data = $self->_get_json_object()->decode( $resp->content() );

	    my $content;
	    foreach my $row ( @head ) {
		$content .= join( "\t", @{ $row } ) . "\n";
	    }
	    foreach my $datum ( @{ $data } ) {
		defined $datum->{SPADOC_CD}
		    and $datum->{SPADOC_CD} eq 'ALL'
		    and $datum->{SPADOC_CD} = 'Total';
		$content .= join( "\t", map {
			defined $datum->{$_} ? $datum->{$_} : '<undef>'
		    } @fields ) . "\n";
	    }

	    $resp = HTTP::Response->new (HTTP_OK, undef, undef, $content);
	}

	wantarray
	    or return $resp;

	my @table;
	foreach my $row ( @head ) {
	    push @table, [ @{ $row } ];
	}
	$data ||= $self->_get_json_object()->decode( $resp->content() );
	foreach my $datum ( @{ $data } ) {
	    push @table, [ map { $datum->{$_} } @fields ];
	}
	return ( $resp, \@table );
    }
}

# Given a catalog name, return the catalog, which MUST NOT be modified.
# UNSUPPORTED AND SUBJECT TO CHANGE OR REMOVAL WITHOUT NOTICE!
# If you have a use for this information, please let me know and I will
# see about putting together something I believe I can support.
sub __catalog {
    my ( $self, $name ) = @_;
    $name = lc $name;
    my $src = $catalogs{$name};
    $name eq 'spacetrack'
	and $src = $src->[ $self->getv( 'space_track_version' ) ];
    return $src;
}

=for html <a name="celestrak"></a>

=item $resp = $st->celestrak ($name);

As of version 0.158 this version is an interface to the CelesTrak API.
The argument is the argument of a Celestrak query (see
L<https://celestrak.org/NORAD/documentation/gp-data-formats.php>). The
following options are available:

=over

=item format

 --format json

This option specifies the format of the returned data. Valid values are
C<'TLE'>, C<'3LE'>, C<'2LE'>, C<'XML'>, C<'KVN'>, C<'JSON'>, or
C<'CSV'>. See
L<https://celestrak.org/NORAD/documentation/gp-data-formats.php> for a
discussion of these. C<'JSON-PRETTY'> is not a valid format option, but
will be generated if the C<pretty> attribute is true.

The default is C<'TLE'>.

=item query

 --query name

This option specifies the type of query to be done. Valid values are

=over

=item CATNR

The argument is a NORAD catalog number (1-9 digits).

=item GROUP

The argument is the name of a named group of satellites.

=item INTDES

The argument is an international launch designator of the form yyyy-nnn,
where the C<yyyy> is the Gregorian year, and the C<nnn> is the launch
number in the year.

=item NAME

The argument is a satellite name or a portion thereof.

=item SPECIAL

The argument specifies a special data set.

=back

The default is C<'CATNR'> if the argument is numeric, C<'INTDES'> if the
argument looks like an international designator, or C<'GROUP'>
otherwise.

=back

A list of valid C<GROUP> names and brief descriptions can be obtained by
calling C<< $st->names ('celestrak') >>. If you have set the C<verbose>
attribute true (e.g. C<< $st->set (verbose => 1) >>), the content of the
error response will include this list. Note, however, that this list
does not determine what can be retrieved; if Dr. Kelso adds a data set,
it can be retrieved even if it is not on the list, and if he removes
one, being on the list won't help.

If this method succeeds, the response will contain headers

 Pragma: spacetrack-type = orbit
 Pragma: spacetrack-source = celestrak

These can be accessed by C<< $st->content_type( $resp ) >> and
C<< $st->content_source( $resp ) >> respectively.

=cut

# Called dynamically
sub _celestrak_opts {	## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
    return CELESTRAK_OPTIONS;
}

sub celestrak {
    my ($self, @args) = @_;
    delete $self->{_pragmata};

    ( my $opt, @args ) = _parse_args( CELESTRAK_OPTIONS, @args );

    my $name = shift @args;
    defined $name
	or return HTTP::Response->new(
	HTTP_PRECONDITION_FAILED,
	'No catalog name specified' );

    # $self->_deprecation_notice( celestrak => $name );
    # $self->_deprecation_notice( celestrak => "--$_" ) foreach sort keys %{ $opt };

    my $query;
    ref( $query = $self->_celestrak_validate_query(
	    delete $opt->{query}, $name,
	    CELESTRAK_VALID_QUERY, 'GROUP' ) )
	and return $query;

    my $format;
    ref( $format = $self->_celestrak_validate_format(
	    delete $opt->{format} ) )
	and return $format;

    my $uri = URI->new( 'https://celestrak.org/NORAD/elements/gp.php' );
    $uri->query_form(
	$query	=> $name,
	FORMAT	=> $format,
    );

    return $self->_get_from_net(
	%{ $opt },
	url		=> $uri,
	post_process	=> sub {
	    my ( $self, $resp ) = @_;
	    my $check;
	    $check = $self->_celestrak_response_check( $resp,
		celestrak => $name )
		and return $check;
	    $name eq 'iridium'
		and _celestrak_repack_iridium( $resp );
	    return $resp;
	},
	spacetrack_source	=> 'celestrak',
	spacetrack_type		=> 'orbit',
    );
}

=for html <a name="celestrak_supplemental"></a>

=item $resp = $st->celestrak_supplemental ($name);

This method takes the name of a Celestrak supplemental data set and
returns an HTTP::Response object whose content is the relevant element
sets.

These TLE data are B<not> redistributed from Space Track, but are
derived from publicly available ephemeris data for the satellites in
question.

As of version 0.158 this version is an interface to the CelesTrak API.
The argument is the argument of a Celestrak query (see
L<https://celestrak.org/NORAD/documentation/gp-data-formats.php>).  The
following options are available:

=over

=item file

 --file my_data.tle

This option specifies the name of an output file for the data.

=item format

 --format json

This option specifies the format of the returned data. Valid values are
C<'TLE'>, C<'3LE'>, C<'2LE'>, C<'XML'>, C<'KVN'>, C<'JSON'>, or
C<'CSV'>. See
L<https://celestrak.org/NORAD/documentation/gp-data-formats.php> for a
discussion of these. C<'JSON-PRETTY'> is not a valid format option, but
will be generated if the C<pretty> attribute is true.

The default is C<'TLE'>.

=item match

This Boolean option specifies that match data be returned rather than
TLE data, if available. This option is valid only on known catalogs that
actually have match data. If this option is asserted, C<--format> and
C<--query> are invalid.

=item query

 --query name

This option specifies the type of query to be done. Valid values are

=over

=item CATNR

The argument is a NORAD catalog number (1-9 digits).

=item FILE

The argument is the name of a standard data set.

=item INTDES

The argument is an international launch designator of the form yyyy-nnn,
where the C<yyyy> is the Gregorian year, and the C<nnn> is the launch
number in the year.

=item NAME

The argument is a satellite name or a portion thereof.

=item SOURCE

The argument specifies a data source as specified at
L<https://celestrak.org/NORAD/documentation/sup-gp-queries.php>.

=item SPECIAL

The argument specifies a special data set.

=back

The default is C<'CATNR'> if the argument is numeric, C<'INTDES'> if the
argument looks like an international designator, or C<'FILE'> otherwise.

=item rms

This Boolean option specifies that RMS data be returned rather than TLE
data, if available. This option is valid only on known catalogs that
actually have RMS data. If this option is asserted, C<--format> and
C<--query> are invalid.

=back

Valid catalog names are:

 ast      AST Space Mobile
 cpf      CPF (no match data)
 css      CSS (no match data)
 glonass  Glonass satellites
 gps      GPS satellites
 intelsat Intelsat satellites
 iridium  Iridium Next
 iss      ISS (from NASA, no match data)
 kuiper   Project Kuiper (Amazon; no match data)
 oneweb   OneWeb
 planet   Planet (no, not Mercury etc.)
 ses      SES satellites
 starlink Starlink
 telesat  Telesat

You can specify options as either command-type options (e.g.
C<< celestrak_supplemental( '-file', 'foo.dat' ) >>) or as a leading
hash reference (e.g.
C<< celestrak_supplemental( { file => 'foo.dat' }) >>). If you specify
the hash reference, option names must be specified in full, without the
leading '-', and the argument list will not be parsed for command-type
options.  If you specify command-type options, they may be abbreviated,
as long as the abbreviation is unique. Errors in either sort result in
an exception being thrown.

A list of valid catalog names and brief descriptions can be obtained by
calling C<< $st->names( 'celestrak_supplemental' ) >>. If you have set
the C<verbose> attribute true (e.g. C<< $st->set (verbose => 1) >>), the
content of the error response will include this list. Note, however,
that this list does not determine what can be retrieved; if Dr. Kelso
adds a data set, it can be retrieved even if it is not on the list, and
if he removes one, being on the list won't help.

If the C<file> option was passed, the following additional header will
be provided:

 Pragma: spacetrack-cache-hit = (either true or false)

This can be accessed by the C<cache_hit()> method. If this pragma is
true, the C<Last-Modified> header of the response will contain the
modification time of the file.

B<Note> that it is my belief that the current Celestrak API (as of
September 26 2022) does not support this kind of functionality, so
C<cache_hit()> will always return false.

For more information, see
L<https://celestrak.org/NORAD/elements/supplemental/>.

=cut

# Called dynamically
sub _celestrak_supplemental_opts {	## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
    return [
	@{ CELESTRAK_API_OPTIONS() },
	'file=s'	=> 'Name of cache file',
	'rms!'		=> 'Return RMS data',
	'match!'	=> 'Return match data',
    ];
}

sub celestrak_supplemental {
    my ( $self, @args ) = @_;
    ( my $opt, @args ) = _parse_args( @args );

    $opt->{rms}
	and $opt->{match}
	and return HTTP::Response->new(
	HTTP_PRECONDITION_FAILED,
	'You may not assert both --rms and --match',
    );

    if ( $opt->{rms} || $opt->{match} ) {
	foreach my $key ( qw{ query format } ) {
	    defined $opt->{$key}
		and return HTTP::Response->new(
		HTTP_PRECONDITION_FAILED,
		"You may not assert --$key with --rms or --match",
	    );
	}
    }

    my $name = $args[0];

    my $info = $catalogs{celestrak_supplemental}{$name};

    foreach my $key ( qw{ rms match } ) {
	not $opt->{$key}
	    or $info->{$key}
	    or return HTTP::Response->new(
	    HTTP_PRECONDITION_FAILED,
	    "$name does not take the --$key option" );
    }

    my $base_url = 'https://celestrak.org/NORAD/elements/supplemental';

    my ( $spacetrack_type, $uri );

    if ( $opt->{rms} ) {
	$spacetrack_type = 'rms';
	$uri = URI->new( "$base_url/$name.rms.txt" );
    } elsif ( $opt->{match} ) {
	$spacetrack_type = 'match';
	$uri = URI->new( "$base_url/$name.match.txt" );
    } else {
	$spacetrack_type = 'orbit';

	my $source = $info->{source};
	defined $source
	    or $source = $name;

	my $query;
	ref( $query = $self->_celestrak_validate_query(
		delete $opt->{query}, $name,
		CELESTRAK_SUPPLEMENTAL_VALID_QUERY, 'FILE' ) )
	    and return $query;

	my $format;
	ref( $format = $self->_celestrak_validate_format(
		delete $opt->{format} ) )
	    and return $format;

	$uri = URI->new( "$base_url/sup-gp.php" );
	$uri->query_form(
	    $query	=> $source,
	    FORMAT	=> $format,
	);
    }

    return $self->_get_from_net(
	%{ $opt },
	url		=> $uri,
	post_process	=> sub {
	    my ( $self, $resp ) = @_;
	    my $check;
	    $check = $self->_celestrak_response_check( $resp,
		celestrak_supplemental => $name )
		and return $check;
	    return $resp;
	},
	spacetrack_source	=> 'celestrak',
	spacetrack_type		=> $spacetrack_type,
    );
}

{
    my %valid_format = map { $_ => 1 } qw{ TLE 3LE 2LE XML KVN JSON CSV };

    sub _celestrak_validate_format {
	my ( $self, $format ) = @_;
	$format = defined $format ? uc( $format ) : 'TLE';
	$valid_format{$format}
	    or return HTTP::Response->new(
	    HTTP_PRECONDITION_FAILED,
	    "Format '$format' is not valid" );
	$format eq 'JSON'
	    and $self->getv( 'pretty' )
	    and $format = 'JSON-PRETTY';
	return $format;
    }
}

sub _celestrak_validate_query {
    my ( undef, $query, $name, $valid, $dflt ) = @_;
    $query = defined $query ? uc( $query ) :
	$name =~ m/ \A [0-9]+ \z /smx ? 'CATNR' :
	$name =~ m/ \A [0-9]{4}-[0-9]+ \z /smx ? 'INTDES' :
	defined $dflt ? uc( $dflt ) : $dflt;
    defined $query
	or return $query;
    $valid->{$query}
	or return HTTP::Response->new(
	HTTP_PRECONDITION_FAILED,
	"Query '$query' is not valid" );
    return $query;
}

sub _celestrak_repack_iridium {
    my ( $resp ) = @_;
    local $_ = $resp->content();
    s/ \s+ [[] . []] [ \t]* (?= \r? \n | \z ) //smxg;
    $resp->content( $_ );
    return;
}

{	# Local symbol block.

    my %valid_type = map { $_ => 1 }
	qw{ text/plain text/text application/json application/xml };

    sub _celestrak_response_check {
	my ($self, $resp, $source, $name, @args) = @_;

	# As of 2023-10-17, celestrak( 'fubar' ) gives 200 OK, with
	# content
	# Invalid query: "GROUP=fubar&FORMAT=TLE" (GROUP=fubar not found)

	unless ( $resp->is_success() ) {
	    $resp->code == HTTP_NOT_FOUND
		and return $self->_no_such_catalog(
		$source => $name, @args);
	    return $resp;
	}

	my $content = $resp->decoded_content();

	if ( $content =~ m/ \A Invalid \s+ query: /smx ) {
	    $content =~ m/ \b (?: GROUP | FILE ) =\Q$name\E \s not \s found \b /smx
		and return $self->_no_such_catalog(
		$source => $name, @args);
	    $resp->code( HTTP_BAD_REQUEST );
	    $resp->message( HTTP::Status::status_message(
		    HTTP_BAD_REQUEST ) );
	    return $resp;
	}

	if (my $loc = $resp->header('Content-Location')) {
	    if ($loc =~ m/ redirect [.] htm [?] ( \d{3} ) ; /smx) {
		my $msg = "redirected $1";
		@args and $msg = "@args; $msg";
		$1 == HTTP_NOT_FOUND
		    and return $self->_no_such_catalog(
		    $source => $name, $msg);
		return HTTP::Response->new (+$1, "$msg\n")
	    }
	}
	my $type = lc $resp->header('Content-Type')
	    or do {
	    my $msg = 'No Content-Type header found';
	    @args and $msg = "@args; $msg";
	    return $self->_no_such_catalog(
		$source => $name, $msg);
	};
	foreach my $type ( _trim( split ',', $type ) ) {
	    $type =~ s/ ; .* //smx;
	    $valid_type{$type}
		or next;
	    local $_ = $resp->decoded_content();
	    # As of February 12 2022 Celestrak does this
	    # As of July 23 2022 this is not at the beginning of the
	    # string
	    m/^No GP data found\b/sm
		and last;
	    # As of July 25 2022 Celestrak does this.
	    m/^(?:GROUP|FILE) "[^"]+" does not exist/sm
		and last;
	    return;
	}
	my $msg = "Content-Type: $type";
	@args and $msg = "@args; $msg";
	return $self->_no_such_catalog(
	    $source => $name, $msg);
    }

}	# End local symbol block.

=item $bool = $st->cache_hit( $resp );

This method takes the given HTTP::Response object and returns the cache
hit indicator specified by the 'Pragma: spacetrack-cache-hit =' header.
This will be true if the response came from cache, false if it did not,
and C<undef> if cache was not available.

If the response object is not provided, it returns the data type
from the last method call that returned an HTTP::Response object.

=cut

sub cache_hit {
    $_[2] = 'spacetrack-cache-hit';
    goto &_get_pragma_value;
}

=item $source = $st->content_source($resp);

This method takes the given HTTP::Response object and returns the data
source specified by the 'Pragma: spacetrack-source =' header. What
values you can expect depend on the content_type (see below) as follows:

If the C<content_type()> method returns C<'box_score'>, you can expect
a content-source value of C<'spacetrack'>.

If the content_type method returns C<'iridium-status'>, you can expect
content_source values of C<'kelso'>, C<'mccants'>, or C<'sladen'>,
corresponding to the main source of the data.

If the content_type method returns C<'molczan'>, you can expect a
content_source value of C<'mccants'>.

If the C<content_type()> method returns C<'orbit'>, you can expect
content-source values of C<'amsat'>, C<'celestrak'>, C<'mccants'>,
or C<'spacetrack'>, corresponding to the actual source
of the TLE data.

If the content_type method returns C<'quicksat'>, you can expect a
content_source value of C<'mccants'>.

If the C<content_type()> method returns C<'search'>, you can expect a
content-source value of C<'spacetrack'>.

For any other values of content-type (e.g. C<'get'>, C<'help'>), the
expected values are undefined.  In fact, you will probably literally get
undef, but the author does not commit even to this.

If the response object is not provided, it returns the data source
from the last method call that returned an HTTP::Response object.

If the response object B<is> provided, you can call this as a static
method (i.e. as Astro::SpaceTrack->content_source($response)).

=cut

sub content_source {
    $_[2] = 'spacetrack-source';
    goto &_get_pragma_value;
}

=item $type = $st->content_type ($resp);

This method takes the given HTTP::Response object and returns the
data type specified by the 'Pragma: spacetrack-type =' header. The
following values are supported:

 'box_score': The content is the Space Track satellite
         box score.
 'get': The content is a parameter value.
 'help': The content is help text.
 'iridium_status': The content is Iridium status.
 'modeldef': The content is a REST model definition.
 'molczan': Molczan-format magnitude data.
 'orbit': The content is NORAD data sets.
 'quicksat': Quicksat-format magnitude data.
 'search': The content is Space Track search results.
 'set': The content is the result of a 'set' operation.
 undef: No spacetrack-type pragma was specified. The
        content is something else (typically 'OK').

If the response object is not provided, it returns the data type
from the last method call that returned an HTTP::Response object.

If the response object B<is> provided, you can call this as a static
method (i.e. as Astro::SpaceTrack->content_type($response)).

For the format of the magnitude data, see
L<https://www.mmccants.org//tles/index.html>.

=cut

sub content_type {
    $_[2] = 'spacetrack-type';
    goto &_get_pragma_value;
}

=item $type = $st->content_interface( $resp );

This method takes the given HTTP::Response object and returns the Space
Track interface version specified by the
C<'Pragma: spacetrack-interface ='> header. The following values are
supported:

 1: The content was obtained using the version 1 interface.
 2: The content was obtained using the version 2 interface.
 undef: The content did not come from Space Track.

If the response object is not provided, it returns the data type
from the last method call that returned an HTTP::Response object.

If the response object B<is> provided, you can call this as a static
method (i.e. as Astro::SpaceTrack->content_type($response)).

=cut

sub content_interface {
    $_[2] = 'spacetrack-interface';
    goto &_get_pragma_value;
}

sub _get_pragma_value {
    my ( $self, $resp, $pragma ) = @_;
    defined $resp
	or return $self->{_pragmata}{$pragma};
    ( my $re = $pragma ) =~ s/ _ /-/smxg;
    $re = qr{ \Q$re\E }smxi;
    foreach ( $resp->header( 'Pragma' ) ) {
	m/ $re \s+ = \s+ (.+) /smxi and return $1;
    }
    # Sorry, PBP -- to be compatible with the performance of this method
    # when $resp is defined, we must return an explicit undef here.
    return undef;	## no critic (ProhibitExplicitReturnUndef)
}

=for html <a name="country_names"></a>

=item $resp = $st->country_names()

This method returns an HTTP::Response object. If the request succeeds,
the content of the object will be the known country names and their
abbreviations in the desired format. If the desired format is
C<'legacy'> or C<'json'> and the method is called in list context, the
second returned item will be a reference to an array containing the
parsed data.

This method takes the following options, specified either command-style
or as a hash reference.

C<-format> specifies the desired format of the retrieved data. Possible
values are C<'xml'>, C<'json'>, C<'html'>, C<'csv'>, and C<'legacy'>,
which is the default. The legacy format is tab-delimited text, such as
was returned by the version 1 interface.

C<-json> specifies JSON format. If you specify both C<-json> and
C<-format> you will get an exception unless you specify C<-format=json>.

This method requires a Space Track username and password. It
implicitly calls the C<login()> method if the session cookie is
missing or expired.  If C<login()> fails, you will get the
HTTP::Response from C<login()>.

If this method succeeds, the response will contain headers

 Pragma: spacetrack-type = country_names
 Pragma: spacetrack-source = spacetrack

There are no arguments.

=cut

sub country_names {

    my ( $self, @args ) = @_;

    ( my $opt, @args ) = _parse_args(
	[
	    'json!'	=> 'Return data in JSON format',
	    'format=s'	=> 'Specify return format',
	], @args );
    my $format = _retrieval_format( country_names => $opt );

    my $resp = $self->spacetrack_query_v2(
	basicspacedata	=> 'query',
	class		=> 'boxscore',
	format		=> $format,
	predicates	=> 'COUNTRY,SPADOC_CD',
    );
    $resp->is_success()
	or return $resp;

    $self->_add_pragmata( $resp,
	'spacetrack-type'	=> 'country_names',
	'spacetrack-source'	=> 'spacetrack',
	'spacetrack-interface'	=> 2,
    );

    'json' eq $format
	or return $resp;

    my $json = $self->_get_json_object();

    my $data = $json->decode( $resp->content() );

    my %dict;
    foreach my $datum ( @{ $data } ) {
	defined $datum->{SPADOC_CD}
	    and $dict{$datum->{SPADOC_CD}} = $datum->{COUNTRY};
    }

    if ( $opt->{json} ) {

	$resp->content( $json->encode( \%dict ) );

    } else {

	$resp->content(
	    join '',
		join( "\t", 'Abbreviation', 'Country/Organization' )
		    . "\n",
		map { "$_\t$dict{$_}\n" } sort keys %dict
	);

    }

    return $resp;
}


=for html <a name="favorite"></a>

=item $resp = $st->favorite( $name )

This method returns an HTTP::Response object. If the request succeeds,
the content of the response will be TLE data specified by the named
favorite in the desired format. The named favorite must have previously
been set up by the user, or be one of the 'global' favorites (e.g.
C<'Navigation'>, C<'Weather'>, and so on).

This method takes the following options, specified either command-style
or as a hash reference.

C<-format> specifies the desired format of the retrieved data. Possible
values are C<'xml'>, C<'json'>, C<'html'>, C<'csv'>, and C<'legacy'>,
which is the default. The legacy format is tab-delimited text, such as
was returned by the version 1 interface.

C<-json> specifies JSON format. If you specify both C<-json> and
C<-format> you will get an exception unless you specify C<-format=json>.

This method requires a Space Track username and password. It
implicitly calls the C<login()> method if the session cookie is
missing or expired.  If C<login()> fails, you will get the
HTTP::Response from C<login()>.

=cut

# Called dynamically
sub _favorite_opts {	## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
    return [
	'json!'	=> 'Return data in JSON format',
	'format=s'	=> 'Specify return format',
    ];
}

sub favorite {
    my ($self, @args) = @_;
    delete $self->{_pragmata};

    ( my $opt, @args ) = _parse_args( @args );

    @args
	and defined $args[0]
	or Carp::croak 'Must specify a favorite';
    @args > 1
	and Carp::croak 'Can not specify more than one favorite';
    # https://beta.space-track.org/basicspacedata/query/class/tle_latest/favorites/Visible/ORDINAL/1/EPOCH/%3Enow-30/format/3le

    my $rest = $self->_convert_retrieve_options_to_rest( $opt );
    $rest->{favorites}	= $args[0];
    $rest->{EPOCH}	= '>now-30';
    delete $rest->{orderby};

    my $resp = $self->spacetrack_query_v2(
	basicspacedata	=> 'query',
	_sort_rest_arguments( $rest )
    );

    $resp->is_success()
	or return $resp;

    _spacetrack_v2_response_is_empty( $resp )
	and return HTTP::Response->new(
	    HTTP_NOT_FOUND,
	    "Favorite '$args[0]' not found"
	);

    return $resp;
}


=for html <a name="file"></a>

=item $resp = $st->file ($name)

This method takes the name of an observing list file, or a handle to an
open observing list file, and returns an HTTP::Response object whose
content is the relevant element sets, retrieved from the Space Track web
site. If called in list context, the first element of the list is the
aforementioned HTTP::Response object, and the second element is a list
reference to list references  (i.e.  a list of lists). Each of the list
references contains the catalog ID of a satellite or other orbiting body
and the common name of the body.

This method requires a Space Track username and password. It implicitly
calls the C<login()> method if the session cookie is missing or expired.
If C<login()> fails, you will get the HTTP::Response from C<login()>.

The observing list file is (how convenient!) in the Celestrak format,
with the first five characters of each line containing the object ID,
and the rest containing a name of the object. Lines whose first five
characters do not look like a right-justified number will be ignored.

If this method succeeds, the response will contain headers

 Pragma: spacetrack-type = orbit
 Pragma: spacetrack-source = spacetrack

These can be accessed by C<< $st->content_type( $resp ) >> and
C<< $st->content_source( $resp ) >> respectively.

You can specify the C<retrieve()> options on this method as well.

=cut

# Called dynamically
sub _file_opts {	## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
    return [ _get_retrieve_options() ];
}

sub file {
    my ($self, @args) = @_;

    my ( $opt, $file ) = $self->_parse_retrieve_args( @args );

    delete $self->{_pragmata};

    if ( ! Scalar::Util::openhandle( $file ) ) {
	-e $file or return HTTP::Response->new (
	    HTTP_NOT_FOUND, "Can't find file $file");
	my $fh = IO::File->new($file, '<') or
	    return HTTP::Response->new (
		HTTP_INTERNAL_SERVER_ERROR, "Can't open $file: $!");
	$file = $fh;
    }

    local $/ = undef;
    return $self->_handle_observing_list( $opt, <$file> )
}


=for html <a name="get"></a>

=item $resp = $st->get (attrib)

B<This method returns an HTTP::Response object> whose content is the value
of the given attribute. If called in list context, the second element
of the list is just the value of the attribute, for those who don't want
to winkle it out of the response object. We croak on a bad attribute name.

If this method succeeds, the response will contain header

 Pragma: spacetrack-type = get

This can be accessed by C<< $st->content_type( $resp ) >>.

See L</Attributes> for the names and functions of the attributes.

=cut

# Called dynamically
sub _readline_complete_command_get {	## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
    # my ( $self, $text, $line, $start, $cmd_line ) = @_;
    my ( $self, $text ) = @_;
    $text eq ''
	and return( $self->attribute_names() );
    my $re = qr/ \A \Q$text\E /smx;
    return( sort grep { $_ =~ $re } $self->attribute_names() );
}

sub get {
    my ( $self, $name ) = @_;
    delete $self->{_pragmata};
    my $code = $self->can( "_get_attr_$name" ) || $self->can( 'getv' );
    my $value = $code->( $self, $name );
    my $resp = HTTP::Response->new( HTTP_OK, COPACETIC, undef, $value );
    $self->_add_pragmata( $resp,
	'spacetrack-type' => 'get',
    );
    $self->__dump_response( $resp );
    return wantarray ? ($resp, $value ) : $resp;
}

# Called dynamically
sub _get_attr_dump_headers {	## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
    my ( $self, $name ) = @_;
    my $value = $self->getv( $name );
    my @opts = ( $value, '#' );
    if ( $value ) {
	foreach my $key ( @dump_options ) {
	    my $const = "DUMP_\U$key";
	    my $mask = __PACKAGE__->$const();
	    $value & $mask
		and push @opts, "--$key";
	}
    } else {
	push @opts, '--none';
    }
    return "@opts";
}


=for html <a name="getv"></a>

=item $value = $st->getv (attrib)

This method returns the value of the given attribute, which is what
C<get()> should have done.

See L</Attributes> for the names and functions of the attributes.

=cut

sub getv {
    my ( $self, $name ) = @_;
    defined $name
	or Carp::croak 'No attribute name specified';
    my $code = $accessor{$name}
	or Carp::croak "No such attribute as '$name'";
    return $code->( $self, $name );
}


=for html <a name="help"></a>

=item $resp = $st->help ()

This method exists for the convenience of the shell () method. It
always returns success, with the content being whatever it's
convenient (to the author) to include.

If the C<webcmd> attribute is set, the L<https://metacpan.org/>
web page for Astro::Satpass is launched.

If this method succeeds B<and> the webcmd attribute is not set, the
response will contain header

 Pragma: spacetrack-type = help

This can be accessed by C<< $st->content_type( $resp ) >>.

Otherwise (i.e. in any case where the response does B<not> contain
actual help text) this header will be absent.

=cut

sub help {
    my $self = shift;
    delete $self->{_pragmata};
    if ($self->{webcmd}) {
	my $cmd = $self->{webcmd};
	if ( '1' eq $cmd ) {
	    require Browser::Open;
	    $cmd = Browser::Open::open_browser_cmd();
	}
	# TODO just use open_browser() once webcmd becomes Boolean.
	system { $cmd } $cmd,
	    'https://metacpan.org/release/Astro-SpaceTrack';
	return HTTP::Response->new (HTTP_OK, undef, undef, 'OK');
    } else {
	my $resp = HTTP::Response->new (HTTP_OK, undef, undef, <<'EOD');
The following commands are defined:
  box_score
    Retrieve the SATCAT box score. A Space Track login is needed.
  celestrak name
    Retrieves the named catalog of IDs from Celestrak.
  exit (or bye)
    Terminate the shell. End-of-file also works.
  file filename
    Retrieve the catalog IDs given in the named file (one per
    line, with the first five characters being the ID).
  get
    Get the value of a single attribute.
  help
    Display this help text.
  iridium_status
    Status of Iridium satellites, from Rod Sladen and/or T. S. Kelso.
  login
    Acquire a session cookie. You must have already set the
    username and password attributes. This will be called
    implicitly if needed by any method that accesses data.
  names source
    Lists the catalog names from the given source.
  retrieve number ...
    Retieves the latest orbital elements for the given
    catalog numbers.
  search_date date ...
    Retrieves orbital elements by launch date.
  search_decay date ...
    Retrieves orbital elements by decay date.
  search_id id ...
    Retrieves orbital elements by international designator.
  search_name name ...
    Retrieves orbital elements by satellite common name.
  set attribute value ...
    Sets the given attributes. Legal attributes are
      addendum = extra text for the shell () banner;
      banner = false to supress the shell () banner;
      cookie_expires = Perl date the session cookie expires;
      filter = true supresses all output to stdout except
        orbital elements;
      identity = load username and password from identity file
        if true and Config::Identity can be loaded;
      max_range = largest range of numbers that can be re-
        trieved (default: 500);
      password = the Space-Track password;
      session_cookie = the text of the session cookie;
      username = the Space-Track username;
      verbose = true for verbose catalog error messages;
      webcmd = command to launch a URL (for web-based help);
      with_name = true to retrieve common names as well.
    The session_cookie and cookie_expires attributes should
    only be set to previously-retrieved, matching values.
  source filename
    Executes the contents of the given file as shell commands.
  spacetrack name
    Retrieves the named catalog of orbital elements from
    Space Track.
The shell supports a pseudo-redirection of standard output,
using the usual Unix shell syntax (i.e. '>output_file').
EOD
	$self->_add_pragmata($resp,
	    'spacetrack-type' => 'help',
	);
	$self->__dump_response( $resp );
	return $resp;
    }
}


=for html <a name="iridium_status"></a>

=item $resp = $st->iridium_status ($format);

This method queries its sources of Iridium status, returning an
HTTP::Response object containing the relevant data (if all queries
succeeded) or the status of the first failure. If the queries succeed,
the content is a series of lines formatted by "%6d   %-15s%-8s %s\n",
with NORAD ID, name, status, and comment substituted in.

If no format is specified, the format specified in the
C<iridium_status_format> attribute is used.

There is one option, C<'raw'>, which can be specified either
command-line style (i.e. C<-raw>) or as a leading hash reference.
Asserting this option causes status information from sources other than
Celestrak and Rod Sladen not to be supplemented by Celestrak data. In
addition, it prevents all sources from being supplemented by canned data
that includes all original-design Iridium satellites, including those
that have decayed. By default this option is not asserted.

Format C<'mccants'> is B<deprecated>, and throws an exception as of
version 0.137.  This entire method will be deprecated and removed once
the last flaring Iridium satellite is removed from service.

A Space Track username and password are required only if the format is
C<'spacetrack'>.

If this method succeeds, the response will contain headers

 Pragma: spacetrack-type = iridium_status
 Pragma: spacetrack-source = 

The spacetrack-source will be C<'kelso'>, C<'sladen'>, or
C<'spacetrack'>, depending on the format requested.

These can be accessed by C<< $st->content_type( $resp ) >> and
C<< $st->content_source( $resp ) >> respectively.

The source of the data and, to a certain extent, the format of the
results is determined by the optional $format argument, which defaults
to the value of the C<iridium_status_format> attribute.

If the format is 'kelso', only Dr. Kelso's Celestrak web site
(L<https://celestrak.org/SpaceTrack/query/iridium.txt>) is queried for
the data. The possible status values are documented at
L<https://celestrak.org/satcat/status.php>, and repeated here for
convenience:

    '[+]' - Operational
    '[-]' - Nonoperational
    '[P]' - Partially Operational
    '[B]' - Backup/Standby
    '[S]' - Spare
    '[X]' - Extended Mission
    '[D]' - Decayed
    '[?]' - Unknown

The comment will be 'Spare', 'Tumbling', or '' depending on the status.

In addition, the data from Celestrak may contain the following
status:

 'dum' - Dummy mass

A blank status indicates that the satellite is in service and
therefore capable of producing flares.

If the format is 'sladen', the primary source of information will be Rod
Sladen's "Iridium Constellation Status" web page,
L<http://www.rod.sladen.org.uk/iridium.htm>, which gives status on all
Iridium satellites, but no OID. The Celestrak list will be used to
provide OIDs for Iridium satellite numbers, so that a complete list is
generated. Mr. Sladen's page simply lists operational and failed
satellites in each plane, so this software imposes Kelso-style statuses
on the data. That is to say, operational satellites will be marked
'[+]', spares will be marked '[S]', and failed satellites will be
marked '[-]', with the corresponding portable statuses. As of version
0.035, all failed satellites will be marked '[-]'. Previous to this
release, failed satellites not specifically marked as tumbling were
considered spares.

The comment field in 'sladen' format data will contain the orbital plane
designation for the satellite, 'Plane n' with 'n' being a number from 1
to 6. If the satellite is failed but not tumbling, the text ' - Failed
on station?' will be appended to the comment. The dummy masses will be
included from the Kelso data, with status '[-]' but comment 'Dummy'.

If the format is 'spacetrack', the data come from both Celestrak and
Space Track. For any given OID, we take the Space Track data if it shows
the OID as being decayed, or if the OID does not appear in the Celestrak
data; otherwise we take the Celestrak data.  The idea here is to get a
list of statuses that include decayed satellites dropped from the
Celestrak list. You will need a Space Track username and password for
this. The format of the returned data is the same as for Celestrak data.

If the method is called in list context, the first element of the
returned list will be the HTTP::Response object, and the second
element will be a reference to a list of anonymous lists, each
containing [$id, $name, $status, $comment, $portable_status] for
an Iridium satellite. The portable statuses are:

  0 = BODY_STATUS_IS_OPERATIONAL means object is operational,
      and capable of producing predictable flares;
  1 = BODY_STATUS_IS_SPARE means object is a spare or
      otherwise not in regular service, but is controlled
      and may be capable of producing predictable flares;
  2 = BODY_STATUS_IS_TUMBLING means object is tumbling
      or otherwise unservicable, and incapable of producing
      predictable flares
  3 - BODY_STATUS_IS_DECAYED neans that the object is decayed.

In terms of the Kelso statuses, the mapping is:

    '[+]' - BODY_STATUS_IS_OPERATIONAL
    '[-]' - BODY_STATUS_IS_TUMBLING
    '[P]' - BODY_STATUS_IS_SPARE
    '[B]' - BODY_STATUS_IS_SPARE
    '[S]' - BODY_STATUS_IS_SPARE
    '[X]' - BODY_STATUS_IS_SPARE
    '[D]' - BODY_STATUS_IS_DECAYED
    '[?]' - BODY_STATUS_IS_TUMBLING

The BODY_STATUS constants are exportable using the :status tag.

This method and the associated manifest constants are B<deprecated>.

=cut

{	# Begin local symbol block.

    # NOTE the indirection here is so that, at the next deprecation
    # step, the exported stuff can become a normal subroutine that
    # triggers a deprecation warning, but the internal stuff can still
    # be in-lined and trigger no warning.
    use constant _BODY_STATUS_IS_OPERATIONAL	=> 0;
    use constant _BODY_STATUS_IS_SPARE		=> 1;
    use constant _BODY_STATUS_IS_TUMBLING	=> 2;
    use constant _BODY_STATUS_IS_DECAYED	=> 3;


    foreach ( qw{
	BODY_STATUS_IS_OPERATIONAL
	BODY_STATUS_IS_SPARE
	BODY_STATUS_IS_TUMBLING
	BODY_STATUS_IS_DECAYED
	} )
    {
	eval "sub $_ () { _deprecation_notice(); return _$_ }";	## no critic (ProhibitStringyEval,RequireCheckingReturnValueOfEval)
    }

    my %kelso_comment = (	# Expand Kelso status.
	'[S]' => 'Spare',
	'[-]' => 'Tumbling',
	'[D]'	=> 'Decayed',
	);
    my %status_portable = (	# Map statuses to portable.
	kelso => {
	    ''	=> _BODY_STATUS_IS_OPERATIONAL,
	    '[+]' => _BODY_STATUS_IS_OPERATIONAL,	# Operational
	    '[-]' => _BODY_STATUS_IS_TUMBLING,		# Nonoperational
	    '[P]' => _BODY_STATUS_IS_SPARE,		# Partially Operational
	    '[B]' => _BODY_STATUS_IS_SPARE,		# Backup/Standby
	    '[S]' => _BODY_STATUS_IS_SPARE,		# Spare
	    '[X]' => _BODY_STATUS_IS_SPARE,		# Extended Mission
	    '[D]' => _BODY_STATUS_IS_DECAYED,		# Decayed
	    '[?]' => _BODY_STATUS_IS_TUMBLING,		# Unknown
	},
#	sladen => undef,	# Not needed; done programmatically.
    );

    $status_portable{kelso_inverse} = {
	map { $status_portable{kelso}{$_} => $_ } qw{ [-] [S] [+] } };

    # All Iridium Classic satellites. The order of the data is:
    # OID, name, status string, comment, portable status.
    #
    # Generated by tools/all_iridium_classic -indent=4
    # on Sun May 31 12:27:10 2020 GMT

    my @all_iridium_classic = (
	[ 24792, 'Iridium 8', '[D]', 'Decayed 2017-11-24', 3 ],
	[ 24793, 'Iridium 7', '[?]', 'SpaceTrack', 2 ],
	[ 24794, 'Iridium 6', '[D]', 'Decayed 2017-12-23', 3 ],
	[ 24795, 'Iridium 5', '[?]', 'SpaceTrack', 2 ],
	[ 24796, 'Iridium 4', '[?]', 'SpaceTrack', 2 ],
	[ 24836, 'Iridium 914', '[?]', 'SpaceTrack', 2 ],
	[ 24837, 'Iridium 12', '[D]', 'Decayed 2018-09-02', 3 ],
	[ 24838, 'Iridium 9', '[D]', 'Decayed 2003-03-11', 3 ],
	[ 24839, 'Iridium 10', '[D]', 'Decayed 2018-10-06', 3 ],
	[ 24840, 'Iridium 13', '[D]', 'Decayed 2018-04-29', 3 ],
	[ 24841, 'Iridium 16', '[?]', 'SpaceTrack', 2 ],
	[ 24842, 'Iridium 911', '[?]', 'SpaceTrack', 2 ],
	[ 24869, 'Iridium 15', '[D]', 'Decayed 2018-10-14', 3 ],
	[ 24870, 'Iridium 17', '[?]', 'SpaceTrack', 2 ],
	[ 24871, 'Iridium 920', '[?]', 'SpaceTrack', 2 ],
	[ 24872, 'Iridium 18', '[D]', 'Decayed 2018-08-19', 3 ],
	[ 24873, 'Iridium 921', '[?]', 'SpaceTrack', 2 ],
	[ 24903, 'Iridium 26', '[?]', 'SpaceTrack', 2 ],
	[ 24904, 'Iridium 25', '[D]', 'Decayed 2018-05-14', 3 ],
	[ 24905, 'Iridium 46', '[D]', 'Decayed 2019-05-11', 3 ],
	[ 24906, 'Iridium 23', '[D]', 'Decayed 2018-03-28', 3 ],
	[ 24907, 'Iridium 22', '[?]', 'SpaceTrack', 2 ],
	[ 24944, 'Iridium 29', '[?]', 'SpaceTrack', 2 ],
	[ 24945, 'Iridium 32', '[D]', 'Decayed 2019-03-10', 3 ],
	[ 24946, 'Iridium 33', '[?]', 'SpaceTrack', 2 ],
	[ 24947, 'Iridium 27', '[D]', 'Decayed 2002-02-01', 3 ],
	[ 24948, 'Iridium 28', '[?]', 'SpaceTrack', 2 ],
	[ 24949, 'Iridium 30', '[D]', 'Decayed 2017-09-28', 3 ],
	[ 24950, 'Iridium 31', '[D]', 'Decayed 2018-12-20', 3 ],
	[ 24965, 'Iridium 19', '[D]', 'Decayed 2018-04-07', 3 ],
	[ 24966, 'Iridium 35', '[D]', 'Decayed 2018-12-26', 3 ],
	[ 24967, 'Iridium 36', '[?]', 'SpaceTrack', 2 ],
	[ 24968, 'Iridium 37', '[D]', 'Decayed 2018-05-26', 3 ],
	[ 24969, 'Iridium 34', '[D]', 'Decayed 2018-01-08', 3 ],
	[ 25039, 'Iridium 43', '[D]', 'Decayed 2018-02-11', 3 ],
	[ 25040, 'Iridium 41', '[D]', 'Decayed 2018-07-28', 3 ],
	[ 25041, 'Iridium 40', '[D]', 'Decayed 2018-09-23', 3 ],
	[ 25042, 'Iridium 39', '[?]', 'SpaceTrack', 2 ],
	[ 25043, 'Iridium 38', '[?]', 'SpaceTrack', 2 ],
	[ 25077, 'Iridium 42', '[?]', 'SpaceTrack', 2 ],
	[ 25078, 'Iridium 44', '[?]', 'SpaceTrack', 2 ],
	[ 25104, 'Iridium 45', '[?]', 'SpaceTrack', 2 ],
	[ 25105, 'Iridium 24', '[?]', 'SpaceTrack', 2 ],
	[ 25106, 'Iridium 47', '[D]', 'Decayed 2018-09-01', 3 ],
	[ 25107, 'Iridium 48', '[D]', 'Decayed 2001-05-05', 3 ],
	[ 25108, 'Iridium 49', '[D]', 'Decayed 2018-02-13', 3 ],
	[ 25169, 'Iridium 52', '[D]', 'Decayed 2018-11-05', 3 ],
	[ 25170, 'Iridium 56', '[D]', 'Decayed 2018-10-11', 3 ],
	[ 25171, 'Iridium 54', '[D]', 'Decayed 2019-05-11', 3 ],
	[ 25172, 'Iridium 50', '[D]', 'Decayed 2018-09-23', 3 ],
	[ 25173, 'Iridium 53', '[D]', 'Decayed 2018-09-30', 3 ],
	[ 25262, 'Iridium 51', '[?]', 'SpaceTrack', 2 ],
	[ 25263, 'Iridium 61', '[D]', 'Decayed 2019-07-23', 3 ],
	[ 25272, 'Iridium 55', '[D]', 'Decayed 2019-03-31', 3 ],
	[ 25273, 'Iridium 57', '[?]', 'SpaceTrack', 2 ],
	[ 25274, 'Iridium 58', '[D]', 'Decayed 2019-04-07', 3 ],
	[ 25275, 'Iridium 59', '[D]', 'Decayed 2019-03-11', 3 ],
	[ 25276, 'Iridium 60', '[D]', 'Decayed 2019-03-17', 3 ],
	[ 25285, 'Iridium 62', '[D]', 'Decayed 2018-11-07', 3 ],
	[ 25286, 'Iridium 63', '[?]', 'SpaceTrack', 2 ],
	[ 25287, 'Iridium 64', '[D]', 'Decayed 2019-04-01', 3 ],
	[ 25288, 'Iridium 65', '[D]', 'Decayed 2018-07-19', 3 ],
	[ 25289, 'Iridium 66', '[D]', 'Decayed 2018-08-23', 3 ],
	[ 25290, 'Iridium 67', '[D]', 'Decayed 2018-07-02', 3 ],
	[ 25291, 'Iridium 68', '[D]', 'Decayed 2018-06-06', 3 ],
	[ 25319, 'Iridium 69', '[?]', 'SpaceTrack', 2 ],
	[ 25320, 'Iridium 71', '[?]', 'SpaceTrack', 2 ],
	[ 25342, 'Iridium 70', '[D]', 'Decayed 2018-10-11', 3 ],
	[ 25343, 'Iridium 72', '[D]', 'Decayed 2018-05-14', 3 ],
	[ 25344, 'Iridium 73', '[?]', 'SpaceTrack', 2 ],
	[ 25345, 'Iridium 74', '[D]', 'Decayed 2017-06-11', 3 ],
	[ 25346, 'Iridium 75', '[D]', 'Decayed 2018-07-10', 3 ],
	[ 25431, 'Iridium 3', '[D]', 'Decayed 2018-02-08', 3 ],
	[ 25432, 'Iridium 76', '[D]', 'Decayed 2018-08-28', 3 ],
	[ 25467, 'Iridium 82', '[?]', 'SpaceTrack', 2 ],
	[ 25468, 'Iridium 81', '[D]', 'Decayed 2018-07-17', 3 ],
	[ 25469, 'Iridium 80', '[D]', 'Decayed 2018-08-12', 3 ],
	[ 25470, 'Iridium 79', '[D]', 'Decayed 2000-11-29', 3 ],
	[ 25471, 'Iridium 77', '[D]', 'Decayed 2017-09-22', 3 ],
	[ 25527, 'Iridium 2', '[?]', 'SpaceTrack', 2 ],
	[ 25528, 'Iridium 86', '[D]', 'Decayed 2018-10-05', 3 ],
	[ 25529, 'Iridium 85', '[D]', 'Decayed 2000-12-30', 3 ],
	[ 25530, 'Iridium 84', '[D]', 'Decayed 2018-11-04', 3 ],
	[ 25531, 'Iridium 83', '[D]', 'Decayed 2018-11-05', 3 ],
	[ 25577, 'Iridium 20', '[D]', 'Decayed 2018-10-22', 3 ],
	[ 25578, 'Iridium 11', '[D]', 'Decayed 2018-10-22', 3 ],
	[ 25777, 'Iridium 14', '[D]', 'Decayed 2019-03-15', 3 ],
	[ 25778, 'Iridium 21', '[D]', 'Decayed 2018-05-24', 3 ],
	[ 27372, 'Iridium 91', '[D]', 'Decayed 2019-03-13', 3 ],
	[ 27373, 'Iridium 90', '[D]', 'Decayed 2019-01-23', 3 ],
	[ 27374, 'Iridium 94', '[D]', 'Decayed 2018-04-18', 3 ],
	[ 27375, 'Iridium 95', '[D]', 'Decayed 2019-03-25', 3 ],
	[ 27376, 'Iridium 96', '[D]', 'Decayed 2020-05-30', 3 ],
	[ 27450, 'Iridium 97', '[D]', 'Decayed 2019-12-27', 3 ],
	[ 27451, 'Iridium 98', '[D]', 'Decayed 2018-08-24', 3 ],
    );

    my %ignore_raw = map { $_ => 1 } qw{ kelso sladen };

    # Called dynamically
    sub _iridium_status_opts {	## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
	return [
	    'raw!'	=> 'Do not supplement with kelso data'
	];
    }

    sub iridium_status {
	my ( $self, @args ) = @_;
	my ( $opt, $fmt ) = _parse_args( @args );
	defined $fmt
	    or $fmt = $self->{iridium_status_format};
	$self->_deprecation_notice( iridium_status => $fmt );
	delete $self->{_pragmata};
	my %rslt;
	my $resp;

	if ( ! $opt->{raw} || $ignore_raw{$fmt} ) {
	    $resp = $self->_iridium_status_kelso( $fmt, \%rslt );
	    $resp->is_success()
		or return $resp;
	}

	unless ( 'kelso' eq $fmt ) {
	    my $code = $self->can( "_iridium_status_$fmt" )
		or Carp::croak "Bad iridium_status format '$fmt'";
	    ( $resp = $code->( $self, $fmt, \%rslt ) )->is_success()
		or return $resp;
	}

	unless ( $opt->{raw} ) {
	    foreach my $body ( @all_iridium_classic ) {
		$rslt{$body->[0]}
		    and $body->[4] != _BODY_STATUS_IS_DECAYED
		    and next;
		$rslt{$body->[0]} = [ @{ $body } ];	# shallow clone
	    }
	}

	$resp->content (join '', map {
		sprintf "%6d   %-15s%-8s %s\n", @{$rslt{$_}}[0 .. 3]}
	    sort {$a <=> $b} keys %rslt);
	$self->_add_pragmata($resp,
	    'spacetrack-type' => 'iridium-status',
	    'spacetrack-source' => $fmt,
	);
	$self->__dump_response( $resp );
	return wantarray ? ($resp, [
		sort { $a->[0] <=> $b->[0] }
		values %rslt
	    ]) : $resp;
    }

    # Get Iridium data from Celestrak.
    sub _iridium_status_kelso {
	# my ( $self, $fmt, $rslt ) = @_;
	my ( $self, undef, $rslt ) = @_;	# $fmt only relevant to mccants
	my $resp = $self->_get_agent()->get(
	    $self->getv( 'url_iridium_status_kelso' )
	);
	$resp->is_success or return $resp;
	foreach my $buffer (split '\n', $resp->content) {
	    $buffer =~ s/ \s+ \z //smx;
	    my $id = substr ($buffer, 0, 5) + 0;
	    my $name = substr ($buffer, 5);
	    my $status = '';
	    $name =~ s/ \s+ ( [[] .+? []] ) \s* \z //smx
		and $status = $1;
	    my $portable_status = $status_portable{kelso}{$status};
	    my $comment = $kelso_comment{$status} || '';
	    $name = ucfirst lc $name;
	    $rslt->{$id} = [ $id, $name, $status, $comment,
		$portable_status ];
	}
	return $resp;
    }

    # Mung an Iridium status hash to assume all actual Iridium
    # satellites are good. This is used to prevent bleed-through from
    # Kelso to McCants, since the latter only reports by exception.
    sub _iridium_status_assume_good {
	my ( undef, $rslt ) = @_;	# Invocant unused

	foreach my $val ( values %{ $rslt } ) {
	    $val->[1] =~ m/ \A iridium \b /smxi
		or next;
	    $val->[2] = '';
	    $val->[4] = _BODY_STATUS_IS_OPERATIONAL;
	}

	return;
    }

    my %sladen_interpret_detail = (
	'' => sub {
	    my ( $rslt, $id, $name, $plane ) = @_;
	    $rslt->{$id} = [ $id, $name, '[-]',
		"$plane - Failed on station?",
		_BODY_STATUS_IS_TUMBLING ];
	    return;
	},
	d => sub {
	    return;
	},
	t => sub {
	    my ( $rslt, $id, $name, $plane ) = @_;
	    $rslt->{$id} = [ $id, $name, '[-]', $plane,
		_BODY_STATUS_IS_TUMBLING ];
	},
    );

    # Get Iridium status from Rod Sladen. Called dynamically
    sub _iridium_status_sladen {	## no critic (ProhibitUnusedPrivateSubroutines)
	my ( $self, undef, $rslt ) = @_;	# $fmt arg not used

	$self->_iridium_status_assume_good( $rslt );
	my $resp = $self->_get_agent()->get(
	    $self->getv( 'url_iridium_status_sladen' )
	);
	$resp->is_success or return $resp;
	my %oid;
	my %dummy;
	foreach my $id (keys %{ $rslt } ) {
	    $rslt->{$id}[1] =~ m/ dummy /smxi and do {
		$dummy{$id} = $rslt->{$id};
		$dummy{$id}[3] = 'Dummy';
		next;
	    };
	    $rslt->{$id}[1] =~ m/ (\d+) /smx or next;
	    $oid{+$1} = $id;
	}
	%{ $rslt } = %dummy;

	my $fail;
	my $re = qr{ ( [\d/]+) }smx;
	local $_ = $resp->content;
####	s{ <em> .*? </em> }{}smxgi;	# Strip emphasis notes
	s/ < .*? > //smxg;	# Strip markup
	# Parenthesized numbers are assumed to represent tumbling
	# satellites in the in-service or spare grids.
	my %exception;
	{
	    # 23-Nov-2017 update double-parenthesized 6.
	    s< [(]+ (\d+) [)]+ >
		< $exception{$1} = _BODY_STATUS_IS_TUMBLING; $1>smxge;
	}
	s/ [(] .*? [)\n] //smxg;	# Strip parenthetical comments
	foreach ( split qr{ \n }smx ) {
	    if (m/ &lt; -+ \s+ failed \s+ (?: or \s+ retired \s+ )? -+ &gt; /smxi) {
		$fail++;
		$re = qr{ (\d+) (\w?) }smx;
	    } elsif ( s/ \A \s* ( plane \s+ \d+ ) \s* : \s* //smxi ) {
		my $plane = $1;
##		s/ \A \D+ //smx;	# Strip leading non-digits
		s/ \b [[:alpha:]] .* //smx;	# Strip trailing comments
		s/ \s+ \z //smx;		# Strip trailing whitespace
		my $inx = 0;	# First 11 functional are in service
		while (m/ $re /smxg) {
		    my $num_list = $1;
		    my $detail = $2;
		    foreach my $num ( split qr{ / }smx, $num_list ) {
			$num = $num + 0;	# Numify.
			my $id = $oid{$num} or do {
#			This is normal for decayed satellites or Iridium
#			NEXT.
#			warn "No oid for Iridium $num\n";
			    next;
			};
			my $name = "Iridium $num";
			if ($fail) {
			    my $interp = $sladen_interpret_detail{$detail}
				|| $sladen_interpret_detail{''};
			    $interp->( $rslt, $id, $name, $plane );
			} else {
			    my $status = $inx > 10 ?
				_BODY_STATUS_IS_SPARE :
				_BODY_STATUS_IS_OPERATIONAL;
			    exists $exception{$num}
				and $status = $exception{$num};
			    $rslt->{$id} = [ $id, $name,
				$status_portable{kelso_inverse}{$status},
				$plane, $status ];
			}
		    }
		} continue {
		    $inx++;
		}
	    } elsif ( m/ Notes: /smx ) {
		last;
	    } else {	# TODO this is just for debugging.
		0;
	    }
	}

	return $resp;
    }

    # FIXME in the last couple days this has started returning nothing.
    # It looks like -exclude debris excludes everything, as does
    # -exclude rocket.

    # Get Iridium status from Space Track. Unlike the other sources,
    # Space Track does not know whether satellites are in service or
    # not, but it does know about all of them, and whether or not they
    # are on orbit. So the statuses we report are unknown and decayed.
    # Note that the portable status for unknown is
    # BODY_STATUS_IS_TUMBLING. Called dynamically
    sub _iridium_status_spacetrack {	## no critic (ProhibitUnusedPrivateSubroutines)
	my ( $self, undef, $rslt ) = @_;	# $fmt arg not used

	my ( $resp, $data ) = $self->search_name( {
		tle	=> 0,
		status	=> 'all',
		include	=> [ qw{ payload } ],
		format	=> 'legacy',
	    }, 'iridium' );
	$resp->is_success()
	    or return $resp;
	foreach my $body ( @{ $data } ) {
	    # Starting in 2017, the launches were Iridium Next
	    # satellites, which do not flare.
	    $body->{LAUNCH_YEAR} < 2017
		or next;
	    my $oid = $body->{OBJECT_NUMBER};
	    $rslt->{$oid}
		and not $body->{DECAY}
		and next;
	    $rslt->{$oid} = [
		$oid,
		ucfirst lc $body->{OBJECT_NAME},
		defined $body->{DECAY} ?
		( '[D]', "Decayed $body->{DECAY}", _BODY_STATUS_IS_DECAYED ) :
		( '[?]', 'SpaceTrack', _BODY_STATUS_IS_TUMBLING )
	    ];
	}
	$resp->content( join '',
	    map { "$_->[0]\t$_->[1]\t$_->[2]\t$_->[3]\n" }
	    sort { $a->[0] <=> $b->[0] }
	    values %{ $rslt }
	);
	return $resp;
    }

}	# End of local symbol block.

=for html <a name="launch_sites"></a>

=item $resp = $st->launch_sites()

This method returns an HTTP::Response object. If the request succeeds,
the content of the object will be the known launch sites and their
abbreviations in the desired format. If the desired format is
C<'legacy'> or C<'json'> and the method is called in list context, the
second returned item will be a reference to an array containing the
parsed data.

This method takes the following options, specified either command-style
or as a hash reference.

C<-format> specifies the desired format of the retrieved data. Possible
values are C<'xml'>, C<'json'>, C<'html'>, C<'csv'>, and C<'legacy'>,
which is the default. The legacy format is tab-delimited text, such as
was returned by the version 1 interface.

C<-json> specifies JSON format. If you specify both C<-json> and
C<-format> you will get an exception unless you specify C<-format=json>.

This method requires a Space Track username and password. It
implicitly calls the C<login()> method if the session cookie is
missing or expired.  If C<login()> fails, you will get the
HTTP::Response from C<login()>.

If this method succeeds, the response will contain headers

 Pragma: spacetrack-type = launch_sites
 Pragma: spacetrack-source = spacetrack

There are no arguments.

=cut

{
    my @headings = ( 'Abbreviation', 'Launch Site' );

    # Called dynamically
    sub _launch_sites_opts {	## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
	return [
	    'json!'	=> 'Return data in JSON format',
	    'format=s'	=> 'Specify return format',
	];
    }

    sub launch_sites {
	my ( $self, @args ) = @_;

	( my $opt, @args ) = _parse_args( @args );
	my $format = _retrieval_format( launch_sites => $opt );

	my $resp = $self->spacetrack_query_v2( qw{
	    basicspacedata query class launch_site },
	    format	=> $format,
	    orderby	=> 'SITE_CODE asc',
	    qw{ predicates all
	} );
	$resp->is_success()
	    or return $resp;

	$self->_add_pragmata($resp,
	    'spacetrack-type' => 'launch_sites',
	    'spacetrack-source' => 'spacetrack',
	    'spacetrack-interface' => 2,
	);

	'json' ne $format
	    and return $resp;

	my $json = $self->_get_json_object();

	my $data = $json->decode( $resp->content() );

	my %dict;
	foreach my $datum ( @{ $data } ) {
	    defined $datum->{SITE_CODE}
		and $dict{$datum->{SITE_CODE}} = $datum->{LAUNCH_SITE};
	}

	if ( $opt->{json} ) {

	    $resp->content( $json->encode( \%dict ) );

	} else {

	    $resp->content(
		join '',
		join( "\t", @headings ) . "\n",
		map { "$_\t$dict{$_}\n" } sort keys %dict
	    );

	}

	wantarray
	    or return $resp;

	my @table;
	push @table, [ @headings ];
	foreach my $key ( sort keys %dict ) {
	    push @table, [ $key, $dict{$key} ];
	}
	return ( $resp, \@table );
    }
}


=for html <a name="login"></a>

=item $resp = $st->login ( ... )

If any arguments are given, this method passes them to the set ()
method. Then it executes a login to the Space Track web site. The return
is normally the HTTP::Response object from the login. But if no session
cookie was obtained, the return is an HTTP::Response with an appropriate
message and the code set to HTTP_UNAUTHORIZED from HTTP::Status (a.k.a.
401). If a login is attempted without the username and password being
set, the return is an HTTP::Response with an appropriate message and the
code set to HTTP_PRECONDITION_FAILED from HTTP::Status (a.k.a. 412).

A Space Track username and password are required to use this method.

=cut

sub login {
    my ( $self, @args ) = @_;
    delete $self->{_pragmata};
    @args and $self->set( @args );
    ( $self->{username} && $self->{password} ) or
	return HTTP::Response->new (
	    HTTP_PRECONDITION_FAILED, NO_CREDENTIALS);
    $self->{dump_headers} & DUMP_TRACE and warn <<"EOD";
Logging in as $self->{username}.
EOD

    # Do not use the spacetrack_query_v2 method to retrieve the session
    # cookie, unless you like bottomless recursions.
    my $url = $self->_make_space_track_base_url( 2 ) .
    '/ajaxauth/login';
    $self->_dump_request(
	arg	=> [
	    identity => $self->{username},
	    password => $self->{password},
	],
	method	=> 'POST',
	url	=> $url,
    );
    my $resp = $self->_get_agent()->post(
	$url, [
	    identity => $self->{username},
	    password => $self->{password},
	] );

    $resp->is_success()
	or return _mung_login_status( $resp );
    $self->__dump_response( $resp );

    $resp->content() =~ m/ \b failed \b /smxi
	and return HTTP::Response->new( HTTP_UNAUTHORIZED, LOGIN_FAILED );

    $self->_record_cookie_generic( 2 )
	or return HTTP::Response->new( HTTP_UNAUTHORIZED, LOGIN_FAILED );

    $self->{dump_headers} & DUMP_TRACE and warn <<'EOD';
Login successful.
EOD
    return HTTP::Response->new (HTTP_OK, undef, undef, "Login successful.\n");
}

=for html <a name="logout"></a>

=item $st->logout()

This method deletes all session cookies. It returns an HTTP::Response
object that indicates success.

=cut

sub logout {
    my ( $self ) = @_;
    foreach my $spacetrack_interface_info (
	@{ $self->{_space_track_interface} } ) {
	$spacetrack_interface_info
	    or next;
	exists $spacetrack_interface_info->{session_cookie}
	    and $spacetrack_interface_info->{session_cookie} = undef;
	exists $spacetrack_interface_info->{cookie_expires}
	    and $spacetrack_interface_info->{cookie_expires} = 0;
    }
    return HTTP::Response->new(
	HTTP_OK, undef, undef, "Logout successful.\n" );
}

=for html <a name="mccants"></a>

=item $resp = $st->mccants( catalog )

This method retrieves one of several pieces of data that Mike McCants
makes available on his web site. The return is the
L<HTTP::Response|HTTP::Response> object from the retrieval. Valid
catalog names are:

 classified: Classified TLE file (classfd.zip)
 integrated: Integrated TLE file (inttles.zip)
 mcnames: Molczan-format magnitude file (mcnames.zip) REMOVED
 quicksat: Quicksat-format magnitude file (qsmag.zip)
 vsnames: Molczan-format mags of visual bodies (vsnames.zip) REMOVED

The files marked B<REMOVED> have been removed from Mike McCants' web
site. The associated arguments are deprecated, will warn on every use,
and return a C<404> error. Six months after the release of
C<Astro-SpaceTrack> version 0.171, these arguments will produce a fatal
error.

You can specify options as either command-type options (e.g. C<<
mccants( '-file', 'foo.dat', ... ) >>) or as a leading hash reference
(e.g. C<< mccants( { file => 'foo.dat' }, ...) >>). If you specify the
hash reference, option names must be specified in full, without the
leading '-', and the argument list will not be parsed for command-type
options.  If you specify command-type options, they may be abbreviated,
as long as the abbreviation is unique. Errors in either sort result in
an exception being thrown.

The legal options are:

 -file
   specifies the name of the cache file. If the data
   on line are newer than the modification date of
   the cache file, the cache file will be updated.
   Otherwise the data will be returned from the file.
   Either way the content of the file and the content
   of the returned HTTP::Response object end up the
   same.

On success, the content of the returned object is the actual data,
unzipped and with line endings normalized for the current system.

If this method succeeds, the response will contain headers

 Pragma: spacetrack-type = (see below)
 Pragma: spacetrack-source = mccants

The content of the spacetrack-type pragma depends on the catalog
fetched, as follows:

 classified: 'orbit'
 integrated: 'orbit'
 mcnames:    'molczan'
 quicksat:   'quicksat'
 rcs:        'rcs.mccants'
 vsnames:    'molczan'

If the C<file> option was passed, the following additional header will
be provided:

 Pragma: spacetrack-cache-hit = (either true or false)

This can be accessed by the C<cache_hit()> method. If this pragma is
true, the C<Last-Modified> header of the response will contain the
modification time of the file.

No Space Track username and password are required to use this method.

=cut

# Called dynamically
sub _mccants_opts {	## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
    return [
	'file=s'	=> 'Name of cache file',
    ];
}

sub mccants {
    my ( $self, @args ) = @_;

    ( my $opt, @args ) = _parse_args( @args );

    return $self->_get_from_net(
	%{ $opt },
	catalog	=> $args[0],
	post_process	=> sub {
	    my ( undef, $resp, $info ) = @_;	# Invocant unused
	    my ( $content, @zip_opt );
	    defined $info->{member}
		and push @zip_opt, Name => $info->{member};
	    IO::Uncompress::Unzip::unzip( \( $resp->content() ),
		\$content, @zip_opt )
		or return HTTP::Response->new(
		HTTP_NOT_FOUND,
		$IO::Uncompress::Unzip::UnzipError );
	    $resp->content( $content );
	    return $resp;
	},
    );
}

=for html <a name="names"></a>

=item $resp = $st->names (source)

This method retrieves the names of the catalogs for the given source,
either C<'celestrak'>, C<'celestrak_supplemental'>, C<'iridium_status'>,
C<'mccants'>, or C<'spacetrack'>, in the content of
the given HTTP::Response object. If the argument is not one of the
supported values, the C<$resp> object represents a 404 (Not found)
error.

In list context, you also get a reference to a list of two-element
lists; each inner list contains the description and the catalog name, in
that order (suitable for inserting into a Tk Optionmenu). If the
argument is not one of the supported values, the second return will be
C<undef>.

No Space Track username and password are required to use this method,
since all it is doing is returning data kept by this module.

=cut

sub names {
    my ( $self, $name ) = @_;
    delete $self->{_pragmata};

    my $src = $self->__catalog( $name )
	or return HTTP::Response->new(
	    HTTP_NOT_FOUND, "Data source '$name' not found.");

    my @list;
    foreach my $cat (sort keys %$src) {
	push @list, defined ($src->{$cat}{number}) ?
	    "$cat ($src->{$cat}{number}): $src->{$cat}{name}\n" :
	    "$cat: $src->{$cat}{name}\n";
	    defined $src->{$cat}{note}
		and $list[-1] .= "    $src->{$cat}{note}\n";
    }
    my $resp = HTTP::Response->new (HTTP_OK, undef, undef, join ('', @list));
    return $resp unless wantarray;
    @list = ();
    foreach my $cat (sort {$src->{$a}{name} cmp $src->{$b}{name}}
	keys %$src) {
	push @list, [$src->{$cat}{name}, $cat];
	defined $src->{$cat}{note}
	    and push @{ $list[-1] }, $src->{$cat}{note};
    }
    return ($resp, \@list);
}

=for html <a name="retrieve"></a>

=item $resp = $st->retrieve (number_or_range ...)

This method retrieves the latest element set for each of the given
satellite ID numbers (also known as SATCAT IDs, NORAD IDs, or OIDs) from
The Space Track web site.  Non-numeric catalog numbers are ignored, as
are (at a later stage) numbers that do not actually represent a
satellite.

A Space Track username and password are required to use this method.

If this method succeeds, the response will contain headers

 Pragma: spacetrack-type = orbit
 Pragma: spacetrack-source = spacetrack

These can be accessed by C<< $st->content_type( $resp ) >> and
C<< $st->content_source( $resp ) >> respectively.

Number ranges are represented as 'start-end', where both 'start' and
'end' are catalog numbers. If 'start' > 'end', the numbers will be
taken in the reverse order. Non-numeric ranges are ignored.

You can specify options for the retrieval as either command-type options
(e.g. C<< retrieve ('-last5', ...) >>) or as a leading hash reference
(e.g. C<< retrieve ({last5 => 1}, ...) >>). If you specify the hash
reference, option names must be specified in full, without the leading
'-', and the argument list will not be parsed for command-type options.
If you specify command-type options, they may be abbreviated, as long as
the abbreviation is unique. Errors in either sort result in an exception
being thrown.

The legal options are:

 -descending
   specifies the data be returned in descending order.
 -end_epoch date
   specifies the end epoch for the desired data.
 -format format_name
   specifies the format in which the data are retrieved.
 -json
   specifies the TLE be returned in JSON format.
 -last5
   specifies the last 5 element sets be retrieved.
   Ignored if start_epoch, end_epoch or since_file is
   specified.
 -start_epoch date
   specifies the start epoch for the desired data.
 -since_file number
   specifies that only data since the given Space Track
   file number be retrieved.
 -sort type
   specifies how to sort the data. Legal types are
   'catnum' and 'epoch', with 'catnum' the default.

The C<-format> option takes any argument supported by the Space Track
interface: C<tle>, C<3le>, C<json>, C<csv>, C<html>, or C<xml>.
Specifying C<-json> is equivalent to specifying C<-format json>, and if
you specify C<-json>, specifying C<-format> with any other value than
C<'json'> results in an exception being thrown. In addition, you can
specify format C<'legacy'> which is equivalent to C<'tle'> if the
C<with_name> attribute is false, or C<'3le'> (but without the leading
C<'0 '> before the common name) if C<with_name> is true. The default is
C<'legacy'> unless C<-json> is specified.

If you specify either start_epoch or end_epoch, you get data with epochs
at least equal to the start epoch, but less than the end epoch (i.e. the
interval is closed at the beginning but open at the end). If you specify
only one of these, you get a one-day interval. Dates are specified
either numerically (as a Perl date) or as numeric year-month-day (and
optional hour, hour:minute, or hour:minute:second), punctuated by any
non-numeric string. It is an error to specify an end_epoch before the
start_epoch.

If you are passing the options as a hash reference, you must specify
a value for the Boolean options 'descending' and 'last5'. This value is
interpreted in the Perl sense - that is, undef, 0, and '' are false,
and anything else is true.

In order not to load the Space Track web site too heavily, data are
retrieved in batches of 200. Ranges will be subdivided and handled in
more than one retrieval if necessary. To limit the damage done by a
pernicious range, ranges greater than the max_range setting (which
defaults to 500) will be ignored with a warning to STDERR.

If you specify C<-json> and more than one retrieval is needed, data from
retrievals after the first B<may> have field C<_file_of_record> added.
This is because of the theoretical possibility that the database may be
updated between the first and last queries, and therefore taking the
maximum C<FILE> from queries after the first may cause updates to be
skipped. The C<_file_of_record> key will appear only in data having a
C<FILE> value greater than the largest C<FILE> in the first retrieval.

This method implicitly calls the C<login()> method if the session cookie
is missing or expired. If C<login()> fails, you will get the
HTTP::Response from C<login()>.

If this method succeeds, a 'Pragma: spacetrack-type = orbit' header is
added to the HTTP::Response object returned.

=cut

# Called dynamically
sub _retrieve_opts {	## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
    return [
	_get_retrieve_options(),
    ];
}

sub retrieve {
    my ( $self, @args ) = @_;
    delete $self->{_pragmata};

    @args = $self->_parse_retrieve_args( @args );
    my $opt = _parse_retrieve_dates( shift @args );

    my $rest = $self->_convert_retrieve_options_to_rest( $opt );

    @args = $self->_expand_oid_list( @args )
	or return HTTP::Response->new( HTTP_PRECONDITION_FAILED, NO_CAT_ID );

    my $no_execute = $self->getv( 'dump_headers' ) & DUMP_DRY_RUN;

##  $rest->{orderby} = 'EPOCH desc';

    my $accumulator = _accumulator_for (
	$no_execute ?
	    ( json => { pretty => 1 } ) :
	    ( $rest->{format}, {
		    file => 1,
		    pretty => $self->getv( 'pretty' )
		},
	    )
    );

    while ( @args ) {

	my @batch = splice @args, 0, $RETRIEVAL_SIZE;
	$rest->{OBJECT_NUMBER} = _stringify_oid_list( {
		separator	=> ',',
		range_operator	=> '--',
	    }, @batch );

	my $resp = $self->spacetrack_query_v2(
	    basicspacedata	=> 'query',
	    _sort_rest_arguments( $rest )
	);

	$resp->is_success()
	    or $resp->code() == HTTP_I_AM_A_TEAPOT
	    or return $resp;

	$accumulator->( $self, $resp );

    }

    ( my $data = $accumulator->( $self ) )
	or return HTTP::Response->new ( HTTP_NOT_FOUND, NO_RECORDS );

    ref $data
	and $data = $self->_get_json_object()->encode( $data );

    $no_execute
	and return HTTP::Response->new(
	    HTTP_I_AM_A_TEAPOT, undef, undef, $data );

    my $resp = HTTP::Response->new( HTTP_OK, COPACETIC, undef,
	$data );

    $self->_convert_content( $resp );
    $self->_add_pragmata( $resp,
	'spacetrack-type' => 'orbit',
	'spacetrack-source' => 'spacetrack',
	'spacetrack-interface' => 2,
    );
    return $resp;
}

{

    my %rest_sort_map = (
	catnum	=> 'OBJECT_NUMBER',
	epoch	=> 'EPOCH',
    );

    sub _convert_retrieve_options_to_rest {
	my ( $self, $opt ) = @_;

	my %rest = (
	    class	=> 'tle_latest',
	);

	if ( $opt->{start_epoch} || $opt->{end_epoch} ) {
	    $rest{EPOCH} = join '--', map { _rest_date( $opt->{$_} ) }
	    qw{ _start_epoch _end_epoch };
	    $rest{class} = 'tle';
	}

	$rest{orderby} = ( $rest_sort_map{$opt->{sort} || 'catnum'} ||
	    'OBJECT_NUMBER' )
	.  ( $opt->{descending} ? ' desc' : ' asc' );

	if ( $opt->{since_file} ) {
	    $rest{FILE} = ">$opt->{since_file}";
	    $rest{class} = 'tle';
	}

	if ( $opt->{status} && $opt->{status} ne 'onorbit' ) {
	    $rest{class} = 'tle';
	}

	foreach my $name (
	    qw{ class format },
	    qw{ ECCENTRICITY FILE MEAN_MOTION OBJECT_NAME },
	) {
	    defined $opt->{$name}
		and $rest{$name} = $opt->{$name};
	}

	if ( 'legacy' eq $rest{format} ) {
	    if ( $self->{with_name} ) {
		$rest{format} = '3le';
		defined $rest{predicates}
		    or $rest{predicates} = 'OBJECT_NAME,TLE_LINE1,TLE_LINE2';
	    } else {
		$rest{format} = 'tle';
	    }
	}

	$rest{class} eq 'tle_latest'
	    and $rest{ORDINAL} = $opt->{last5} ? '1--5' : 1;

	return \%rest;
    }

}

{
    my @heading_info = (
	[ undef,	OBJECT_NUMBER	=> 'Catalog Number' ],
	[ undef,	OBJECT_NAME	=> 'Common Name' ],
	[ undef,	OBJECT_ID	=> 'International Designator' ],
	[ undef,	COUNTRY		=> 'Country' ],
	[ undef,	LAUNCH		=> 'Launch Date' ],
	[ undef,	SITE		=> 'Launch Site' ],
	[ undef,	DECAY		=> 'Decay Date' ],
	[ undef,	PERIOD		=> 'Period' ],
	[ undef,	APOGEE		=> 'Apogee' ],
	[ undef,	PERIGEE		=> 'Perigee' ],
	[ 'comment',	COMMENT		=> 'Comment' ],
	[ undef,	RCSVALUE	=> 'RCS' ],
    );

    sub _search_heading_order {
	my ( $opt ) = @_;
	return ( map { $_->[1] }
	    _search_heading_relevant( $opt )
	);
    }

    sub _search_heading_relevant {
	my ( $opt ) = @_;
	return (
	    grep { ! defined $_->[0] || $opt->{$_->[0]} }
	    @heading_info
	);
    }

    sub _search_heading_hash_ref {
	my ( $opt ) = @_;
	return {
	    map { $_->[1] => $_->[2] }
	    _search_heading_relevant( $opt )
	};
    }

}

sub _search_rest {
    my ( $self, $pred, $xfrm, @args ) = @_;
    delete $self->{_pragmata};

    ( my $opt, @args ) = $self->_parse_search_args( @args );

    my $headings = _search_heading_hash_ref( $opt );
    my @heading_order = _search_heading_order( $opt );

    if ( $pred eq 'OBJECT_NUMBER' ) {

	@args = $self->_expand_oid_list( @args )
	    or return HTTP::Response->new(
		HTTP_PRECONDITION_FAILED, NO_CAT_ID );

	@args = (
	    _stringify_oid_list( {
		    separator	=> ',',
		    range_operator	=> '--',
		},
		@args
	    )
	);

    }

    my $rest_args = $self->_convert_search_options_to_rest( $opt );
    if ( $opt->{tle} || 'legacy' eq $opt->{format} ) {
	$rest_args->{format} = 'json'
    } else {
	$rest_args->{format} = $opt->{format};
    }

    my $class = defined $rest_args->{class} ?
	$rest_args->{class} :
	DEFAULT_SPACE_TRACK_REST_SEARCH_CLASS;

    my $accumulator = _accumulator_for( $rest_args->{format} );

    foreach my $search_for ( map { $xfrm->( $_, $class ) } @args ) {

	my $rslt;
	{
	    local $self->{pretty} = 0;
	    $rslt = $self->__search_rest_raw( %{ $rest_args },
		$pred, $search_for );
	}

	$rslt->is_success()
	    or return $rslt;

	$accumulator->( $self, $rslt );

    }

    my ( $content, $data ) = $accumulator->( $self );

    if ( $opt->{tle} ) {
	defined $opt->{format}
	    or $opt->{format} = 'tle';
	ARRAY_REF eq ref $data
	    or Carp::croak "Format $rest_args->{format} does not support TLE retrieval";
	my $ropt = _remove_search_options( $opt );

	my $rslt = $self->retrieve( $ropt,
	    map { $_->{OBJECT_NUMBER} } @{ $data } );

	return $rslt;

    } else {

	if ( 'legacy' eq $opt->{format} ) {
	    $content = '';
	    foreach my $datum (
		$headings,
		@{ $data }
	    ) {
		$content .= join( "\t",
		    map { defined $datum->{$_} ? $datum->{$_} : '' }
		    @heading_order
		) . "\n";
	    }
	}

	my $rslt = HTTP::Response->new( HTTP_OK, undef, undef, $content );
	$self->_add_pragmata( $rslt,
	    'spacetrack-type' => 'search',
	    'spacetrack-source' => 'spacetrack',
	    'spacetrack-interface' => 2,
	);
	wantarray
	    and $data
	    and return ( $rslt, $data );
	return $rslt;
    }

    # Note - if we're doing the tab output, the names and order are:
    # Catalog Number: OBJECT_NUMBER
    # Common Name: OBJECT_NAME
    # International Designator: OBJECT_ID
    # Country: COUNTRY
    # Launch Date: LAUNCH (yyyy-mm-dd)
    # Launch Site: SITE
    # Decay Date: DECAY
    # Period: PERIOD
    # Incl.: INCLINATION
    # Apogee: APOGEE
    # Perigee: PERIGEE
    # RCS: RCSVALUE

}

sub __search_rest_raw {
    my ( $self, %args ) = @_;
    delete $self->{_pragmata};
    # https://beta.space-track.org/basicspacedata/query/class/satcat/CURRENT/Y/OBJECT_NUMBER/25544/predicates/all/limit/10,0/metadata/true

    %args
	or return HTTP::Response->new( HTTP_PRECONDITION_FAILED, NO_CAT_ID );

    exists $args{class}
	or $args{class} = DEFAULT_SPACE_TRACK_REST_SEARCH_CLASS;
    $args{class} ne 'satcat'
	or exists $args{CURRENT}
	or $args{CURRENT} = 'Y';
    exists $args{format}
	or $args{format} = 'json';
    exists $args{predicates}
	or $args{predicates} = 'all';
    exists $args{orderby}
	or $args{orderby} = 'OBJECT_NUMBER asc';
#   exists $args{limit}
#	or $args{limit} = 1000;

    my $resp = $self->spacetrack_query_v2(
	basicspacedata	=> 'query',
	_sort_rest_arguments( \%args ),
    );
#   $resp->content( $content );
#   $self->_convert_content( $resp );
    $self->_add_pragmata( $resp,
	'spacetrack-type' => 'orbit',
	'spacetrack-source' => 'spacetrack',
	'spacetrack-interface' => 2,
    );
    return $resp;
}

=for html <a name="search_date"></a>

=item $resp = $st->search_date (date ...)

This method searches the Space Track database for objects launched on
the given date. The date is specified as year-month-day, with any
non-digit being legal as the separator. You can omit -day or specify it
as 0 to get all launches for the given month. You can omit -month (or
specify it as 0) as well to get all launches for the given year.

A Space Track username and password are required to use this method.

You can specify options for the search as either command-type options
(e.g. C<< $st->search_date (-status => 'onorbit', ...) >>) or as a
leading hash reference (e.g.
C<< $st->search_date ({status => onorbit}, ...) >>). If you specify the
hash reference, option names must be specified in full, without the
leading '-', and the argument list will not be parsed for command-type
options.  Options that take multiple values (i.e. 'exclude') must have
their values specified as a hash reference, even if you only specify one
value - or none at all.

If you specify command-type options, they may be abbreviated, as long as
the abbreviation is unique. Errors in either sort of specification
result in an exception being thrown.

In addition to the options available for C<retrieve()>, the following
options may be specified:

 -exclude
   specifies the types of bodies to exclude. The
   value is one or more of 'payload', 'debris', 'rocket',
   'unknown', 'tba', or 'other'. If you specify this as a
   command-line option you may either specify this more
   than once or specify the values comma-separated.
 -include
   specifies the types of bodies to include. The possible
   values are the same as for -exclude. If you specify a
   given body as both included and excluded it is included.
 -rcs
   used to specify that the radar cross-section returned
   by the search was to be appended to the name, in the form
   --rcs radar_cross_section. Beginning with version 0.086_02
   it does nothing, since as of August 18 2014 Space Track
   no longer provides quantitative RCS data.
 -status
   specifies the desired status of the returned body (or
   bodies). Must be 'onorbit', 'decayed', or 'all'.  The
   default is 'onorbit'. Specifying a value other than the
   default will cause the -last5 option to be ignored.
   Note that this option represents status at the time the
   search was done; you can not combine it with the
   retrieve() date options to find bodies onorbit as of a
   given date in the past.
 -tle
   specifies that you want TLE data retrieved for all
   bodies that satisfy the search criteria. This is
   true by default, but may be negated by specifying
   -notle ( or { tle => 0 } ). If negated, the content
   of the response object is the results of the search,
   one line per body found, with the fields tab-
   delimited.
 -comment
   specifies that you want the comment field. This will
   not appear in the TLE data, but in the satcat data
   returned in array context, or if C<-notle> is
   specified. The default is C<-nocomment> for backward
   compatibility.

The C<-rcs> option does not work with all values of C<-format>. An
exception will be thrown unless C<-format> is C<'tle'>, C<'3le'>,
C<'legacy'>, or C<'json'>.

Examples:

 search_date (-status => 'onorbit', -exclude =>
    'debris,rocket', -last5 '2005-12-25');
 search_date (-exclude => 'debris',
    -exclude => 'rocket', '2005/12/25');
 search_date ({exclude => ['debris', 'rocket']},
    '2005-12-25');
 search_date ({exclude => 'debris,rocket'}, # INVALID!
    '2005-12-25');
 search_date ( '-notle', '2005-12-25' );

The C<-exclude> option is implemented in terms of the C<OBJECT_TYPE>
predicate, which is one of the values C<'PAYLOAD'>, C<'ROCKET BODY'>,
C<'DEBRIS'>, C<'UNKNOWN'>, C<'TBA'>, or C<'OTHER'>. It works by
selecting all values other than the ones specifically excluded. The
C<'TBA'> status was introduced October 1 2013, supposedly replacing
C<'UNKNOWN'>, but I have retained both.

This method implicitly calls the C<login()> method if the session cookie
is missing or expired. If C<login()> fails, you will get the
HTTP::Response from C<login()>.

What you get on success depends on the value specified for the -tle
option.

Unless you explicitly specified C<-notle> (or C<< { tle => 0 } >>), this
method returns an HTTP::Response object whose content is the relevant
element sets. It will also have the following headers set:

 Pragma: spacetrack-type = orbit
 Pragma: spacetrack-source = spacetrack

These can be accessed by C<< $st->content_type( $resp ) >> and
C<< $st->content_source( $resp ) >> respectively.

If you explicitly specified C<-notle> (or C<< { tle => 0 } >>), this
method returns an HTTP::Response object whose content is in the format
specified by the C<-format> retrieval option (q.v.). If the format is
C<'legacy'> (the default if C<-json> is not specified) the content
mimics what was returned under the version 1 interface; that is, it is
the results of the relevant search, one line per object found. Within a
line the fields are tab-delimited, and occur in the same order as the
underlying web page. The first line of the content is the header lines
from the underlying web page.

The returned object will also have the following headers set if
C<-notle> is specified:

 Pragma: spacetrack-type = search
 Pragma: spacetrack-source = spacetrack

If you call this method in list context, the first element of the
returned object is the aforementioned HTTP::Response object, and the
second is a reference to an array containing the search results. The
first element is a reference to an array containing the header lines
from the web page. Subsequent elements are references to arrays
containing the actual search results.

=cut

*_search_date_opts = \&_get_search_options;

sub search_date {	## no critic (RequireArgUnpacking)
    splice @_, 1, 0, LAUNCH => \&_format_launch_date_rest;
    goto &_search_rest;
}


=for html <a name="search_decay"></a>

=item $resp = $st->search_decay (decay ...)

This method searches the Space Track database for objects decayed on
the given date. The date is specified as year-month-day, with any
non-digit being legal as the separator. You can omit -day or specify it
as 0 to get all decays for the given month. You can omit -month (or
specify it as 0) as well to get all decays for the given year.

The options are the same as for C<search_date()>.

A Space Track username and password are required to use this method.

What you get on success depends on the value specified for the -tle
option.

Unless you explicitly specified C<-notle> (or C<< { tle => 0 } >>), this
method returns an HTTP::Response object whose content is the relevant
element sets. It will also have the following headers set:

 Pragma: spacetrack-type = orbit
 Pragma: spacetrack-source = spacetrack

These can be accessed by C<< $st->content_type( $resp ) >> and
C<< $st->content_source( $resp ) >> respectively.

If you explicitly specified C<-notle> (or C<< { tle => 0 } >>), this
method returns an HTTP::Response object whose content is the results of
the relevant search, one line per object found. Within a line the fields
are tab-delimited, and occur in the same order as the underlying web
page. The first line of the content is the header lines from the
underlying web page. It will also have the following headers set:

 Pragma: spacetrack-type = search
 Pragma: spacetrack-source = spacetrack

If you call this method in list context, the first element of the
returned object is the aforementioned HTTP::Response object, and the
second is a reference to an array containing the search results. The
first element is a reference to an array containing the header lines
from the web page. Subsequent elements are references to arrays
containing the actual search results.

=cut

*_search_decay_opts = \&_get_search_options;

sub search_decay {	## no critic (RequireArgUnpacking)
    splice @_, 1, 0, DECAY => \&_format_launch_date_rest;
    goto &_search_rest;
}


=for html <a name="search_id"></a>

=item $resp = $st->search_id (id ...)

This method searches the Space Track database for objects having the
given international IDs. The international ID is the last two digits of
the launch year (in the range 1957 through 2056), the three-digit
sequence number of the launch within the year (with leading zeroes as
needed), and the piece (A through ZZZ, with A typically being the
payload). You can omit the piece and get all pieces of that launch, or
omit both the piece and the launch number and get all launches for the
year. There is no mechanism to restrict the search to a given on-orbit
status, or to filter out debris or rocket bodies.

The options are the same as for C<search_date()>.

A Space Track username and password are required to use this method.

This method implicitly calls the C<login()> method if the session cookie
is missing or expired. If C<login()> fails, you will get the
HTTP::Response from C<login()>.

What you get on success depends on the value specified for the C<-tle>
option.

Unless you explicitly specified C<-notle> (or C<< { tle => 0 } >>), this
method returns an HTTP::Response object whose content is the relevant
element sets. It will also have the following headers set:

 Pragma: spacetrack-type = orbit
 Pragma: spacetrack-source = spacetrack

These can be accessed by C<< $st->content_type( $resp ) >> and
C<< $st->content_source( $resp ) >> respectively.

If you explicitly specified C<-notle> (or C<< { tle => 0 } >>), this
method returns an HTTP::Response object whose content is the results of
the relevant search, one line per object found. Within a line the fields
are tab-delimited, and occur in the same order as the underlying web
page. The first line of the content is the header lines from the
underlying web page. It will also have the following headers set:

 Pragma: spacetrack-type = search
 Pragma: spacetrack-source = spacetrack

If you call this method in list context, the first element of the
returned object is the aforementioned HTTP::Response object, and the
second is a reference to an array containing the search results. The
first element is a reference to an array containing the header lines
from the web page. Subsequent elements are references to arrays
containing the actual search results.
 
=cut

*_search_id_opts = \&_get_search_options;

sub search_id {	## no critic (RequireArgUnpacking)
    splice @_, 1, 0, OBJECT_ID => \&_format_international_id_rest;
    goto &_search_rest;
}


=for html <a name="search_name"></a>

=item $resp = $st->search_name (name ...)

This method searches the Space Track database for the named objects.
Matches are case-insensitive and all matches are returned.

The options are the same as for C<search_date()>. The C<-status> option
is known to work, but I am not sure about the efficacy the C<-exclude>
option.

A Space Track username and password are required to use this method.

This method implicitly calls the C<login()> method if the session cookie
is missing or expired. If C<login()> fails, you will get the
HTTP::Response from C<login()>.

What you get on success depends on the value specified for the -tle
option.

Unless you explicitly specified C<-notle> (or C<< { tle => 0 } >>), this
method returns an HTTP::Response object whose content is the relevant
element sets. It will also have the following headers set:

 Pragma: spacetrack-type = orbit
 Pragma: spacetrack-source = spacetrack

These can be accessed by C<< $st->content_type( $resp ) >> and
C<< $st->content_source( $resp ) >> respectively.

If you explicitly specified C<-notle> (or C<< { tle => 0 } >>), this
method returns an HTTP::Response object whose content is the results of
the relevant search, one line per object found. Within a line the fields
are tab-delimited, and occur in the same order as the underlying web
page. The first line of the content is the header lines from the
underlying web page. It will also have the following headers set:

 Pragma: spacetrack-type = search
 Pragma: spacetrack-source = spacetrack

If you call this method in list context, the first element of the
returned object is the aforementioned HTTP::Response object, and the
second is a reference to an array containing the search results. The
first element is a reference to an array containing the header lines
from the web page. Subsequent elements are references to arrays
containing the actual search results.

=cut

*_search_name_opts = \&_get_search_options;

sub search_name {	## no critic (RequireArgUnpacking)
    splice @_, 1, 0, OBJECT_NAME => sub { return "~~$_[0]" };
    goto &_search_rest;
}


=for html <a name="search_oid"></a>

=item $resp = $st->search_oid (name ...)

This method searches the Space Track database for the given Space Track
IDs (also known as OIDs, hence the method name).

B<Note> that in effect this is just a stupid, inefficient version of
C<retrieve()>, which does not understand ranges. Unless you
assert C<-notle> or call it in list context to get the
search data, you should simply call
C<retrieve()> instead.

In addition to the options available for C<retrieve()>, the following
option may be specified:

 rcs
   Used to specify that the radar cross-section returned by
   the search is to be appended to the name, in the form
   --rcs radar_cross_section. Starting with version 0.086_02
   it does nothing, since as of August 18 2014 Space Track
   no longer provides quantitative RCS data.
 tle
   specifies that you want TLE data retrieved for all
   bodies that satisfy the search criteria. This is
   true by default, but may be negated by specifying
   -notle ( or { tle => 0 } ). If negated, the content
   of the response object is the results of the search,
   one line per body found, with the fields tab-
   delimited.

If you specify C<-notle>, all other options are ignored, except for
C<-descending>.

A Space Track username and password are required to use this method.

This method implicitly calls the C<login()> method if the session cookie
is missing or expired. If C<login()> fails, you will get the
HTTP::Response from C<login()>.

What you get on success depends on the value specified for the -tle
option.

Unless you explicitly specified C<-notle> (or C<< { tle => 0 } >>), this
method returns an HTTP::Response object whose content is the relevant
element sets. It will also have the following headers set:

 Pragma: spacetrack-type = orbit
 Pragma: spacetrack-source = spacetrack

If the C<content_type()> method returns C<'box_score'>, you can expect
a content-source value of C<'spacetrack'>.

If you explicitly specified C<-notle> (or C<< { tle => 0 } >>), this
method returns an HTTP::Response object whose content is the results of
the relevant search, one line per object found. Within a line the fields
are tab-delimited, and occur in the same order as the underlying web
page. The first line of the content is the header lines from the
underlying web page. It will also have the following headers set:

 Pragma: spacetrack-type = search
 Pragma: spacetrack-source = spacetrack

If you call this method in list context, the first element of the
returned object is the aforementioned HTTP::Response object, and the
second is a reference to an array containing the search results. The
first element is a reference to an array containing the header lines
from the web page. Subsequent elements are references to arrays
containing the actual search results.

=cut

*_search_oid_opts = \&_get_search_options;

sub search_oid {	## no critic (RequireArgUnpacking)
##  my ( $self, @args ) = @_;
    splice @_, 1, 0, OBJECT_NUMBER => sub { return $_[0] };
    goto &_search_rest;
}

sub _check_range {
    my ( $self, $lo, $hi ) = @_;
    ($lo, $hi) = ($hi, $lo) if $lo > $hi;
    $lo or $lo = 1;	# 0 is illegal
    $hi - $lo >= $self->{max_range} and do {
	Carp::carp <<"EOD";
Warning - Range $lo-$hi ignored because it is greater than the
	  currently-set maximum of $self->{max_range}.
EOD
	return;
    };
    return ( $lo, $hi );
}

=for html <a name="set"></a>

=item $st->set ( ... )

This is the mutator method for the object. It can be called explicitly,
but other methods as noted may call it implicitly also. It croaks if
you give it an odd number of arguments, or if given an attribute that
either does not exist or cannot be set.

For the convenience of the shell method we return a HTTP::Response
object with a success status if all goes well. But if we encounter an
error we croak.

See L</Attributes> for the names and functions of the attributes.

=cut

# Called dynamically
sub _readline_complete_command_set {	## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
    # my ( $self, $text, $line, $start, $cmd_line ) = @_;
    my ( undef, undef, undef, undef, $cmd_line ) = @_;
    @{ $cmd_line } % 2
	or return;	# Can't complete arguments
    goto &_readline_complete_command_get;
}

sub set {	## no critic (ProhibitAmbiguousNames)
    my ($self, @args) = @_;
    delete $self->{_pragmata};
    while ( @args > 1 ) {
	my $name = shift @args;
	Carp::croak "Attribute $name may not be set. Legal attributes are ",
		join (', ', sort keys %mutator), ".\n"
	    unless $mutator{$name};
	my $value = $args[0];
	$mutator{$name}->( $self, $name, $value, \@args );
	shift @args;
    }
    @args
	and Carp::croak __PACKAGE__, "->set() specifies no value for @args";
    my $resp = HTTP::Response->new( HTTP_OK, COPACETIC, undef, COPACETIC );
    $self->_add_pragmata( $resp,
	'spacetrack-type' => 'set',
    );
    $self->__dump_response( $resp );
    return $resp;
}


=for html <a name="shell"></a>

=item $st->shell ()

This method implements a simple shell. Any public method name except
'new' or 'shell' is a command, and its arguments if any are parameters.
We use L<Text::ParseWords|Text::ParseWords> to parse the line, and blank
lines or lines beginning with a hash mark ('#') are ignored. Input is
via Term::ReadLine if that is available. If not, we do the best we can.

We also recognize 'bye' and 'exit' as commands, which terminate the
method. In addition, 'show' is recognized as a synonym for 'get', and
'get' (or 'show') without arguments is special-cased to list all
attribute names and their values. Attributes listed without a value have
the undefined value.

There are also a couple meta-commands, that in effect wrap other
commands. These are specified before the command, and can (depending on
the meta-command) have effect either right before the command is
executed, right after it is executed, or both. If more than one
meta-command is specified, the before-actions take place in the order
specified, and the after-actions in the reverse of the order specified.

The 'time' meta-command times the command, and writes the timing to
standard error before any output from the command is written.

The 'olist' meta-command turns TLE data into an observing list. This
only affects results with C<spacetrack-type> of C<'orbit'>. If the
content is affected, the C<spacetrack-type> will be changed to
C<'observing-list'>. This meta-command is experimental, and may change
function or be retracted.  It is unsupported when applied to commands
that do not return TLE data.

For commands that produce output, we allow a sort of pseudo-redirection
of the output to a file, using the syntax ">filename" or ">>filename".
If the ">" is by itself the next argument is the filename. In addition,
we do pseudo-tilde expansion by replacing a leading tilde with the
contents of environment variable HOME. Redirection can occur anywhere
on the line. For example,

 SpaceTrack> catalog special >special.txt

sends the "Special Interest Satellites" to file special.txt. Line
terminations in the file should be appropriate to your OS.

Redirections will not be recognized as such if quoted or escaped. That
is, both C<< >foo >> and C<< >'foo' >> (without the double quotes) are
redirections to file F<foo>, but both "C<< '>foo' >>" and C<< \>foo >>
are arguments whose value is C<< >foo >>.

This method can also be called as a subroutine - i.e. as

 Astro::SpaceTrack::shell (...)

Whether called as a method or as a subroutine, each argument passed
(if any) is parsed as though it were a valid command. After all such
have been executed, control passes to the user. Unless, of course,
one of the arguments was 'exit'.

Unlike most of the other methods, this one returns nothing.

=cut

my $rdln;
my %known_meta = (
    olist	=> {
	after	=> sub {
	    my ( $self, undef, $rslt ) = @_;	# Context unused

	    ARRAY_REF eq ref $rslt
		and return;
	    $rslt->is_success()
		and 'orbit' eq ( $self->content_type( $rslt ) || '' )
		or return;

	    my $content = $rslt->content();
	    my @lines;

	    if ( $content =~ m/ \A [[]? [{] /smx ) {
		my $data = $self->_get_json_object()->decode( $content );
		foreach my $datum ( @{ $data } ) {
		    push @lines, [
			sprintf '%05d', $datum->{OBJECT_NUMBER},
			defined $datum->{OBJECT_NAME} ? $datum->{OBJECT_NAME} :
			(),
		    ];
		}
	    } else {

		my @name;

		foreach ( split qr{ \n }smx, $content ) {
		    if ( m/ \A 1 \s+ ( \d+ ) /smx ) {
			splice @name, 1;
			push @lines, [ sprintf( '%05d', $1 ), @name ];
			@name = ();
		    } elsif ( m/ \A 2 \s+ \d+ /smx || m/ \A \s* [#] /smx ) {
		    } else {
			push @name, $_;
		    }
		}
	    }

	    foreach ( $rslt->header( pragma => undef ) ) {
		my ( $name, $value ) = split qr{ \s* = \s* }smx, $_, 2;
		'spacetrack-type' eq $name
		    and $value = 'observing_list';
		$self->_add_pragmata( $rslt, $name, $value );
	    }

	    $rslt->content( join '', map { "$_\n" } @lines );

	    {
		local $" = '';	# Make "@a" equivalent to join '', @a.
		$rslt->content( join '',
		    map { "@$_\n" }
		    sort { $a->[0] <=> $b->[0] }
		    @lines
		);
	    }
	    $self->__dump_response( $rslt );
	    return;
	},
    },
    time	=> {
	before	=> sub {
	    my ( undef, $context ) = @_;	# Invocant unused
	    eval {
		require Time::HiRes;
		$context->{start_time} = Time::HiRes::time();
		1;
	    } or warn 'No timings available. Can not load Time::HiRes';
	    return;
	},
	after	=> sub {
	    my ( undef, $context ) = @_;	# Invocant unused
	    $context->{start_time}
		and warn sprintf "Elapsed time: %.2f seconds\n",
		    Time::HiRes::time() - $context->{start_time};
	    return;
	}
    },
);

my $readline_word_break_re;

{
    my %alias = (
	show	=> 'get',
    );

    sub _verb_alias {
	my ( $verb ) = @_;
	return $alias{$verb} || $verb;
    }
}

sub shell {
    my @args = @_;
    my $self = _instance( $args[0], __PACKAGE__ ) ? shift @args :
	Astro::SpaceTrack->new (addendum => <<'EOD');

'help' gets you a list of valid commands.
EOD

    my $stdout = \*STDOUT;
    my $read;

    unshift @args, 'banner' if $self->{banner} && !$self->{filter};
    # Perl::Critic wants IO::Interactive::is_interactive() here. But
    # that assumes we're using the *ARGV input mechanism, which we're
    # not (command arguments are SpaceTrack commands.) Also, we would
    # like to be prompted even if output is to a pipe, but the
    # recommended module calls that non-interactive even if input is
    # from a terminal. So:
    my $interactive = -t STDIN;
    while (1) {
	my $buffer;
	if (@args) {
	    $buffer = shift @args;
	} else {
	    $read ||= $interactive ? ( eval {
		    $self->_get_readline( $stdout )
		} || sub { print { $stdout } $self->getv( 'prompt' ); return <STDIN> } ) :
		sub { return<STDIN> };
	    $buffer = $read->();
	}
	last unless defined $buffer;

	$buffer =~ s/ \A \s+ //smx;
	$buffer =~ s/ \s+ \z //smx;
	next unless $buffer;
	next if $buffer =~ m/ \A [#] /smx;

	# Break the buffer up into tokens, but leave quotes and escapes
	# in place, so that (e.g.) '\>foo' is seen as an argument, not a
	# redirection.

	my @cmdarg = Text::ParseWords::parse_line( '\s+', 1, $buffer );

	# Pull off any redirections.

	my $redir = '';
	@cmdarg = map {
	    m/ \A > /smx ? do {$redir = $_; ()} :
	    $redir =~ m/ \A >+ \z /smx ? do {$redir .= $_; ()} :
	    $_
	} @cmdarg;

	# Rerun everything through parse_line again, but with the $keep
	# argument false. This should not create any more tokens, it
	# should just un-quote and un-escape the data.

	@cmdarg = map { Text::ParseWords::parse_line( qr{ \s+ }, 0, $_ ) } @cmdarg;
	$redir ne ''
	    and ( $redir ) = Text::ParseWords::parse_line ( qr{ \s+ }, 0, $redir );

	$redir =~ s/ \A (>+) ~ /$1$ENV{HOME}/smx;
	my $verb = lc shift @cmdarg;

	my %meta_command = (
	    before	=> [],
	    after	=> [],
	);

	while ( my $def = $known_meta{$verb} ) {
	    my %context;
	    foreach my $key ( qw{ before after } ) {
		$def->{$key}
		    or next;
		push @{ $meta_command{$key} }, sub {
		    return $def->{$key}->( $self, \%context, @_ );
		};
	    }
	    $verb = shift @cmdarg;
	}

	last if $verb eq 'exit' || $verb eq 'bye';
	$verb = _verb_alias( $verb );
	$verb eq 'source' and do {
	    eval {
		splice @args, 0, 0, $self->_source (shift @cmdarg);
		1;
	    } or warn ( $@ || 'An unknown error occurred' );	## no critic (RequireCarping)
	    next;
	};

	$verb ne 'new'
	    and $verb ne 'shell'
	    and $verb !~ m/ \A _ [^_] /smx
	    or do {
	    warn <<"EOD";
Verb '$verb' undefined. Use 'help' to get help.
EOD
	    next;
	};
	my $out;
	if ( $redir ) {
	    $out = IO::File->new( $redir ) or do {
		warn <<"EOD";
Error - Failed to open $redir
	$^E
EOD
		next;
	    };
	} else {
	    $out = $stdout;
	}
	my $rslt;

	foreach my $pseudo ( @{ $meta_command{before} } ) {
	    $pseudo->();
	}

	if ($verb eq 'get' && @cmdarg == 0) {
	    $rslt = [];
	    foreach my $name ($self->attribute_names ()) {
		my $val = $self->getv( $name );
		push @$rslt, defined $val ? "$name $val" : $name;
	    }
	} else {
	    eval {
		$rslt = $self->$verb (@cmdarg);
		1;
	    } or do {
		warn $@;	## no critic (RequireCarping)
		next;
	    };
	}

	foreach my $pseudo ( reverse @{ $meta_command{after} } ) {
	    $pseudo->( $rslt );
	}

	if ( ARRAY_REF eq ref $rslt ) {
	    foreach (@$rslt) {print { $out } "$_\n"}
	} elsif ( ! ref $rslt ) {
	    print { $out } "$rslt\n";
	} elsif ($rslt->is_success) {
	    $self->content_type()
		or not $self->{filter}
		or next;
	    my $content = $rslt->content;
	    chomp $content;
	    print { $out } "$content\n";
	} else {
	    my $status = $rslt->status_line;
	    chomp $status;
	    warn $status, "\n";
	    $rslt->code() == HTTP_I_AM_A_TEAPOT
		and print { $out } $rslt->content(), "\n";
	}
    }
    $interactive
	and not $self->{filter}
	and print { $stdout } "\n";
    return;
}

sub _get_readline {	## no critic (Subroutines::RequireArgUnpacking)
    my ( $self ) = @_;
    require Term::ReadLine;
    $rdln ||= Term::ReadLine->new (
	'SpaceTrack orbital element access');
    @_ > 1
	and $_[1] = ( $rdln->OUT || \*STDOUT );	# $stdout
    if ( 'Term::ReadLine::Perl' eq $rdln->ReadLine() ) {
	require File::Glob;

	$readline_word_break_re ||= qr<
	    [\Q$readline::rl_completer_word_break_characters\E]+
	>smx;

	no warnings qw{ once };
	$readline::rl_completion_function = sub {
	    my ( $text, $line, $start ) = @_;
	    return $self->__readline_completer(
		$text, $line, $start );
	};
    }
    return sub { $rdln->readline ( $self->getv( 'prompt' ) ) };
}


=for html <a name="source"></a>

=item $st->source ($filename);

This convenience method reads the given file, and passes the individual
lines to the shell method. It croaks if the file is not provided or
cannot be read.

=cut

# We really just delegate to _source, which unpacks.
sub source {
    my $self = _instance( $_[0], __PACKAGE__ ) ? shift :
	Astro::SpaceTrack->new ();
    $self->shell ($self->_source (@_), 'exit');
    return;
}


=for html <a name="spacetrack"></a>

=item $resp = $st->spacetrack ($name);

This method returns predefined sets of data from the Space Track web
site, using either canned queries or global favorites.

The following catalogs are available:

    Name            Description
    full            Full catalog
    payloads        All payloads
    navigation      Navigation satellites
    weather         Weather satellites
    geosynchronous  Geosynchronous bodies
    iridium         Iridium satellites
    orbcomm         OrbComm satellites
    globalstar      Globalstar satellites
    intelsat        Intelsat satellites
    inmarsat        Inmarsat satellites
    amateur         Amateur Radio satellites
    visible         Visible satellites
    special         Special satellites
    bright_geosynchronous
                    Bright Geosynchronous satellites
    human_spaceflight
                    Human Spaceflight
    well_tracked_objects
                    Well-Tracked Objects having
		    unknown country and launch point

The following option is supported:

 -json
   specifies the TLE be returned in JSON format

Options may be specified either in command-line style
(that is, as C<< spacetrack( '-json', ... ) >>) or as a hash reference
(that is, as C<< spacetrack( { json => 1 }, ... ) >>).

This method returns an L<HTTP::Response|HTTP::Response> object. If the
operation succeeded, the content of the response will be the requested
data, unzipped if you used the version 1 interface.

If you requested a non-existent catalog, the response code will be
C<HTTP_NOT_FOUND> (a.k.a.  404); otherwise the response code will be
whatever the underlying HTTPS request returned.

A Space Track username and password are required to use this method.

If this method succeeds, the response will contain headers

 Pragma: spacetrack-type = orbit
 Pragma: spacetrack-source = spacetrack

These can be accessed by C<< $st->content_type( $resp ) >> and
C<< $st->content_source( $resp ) >> respectively.

A list of valid names and brief descriptions can be obtained by calling
C<< $st->names ('spacetrack') >>.

If you have set the C<verbose> attribute true (e.g.  C<< $st->set
(verbose => 1) >>), the content of the error response will include the
list of valid names. Note, however, that under version 1 of the
interface this list does not determine what can be retrieved.

This method implicitly calls the C<login()> method if the session cookie
is missing or expired. If C<login()> fails, you will get the
HTTP::Response from C<login()>.

=cut

{

    my %unpack_query = (
	ARRAY_REF()	=> sub { return @{ $_[0] } },
	HASH_REF()	=> sub { return $_[0] },
    );

    # Unpack a Space Track REST query. References are unpacked per the
    # above table, if found there. Undefined values return an empty hash
    # reference. Anything else croaks with a stack trace.

    sub _unpack_query {
	my ( $arg ) = @_;
	my $code = $unpack_query{ref $arg}
	    or Carp::confess "Bug - unexpected query $arg";
	return $code->( $arg );
    }

}

# Called dynamically
sub _spacetrack_opts {	## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
    return [
	'json!'		=> 'Return data in JSON format',
	'format=s'	=> 'Specify retrieval format',
    ];
}

# Called dynamically
sub _spacetrack_catalog_version {	## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
    return $_[0]->getv( 'space_track_version' );
}

sub spacetrack {
    my ( $self, @args ) = @_;

    my ( $opt, $catalog ) = _parse_args( @args );

    _retrieval_format( tle => $opt );

    defined $catalog
	and my $info = $catalogs{spacetrack}[2]{$catalog}
	or return $self->_no_such_catalog( spacetrack => 2, $catalog );

    defined $info->{deprecate}
	and Carp::croak "Catalog '$catalog' is deprecated in favor of '$info->{deprecate}'";

    defined $info->{favorite}
	and return $self->favorite( $opt, $info->{favorite} );

    my %retrieve_opt = %{
	$self->_convert_retrieve_options_to_rest( $opt )
    };

    $info->{tle}
	and @retrieve_opt{ keys %{ $info->{tle} } } =
	    values %{ $info->{tle} };

    my $rslt;

    if ( $info->{satcat} ) {

	my %oid;

	foreach my $query ( _unpack_query( $info->{satcat} ) ) {

	    $rslt = $self->spacetrack_query_v2(
		basicspacedata	=> 'query',
		class		=> 'satcat',
		format		=> 'json',
		predicates	=> 'OBJECT_NUMBER',
		CURRENT		=> 'Y',
		DECAY		=> 'null-val',
		_sort_rest_arguments( $query ),
	    );

	    $rslt->is_success()
		or return $rslt;

	    foreach my $body ( @{
		$self->_get_json_object()->decode( $rslt->content() )
	    } ) {
		$oid{ $body->{OBJECT_NUMBER} + 0 } = 1;
	    }

	}

	$rslt = $self->retrieve( $opt,
	    sort { $a <=> $b } keys %oid );

	$rslt->is_success()
	    or return $rslt;

    } else {

	$rslt = $self->spacetrack_query_v2(
	    basicspacedata	=> 'query',
	    _sort_rest_arguments( \%retrieve_opt ),
	);

	$rslt->is_success()
	    or return $rslt;

	$self->_convert_content( $rslt );

	$self->_add_pragmata( $rslt,
	    'spacetrack-type' => 'orbit',
	    'spacetrack-source' => 'spacetrack',
	    'spacetrack-interface' => 2,
	);

    }

    return $rslt;

}

=for html <a name="spacetrack_query_v2"></a>

=item $resp = $st->spacetrack_query_v2( @path );

This method exposes the Space Track version 2 interface (a.k.a the REST
interface). It has nothing to do with the (probably badly-named)
C<spacetrack()> method.

The arguments are the arguments to the REST interface. These will be
URI-escaped, and a login will be performed if necessary. This method
returns an C<HTTP::Response> object containing the results of the
operation.

Except for the URI escaping of the arguments and the implicit login,
this method interfaces directly to Space Track. It is provided for those
who want a way to experiment with the REST interface, or who wish to do
something not covered by the higher-level methods.

For example, if you want the JSON version of the satellite box score
(rather than the tab-delimited version provided by the C<box_score()>
method) you will find the JSON in the response object of the following
call:

 my $resp = $st->spacetrack_query_v2( qw{
     basicspacedata query class boxscore
     format json predicates all
     } );
 );

If this method is called directly from outside the C<Astro::SpaceTrack>
name space, pragmata will be added to the results based on the
arguments, as follows:

For C<< basicspacedata => 'modeldef' >>

 Pragma: spacetrack-type = modeldef
 Pragma: spacetrack-source = spacetrack
 Pragma: spacetrack-interface = 2

For C<< basicspacedata => 'query' >> and C<< class => 'tle' >> or
C<'tle_latest'>,

 Pragma: spacetrack-type = orbit
 Pragma: spacetrack-source = spacetrack
 Pragma: spacetrack-interface = 2

=cut

{
    our $SPACETRACK_DELAY_SECONDS = $ENV{SPACETRACK_DELAY_SECONDS} || 3;

    my $spacetrack_delay_until;

    sub _spacetrack_delay {
	my ( $self ) = @_;
	$SPACETRACK_DELAY_SECONDS
	    or return;
	$self->{dump_headers} & DUMP_DRY_RUN
	    and return;
	if ( defined $spacetrack_delay_until ) {
	    my $now = _time();
	    $now < $spacetrack_delay_until
		and _sleep( $spacetrack_delay_until - $now );
	}
	$spacetrack_delay_until = _time() + $SPACETRACK_DELAY_SECONDS;

	return;
    }
}

{
    my %tle_class = map { $_ => 1 } qw{ tle tle_latest };

    sub spacetrack_query_v2 {
	my ( $self, @args ) = @_;

	# Space Track has announced that beginning September 22 2014
	# they will begin limiting queries to 20 per minute. But they
	# seem to have jumped the gun, since I get failures August 19
	# 2014 if I don't throttle. None of this applies, though, if
	# we're not actually executing the query.
	$self->_spacetrack_delay();

	delete $self->{_pragmata};

#	# Note that we need to add the comma to URI::Escape's RFC3986 list,
#	# since Space Track does not decode it.
#	my $url = join '/',
#	    $self->_make_space_track_base_url( 2 ),
#	    map {
#		URI::Escape::uri_escape( $_, '^A-Za-z0-9.,_~:-' )
#	    } @args;

	my $uri = URI->new( $self->_make_space_track_base_url( 2 ) );
	$uri->path_segments( @args );
#	$url eq $uri->as_string()
#	    or warn "'$url' ne '@{[ $uri->as_string() ]}'";
#	$url = $uri->as_string();

	if ( my $resp = $self->_dump_request(
		args	=> \@args,
		method	=> 'GET',
		url	=> $uri,
		version	=> 2,
	    ) ) {
	    return $resp;
	}

	$self->_check_cookie_generic( 2 )
	    or do {
	    my $resp = $self->login();
	    $resp->is_success()
		or return $resp;
	};
##	warn "Debug - $url/$cgi";
#	my $resp = $self->_get_agent()->get( $url );
	my $resp = $self->_get_agent()->get( $uri );

	if ( $resp->is_success() ) {

	    if ( $self->{pretty} &&
		_find_rest_arg_value( \@args, format => 'json' ) eq 'json'
	    ) {
		my $json = $self->_get_json_object();
		$resp->content( $json->encode( $json->decode(
			    $resp->content() ) ) );
	    }

	    if ( __PACKAGE__ ne caller ) {

		my $kind = _find_rest_arg_value( \@args,
		    basicspacedata => '' );
		my $class = _find_rest_arg_value( \@args,
		    class => '' );

		if ( 'modeldef' eq $kind ) {

		    $self->_add_pragmata( $resp,
			'spacetrack-type' => 'modeldef',
			'spacetrack-source' => 'spacetrack',
			'spacetrack-interface' => 2,
		    );

		} elsif ( 'query' eq $kind && $tle_class{$class} ) {

		    $self->_add_pragmata( $resp,
			'spacetrack-type' => 'orbit',
			'spacetrack-source' => 'spacetrack',
			'spacetrack-interface' => 2,
		    );

		}
	    }
	}

	$self->__dump_response( $resp );
	return $resp;
    }
}

sub _find_rest_arg_value {
    my ( $args, $name, $default ) = @_;
    for ( my $inx = $#$args - 1; $inx >= 0; $inx -= 2 ) {
	$args->[$inx] eq $name
	    and return $args->[$inx + 1];
    }
    return $default;
}

=for html <a name="update"></a>

=item $resp = $st->update( $file_name );

This method updates the named TLE file, which must be in JSON format. On
a successful update, the content of the returned HTTP::Response object
is the updated TLE data, in whatever format is desired. If any updates
were in fact found, the file is rewritten. The rewritten JSON will be
pretty if the C<pretty> attribute is true.

The file to be updated can be generated by using the C<-json> option on
any of the methods that accesses Space Track data. For example,

 # Assuming $ENV{SPACETRACK_USER} contains
 # username/password
 my $st = Astro::SpaceTrack->new(
     pretty              => 1,
 );
 my $rslt = $st->spacetrack( { json => 1 }, 'iridium' );
 $rslt->is_success()
     or die $rslt->status_line();
 open my $fh, '>', 'iridium.json'
     or die "Failed to open file: $!";
 print { $fh } $rslt->content();
 close $fh;

The following is the equivalent example using the F<SpaceTrack> script:

 SpaceTrack> set pretty 1
 SpaceTrack> spacetrack -json iridium >iridium.json

This method reads the file to be updated, determines the highest C<FILE>
value, and then requests the given OIDs, restricting the return to
C<FILE> values greater than the highest found. If anything is returned,
the file is rewritten.

The following options may be specified:

 -json
   specifies the TLE be returned in JSON format

Options may be specified either in command-line style (that is, as
C<< spacetrack( '-json', ... ) >>) or as a hash reference (that is, as
C<< spacetrack( { json => 1 }, ... ) >>).

B<Note> that there is no way to specify the C<-rcs> or C<-effective>
options. If the file being updated contains these values, they will be
lost as the individual OIDs are updated.

=cut

{

    my %encode = (
	'3le'	=> sub {
	    my ( undef, $data ) = @_;	# JSON object unused
	    return join '', map {
		"$_->{OBJECT_NAME}\n$_->{TLE_LINE1}\n$_->{TLE_LINE2}\n"
	    } @{ $data };
	},
	json	=> sub {
	    my ( $json, $data ) = @_;
	    return $json->encode( $data );
	},
	tle	=> sub {
	    my ( undef, $data ) = @_;	# JSON object unused
	    return join '', map {
		"$_->{TLE_LINE1}\n$_->{TLE_LINE2}\n"
	    } @{ $data };
	},
    );

    # Called dynamically
    sub _update_opts {	## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
	return [
	    _get_retrieve_options(),
	];
    }

    sub update {
	my ( $self, @args ) = @_;

	my ( $opt, $fn ) = $self->_parse_retrieve_args( @args );

	$opt = { %{ $opt } };	# Since we modify it.

	delete $opt->{start_epoch}
	    and Carp::croak '-start_epoch not allowed';
	delete $opt->{end_epoch}
	    and Carp::croak '-end_epoch not allowed';

	my $json = $self->_get_json_object();
	my $data;
	{
	    local $/ = undef;
	    open my $fh, '<', $fn
		or Carp::croak "Unable to open $fn: $!";
	    $data = $json->decode( <$fh> );
	    close $fh;
	}

	my $file = -1;
	my @oids;
	foreach my $datum ( @{ $data } ) {
	    push @oids, $datum->{OBJECT_NUMBER};
	    my $ff = defined $datum->{_file_of_record} ?
		delete $datum->{_file_of_record} :
		$datum->{FILE};
	    $ff > $file
		and $file = $ff;
	}

	defined $opt->{since_file}
	    or $opt->{since_file} = $file;

	my $format = delete $opt->{json} ? 'json' :
	    $self->getv( 'with_name' ) ? '3le' : 'tle';
	$opt->{format} = 'json';

	my $resp = $self->retrieve( $opt, sort { $a <=> $b } @oids );

	if ( $resp->code() == HTTP_NOT_FOUND ) {

	    $resp->code( HTTP_OK );
	    $self->_add_pragmata( $resp,
		'spacetrack-type' => 'orbit',
		'spacetrack-source' => 'spacetrack',
		'spacetrack-interface' => 2,
	    );

	} else {

	    $resp->is_success()
		or return $resp;

	    my %merge = map { $_->{OBJECT_NUMBER} => $_ } @{ $data };

	    foreach my $datum ( @{ $json->decode( $resp->content() ) } ) {
		%{ $merge{$datum->{OBJECT_NUMBER}} } = %{ $datum };
	    }

	    {
		open my $fh, '>', $fn
		    or Carp::croak "Failed to open $fn: $!";
		print { $fh } $json->encode( $data );
		close $fh;
	    }

	}

	$resp->content( $encode{$format}->( $json, $data ) );

	return $resp;
    }

}


####
#
#	Private methods.
#

#	$self->_add_pragmata ($resp, $name => $value, ...);
#
#	This method adds pragma headers to the given HTTP::Response
#	object, of the form pragma => "$name = $value". The pragmata are
#	also cached in $self.
#
#	Pragmata names are normalized by converting them to lower case
#	and converting underscores to dashes.

sub _add_pragmata {
    my ($self, $resp, @args) = @_;
    while (@args) {
	my ( $name, $value ) = splice @args, 0, 2;
	$name = lc $name;
	$name =~ s/ _ /-/smxg;
	$self->{_pragmata}{$name} = $value;
	$resp->push_header(pragma => "$name = $value");
    }
    return;
}

{
    my %format_map = qw{
	3le	tle
    };

    # $accumulator = _accumulator_for( $format, \%opt )
    #
    # This subroutine manufactires and returns an accumulator for the
    # named format. The reference to the options hash is itself
    # optional. The supported options are:
    #   file => true if the data contains a FILE key and the caller
    #		requests that a _file_of_record key be generated if
    #		possible and appropriate. Individual accumulators are at
    #		liberty to ignore this.
    #	pretty => true if the caller requests that the returned data be
    #		nicely formatted. This normally comes from the 'pretty'
    #		attribute. Individual accumulators are at liberty to
    #		ignore this.
    #
    # The return is a code reference. This reference is intended to be
    # called as
    #	$accumulator->( $self, $resp )
    # for each successful HTTP response. After all responses have been
    # processed, the accumulated data are retrieved using
    #  ( $content, $data ) = $accumulator( $self )
    # The first return is the text representation of the accumulated
    # data. The second is the decoded data, and is returned at the
    # accumulator's option. In scalar context only $content is returned.

    sub _accumulator_for {
	my ( $format, $opt ) = @_;
	my $name = $format_map{$format} || $format;
	my $accumulator = __PACKAGE__->can( "_accumulate_${name}_data" )
	    || \&_accumulate_unknown_data;
	my $returner = __PACKAGE__->can( "_accumulate_${name}_return" )
	|| sub {
	    my ( undef, $context ) = @_;
	    return $context->{data};
	};
	my $context = {
	    format	=> $format,
	    opt		=> $opt || {},
	};
	return sub {
	    my ( $self, $resp ) = @_;
	    defined $resp
		or return $returner->( $self, $context );
	    my $content = $resp->content();
	    defined $content
		and $content ne ''
		or return;
	    my $data = $accumulator->( $self, $content, $context );
	    $context->{opt}{file}
		and $data
		and _accumulate_file_of_record( $self, $context, $data );
	    return;
	}
    }

}

sub _accumulate_file_of_record {
    my ( undef, $context, $data ) = @_;		# Invocant unused
    if ( defined $context->{file} ) {
	foreach my $datum ( @{ $data } ) {
	    defined $datum->{FILE}
		and $datum->{FILE} > $context->{file}
		and $datum->{_file_of_record} = $context->{file};
	}
    } else {
	$context->{file} = List::Util::max( -1,
	    map { $_->{FILE} }
	    grep { defined $_->{FILE} }
	    @{ $data }
	);
    }
    return;
}

# The data accumulators. The conventions which must be followed are
# that, given a format named 'fmt':
#
# 1) There MUST be an accumulator named _accumulate_fmt_data(). Its
#    arguments are the invocant, the content of the return, and the
#    context hash. It must accumulate data in $context->{data}, in any
#    format it likes.
# 2) If _accumulate_fmt_data() decodes the data, it SHOULD return a
#    reference to the decoded array. Otherwise it MUST return nothing.
# 3) There MAY be a returner named _accumulate_fmt_return(). If it
#    exists its arguments are the invocant and the context hash. It MUST
#    return a valid representation of the accumulated data in the
#    desired format.
# 4) If _accumulate_fmt_return() does not exist, the return will be the
#    contents of $context->{data}, which MUST have been maintained by
#    _accumulate_fmt_data() as a valid representation of the data in the
#    desired format.
# 5) Note that if _accumulate_fmt_return() exists,
#    _accumulate_fmt_data need not maintain $context->{data} as a valid
#    representation of the accumulated data.

# Accessed via __PACKAGE__->can( "accumulate_${name}_data" ) in
# _accumulator_for(), above
sub _accumulate_csv_data {	## no critic (ProhibitUnusedPrivateSubroutines)
    my ( undef, $content, $context ) = @_;	# Invocant unused
    if ( defined $context->{data} ) {
	$context->{data} =~ s{ (?<! \n ) \z }{\n}smx;
	$content =~ s{ .* \n }{}smx;
	$context->{data} .= $content;
    } else {
	$context->{data} = $content;
    }
    return;
}

# Accessed via __PACKAGE__->can( "accumulate_${name}_data" ) in
# _accumulator_for(), above
sub _accumulate_html_data {	## no critic (ProhibitUnusedPrivateSubroutines)
    my ( undef, $content, $context ) = @_;	# Invocant unused
    if ( defined $context->{data} ) {
	$context->{data} =~ s{ \s* </tbody> \s* </table> \s* \z }{}smx;
	$content =~ s{ .* <tbody> \s* }{}smx;
	$context->{data} .= $content;
    } else {
	$context->{data} = $content;
    }
    return;
}

# Accessed via __PACKAGE__->can( "accumulate_${name}_data" ) in
# _accumulator_for(), above
sub _accumulate_json_data {	## no critic (ProhibitUnusedPrivateSubroutines)
    my ( $self, $content, $context ) = @_;

    my $json = $context->{json} ||= $self->_get_json_object(
	pretty => $context->{opt}{pretty},
    );

    my $data = $json->decode( $content );

    ARRAY_REF eq ref $data
	or $data = [ $data ];

    @{ $data }
	or return;

    if ( $context->{data} ) {
	push @{ $context->{data} }, @{ $data };
    } else {
	$context->{data} = $data;
    }

    return $data;
}

# Accessed via __PACKAGE__->can( "accumulate_${name}_return" ) in
# _accumulator_for(), above
sub _accumulate_json_return {	## no critic (ProhibitUnusedPrivateSubroutines)
    my ( $self, $context ) = @_;

    my $json = $context->{json} ||= $self->_get_json_object(
	pretty => $context->{opt}{pretty},
    );

    $context->{data} ||= [];	# In case we did not find anything.
    return wantarray
	? ( $json->encode( $context->{data} ), $context->{data} )
	: $json->encode( $context->{data} );
}

sub _accumulate_unknown_data {
    my ( undef, $content, $context ) = @_;	# Invocant unused
    defined $context->{data}
	and Carp::croak "Unable to accumulate $context->{format} data";
    $context->{data} = $content;
    return;
}

# Accessed via __PACKAGE__->can( "accumulate_${name}_data" ) in
# _accumulator_for(), above
sub _accumulate_tle_data {	## no critic (ProhibitUnusedPrivateSubroutines)
    my ( undef, $content, $context ) = @_;	# Invocant unused
    $context->{data} .= $content;
    return;
}

# Accessed via __PACKAGE__->can( "accumulate_${name}_data" ) in
# _accumulator_for(), above
sub _accumulate_xml_data {	## no critic (ProhibitUnusedPrivateSubroutines)
    my ( undef, $content, $context ) = @_;
    if ( defined $context->{data} ) {
	$context->{data} =~ s{ \s* </xml> \s* \z }{}smx;
	$content =~ s{ .* <xml> \s* }{}smx;
	$context->{data} .= $content;
    } else {
	$context->{data} = $content;
    }
    return;
}

# _check_cookie_generic looks for our session cookie. If it is found, it
# returns true if it thinks the cookie is valid, and false otherwise. If
# it is not found, it returns false.

sub _record_cookie_generic {
    my ( $self, $version ) = @_;
    defined $version
	or $version = $self->{space_track_version};
    my $interface_info = $self->{_space_track_interface}[$version];
    my $cookie_name = $interface_info->{cookie_name};
    my $domain = $interface_info->{domain_space_track};

    my ( $cookie, $expires );
    $self->_get_agent()->cookie_jar->scan( sub {
	    $self->{dump_headers} & DUMP_COOKIE
		and $self->_dump_cookie( "_record_cookie_generic:\n", @_ );
	    $_[4] eq $domain
		or return;
	    $_[3] eq SESSION_PATH
		or return;
	    $_[1] eq $cookie_name
		or return;
	    ( $cookie, $expires ) = @_[2, 8];
	    return;
	} );

    # I don't get an expiration time back from the version 2 interface.
    # But the docs say the cookie is only good for about two hours, so
    # to be on the safe side I fudge in an hour.
    $version == 2
	and not defined $expires
	and $expires = time + 3600;

    if ( defined $cookie ) {
	$interface_info->{session_cookie} = $cookie;
	$self->{dump_headers} & DUMP_TRACE
	    and warn "Session cookie: $cookie\n";	## no critic (RequireCarping)
	if ( exists $interface_info->{cookie_expires} ) {
	    $interface_info->{cookie_expires} = $expires;
	    $self->{dump_headers} & DUMP_TRACE
		and warn 'Cookie expiration: ',
		    POSIX::strftime( '%d-%b-%Y %H:%M:%S', localtime $expires ),
		    " ($expires)\n";	## no critic (RequireCarping)
	    return $expires > time;
	}
	return $interface_info->{session_cookie} ? 1 : 0;
    } else {
	$self->{dump_headers} & DUMP_TRACE
	    and warn "Session cookie not found\n";	## no critic (RequireCarping)
	return;
    }
}

sub _check_cookie_generic {
    my ( $self, $version ) = @_;
    defined $version
	or $version = $self->{space_track_version};
    my $interface_info = $self->{_space_track_interface}[$version];

    if ( exists $interface_info->{cookie_expires} ) {
	return defined $interface_info->{cookie_expires}
	    && $interface_info->{cookie_expires} > time;
    } else {
	return defined $interface_info->{session_cookie};
    }
}

#	_convert_content converts the content of an HTTP::Response
#	from crlf-delimited to lf-delimited.

{	# Begin local symbol block

    my $lookfor = $^O eq 'MacOS' ? qr{ \012|\015+ }smx : qr{ \r \n }smx;

    sub _convert_content {
	my ( undef, @args ) = @_;	# Invocant unused
	local $/ = undef;	# Slurp mode.
	foreach my $resp (@args) {
	    my $buffer = $resp->content;
	    # If we request a non-existent Space Track catalog number,
	    # we get 200 OK but the unzipped content is undefined. We
	    # catch this before we get this far, but the buffer check is
	    # left in in case something else leaks through.
	    defined $buffer or $buffer = '';
	    $buffer =~ s/$lookfor/\n/smxgo;
	    1 while ($buffer =~ s/ \A \n+ //smx);
	    $buffer =~ s/ \s+ \n /\n/smxg;
	    $buffer =~ m/ \n \z /smx or $buffer .= "\n";
	    $resp->content ($buffer);
	    $resp->header (
		'content-length' => length ($buffer),
		);
	}
	return;
    }
}	# End local symbol block.

#	$self->_deprecation_notice( $method, $argument );
#
#	This method centralizes deprecation.  Deprecation is driven of
#	the %deprecate hash. Values are:
#	    false - no warning
#	    1 - warn on first use
#	    2 - warn on each use
#	    3 - die on each use.

{

    use constant _MASTER_IRIDIUM_DEPRECATION_LEVEL	=> 2;

    my %deprecate = (
	celestrak => {
#	    sts	=> 3,
#	    '--descending'	=> 3,
#	    '--end_epoch'	=> 3,
#	    '--last5'		=> 3,
#	    '--sort'		=> 3,
#	    '--start_epoch'	=> 3,
	},
	amsat		=> 0,
	attribute	=> {
#	    direct		=> 3,
	    url_iridium_status_kelso	=> 3,
	    url_iridium_status_mccants	=> 3,
	    url_iridium_status_sladen	=> _MASTER_IRIDIUM_DEPRECATION_LEVEL,
	},
	iridium_status	=> _MASTER_IRIDIUM_DEPRECATION_LEVEL,
	iridium_status_format	=> {
	    kelso	=> 3,
	    mccants	=> 3,
	    sladen	=> _MASTER_IRIDIUM_DEPRECATION_LEVEL,
	},
	mccants	=> {
	    mcnames	=> 2,
	    vsnames	=> 2,
	},
	BODY_STATUS_IS_OPERATIONAL	=> _MASTER_IRIDIUM_DEPRECATION_LEVEL,
	BODY_STATUS_IS_SPARE	=> _MASTER_IRIDIUM_DEPRECATION_LEVEL,
	BODY_STATUS_IS_TUMBLING	=> _MASTER_IRIDIUM_DEPRECATION_LEVEL,
	BODY_STATUS_IS_DECAYED	=> _MASTER_IRIDIUM_DEPRECATION_LEVEL,
    );

    sub _deprecation_notice {
	my ( undef, $method, $argument ) = @_;	# Invocant unused
	defined $method
	    or ( $method = ( caller 1 )[3] ) =~ s/ .* :: //smx;
	my $level = $deprecate{$method}
	    or return;
	my $desc = $method;
	if ( ref $level ) {
	    defined $argument or Carp::confess( 'Bug - $argument undefined' );
	    $level = $level->{$argument}
		or return;
	    $desc = "$method $argument";
	}
	$level >= 3
	    and Carp::croak "$desc is retracted";
	warnings::enabled( 'deprecated' )
	    and Carp::carp "$desc is deprecated";
	1 == $level
	    or return;
	if ( ref $deprecate{$method} ) {
	    $deprecate{$method}{$argument} = 0;
	} else {
	    $deprecate{$method} = 0;
	}
	return;
    }

}

#	_dump_cookie is intended to be called from inside the
#	HTTP::Cookie->scan method. The first argument is prefix text
#	for the dump, and the subsequent arguments are the arguments
#	passed to the scan method.
#	It dumps the contents of the cookie to STDERR via a warn ().
#	A typical session cookie looks like this:
#	    version => 0
#	    key => 'spacetrack_session'
#	    val => whatever
#	    path => '/'
#	    domain => 'www.space-track.org'
#	    port => undef
#	    path_spec => 1
#	    secure => undef
#	    expires => undef
#	    discard => 1
#	    hash => {}
#	The response to the login, though, has an actual expiration
#	time, which we take cognisance of.

{	# begin local symbol block

    my @names = qw{version key val path domain port path_spec secure
	    expires discard hash};

    sub _dump_cookie {
	my ( $self, $prefix, @args ) = @_;
	my $json = $self->_get_json_object( pretty => 1 );
	$prefix and warn $prefix;	## no critic (RequireCarping)
	for (my $inx = 0; $inx < @names; $inx++) {
	    warn "    $names[$inx] => ", $json->encode( $args[$inx] ); ## no critic (RequireCarping)
	}
	return;
    }
}	# end local symbol block


#	__dump_response dumps the headers of the passed-in response
#	object. The hook is used for capturing responses to use when
#	mocking LWP::UserAgent, and is UNSUPPORTED, and subject to
#	change or retraction without notice.

sub __dump_response {
    my ( $self, $resp, $message ) = @_;

    if ( $self->{dump_headers} & DUMP_RESPONSE ) {
	my $content = $resp->content();
	if ( $self->{dump_headers} & DUMP_TRUNCATED
	    && 61 < length $content ) {
	    $content = substr( $content, 0, 61 ) . '...';
	}
	my @data = ( $resp->code(), $resp->message(), [], $content );
	foreach my $name ( $resp->headers()->header_field_names() ) {
	    my @val = $resp->header( $name );
	    push @{ $data[2] }, $name, @val > 1 ? \@val : $val[0];
	}
	if ( my $rqst = $resp->request() ) {
	    push @data, {
		method	=> $rqst->method(),
		uri	=> '' . $rqst->uri(),	# Force stringification
	    };
	}
	my $encoded = $self->_get_json_object( pretty => 1 )->encode(
	    \@data );
	defined $message
	    or $message = 'Response object';
	$message =~ s/ \s+ \z //smx;
	warn "$message:\n$encoded";
    }
    return;
}

#	_dump_request dumps the request if desired.
#
#	If the dump_request attribute has the DUMP_REQUEST bit set, this
#	routine dumps the request. If the DUMP_DRY_RUN bit is set,
#	the dump is returned in the content of an HTTP::Response object,
#	with the response code set to HTTP_I_AM_A_TEAPOT. Otherwise the
#	request is dumped to STDERR.
#
#	If any of the conditions fails, this module simply returns.

sub _dump_request {
    my ( $self, %args ) = @_;
    $self->{dump_headers} & DUMP_REQUEST
	or return;

    my $message = delete $args{message};
    defined $message
	or $message = 'Request object';
    $message =~ s/ \s* \z /:\n/smx;

    my $json = $self->_get_json_object( pretty => 1 )
	or return;

    foreach my $key ( keys %args ) {
	CODE_REF eq ref $args{$key}
	    or next;
	$args{$key} = $args{$key}->( \%args );
    }

    $self->{dump_headers} & DUMP_DRY_RUN
	and return HTTP::Response->new(
	HTTP_I_AM_A_TEAPOT, undef, undef, $json->encode( [ \%args ] )
    );

    warn $message, $json->encode( \%args );

    return;
}

sub _get_json_object {
    my ( $self, %arg ) = @_;
    defined $arg{pretty}
	or $arg{pretty} = $self->{pretty};
    my $json = JSON->new()->utf8()->convert_blessed();
    $arg{pretty}
	and $json->pretty()->canonical();
    return $json;
}

# my @oids = $self->_expand_oid_list( @args );
#
# This subroutine expands the input into a list of OIDs. Commas are
# recognized as separating an argument into multiple specifications.
# Dashes are recognized as range operators, which are expanded. The
# result is returned.

sub _expand_oid_list {
    my ( $self, @args ) = @_;

    my @rslt;
    foreach my $arg ( map { split qr{ , | \s+ }smx, $_ } @args ) {
	if ( my ( $lo, $hi ) = $arg =~
	    m/ \A \s* ( \d+ ) \s* - \s* ( \d+ ) \s* \z /smx
	) {
	    ( $lo, $hi ) = $self->_check_range( $lo, $hi )
		and push @rslt, $lo .. $hi;
	} elsif ( $arg =~ m/ \A \s* ( \d+ ) \s* \z /smx ) {
	    push @rslt, $1;
	} else {
	    # TODO -- ignore? die? what?
	}
    }
    return @rslt;
}

# Take as input a reference to one of the legal options arrays, and
# extract the equivalent keys. The return is suitable for assigning to a
# hash used to test the keys; that is, it is ( key0 => 1, key1 => 1, ...
# ).

{
    my $strip = qr{ [=:|!+] .* }smx;

    sub _extract_keys {
	my ( $lgl_opts ) = @_;
	if ( ARRAY_REF eq ref $lgl_opts ) {
	    my $len = @{ $lgl_opts };
	    my @rslt;
	    for ( my $inx = 0; $inx < $len; $inx += 2 ) {
		( my $key = $lgl_opts->[$inx] ) =~ s/ $strip //smxo;
		push @rslt, $key, 1;
	    }
	    return @rslt;
	} else {
	    $lgl_opts =~ s/ $strip //smxo;
	    return $lgl_opts;
	}
    }
}

# The following are data transform routines for _search_rest().
# The arguments are the datum and the class for which it is being
# formatted.

# Parse an international launch id, and format it for a Space-Track REST
# query. The parsing is done by _parse_international_id(). The
# formatting prefixes the 'contains' wildcard '~~' unless year, sequence
# and part are all present.

sub _format_international_id_rest {
    my ( $intl_id ) = @_;
    my @parts = _parse_international_id( $intl_id );
    @parts >= 3
	and return sprintf '%04d-%03d%s', @parts;
    @parts >= 2
	and return sprintf '~~%04d-%03d', @parts;
    return sprintf '~~%04d-', $parts[0];
}

# Parse a launch date, and format it for a Space-Track REST query. The
# parsing is done by _parse_launch_date(). The formatting prefixes the
# 'contains' wildcard '~~' unless year, month, and day are all present.

sub _format_launch_date_rest {
    my ( $date ) = @_;
    my @parts = _parse_launch_date( $date )
	or return;
    @parts >= 3
	and return sprintf '%04d-%02d-%02d', @parts;
    @parts >= 2
	and return sprintf '~~%04d-%02d', @parts;
    return sprintf '~~%04d', $parts[0];
}

#	Note: If we have a bad cookie, we get a success status, with
#	the text
# <?xml version="1.0" encoding="iso-8859-1"?>
# <!DOCTYPE html
#         PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
#          "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
# <html xmlns="http://www.w3.org/1999/xhtml" lang="en-US" xml:lang="en-US"><head><title>Space-Track</title>
# </head><body>
# <body bgcolor='#fffacd' text='#191970' link='#3333e6'>
#          <div align='center'><img src='http://www.space-track.org/icons/spacetrack_logo3.jpg' width=640 height=128 align='top' border=0></div>
# <h2>Error, Corrupted session cookie<br>
# Please <A HREF='login.pl'>LOGIN</A> again.<br>
# </h2>
# </body></html>
#	If this happens, it would be good to retry the login.

sub _get_agent {
    my ( $self ) = @_;
    $self->{agent}
	and return $self->{agent};
    my $agent = $self->{agent} = LWP::UserAgent->new(
	ssl_opts	=> {
	    verify_hostname	=> $self->getv( 'verify_hostname' ),
	},
    );

    $agent->env_proxy();

    $agent->cookie_jar()
	or $agent->cookie_jar( {} );

    return $agent;
}

# $resp = $self->_get_from_net( name => value ... )
#
# This private method retrieves a URL and returns the response object.
# The optional name/value pairs are:
#
#   catalog => catalog_name
#      If this exists, it is the name of the catalog to retrieve. An
#      error is returned if it is not defined, or if the catalog does
#      not exist.
#   file => cache_file_name
#      If this is defined, the data are returned only if it has been
#      modified since the modification date of the file. If the data
#      have been modified, the cache file is refreshed; otherwise the
#      response is loaded from the cache file.
#   method => method_name
#      If this is defined, it is the name of the method doing the
#      catalog lookup. This is unused unless 'catalog' is defined, and
#      defaults to the name of the calling method.
#   post_process => code reference
#      If the network operation succeeded and this is defined, it is
#      called and passed the invocant, the HTTP::Response object, and
#      a reference to the catalog information hash (or to an empty hash
#      if 'url' was specified). The HTTP::Response object returned
#      (which may or may not be the one passed in) is the basis for any
#      further processing.
#   spacetrack_source => spacetrack_source
#      If this is defined, the corresponding-named pragma is set. The
#      default comes from the same-named key in the catalog info if that
#      is defined, or the 'method' argument (as defaulted).
#   spacetrack_type => spacetrack_type
#      If this is defined, the corresponding-named pragma is set.
#   url => URL
#      If this is defined, it is the URL of the data to retrieve.
#
# Either 'catalog' or 'url' MUST be specified. If 'url' is defined,
# 'catalog' is ignored.

sub _get_from_net {
    my ( $self, %arg ) = @_;
    delete $self->{_pragmata};

    my $method = defined $arg{method} ? $arg{method} : ( caller 1)[3];
    $method =~ s/ .* :: //smx;

    my $url;
    my $info;
    if ( defined $arg{url} ) {
	$url = $arg{url};
	$info	= {};
    } elsif ( exists $arg{catalog} ) {
	defined $arg{catalog}
	    and $catalogs{$method}
	    and $info = $catalogs{$method}{$arg{catalog}}
	    or return $self->_no_such_catalog( $method, $arg{catalog} );
	$self->_deprecation_notice( $method => $arg{catalog} );
	$url = $info->{url}
	    or Carp::confess "Bug - No url defined for $method( '$arg{catalog}' )";
    } else {
	Carp::confess q<Bug - neither 'url' nor 'catalog' specified>;
    }

    if ( my $resp = $self->_dump_request(
	    args	=> { map { $_ => CODE_REF eq ref $arg{$_} ? 'sub { ... }' : $arg{$_} } keys %arg },
	    method	=> 'GET',
	    url		=> $url,
	    version	=> 2,
	) ) {
	return $resp;
    }

    my $agent = $self->_get_agent();
    my $rqst = HTTP::Request->new( GET	=> $url );
    my $file_time;
    if ( defined $arg{file} ) {
	if ( my @stat = stat $arg{file} ) {
	    $file_time = HTTP::Date::time2str( $stat[9] );
	    $rqst->header( if_modified_since => $file_time );
	}
    }

    my $resp;
    $resp = $self->_dump_request(
	arg	=> sub {
	    my %sanitary = %arg;
	    foreach my $key ( qw{ post_process } ) {
		delete $sanitary{$key}
		    and $sanitary{$key} = CODE_REF;
	    }
	    return \%sanitary;
	},
	message	=> '_get_from_net() request object',
	method	=> 'GET',
	url	=> $url,
	hdrs	=> sub {
	    my %rslt;
	    foreach my $name ( $rqst->header_field_names() ) {
		my @v = $rqst->header( $name );
		$rslt{$name} = @v == 1 ? $v[0] : \@v;
	    }
	    return \%rslt;
	},
    )
	and return $resp;
    $resp = $agent->request( $rqst );
    $self->__dump_response(
	$resp, '_get_from_net() initial response object' );

    if ( $resp->code() == HTTP_NOT_MODIFIED ) {
	defined $arg{file}
	    or Carp::confess q{Programming Error - argument 'file' not defined};
	local $/ = undef;
	open my $fh, '<', $arg{file}
	    or return HTTP::Response->new(
	    HTTP_INTERNAL_SERVER_ERROR,
	    "Unable to read $arg{file}: $!" );
	$resp->content( scalar <$fh> );
	close $fh;
	$resp->code( HTTP_OK );
	defined $file_time
	    and $resp->header( last_modified => $file_time );
	$arg{spacetrack_cache_hit} = 1;
    } else {
	$resp->is_success()
	    and defined $arg{post_process}
	    and $resp = $arg{post_process}->( $self, $resp, $info );
	$resp->is_success()	# $resp may be a different object now.
	    or return $resp;
	$self->_convert_content( $resp );
	if ( defined $arg{file} ) {
	    open my $fh, '>', $arg{file}
		or return HTTP::Response->new(
		HTTP_INTERNAL_SERVER_ERROR,
		"Unable to write $arg{file}: $!" );
	    print { $fh } $resp->content();
	    close $fh;
	    $arg{spacetrack_cache_hit} = 0;
	}
    }

    defined $arg{spacetrack_source}
	or $arg{spacetrack_source} =
	    defined $info->{spacetrack_source} ?
		$info->{spacetrack_source} :
		$method;

    $self->_add_pragmata( $resp,
	map {
	    defined $arg{$_} ? ( $_ => $arg{$_} ) :
	    defined $info->{$_} ? ( $_ => $info->{$_} ) :
	    ()
	}
	qw{ spacetrack_type spacetrack_source spacetrack_cache_hit } );
    $self->__dump_response( $resp,
	'_get_from_net() final response object' );
    return $resp;
}

# _get_space_track_domain() returns the domain name portion of the Space
# Track URL from the appropriate attribute. The argument is the
# interface version number, which defaults to the value of the
# space_track_version attribute.

sub _get_space_track_domain {
    my ( $self, $version ) = @_;
    defined $version
	or $version = $self->{space_track_version};
    return $self->{_space_track_interface}[$version]{domain_space_track};
}

# __get_loader() retrieves a loader. A code reference to it is returned.
#
# NOTE WELL: This subroutine is for the benefit of
# t/spacetrack_request.t, and is called by that code. The leading double
# underscore is to flag it to Perl::Critic as package private rather
# than module private.

sub __get_loader {
##  my ( $invocant, %arg ) = @_;	# Arguments unused
    my $json = JSON->new()->utf8( 1 );
    return sub {
	return $json->decode( $_[0] );
    }
}

#	_handle_observing_list takes as input any number of arguments.
#	each is split on newlines, and lines beginning with a five-digit
#	number (with leading spaces allowed) are taken to specify the
#	catalog number (first five characters) and common name (the rest)
#	of an object. The resultant catalog numbers are run through the
#	retrieve () method. If called in scalar context, the return is
#	the resultant HTTP::Response object. In list context, the first
#	return is the HTTP::Response object, and the second is a reference
#	to a list of list references, each lower-level reference containing
#	catalog number and name.

sub _handle_observing_list {
    my ( $self, $opt, @args ) = @_;
    my (@catnum, @data);

    # Do not _parse_retrieve_args() here; we expect our caller to handle
    # this.

    foreach (map {split qr{ \n }smx, $_} @args) {
	s/ \s+ \z //smx;
	my ( $id ) = m/ \A ( [\s\d]{5} ) /smx or next;
	$id =~ m/ \A \s* \d+ \z /smx or next;
	my $name = substr $_, 5;
	$name =~ s/ \A \s+ //smx;
	push @catnum, $id;
	push @data, [ $id, $name ];
    }
    my $resp;
    if ( $opt->{observing_list} ) {
	$resp = HTTP::Response->new( HTTP_OK, undef, undef,
	    join '', map { m/ \n \z /smx ? $_ : "$_\n" } @args );
	my $source = ( caller 1 )[3];
	$source =~ s/ .* :: //smx;
	$self->_add_pragmata( $resp,
	    'spacetrack-type' => 'observing-list',
	    'spacetrack-source' => $source,
	);
	$self->__dump_response( $resp );
    } else {
	$resp = $self->retrieve( $opt, sort {$a <=> $b} @catnum );
	if ( $resp->is_success ) {

	    unless ( $self->{_pragmata} ) {
		$self->_add_pragmata( $resp,
		    'spacetrack-type' => 'orbit',
		    'spacetrack-source' => 'spacetrack',
		);
	    }
	    $self->__dump_response( $resp );
	}
    }
    return wantarray ? ($resp, \@data) : $resp;
}

#	_instance takes a variable and a class, and returns true if the
#	variable is blessed into the class. It returns false for
#	variables that are not references.
sub _instance {
    my ( $object, $class ) = @_;
    ref $object or return;
    Scalar::Util::blessed( $object ) or return;
    return $object->isa( $class );
}


# _make_space_track_base_url() makes the a base Space Track URL. You can
# pass the interface version number (1 or 2) as an argument -- it
# defaults to the value of the space_track_version attribute.

sub _make_space_track_base_url {
    my ( $self, $version ) = @_;
    return $self->{scheme_space_track} . '://' .
	$self->_get_space_track_domain( $version );
}

# _mung_login_status() takes as its argument an HTTP::Response object.
# If the code is 500 and the message suggests a certificate problem, add
# the suggestion that the user set verify_hostname false.

sub _mung_login_status {
    my ( $resp ) = @_;
    # 500 Can't connect to www.space-track.org:443 (certificate verify failed)
    $resp->code() == HTTP_INTERNAL_SERVER_ERROR
	or return $resp;
    ( my $msg = $resp->message() ) =~
	    s{ ( [(] \Qcertificate verify failed\E ) [)]}
	    {$1; try setting the verify_hostname attribute false)}smx
	or return $resp;
    $resp->message( $msg );
    return $resp;
}

#	_mutate_attrib takes the name of an attribute and the new value
#	for the attribute, and does what its name says.

# We supress Perl::Critic because we're a one-liner. CAVEAT: we MUST
# not modify the contents of @_. Modifying @_ itself is fine.
sub _mutate_attrib {
    $_[0]->_deprecation_notice( attribute => $_[1] );
    return ($_[0]{$_[1]} = $_[2]);
}

sub _mutate_dump_headers {
    my ( $self, $name, $value, $args ) = @_;
    if ( $value =~ m/ \A --? /smx ) {
	$value = 0;
	my $go = Getopt::Long::Parser->new();
	$go->configure( qw{ require_order } );
	$go->getoptionsfromarray(
	    $args,
	    map {; "$_!" => sub {
		    $_[1] and do {
			my $method = "DUMP_\U$_[0]";
			$value |= $self->$method();
		    };
		    return;
		}
	    } @dump_options
	);
	push @{ $args }, $value;	# Since caller pops it.
    } else {
	$value =~ m/ \A 0 (?: [0-7]+ | x [[:xdigit:]]+ ) \z /smx
	    and $value = oct $value;
    }
    return ( $self->{$name} = $value );
}

{
    my %id_file_name = (
	MSWin32	=> sub {
	    my $home = $ENV{HOME} || $ENV{USERPROFILE} || join '',
		$ENV{HOMEDRIVE}, $ENV{HOMEPATH};
	    return "$home\\spacetrack.id";
	},
	VMS	=> sub {
	    my $home = $ENV{HOME} || 'sys$login';
	    return "$home:spacetrack.id";
	},
    );

    sub __identity_file_name {
	my $id_file = ( $id_file_name{$^O} || sub {
		return join '/', $ENV{HOME}, '.spacetrack-identity' }
	)->();
	my $gpg_file = "$id_file.gpg";
	-e $gpg_file
	    and return $gpg_file;
	return $id_file;
    }

}

# This basically duplicates the logic in Config::Identity
sub __identity_file_is_encrypted {
    my $fn = __identity_file_name();
    -B $fn
	and return 1;
    open my $fh, '<:encoding(utf-8)', $fn
	or return;
    local $/ = undef;
    my $content = <$fh>;
    close $fh;
    return $content =~ m/ \Q----BEGIN PGP MESSAGE----\E /smx;
}

sub _mutate_identity {
    my ( $self, $name, $value ) = @_;
    defined $value
	or $value = $ENV{SPACETRACK_IDENTITY};
    if ( $value and my $identity = __spacetrack_identity() ) {
	$self->set( %{ $identity } );
    }
    return ( $self->{$name} = $value );
}

=for html <a name="flush_identity_cache"></a>

=item Astro::SpaceTrack->flush_identity_cache();

The identity file is normally read only once, and the data cached. This
static method flushes the cache to force the identity data to be reread.

=cut

{
    my $identity;
    my $loaded;

    sub flush_identity_cache {
	$identity = $loaded = undef;
	return;
    }

    sub __spacetrack_identity {
	$loaded
	    and return $identity;
	$loaded = 1;
	my $fn = __identity_file_name();
	-f $fn
	    or return $identity;
	{
	    local $@ = undef;
	    eval {
		require Config::Identity;
		$identity = { Config::Identity->load( $fn ) };
		1;
	    } or return;
	}
	foreach my $key ( qw{ username password } ) {
	    exists $identity->{$key}
		or Carp::croak "Identity file omits $key";
	}
	scalar keys %{ $identity } > 2
	    and Carp::croak 'Identity file defines keys besides username and password';
	return $identity;
    }
}

{
    my %need_logout = map { $_ => 1 } qw{ domain_space_track };

    sub _mutate_spacetrack_interface {
	my ( $self, $name, $value ) = @_;
	my $version = $self->{space_track_version};

	my $spacetrack_interface_info =
	    $self->{_space_track_interface}[$version];

	exists $spacetrack_interface_info->{$name}
	    or Carp::croak "Can not set $name for interface version $version";

	$need_logout{$name}
	    and $self->logout();

	return ( $spacetrack_interface_info->{$name} = $value );
    }
}

sub _access_spacetrack_interface {
    my ( $self, $name ) = @_;
    my $version = $self->{space_track_version};
    my $spacetrack_interface_info =
	$self->{_space_track_interface}[$version];
    exists $spacetrack_interface_info->{$name}
	or Carp::croak "Can not get $name for interface version $version";
    return $spacetrack_interface_info->{$name};
}

#	_mutate_authen clears the session cookie and then sets the
#	desired attribute

# This clears the session cookie and cookie expiration, then co-routines
# off to _mutate attrib.
sub _mutate_authen {
    $_[0]->logout();
    goto &_mutate_attrib;
}

# This subroutine just does some argument checking and then co-routines
# off to _mutate_attrib.
sub _mutate_iridium_status_format {
    Carp::croak "Error - Illegal status format '$_[2]'"
	unless $catalogs{iridium_status}{$_[2]};
    $_[0]->_deprecation_notice( iridium_status_format => $_[2] );
    goto &_mutate_attrib;
}

#	_mutate_number croaks if the value to be set is not numeric.
#	Otherwise it sets the value. Only unsigned integers pass.

# This subroutine just does some argument checking and then co-routines
# off to _mutate_attrib.
sub _mutate_number {
    $_[2] =~ m/ \D /smx and Carp::croak <<"EOD";
Attribute $_[1] must be set to a numeric value.
EOD
    goto &_mutate_attrib;
}

# _mutate_space_track_version() mutates the version of the interface
# used to retrieve data from Space Track. Valid values are 1 and 2, with
# any false value causing the default to be set.

sub _mutate_space_track_version {
    my ( $self, $name, $value ) = @_;
    $value
	or $value = DEFAULT_SPACE_TRACK_VERSION;
    $value =~ m/ \A \d+ \z /smx
	and $self->{_space_track_interface}[$value]
	or Carp::croak "Invalid Space Track version $value";
##  $self->_deprecation_notice( $name => $value );
    $value == 1
	and Carp::croak 'The version 1 SpaceTrack interface stopped working July 16 2013 at 18:00 UT';
    return ( $self->{$name} = $value );
}

#	_mutate_verify_hostname mutates the verify_hostname attribute.
#	Since the value of this gets fed to LWP::UserAgent->new() to
#	instantiate the {agent} attribute, we delete that attribute
#	before changing the value, relying on $self->_get_agent() to
#	instantiate it appropriately if needed -- and on any code that
#	uses the agent to go through this private method to get it.

sub _mutate_verify_hostname {
    delete $_[0]->{agent};
    goto &_mutate_attrib;
}

#	_no_such_catalog takes as arguments a source and catalog name,
#	and returns the appropriate HTTP::Response object based on the
#	current verbosity setting.

{

    my %no_such_name = (
	celestrak => 'CelesTrak',
	spacetrack => 'Space Track',
    );

    sub _no_such_catalog {
	my ( $self, $source, @args ) = @_;

	my $info = $catalogs{$source}
	    or Carp::confess "Bug - No such source as '$source'";

	if ( ARRAY_REF eq ref $info ) {
	    my $inx = shift @args;
	    $info = $info->[$inx]
		or Carp::confess "Bug - Illegal index $inx ",
		    "for '$source'";
	}

	my ( $catalog, $note ) = @args;

	my $name = $no_such_name{$source} || $source;

	my $lead = defined $catalog ?
	    $info->{$catalog} ?
		"$name '$catalog' missing" :
		"$name '$catalog' not found" :
	    "$name item not defined";
	$lead .= defined $note ? " ($note)." : '.';

	return HTTP::Response->new (HTTP_NOT_FOUND, "$lead\n")
	    unless $self->{verbose};

	my $resp = $self->names ($source);
	return HTTP::Response->new (HTTP_NOT_FOUND,
	    join '', "$lead Try one of:\n", $resp->content,
	);
    }

}

#	_parse_args parses options off an argument list. The first
#	argument must be a list reference of options to be parsed.
#	This list is pairs of values, the first being the Getopt::Long
#	specification for the option, and the second being a description
#	of the option suitable for help text. Subsequent arguments are
#	the arguments list to be parsed. It returns a reference to a
#	hash containing the options, followed by any remaining
#	non-option arguments. If the first argument after the list
#	reference is a hash reference, it simply returns.

{
    my $go = Getopt::Long::Parser->new();

    sub _parse_args {
	my ( $lgl_opts, @args ) = @_;
	unless ( ARRAY_REF eq ref $lgl_opts ) {
	    unshift @args, $lgl_opts;
	    ( my $caller = ( caller 1 )[3] ) =~ s/ ( .* ) :: //smx;
	    my $pkg = $1;
	    my $code = $pkg->can( "_${caller}_opts" )
		or Carp::confess "Bug - _${caller}_opts not found";
	    $lgl_opts = $code->();
	}
	my $opt;
	if ( HASH_REF eq ref $args[0] ) {
	    $opt = { %{ shift @args } };	# Poor man's clone.
	    # Validation is new, so I insert a hack to turn it off if need
	    # be.
	    unless ( $ENV{SPACETRACK_SKIP_OPTION_HASH_VALIDATION} ) {
		my %lgl = _extract_keys( $lgl_opts );
		my @bad;
		foreach my $key ( keys %{ $opt } ) {
		    $lgl{$key}
			or push @bad, $key;
		}
		@bad
		    and _parse_args_failure(
			carp	=> 1,
			name	=> \@bad,
			legal	=> { @{ $lgl_opts } },
			suffix	=> <<'EOD',

You cam suppress this warning by setting environment variable
SPACETRACK_SKIP_OPTION_HASH_VALIDATION to a value Perl understands as
true (say, like 1), but this should be considered a stopgap while you
fix the calling code, or have it fixed, since my plan is to make this
fatal.
EOD
		    );
	    }
	} else {
	    $opt = {};
	    my %lgl = @{ $lgl_opts };
	    $go->getoptionsfromarray(
		\@args,
		$opt,
		keys %lgl,
	    )
		or _parse_args_failure( legal => \%lgl );
	}
	return ( $opt, @args );
    }
}

sub _parse_args_failure {
    my %arg = @_;
    my $msg = $arg{carp} ? 'Warning - ' : 'Error - ';
    if ( defined $arg{name} ) {
	my @names = ( ARRAY_REF eq ref $arg{name} ) ?
	    @{ $arg{name} } :
	    $arg{name};
	@names
	    or return;
	my $opt = @names > 1 ? 'Options' : 'Option';
	my $txt = join ', ', map { "-$_" } sort @names;
	$msg .= "$opt $txt illegal.\n";
    }
    if ( defined $arg{legal} ) {
	$msg .= "Legal options are\n";
	foreach my $opt ( sort keys %{ $arg{legal} } ) {
	    my $desc = $arg{legal}{$opt};
	    $opt = _extract_keys( $opt );
	    $msg .= "  -$opt - $desc\n";
	}
	$msg .= <<"EOD";
with dates being either Perl times, or numeric year-month-day, with any
non-numeric character valid as punctuation.
EOD
    }
    defined $arg{suffix}
	and $msg .= $arg{suffix};
    $arg{carp}
	or Carp::croak $msg;
    Carp::carp $msg;
    return;
}

# Parse an international launch ID in the form yyyy-sssp or yysssp.
# In the yyyy-sssp form, the year can be two digits (in which case 57-99
# are 1957-1999 and 00-56 are 2000-2056) and the dash can be any
# non-alpha, non-digit, non-space character. In either case, trailing
# fields are optional. If provided, the part ('p') can be multiple
# alphabetic characters. Only fields actually specified will be
# returned.

sub _parse_international_id {
    my ( $intl_id ) = @_;
    my ( $year, $launch, $part );

    if ( $intl_id =~
	m< \A ( \d+ ) [^[:alpha:][:digit:]\s]
	    (?: ( \d{1,3} ) ( [[:alpha:]]* ) )? \z >smx
    ) {
	( $year, $launch, $part ) = ( $1, $2, $3 );
    } elsif ( $intl_id =~
	m< \A ( \d\d ) (?: ( \d{3} ) ( [[:alpha:]]* ) )?  >smx
    ) {
	( $year, $launch, $part ) = ( $1, $2, $3 );
    } else {
	return;
    }

    $year += $year < 57 ? 2000 : $year < 100 ? 1900 : 0;
    my @parts = ( $year );
    $launch
	or return @parts;
    push @parts, $launch;
    $part
	and push @parts, uc $part;
    return @parts;
}

# Parse a date in the form yyyy-mm-dd, with either two- or four-digit
# year, and month and day optional. The year is normalized to four
# digits using the NORAD pivot date of 57 -- that is, 57-99 represent
# 1957-1999, and 00-56 represent 2000-2056. The month and day are
# optional. Only fields actually specified will be returned.

sub _parse_launch_date {
    my ( $date ) = @_;
    my ( $year, $month, $day ) =
	$date =~ m/ \A (\d+) (?:\D+ (\d+) (?: \D+ (\d+) )? )? /smx
	    or return;
    $year += $year < 57 ? 2000 : $year < 100 ? 1900 : 0;
    my @parts = ( $year );
    defined $month
	or return @parts;
    push @parts, $month;
    defined $day and push @parts, $day;
    return @parts;
}

#	_parse_retrieve_args parses the retrieve() options off its
#	arguments, prefixes a reference to the resultant options hash to
#	the remaining arguments, and returns the resultant list. If the
#	first argument is a list reference, it is taken as extra
#	options, and removed from the argument list. If the next
#	argument after the list reference (if any) is a hash reference,
#	it simply returns its argument list, under the assumption that
#	it has already been called.

{

    my @legal_retrieve_options = (
	@{ CLASSIC_RETRIEVE_OPTIONS() },
	# Space Track Version 2 interface options
	'since_file=i'
	    => '(Return only results added after the given file number)',
	'json!'	=> '(Return TLEs in JSON format)',
	'format=s' => 'Specify data format'
    );

    sub _get_retrieve_options {
	return @legal_retrieve_options;
    }

    sub _parse_retrieve_args {
	my ( undef, @args ) = @_;	# Invocant unused
	my $extra_options = ARRAY_REF eq ref $args[0] ?
	    shift @args :
	    undef;

	( my $opt, @args ) = _parse_args(
	    ( $extra_options ?
		[ @legal_retrieve_options, @{ $extra_options } ] :
		\@legal_retrieve_options ),
	    @args );

	$opt->{sort} ||= _validate_sort( $opt->{sort} );

	_retrieval_format( undef, $opt );

	return ( $opt, @args );
    }
}

{
    my @usual_formats = map { $_ => 1 } qw{ xml json html csv };
    my $legacy_formats = {
	default	=> 'legacy',
	valid	=> { @usual_formats, map { $_ => 1 } qw{ legacy } },
    };
    my $tle_formats	= {
	default	=> 'legacy',
	valid	=> { @usual_formats, map { $_ => 1 } qw{ tle 3le legacy } },
    };
    my %format = (
	box_score	=> $legacy_formats,
	country_names	=> $legacy_formats,
	launch_sites	=> $legacy_formats,
	satcat		=> $legacy_formats,
	tle		=> $tle_formats,
    );

    sub _retrieval_format {
	my ( $table, $opt ) = @_;
	defined $table
	    or $table = defined $opt->{tle} ? $opt->{tle} ? 'tle' :
	'satcat' : 'tle';
	$opt->{json}
	    and defined $opt->{format}
	    and $opt->{format} ne 'json'
	    and Carp::croak 'Inconsistent retrieval format specification';
	$format{$table}
	    or Carp::confess "Bug - $table not supported";
	defined $opt->{format}
	    or $opt->{format} = $opt->{json} ? 'json' :
		$format{$table}{default};
	exists $opt->{json}
	    or $opt->{json} = 'json' eq $opt->{format};
	$format{$table}{valid}{ $opt->{format} }
	    or Carp::croak "Invalid $table retrieval format '$opt->{format}'";
	return $opt->{format} eq 'legacy' ? 'json' : $opt->{format};
    }
}

# my $sort = _validate_sort( $sort );
#
# Validate and canonicalize the value of the -sort option.
{
    my %valid = map { $_ => 1 } qw{ catnum epoch };
    sub _validate_sort {
	my ( $sort ) = @_;
	defined $sort
	    or return 'catnum';
	$sort = lc $sort;
	$valid{$sort}
	    or Carp::croak "Illegal sort '$sort'";
	return $sort;
    }
}

#	$opt = _parse_retrieve_dates ($opt);

#	This subroutine looks for keys start_epoch and end_epoch in the
#	given option hash, parses them as YYYY-MM-DD (where the letters
#	are digits and the dashes are any non-digit punctuation), and
#	replaces those keys' values with a reference to a list
#	containing the output of timegm() for the given time. If only
#	one epoch is provided, the other is defaulted to provide a
#	one-day date range. If the syntax is invalid, we croak.
#
#	The return is the same hash reference that was passed in.

sub _parse_retrieve_dates {
    my ( $opt ) = @_;

    my $found;
    foreach my $key ( qw{ end_epoch start_epoch } ) {

	next unless $opt->{$key};

	if ( $opt->{$key} =~ m/ \D /smx ) {
	    my $str = $opt->{$key};
	    $str =~ m< \A
		( \d+ ) \D+ ( \d+ ) \D+ ( \d+ )
		(?: \D+ ( \d+ ) (?: \D+ ( \d+ ) (?: \D+ ( \d+ ) )? )? )?
	    \z >smx
		or Carp::croak "Error - Illegal date '$str'";
	    my @time = ( $6, $5, $4, $3, $2, $1 );
	    foreach ( @time ) {
		defined $_
		    or $_ = 0;
	    }
	    if ( $time[5] > 1900 ) {
		$time[5] -= 1900;
	    } elsif ( $time[5] < 57 ) {
		$time[5] += 100;
	    }
	    $time[4] -= 1;
	    eval {
		$opt->{$key} = Time::Local::timegm( @time );
		1;
	    } or Carp::croak "Error - Illegal date '$str'";
	}

	$found++;
    }

    if ( $found ) {

	if ( $found == 1 ) {
	    $opt->{start_epoch} ||= $opt->{end_epoch} - 86400;
	    $opt->{end_epoch} ||= $opt->{start_epoch} + 86400;
	}

	$opt->{start_epoch} <= $opt->{end_epoch} or Carp::croak <<'EOD';
Error - End epoch must not be before start epoch.
EOD

	foreach my $key ( qw{ start_epoch end_epoch } ) {

	    my @time = reverse( ( gmtime $opt->{$key} )[ 0 .. 5 ] );
	    $time[0] += 1900;
	    $time[1] += 1;
	    $opt->{"_$key"} = \@time;

	}
    }

    return $opt;
}

#	_parse_search_args parses the search_*() options off its
#	arguments, prefixes a reference to the resultant options
#	hash to the remaining arguments, and returns the resultant
#	list. If the first argument is a hash reference, it validates
#	that the hash contains only legal options.


{

    my %status_query = (
	onorbit	=> 'null-val',
	decayed	=> '<>null-val',
	all	=> '',
    );

    my %include_map = (
	payload	=> 'PAYLOAD',
	rocket	=> 'ROCKET BODY',
	debris	=> 'DEBRIS',
	unknown	=> 'UNKNOWN',
	tba	=> 'TBA',
	other	=> 'OTHER',
    );

    sub _convert_search_options_to_rest {
	my ( undef, $opt ) = @_;	# Invocant unused
	my %rest;

	if ( defined $opt->{status} ) {
	    defined ( my $query = $status_query{$opt->{status}} )
		or Carp::croak "Unknown status '$opt->{status}'";
	    $query
		and $rest{DECAY} = $query;
	}

	{
	    my %incl;

	    if ( $opt->{exclude} && @{ $opt->{exclude} } ) {
		%incl = map { $_ => 1 } keys %include_map;
		foreach ( @{ $opt->{exclude} } ) {
		    $include_map{$_}
			or Carp::croak "Unknown exclusion '$_'";
		    delete $incl{$_};
		}
	    }

	    if ( $opt->{include} && @{ $opt->{include} } ) {
		foreach ( @{ $opt->{include} } ) {
		    $include_map{$_}
			or Carp::croak "Unknown inclusion '$_'";
		    $incl{$_} = 1;
		}
	    }

	    keys %incl
		and $rest{OBJECT_TYPE} = join ',',
		    map { $include_map{$_} } sort keys %incl;

	}

	return \%rest;
    }

    my @legal_search_args = (
	'rcs!' => '(ignored and deprecated)',
	'tle!' => '(return TLE data from search (defaults true))',
	'status=s' => q{('onorbit', 'decayed', or 'all')},
	'exclude=s@' => q{('payload', 'debris', 'rocket', ... )},
	'include=s@' => q{('payload', 'debris', 'rocket', ... )},
	'comment!' => '(include comment in satcat data)',
    );
    my %legal_search_status = map {$_ => 1} qw{onorbit decayed all};

    sub _get_search_options {
	return \@legal_search_args;
    }

    sub _parse_search_args {
	my ( $self, @args ) = @_;

	my $extra = ARRAY_REF eq ref $args[0] ? shift @args : [];
	@args = $self->_parse_retrieve_args(
	    [ @legal_search_args, @{ $extra } ], @args );

	my $opt = $args[0];

	$opt->{status} ||= 'onorbit';

	$legal_search_status{$opt->{status}} or Carp::croak <<"EOD";
Error - Illegal status '$opt->{status}'. You must specify one of
	@{[join ', ', map {"'$_'"} sort keys %legal_search_status]}
EOD

	foreach my $key ( qw{ exclude include } ) {
	    $opt->{$key} ||= [];
	    $opt->{$key} = [ map { split ',', $_ } @{ $opt->{$key} } ];
	    foreach ( @{ $opt->{$key} } ) {
		$include_map{$_} or Carp::croak <<"EOD";
Error - Illegal -$key value '$_'. You must specify one or more of
	@{[join ', ', map {"'$_'"} sort keys %include_map]}
EOD
	    }
	}

	defined $opt->{tle}
	    or $opt->{tle} = 1;

	return @args;
    }

    my %search_opts = _extract_keys( \@legal_search_args );

    # _remove_search_options
    #
    # Shallow clone the argument hash, remove any search arguments from
    # it, and return a reference to the clone. Used for sanitizing the
    # options for a search before passing them to retrieve() to actually
    # get the TLEs.
    sub _remove_search_options {
	my ( $opt ) = @_;
	my %rslt = %{ $opt };
	delete @rslt{ keys %search_opts };
	return \%rslt;
    }
}

#	@keys = _sort_rest_arguments( \%rest_args );
#
#	This subroutine sorts the argument names in the desired order.
#	A better way to do this may be to use Unicode::Collate, which
#	has been core since 5.7.3.

{

    my %special = map { $_ => 1 } qw{ basicspacedata extendedspacedata };

    sub _sort_rest_arguments {
	my ( $rest_args ) = @_;

	HASH_REF eq ref $rest_args
	    or return;

	my @rslt;

	foreach my $key ( keys %special ) {
	    @rslt
		and Carp::croak "You may not specify both '$rslt[0]' and '$key'";
	    defined $rest_args->{$key}
		and push @rslt, $key, $rest_args->{$key};
	}


	push @rslt, map { ( $_->[0], $rest_args->{$_->[0]} ) }
	    sort { $a->[1] cmp $b->[1] }
	    # Oh, for 5.14 and tr///r
	    map { [ $_, _swap_upper_and_lower( $_ ) ] }
	    grep { ! $special{$_} }
	    keys %{ $rest_args };

	return @rslt;
    }
}

sub _spacetrack_v2_response_is_empty {
    my ( $resp ) = @_;
    return $resp->content() =~ m/ \A \s* (?: [[] \s* []] )? \s* \z /smx;
}

sub __readline_completer {
    my ( $app, $text, $line, $start ) = @_;

    $start
	or return $app->_readline_complete_command( $text );

    my ( $cmd, @cmd_line ) = split $readline_word_break_re, $line, -1;
    $cmd = _verb_alias( $cmd );

    local $COMPLETION_APP = $app;

    if ( my $code = $app->can( "_readline_complete_command_$cmd" ) ) {
	return $code->( $app, $text, $line, $start, \@cmd_line );
    }

    if ( $text =~ m/ \A - /smx and my $code = $app->can( "_${cmd}_opts") ) {
	return _readline_complete_options( $code, $text );
    }


    $catalogs{$cmd}
	and return $app->_readline_complete_catalog( $text, $cmd );

    my @files = File::Glob::bsd_glob( "$text*" );
    if ( 1 == @files ) {
	$files[0] .= -d $files[0] ? '/' : ' ';
    } elsif ( $readline::var_CompleteAddsuffix ) {
	foreach ( @files ) {
	    if ( -l $_ ) {
		$_ .= '@';
	    } elsif ( -d $_ ) {
		$_ .= '/';
	    } elsif ( -x _) {
		$_ .= '*';
	    } elsif ( -S _ || -p _ ) {
		$_ .= '=';
	    }
	}
    }
    $readline::rl_completer_terminator_character = '';
    return @files;
}

sub _readline_complete_catalog {
	my ( $app, $text, $cat ) = @_;
	my $this_cat = $catalogs{$cat};
	if ( ARRAY_REF eq ref $this_cat ) {
	    my $code = $app->can( "_${cat}_catalog_version" )
		or Carp::confess "Bug - _${cat}_catalog_version() not found";
	    $this_cat = $this_cat->[ $code->( $app ) ];
	}
	defined $text
	    and $text ne ''
	    or return( sort keys %{ $this_cat } );
	my $re = qr/ \A \Q$text\E /smx;
	return ( grep { $_ =~ $re } sort keys %{ $this_cat } )
}

{
    my @builtins;
    my %disallow = map { $_ => 1 } qw{
	can getv import isa new
    };
    sub _readline_complete_command {
	my ( $app, $text ) = @_;
	unless ( @builtins ) {
	    push @builtins, qw{ bye exit show };
	    my $stash = ( ref $app || $app ) . '::';
	    no strict qw{ refs };
	    foreach my $sym ( keys %$stash ) {
		$sym =~ m/ \A _ /smx
		    and next;
		$sym =~ m/ [[:upper:]] /smx
		    and next;
		$disallow{$sym}
		    and next;
		$app->can( $sym )
		    or next;
		push @builtins, $sym;
	    }
	    @builtins = sort @builtins;
	}
	my $match = qr< \A \Q$text\E >smx;
	my @rslt = grep { $_ =~ $match } @builtins;
	1 == @rslt
	    and $rslt[0] =~ m/ \W \z /smx
	    and $readline::rl_completer_terminator_character = '';
	return ( sort @rslt );
    }
}

sub _readline_complete_options {
    my ( $code, $text ) = @_;
    $text =~ m/ \A ( --? ) ( .* ) /smx
	or return;
    # my ( $prefix, $match ) = ( $1, $2 );
    my $match = $2;
    my %lgl = @{ $code->() };
    my $re = qr< \A \Q$match\E >smx;
    my @rslt;
    foreach ( keys %lgl ) {
	my $type = '';
	( my $o = $_ ) =~ s/ ( [!=?] ) .* //smx
	    and $type = $1;
	my @names = split qr< \| >smx, $o;
	$type eq q<!>
	    and push @names, map { "no-$_" } @names;
	push @rslt, map { "--$_" } grep { $_ =~ $re } @names;
    }
    return ( sort @rslt );
}

sub _rest_date {
    my ( $time ) = @_;
    return sprintf '%04d-%02d-%02d %02d:%02d:%02d', @{ $time };
}

#	$swapped = _swap_upper_and_lower( $original );
#
#	This subroutine swapps upper and lower case in its argument,
#	using the transliteration operator. It should be used only by
#	_sort_rest_arguments(). This can go away in favor of tr///r when
#	(if!) the minimum version becomes 5.14.

sub _swap_upper_and_lower {
    my ( $arg ) = @_;
    $arg =~ tr/A-Za-z/a-zA-Z/;
    return $arg;
}

#	_source takes a filename, and returns the contents of the file
#	as a list. It dies if anything goes wrong.

sub _source {
    my ( undef, $fn ) = @_;	# Invocant unused
    wantarray or die <<'EOD';
Error - _source () called in scalar or no context. This is a bug.
EOD
    defined $fn or die <<'EOD';
Error - No source file name specified.
EOD
    my $fh = IO::File->new ($fn, '<') or die <<"EOD";
Error - Failed to open source file '$fn'.
        $!
EOD
    return <$fh>;
}

# my $string = _stringify_oid_list( $opt, @oids );
#
# This subroutine sorts the @oids array, and stringifies it by
# eliminating duplicates, combining any consecutive runs of OIDs into
# ranges, and joining the result with commas. The string is returned.
#
# The $opt is a reference to a hash that specifies punctuation in the
# stringified result. The keys used are
#   separator -- The string used to separate OID specifications. The
#       default is ','.
#   range_operator -- The string used to specify a range. If omitted,
#       ranges will not be constructed.
#
# Note that ranges containing only two OIDs (e.g. 5-6) will be expanded
# as "5,6", not "5-6" (presuming $range_operator is '-').

sub _stringify_oid_list {
    my ( $opt, @args ) = @_;

    my @rslt = ( -99 );	# Prime the pump

    @args
	or return @args;

    my $separator = defined $opt->{separator} ? $opt->{separator} : ',';
    my $range_operator = $opt->{range_operator};

    if ( defined $range_operator ) {
	foreach my $arg ( sort { $a <=> $b } @args ) {
	    if ( ARRAY_REF eq ref $rslt[-1] ) {
		if ( $arg == $rslt[-1][1] + 1 ) {
		    $rslt[-1][1] = $arg;
		} else {
		    $arg > $rslt[-1][1]
			and push @rslt, $arg;
		}
	    } else {
		if ( $arg == $rslt[-1] + 1 ) {
		    $rslt[-1] = [ $rslt[-1], $arg ];
		} else {
		    $arg > $rslt[-1]
			and push @rslt, $arg;
		}
	    }
	}
	shift @rslt;	# Drop the pump priming.

	return join( $separator,
	    map { ref $_ ?
		$_->[1] > $_->[0] + 1 ?
		    "$_->[0]$range_operator$_->[1]" :
		    @{ $_ } :
		$_
	    } @rslt
	);

    } else {
	return join $separator, sort { $a <=> $b } @args;
    }

}

eval {
    require Time::HiRes;
    *_sleep = \&Time::HiRes::sleep;
    *_time = \&Time::HiRes::time;
    1;
} or do {
    *_sleep = sub {
	return sleep $_[0];
    };
    *_time = sub {
	return time;
    };
};

#	_trim replaces undefined arguments with '', trims all arguments
#	front and back, and returns the modified arguments.

sub _trim {
    my @args = @_;
    foreach ( @args ) {
	defined $_ or $_ = '';
	s/ \A \s+ //smx;
	s/ \s+ \z //smx;
    }
    return @args;
}

1;

__END__

=back

=head2 Attributes

The following attributes may be modified by the user to affect the
operation of the Astro::SpaceTrack object. The data type of each is
given in parentheses after the attribute name.

Boolean attributes are typically set to 1 for true, and 0 for false.

=over

=item addendum (text)

This attribute specifies text to add to the output of the banner()
method.

The default is an empty string.

=item banner (Boolean)

This attribute specifies whether or not the shell() method should emit
the banner text on invocation.

The default is true (i.e. 1).

=item cookie_expires (number)

This attribute specifies the expiration time of the cookie. You should
only set this attribute with a previously-retrieved value, which
matches the cookie.

=item cookie_name (string)

This attribute specifies the name of the session cookie. You should not
need to change this in normal circumstances, but if Space Track changes
the name of the session cookie you can use this to get you going again.

=item domain_space_track (string)

This attribute specifies the domain name of the Space Track web site.
The user will not normally need to modify this, but if the web site
changes names for some reason, this attribute may provide a way to get
queries going again.

The default is C<'www.space-track.org'>. This will change if necessary
to remain appropriate to the Space Track web site.

=item fallback (Boolean)

This attribute specifies that orbital elements should be fetched from
the redistributer if the original source is offline. At the moment the
only method affected by this is celestrak().

The default is false (i.e. 0).

=item filter (Boolean)

If true, this attribute specifies that the shell is being run in filter
mode, and prevents any output to STDOUT except orbital elements -- that
is, if I found all the places that needed modification.

The default is false (i.e. 0).

=item identity (Boolean)

If this attribute is set to a true value, the C<Astro::SpaceTrack>
object will attempt to load attributes from an identity file. This will
only do anything if the identity file exists and
L<Config::Identity|Config::Identity> is installed. In addition, if the
identity file is encrypted C<gpg2> must be installed and properly
configured. See L<IDENTITY FILE|/IDENTITY FILE> below for details of the
identity file.

I have found that C<gpg> does not seem to work nicely, even though
L<Config::Identity|Config::Identity> prefers it to C<gpg2> if both are
present. The L<Config::Identity|Config::Identity> documentation says
that you can override this by setting environment variable C<CI_GPG>
to the executable you want used.

If this attribute is unspecified (to C<new()> or specified as C<undef>
(to C<new()> or C<set()>), the value of environment variable
C<SPACETRACK_IDENTITY> will be used as the new value.

When a new object is instantiated, the identity is processed first; in
this way attribute values that come from the environment or are
specified explicitly override those that come from the identity file. If
you explicitly set this on an already-instantiated object, the attribute
values from the identity file will replace those in the object.

When you instantiate an object, the identity from environment variable
C<SPACETRACK_USER> will be preferred over the value from the identity
file, if any, even if the C<identity> attribute is explicitly set true.

=item iridium_status_format (string)

This attribute specifies the default format of the data returned by the
C<iridium_status()> method. Valid values are 'kelso', 'sladen' or
'spacetrack'.  See that method for more information.

As of version 0.100_02, the default is C<'kelso'>. It used to be
C<'mccants'>, but Mike McCants no longer maintains his Iridium status
web page, and format C<'mccants'> was removed as of version 0.137.

This attribute is B<deprecated>.

=item max_range (number)

This attribute specifies the maximum size of a range of NORAD IDs to be
retrieved. Its purpose is to impose a sanity check on the use of the
range functionality.

The default is 500.

=item password (text)

This attribute specifies the Space-Track password.

The default is an empty string.

=item pretty (Boolean)

This attribute specifies whether the content of the returned
L<HTTP::Response|HTTP::Response> is to be pretty-formatted. Currently
this only applies to Space Track data returned in C<JSON> format.
Pretty-formatting the C<JSON> is extra overhead, so unless you intend to
read the C<JSON> yourself this should probably be false.

The default is C<0> (i.e. false).

=item prompt (string)

This attribute specifies the prompt issued by the C<shell()> method. The
default is C<< 'SpaceTrack> ' >>.

=item scheme_space_track (string)

This attribute specifies the URL scheme used to access the Space Track
web site. The user will not normally need to modify this, but if the web
site changes schemes for some reason, this attribute may provide a way
to get queries going again.

The default is C<'https'>.

=item session_cookie (text)

This attribute specifies the session cookie. You should only set it
with a previously-retrieved value.

The default is an empty string.

=item space_track_version (integer)

This attribute specifies the version of the Space Track interface to use
to retrieve data. The only valid value is C<2>.  If you set it to a
false value (i.e. C<undef>, C<0>, or C<''>) it will be set to the
default.

The default is C<2>.

=item url_iridium_status_kelso (text)

This attribute specifies the location of the celestrak.org Iridium
information. You should normally not change this, but it is provided
so you will not be dead in the water if Dr. Kelso needs to re-arrange
his web site.

The default is 'https://celestrak.org/SpaceTrack/query/iridium.txt'

This attribute is B<deprecated>.

=item url_iridium_status_mccants (text)

This attribute is B<deprecated>, and any access of it will be fatal.

=item url_iridium_status_sladen (text)

This attribute specifies the location of Rod Sladen's Iridium
Constellation Status page. You should normally not need to change this,
but it is provided so you will not be dead in the water if Mr. Sladen
needs to change his ISP or re-arrange his web site.

The default is 'http://www.rod.sladen.org.uk/iridium.htm'.

This attribute is B<deprecated>.

=item username (text)

This attribute specifies the Space-Track username.

The default is an empty string.

=item verbose (Boolean)

This attribute specifies verbose error messages.

The default is false (i.e. 0).

=item verify_hostname (Boolean)

This attribute specifies whether C<https:> certificates are verified.
If you set this false, you can not verify that hosts using C<https:> are
who they say they are, but it also lets you work around invalid
certificates. Currently only the Space Track web site uses C<https:>.

B<Note> that the default has changed, as follows:

* In version 0.060_08 and earlier, the default was true, to mimic
earlier behavior.

* In version 0.060_09 this was changed to false, in the belief that the
code should work out of the box (which it did not when verify_hostname
was true, at least as of mid-July 2012).

* On September 30 2012 Space Track announced that they had their SSL
certificates set up, so in 0.064_01 the default became false again.

* On August 19 2014 Perl's SSL logic stopped accepting Mike McCants'
GoDaddy certificate, so starting with version 0.086_02 the default is
false once again.

* On December 11 2014 I noticed that Perl was accepting Mike McCants'
certificate again, so starting with version 0.088_01 the default
is restored to true.

If environment variable C<SPACETRACK_VERIFY_HOSTNAME> is defined, its
value will be used as the default of this attribute. Otherwise the
default is false (i.e. 0).

=item webcmd (string)

This attribute specifies a system command that can be used to launch
a URL into a browser. If specified, the 'help' command will append
a space and the metacpan.org URL for the documentation for this
version of Astro::SpaceTrack, and spawn that command to the operating
system. You can use 'open' under Mac OS X, and 'start' under Windows.
Anyone else will probably need to name an actual browser.

As of version 0.105_01, a value of C<'1'> causes
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

The default is C<undef>, which leaves the functionality disabled.

=item with_name (Boolean)

This attribute specifies whether the returned element sets should
include the common name of the body (three-line format) or not
(two-line format). This attribute may be ignored; see the individual
method for details.

The default is false (i.e. 0).

=back

=head1 IDENTITY FILE

This is a L<Config::Identity|Config::Identity> file which specifies the
username and password values for the user. This file is stored in the
user's home directory, and is F<spacetrack.id> under C<MSWin32> or
C<VMS>, or F<.spacetrack-identity> under any other operating system.

If desired, the file can be encrypted using GPG; in this case, to be
useful, C<gpg> and C<gpg-agent> must be installed and properly
configured. Because of implementation details in
L<Config::Identity|Config::Identity>, you may need to either ensure that
C<gpg> is not in your C<PATH>, or set the C<CI_GPG> environment variable
to the path to C<gpg2>. The encrypted file can optionally have C<.gpg>
appended to its name for the convenience of users of the vim-gnupg
plugin and similar software. If the identity file exists both with and
without the C<.gpg> suffix, the suffixed version will be used.

Note that this file is normally read only once during the life of the
Perl process, and the result cached. The username and password that are
set when C<identity> becomes true come from the cache. If you want a
running script to see new identity file information you must call static
method C<flush_identity_cache()>.

=head1 GLOBALS

The following globals modify the behaviour of this class. If you modify
their values, your modifications should be properly localized. For
example:

 {
     local $SPACETRACK_DELAY_SECONDS = 42;
     $rslt = $st->search_name( 'iss' );
 }

=head2 $SPACETRACK_DELAY_SECONDS

This global holds the delay in seconds between queries. It defaults to 3
(or the value of environment variable C<SPACETRACK_DELAY_SECONDS> if
that is true), and should probably not be messed with. But if Space
Track is being persnickety about timing you can set it to a larger
number. This variable must be set to a number. If
L<Time::HiRes|Time::HiRes> is not available this number must be an
integer.

This global is not exported. You must refer to it as
C<$Astro::SpaceTrack::SPACETRACK_DELAY_SECONDS>.

=head1 ENVIRONMENT

The following environment variables are recognized by Astro::SpaceTrack.

=head2 SPACETRACK_DELAY_SECONDS

This environment variable should be set to a positive number to change
the default delay between Space Track queries. This is C<not> something
you should normally need to do. If L<Time::HiRes|Time::HiRes> is not
available this number must be an integer.

This environment variable is only used to initialize
C<$SPACETRACK_DELAY_SECONDS>. If you wish to change the delay you must
assign to the global.

=head2 SPACETRACK_IDENTITY

This environment variable specifies the default value for the identity
attribute any time an undefined value for that attribute is specified.

=head2 SPACETRACK_OPT

If environment variable SPACETRACK_OPT is defined at the time an
Astro::SpaceTrack object is instantiated, it is broken on spaces,
and the result passed to the set command.

If you specify username or password in SPACETRACK_OPT and you also
specify SPACETRACK_USER, the latter takes precedence, and arguments
passed explicitly to the new () method take precedence over both.

=head2 SPACETRACK_TEST_LIVE

If environment variable C<SPACETRACK_TEST_LIVE> is defined to a true
value (in the Perl sense), tests that use the Space Track web site will
actually access it. Otherwise they will either use canned data (i.e. a
regression test) or be skipped.

=head2 SPACETRACK_USER

If environment variable SPACETRACK_USER is defined at the time an
Astro::SpaceTrack object is instantiated, the username and password will
be initialized from it. The value of the environment variable should be
the username and password, separated by either a slash (C<'/'>) or a
colon (C<':'>). That is, either C<'yehudi/menuhin'> or
C<'yehudi:menuhin'> are accepted.

An explicit username and/or password passed to the new () method
overrides the environment variable, as does any subsequently-set
username or password.

=head2 SPACETRACK_VERIFY_HOSTNAME

As of version 0.086_02, if environment variable
C<SPACETRACK_VERIFY_HOSTNAME> is defined at the time an
C<Astro::SpaceTrack> object is instantiated, its value will be used for
the default value of the C<verify_hostname> attribute.

=head2 SPACETRACK_SKIP_OPTION_HASH_VALIDATION

As of version 0.081_01, method options passed as a hash reference will
be validated. Before this, only command-line-style options were
validated. If the validation causes problem, set this environment
variable to a value Perl sees as true (i.e. anything but C<0> or C<''>)
to revert to the old behavior.

Support for this environment variable will be put through a deprecation
cycle and removed once the validation code is deemed solid.

=head1 EXECUTABLES

A couple specimen executables are included in this distribution:

=head2 SpaceTrack

This is just a wrapper for the shell () method.

=head2 SpaceTrackTk

This provides a Perl/Tk interface to Astro::SpaceTrack.

=head1 BUGS

This software is essentially a web page scraper, and relies on the
stability of the user interface to Space Track. The Celestrak
portion of the functionality relies on the presence of .txt files
named after the desired data set residing in the expected location.
The Human Space Flight portion of the functionality relies on the
stability of the layout of the relevant web pages.

This software has not been tested under a HUGE number of operating
systems, Perl versions, and Perl module versions. It is rather likely,
for example, that the module will die horribly if run with an
insufficiently-up-to-date version of LWP.

Support is by the author. Please file bug reports at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Astro-SpaceTrack>,
L<https://github.com/trwyant/perl-Astro-SpaceTrack/issues/>, or in
electronic mail to the author.

=head1 MODIFICATIONS OF HISTORICAL INTEREST

=head2 Data Throttling

Space Track announced August 19 2013 that beginning September 22 they
would limit users to less than 20 API queries per minute. Experience
seems to say they jumped the gun - at least, server errors during
testing were turned into success by throttling queries to one every
three seconds.

The throttling functionality will make use of L<Time::HiRes|Time::HiRes>
if it is available; otherwise it will simply use the built-in C<sleep()>
and C<time()>, with consequent loss of precision.

Unfortunately this makes testing slower. Sorry.

=head2 Quantitative RCS Data

On July 21 2014 Space Track announced the plan to remove quantitative
RCS data (the C<RCSVALUE> field), replacing it with a qualitative field
(C<RCS_SIZE>, values C<'SMALL'> (< 0.1 square meter), C<'MEDIUM'>, (>=
0.1 square meter but < 1 square meter), C<'LARGE'> (> 1 square meter),
and of course, null.

This removal took place August 18 2014. Beginning with version 0.086_02,
any RCS functionality specific to the Space Track web site C<RCSVALUE>
datum (such as the C<-rcs> search option) has been removed. The C<-rcs>
option itself will be put through a deprecation cycle, with the first
release on or after March 1 2015 generating a warning on the first use,
the first release six months later generating a warning on every use,
and the warning becoming fatal six months after that.

On the other hand, the C<RCSVALUE> and C<RCS_SIZE> data will continue
to be returned in such ways and places that the Space Track web site
itself returns them.

=head1 ACKNOWLEDGMENTS

The author wishes to thank Dr. T. S. Kelso of
L<https://celestrak.org/> and the staff of L<https://www.space-track.org/>
(whose names are unfortunately unknown to me) for their co-operation,
assistance and encouragement.

=head1 AUTHOR

Thomas R. Wyant, III (F<wyant at cpan dot org>)

=head1 COPYRIGHT AND LICENSE

Copyright 2005-2025 by Thomas R. Wyant, III (F<wyant at cpan dot org>).

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

The data obtained by this module may be subject to the Space Track user
agreement (L<https://www.space-track.org/documentation#/user_agree>).

=cut

# ex: set textwidth=72 :
