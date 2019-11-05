package main;

use strict;
use warnings;

use lib qw{ inc };
use My::Module::Test::App;

use Test::More 0.88;
use Astro::Coord::ECI::TLE;
use Astro::Coord::ECI::Utils qw{ deg2rad };
use Cwd qw{ cwd };
use File::HomeDir;
use Scalar::Util 1.26 qw{ blessed };

{
    local $@ = undef;

    use constant HAVE_TLE_IRIDIUM	=> eval {
	require Astro::Coord::ECI::TLE::Iridium;
	Astro::Coord::ECI::TLE::Iridium->VERSION( 0.077 );
	1;
    } || 0;
}

$| = 1;	## no critic (RequireLocalizedPunctuationVars)

use Astro::App::Satpass2;

klass   'Astro::App::Satpass2';

call_m  new => INSTANTIATE, 'Instantiate app';

call_m  set => autoheight => undef, stdout => undef, undef,
    q{Clear autoheight and stdout};

call_m  formatter => gmt => 0, TRUE, q{Set formatter gmt false};

# NOTICE
#
# The execute_filter attribute is undocumented and unsupported. It
# exists only so I can scavenge the user's initialization file for the
# (possible) Space Track username and password, to be used in testing,
# without being subject to any other undesired side effects, such as
# running a prediction and exiting. If I change my mind on how or
# whether to do this, execute_filter will be altered or retracted
# without warning, much less a deprecation cycle. If you have a
# legitimate need for this functionality, contact me.
#
# YOU HAVE BEEN WARNED.

call_m  set => execute_filter => sub {
	my ( undef, $args ) = @_;	# Invocant unused
	@{ $args } > 2
	    and $args->[0] eq 'formatter'
	    and $args->[1] eq 'gmt'
	    and return;
	return 1;
    }, undef, 'Filter out the formatter gmt command';

my $can_filter = 1;

execute 'formatter gmt 1', undef,
    'Attempt to set gmt with filter in place';

call_m  formatter => gmt => 0, 'Confirm gmt still false'
    or $can_filter = 0;

# NOTICE
# The execute_filter attribute is undocumented and unsupported.

call_m  set => execute_filter => sub { return 1 }, undef,
    'Turn off the execute filter';

execute 'formatter gmt 1', undef,
    'Attempt to set gmt with no filter in place';

call_m formatter => gmt => 1, 'Confirm gmt now true';

SKIP: {

    my $tests = 2;

    load_or_skip 'File::Temp', $tests;

    my %failing_os = map { $_ => 1 } qw{ MSWin32 };

    $failing_os{$^O}
	and skip "Test of redirect to file fails under $^O for unknown reasons", $tests;

    my $fh = File::Temp->new();
    my $fn = $fh->filename;

    execute "echo Madam, I\\'m Adam >$fn", undef, 'Redirect to file'
	or skip 'Redirect to file failed', --$tests;

    my $got;
    {	# Scope for input record separator
	local $/ = undef;
	$fh->seek( 0, 0 );
	$got = <$fh>;
    }
    chomp $got;

    is $got, q{Madam, I'm Adam}, 'Redirect made it to file';
}

{

    my $got;

    call_m  set => stdout => \$got, undef, 'Set output to scalar ref';

    execute 'echo There was a young lady named Bright', undef,
	'Echo to the scalar ref';

    chomp $got;

    is $got, 'There was a young lady named Bright',
	'Confirm scalar content';
}

{
    my $got;

    call_m set => stdout => sub { $got .= $_[0] }, undef,
	'Set output to subroutine';

    execute 'echo Who could travel much faster than light.', undef,
	'Echo to subroutine';

    chomp $got;
    is $got, 'Who could travel much faster than light.',
	'Confirm output from subroutine';
}

{
    my @output;

    call_m  set => stdout => \@output, undef, 'Set output to array ref';

    execute 'echo She set out one day', undef, 'Echo to array ref';

    my $got = join '', @output;
    chomp $got;

    is $got, 'She set out one day', 'Confirm output to array ref';
}

call_m  set => stdout => undef, undef, 'Clear output attribute';

execute 'echo In a relative way', 'In a relative way',
    'Output is returned';


execute '# And returned the previous night', undef,
    'Comments are ignored';

execute ' ', undef, 'Blank lines are ignored';

{

    my $got = 1;

    SATPASS2_EXECUTE:
    {
	execute 'exit', undef, 'Exit';
	$got = 0;
    }
    ok $got, 'Exit in fact left the block';
}

execute 'set stdout STDOUT',
    q{Attribute 'stdout' may not be set interactively},
    'Can not set stdout interactively';

execute 'foo \'bar', 'Unclosed single quote',
    'Bad command - unclosed quote';

execute 'foo ${1', 'Missing right curly bracket',
    'Bad command - missing right curly';

execute 'foo >>>bar', 'Syntax error near >>>',
    'Bad command - invalid redirect';

execute 'foo', 'Unknown interactive method \'foo\'',
    'Unknown interactive method';

execute 'alias', HAVE_TLE_IRIDIUM ? <<'EOD' : <<'EOD', 'Default aliases';
alias iridium Astro::Coord::ECI::TLE::Iridium
alias moon Astro::Coord::ECI::Moon
alias sun Astro::Coord::ECI::Sun
alias tle Astro::Coord::ECI::TLE
EOD
alias moon Astro::Coord::ECI::Moon
alias sun Astro::Coord::ECI::Sun
alias tle Astro::Coord::ECI::TLE
EOD

execute 'alias fubar sun', undef, 'Add an alias';

execute 'alias', HAVE_TLE_IRIDIUM ? <<'EOD' : <<'EOD',
alias fubar Astro::Coord::ECI::Sun
alias iridium Astro::Coord::ECI::TLE::Iridium
alias moon Astro::Coord::ECI::Moon
alias sun Astro::Coord::ECI::Sun
alias tle Astro::Coord::ECI::TLE
EOD
alias fubar Astro::Coord::ECI::Sun
alias moon Astro::Coord::ECI::Moon
alias sun Astro::Coord::ECI::Sun
alias tle Astro::Coord::ECI::TLE
EOD
    'Confirm addition of alias';

execute 'alias fubar \'\'', undef, 'Remove new alias';

execute 'alias', HAVE_TLE_IRIDIUM ? <<'EOD' : <<'EOD', 'Confirm alias removal';
alias iridium Astro::Coord::ECI::TLE::Iridium
alias moon Astro::Coord::ECI::Moon
alias sun Astro::Coord::ECI::Sun
alias tle Astro::Coord::ECI::TLE
EOD
alias moon Astro::Coord::ECI::Moon
alias sun Astro::Coord::ECI::Sun
alias tle Astro::Coord::ECI::TLE
EOD

execute 'set warn_on_empty 0', undef, 'No warning for empty lists';

execute 'show appulse', 'set appulse 0', 'Default appulse value';

execute 'set appulse 10', undef, 'Change appulse value to 10';

execute 'show appulse', 'set appulse 10', 'Appulse value now 10';

execute 'set latitude 51d28m38s', undef, 'Set latitude';

execute 'show latitude', 'set latitude 51.4772', 'Latitude value';

execute 'set longitude 18:51:50', undef,
    'Longitude in right ascension notation, just to test parse';

execute 'show longitude', 'set longitude -77.042',
    'Confirm results of right ascenscion parse';

execute 'set longitude 0', undef, 'Set longitude';

execute 'show longitude', 'set longitude 0', 'Longitude value';

execute 'set height 2', undef, 'Set height above sea level';

execute 'show height', 'set height 2', 'Height above sea level';

execute 'location', <<'EOD', 'Location command with no name';
Location:
          Latitude 51.4772, longitude 0.0000, height 2 m
EOD

execute q{set location 'Royal Observatory, Greenwich England'},
    undef, q{Set our location's name};

execute 'show location',
    q<set location 'Royal Observatory, Greenwich England'>,
    'Name of location';

execute 'location', <<'EOD', 'Location command with name';
Location: Royal Observatory, Greenwich England
          Latitude 51.4772, longitude 0.0000, height 2 m
EOD

execute 'set date_format %d/%m/%Y time_format "%I:%M:%S %p"',
    undef, 'Set date and time format';

execute 'formatter date_format', 'formatter date_format %d/%m/%Y',
    'Show date format directly';

execute 'formatter time_format',
    q<formatter time_format '%I:%M:%S %p'>,
    'Show time format directly';

execute 'formatter date_format %Y/%m/%d',
    undef, 'Set date format directly';

execute 'formatter time_format %H:%M:%S',
    undef, 'Set time format directly';

execute 'show date_format',
    'formatter date_format %Y/%m/%d',
    'Show date format';

execute 'show time_format',
    'formatter time_format %H:%M:%S',
    'Show time format';

execute q{almanac '20090401T000000Z'},
    <<'EOD', 'Almanac for April Fools 2009';
2009/04/01 00:04:00 local midnight
2009/04/01 01:17:47 Moon set
2009/04/01 05:01:29 begin twilight
2009/04/01 05:35:18 Sunrise
2009/04/01 08:23:38 Moon rise
2009/04/01 12:03:51 local noon
2009/04/01 17:21:29 Moon transits meridian
2009/04/01 18:33:28 Sunset
2009/04/01 19:07:26 end twilight
EOD

execute q{almanac -notransit '20090401T000000Z'},
    <<'EOD', 'Almanac for April Fools 2009';
2009/04/01 01:17:47 Moon set
2009/04/01 05:01:29 begin twilight
2009/04/01 05:35:18 Sunrise
2009/04/01 08:23:38 Moon rise
2009/04/01 18:33:28 Sunset
2009/04/01 19:07:26 end twilight
EOD

execute q{almanac -rise -transit '20090401T000000Z'},
    <<'EOD', 'Almanac for April Fools 2009';
2009/04/01 00:04:00 local midnight
2009/04/01 01:17:47 Moon set
2009/04/01 05:35:18 Sunrise
2009/04/01 08:23:38 Moon rise
2009/04/01 12:03:51 local noon
2009/04/01 17:21:29 Moon transits meridian
2009/04/01 18:33:28 Sunset
EOD

execute 'begin', undef, 'Begin local block';

execute 'show horizon', 'set horizon 20', 'Confirm horizon setting';

execute 'show twilight', 'set twilight civil', 'Confirm twilight setting';

call_m   __TEST__raw_attr => _twilight => '%.6f', '-0.104720',
    'Confirm civil twilight in radians';

execute 'localize horizon twilight', undef, 'Localize horizon and twilight';

execute 'export horizon 15', undef, 'Export horizon, setting its value';

execute 'show horizon', 'set horizon 15', 'Confirm that the horizon was set';

execute q<system perl t/printenv.pl horizon>, 'horizon=15',
    'Confirm that the horizon was exported';

execute 'set horizon 25', undef, 'Set horizon to 25' ;

execute 'show horizon', 'set horizon 25', 'Confirm new horizon value';

execute q<system perl t/printenv.pl horizon>, 'horizon=25',
    'Confirm that the new horizon was exported';

execute 'set twilight astronomical', undef, 'Set twilight to astronomical';

execute 'show twilight', 'set twilight astronomical',
    'Confirm that twilight was set';

call_m  __TEST__raw_attr => _twilight => '%.6f', '-0.314159',
    'Confirm astronomical twilight in radians' ;

execute 'end', undef, 'End local block';

execute 'show horizon', 'set horizon 20', 'Confirm horizon back to 20';

execute q<system perl t/printenv.pl horizon>, 'horizon=20',
    'Confirm exported horizon at 20 also';

execute 'show twilight', 'set twilight civil',
    'Confirm twilight back at civil';

call_m  __TEST__raw_attr => _twilight => '%.6f', '-0.104720',
    'Confirm back at civil twilight in radians' ;

execute 'export BOGUS', 'You must specify a value',
    'Export of environment variable needs a value';

execute 'export BOGUS froboz', undef, 'Export environment variable';

execute 'system perl t/printenv.pl BOGUS', 'BOGUS=froboz',
    'Confirm that value was exported';

execute 'echo Able was I, ere I saw Elba.',
    'Able was I, ere I saw Elba.', 'The echo command';

execute 'echo Able \\',
    'was I, ere I saw Elba.',
    'Able was I, ere I saw Elba.',
    'Assembly of continued line.';

# TODO test height when/if implemented
# TODO test help when/if implemented

execute 'list', undef, 'The list command, with an empty list';

execute 'load t/missing.dat', 'Failed to open',
    'Attempt to load non-existing file';

execute 'load t/data.tle', undef, 'Load a TLE file';

execute 'list', <<'EOD', 'List the loaded items';
   OID Name                     Epoch               Period
 88888                          1980/10/01 23:41:24 01:29:37
 11801                          1980/08/17 07:06:40 10:30:08
EOD

{
    local $ENV{FUBAR} = undef;
    local $ENV{FROBOZZ} = 'Plugh';

    execute 'if loaded 88888 then echo OID 88888 is loaded',
	'OID 88888 is loaded',
	'if loaded 88888, with 88888 loaded';

    execute 'if loaded somesat then echo Somesat is loaded', undef,
	'if loaded somesat, with somesat not loaded';

    execute 'if env FUBAR then echo FUBAR is defined', undef,
	'if env FUBAR, with FUBAR not defined';

    execute 'if not env FUBAR then echo FUBAR is not defined',
	'FUBAR is not defined',
	'if not env FUBAR, with FUBAR not defined';

    execute 'if env FROBOZZ then echo FROBOZZ is defined',
	'FROBOZZ is defined',
	'if env FROBOZZ, with FROBOZZ defined';

    execute 'if not env FROBOZZ then echo FROBOZZ is not defined', undef,
	'if not env FROBOZZ, with FROBOZZ defined';

    execute 'if env FUBAR and env FROBOZZ then echo both defined', undef,
	'if env FUBAR and env FROBOZZ, only FROBOZZ defined';

    execute 'if env FUBAR or env FROBOZZ then echo one defined',
	'one defined',
	'if env FUBAR or env FROBOZZ, only FROBOZZ defined';

    execute 'if not ( env FUBAR and env FROBOZZ ) then echo not both defined',
	'not both defined',
	'if not ( env FUBAR and env FROBOZZ ), only FROBOZZ defined';

    {

	my $os = ( $^O =~ m/ \A fubar \z /smxi ) ? 'Frobozz' : 'Fubar';

	execute "if os '$^O' then echo Running under $^O",
	    "Running under $^O",
	    "if os '$^O', running under $^O";

	execute "if os '$os' then echo Running under $os", undef,
	    "if os '$os', running under $^O";

	execute "if os '$os|$^O' then echo Running under $os or $^O",
	    "Running under $os or $^O",
	    "if os '$os|$^O', running under $^O";

    }

    execute 'if attr horizon then echo the horizon is $horizon',
	'the horizon is 20',
	'if attr horizon, with horizon set';

    execute 'if attr formatter.time_format then echo $formatter.time_format',
	'%H:%M:%S',
	'if attr formatter.time_format';

    execute 'if env FUBAR then begin', undef,
	'if env FUBAR then begin, with FUBAR undefined';

    execute 'echo hello sailor', undef,
	'echo in unsatisfied if() should do nothing';

    execute 'end', undef, 'end of unsatisfied if';

    execute 'echo plugh', "plugh\n", 'echo should now execute';

    execute 'if -z "$FUBAR" then echo FUBAR empty', "FUBAR empty\n", '-z';

    execute 'if -z "$FROBOZZ" then echo FROBOZZ empty', undef,
	'Unsatisfied -z';

    execute 'if -n "$FROBOZZ" then echo FROBOZZ not empty',
	"FROBOZZ not empty\n", '-n';

    execute 'if -n "$FUBAR" then echo FUBAR not empty', undef,
	'Unsatisfied -n';

    execute <<'EOD', 'Something happened', 'Error';
error 'Something happened'
echo 'Nothing happened'
EOD
}

execute 'status clear', undef, 'Clear status for testing' ;

execute 'status', '', 'Nothing in status' ;

SKIP: {
    HAVE_TLE_IRIDIUM
	or skip 'Astro::Coord::ECI::TLE::Iridium not installed', 3;

    execute q{status add 88888 iridium + 'Iridium 88888'}, undef,
	'Pretend OID 88888 is an Iridium' ;

    execute 'status', <<'EOD', 'Iridium 88888 in status';
status add 88888 iridium + 'Iridium 88888' ''
EOD

    execute q{flare '19801013T000000Z' '+1'}, <<'EOD', 'Predict flare';
                                                     Degre
                                                      From   Center Center
Time     Name         Eleva  Azimuth      Range Magn   Sun  Azimuth  Range
1980/10/13
05:43:26               29.9  48.1 NE      412.9 -0.4 night  76.2 E    49.9
EOD
}

execute 'choose 88888', undef, 'Keep OID 88888, losing all others';

execute 'list', <<'EOD', 'Check that the list now includes only 88888';
   OID Name                     Epoch               Period
 88888                          1980/10/01 23:41:24 01:29:37
EOD

execute 'tle', <<'EOD', 'List the TLE for object 888888';
1 88888U          80275.98708465  .00073094  13844-3  66816-4 0    8
2 88888  72.8435 115.9689 0086731  52.6988 110.5714 16.05824518  105
EOD

execute 'clear', undef, 'Remove all items from the list';

execute 'list', undef, 'Confirm that the list is empty again';

execute 'load t/data.tle', undef, 'Load the TLE file again';

execute 'tle', <<'EOD', 'List the loaded TLEs';
1 88888U          80275.98708465  .00073094  13844-3  66816-4 0    8
2 88888  72.8435 115.9689 0086731  52.6988 110.5714 16.05824518  105
1 11801U          80230.29629788  .01431103  00000-0  14311-1
2 11801  46.7916 230.4354 7318036  47.4722  10.4117  2.28537848
EOD

execute 'drop 88888', undef, 'Drop object 88888';

execute 'tle', <<'EOD', 'List the TLEs for object 11801';
1 11801U          80230.29629788  .01431103  00000-0  14311-1
2 11801  46.7916 230.4354 7318036  47.4722  10.4117  2.28537848
EOD

execute 'tle -verbose', <<'EOD', 'Verbose TLE for object 11801';
OID: 11801
    Name:
    International Launch Designator:
    Epoch: 1980/08/17 07:06:40 GMT
    Effective Date: <none> GMT
    Classification: U
    Mean Motion: 0.57134462 degrees/minute
    First Derivative: 2.48455382e-06 degrees/minute squared
    Second Derivative: 0.00000e+00 degrees/minute cubed
    B Star Drag: 1.43110e-02
    Ephemeris Type:
    Inclination: 46.7916 degrees
    Ascending Node: 15:21:44 in right ascension
    Eccentricity: 0.7318036
    Argument Of Perigee: 47.4722 degrees from ascending node
    Mean Anomaly: 10.4117 degrees
    Element Number:
    Revolutions At Epoch:
    Period: 10:30:08
    Semimajor Axis: 24347.3 kilometers
    Perigee: 151.7 kilometers
    Apogee: 35786.6 kilometers
EOD

execute 'macro brief', undef, 'Brief macro listing, without macros';

execute 'macro define place location', undef, q{Define 'place' macro};

execute 'macro brief', 'place', 'Brief macro listing, with a macro';

execute 'macro list', "macro define place \\\n    location", 'Normal macro listing';

execute 'place', <<'EOD', 'Execute place macro';
Location: Royal Observatory, Greenwich England
          Latitude 51.4772, longitude 0.0000, height 2 m
EOD

execute 'macro delete place', undef, 'Delete place macro';

execute 'macro brief', undef, 'Prove place macro went away';

execute 'macro define say \'echo $1\'', undef, 'Define macro with argument';

execute 'say cheese', 'cheese', 'Execute macro with argument';

execute 'say', '', 'Execute macro without argument';

execute 'macro define say \'echo ${1:-Uncle Albert}\'', undef,
    'Redefine macro with argument and default';

execute 'say cheese', 'cheese', 'Execute macro with explicit argument';

execute 'say', 'Uncle Albert', 'Execute macro defaulting argument';

execute 'macro define say \'echo ${fubar:=Cheezburger} $fubar\'', undef,
    'Redefine doubletalk macro with := default';

execute 'say', 'Cheezburger Cheezburger', 'Execute doubletalk with default';

execute 'export fubar cheese', undef, 'Export a value for fubar';

call_m  __TEST__is_exported => 'fubar', 1, 'Fubar is exported';

execute 'say cheese', 'cheese cheese', 'Execute doubletalk macro';

execute  'unexport fubar', undef, 'Undo the export';

call_m  __TEST__is_exported => 'fubar', 0, 'Fubar is no longer exported';

execute 'say', 'Cheezburger Cheezburger', 'Execute doubletalk with default';

call_m  __TEST__is_exported => 'fubar', 0, 'Fubar is no longer exported';

{

    local $ENV{fubar} = 'gorgonzola';

    execute say => 'gorgonzola gorgonzola',
	'Execute doubletalk with environment value';
}

execute 'macro define say \'echo ${1:?Nothing to say}\'', undef,
    'Redefine macro with error';

execute 'say cheese', 'cheese', 'Execute macro, no error';

execute 'say', 'Nothing to say', 'Execute macro, triggering error';

execute 'macro define say \'echo ${1:+something}\'', undef,
    'Redefine macro overriding argument';

execute 'say cheese', 'something', 'Check that argument is overridden';

execute 'say', '', 'Check that override does not appear without argument';

execute q<macro define say 'echo ${1:2:4}'>, undef,
    'Redefine macro with substring operator';

execute 'say abcdefghi', 'cdef', 'Check substring extraction';

execute 'say abcd', 'cd', 'Check substring extraction with short string';

execute 'say a', '', 'Check substring extraction with really short string';

execute 'say', '', 'Check substring extraction with no argument at all';

execute 'macro define say \'echo ${!1}\'', undef,
    'Redefine macro with indirection';

execute 'say horizon', '20', 'Check argument indirection';

{
    no warnings qw{ uninitialized };	# Needed by 5.8.8.
    local $ENV{fubar} = undef;
    execute 'say fubar', '', 'Check argument indirection with missing target';
}

execute 'clear', undef, 'Ensure we have no TLEs loaded';

execute 'load t/data.tle', undef, 'Load our usual set of TLEs';

execute 'pass 19801012T000000Z', <<'EOD',
    Time Eleva  Azimuth      Range Latitude Longitude Altitud Illum Event

1980/10/13     88888 -
05:39:02   0.0 199.0 S      1687.8  37.2228   -6.0197   204.9 lit   rise
05:42:43  55.9 115.6 SE      255.5  50.9259    1.7791   213.1 lit   max
05:46:37   0.0  29.7 NE     1778.5  64.0515   17.6896   224.9 lit   set

1980/10/14     88888 -
05:32:49   0.0 204.8 SW     1691.2  37.6261   -7.7957   205.5 lit   rise
05:36:32  85.6 111.4 E       215.0  51.4245    0.2141   214.4 lit   max
05:40:27   0.0  27.3 NE     1782.5  64.5101   16.6694   226.8 lit   set

1980/10/15     88888 -
05:26:29   0.0 210.3 SW     1693.5  38.1313   -9.4884   206.3 shdw  rise
05:27:33   4.7 212.0 SW     1220.0  42.1574   -7.5648   208.7 lit   lit
05:30:12  63.7 297.6 NW      239.9  51.8981   -1.3250   215.8 lit   max
05:34:08   0.0  25.1 NE     1789.5  64.9426   15.6750   228.8 lit   set

1980/10/16     88888 -
05:20:01   0.0 215.7 SW     1701.3  38.6745  -11.1244   207.2 shdw  rise
05:22:20  14.8 228.1 SW      701.8  47.3322   -6.4800   213.2 lit   lit
05:23:44  43.5 299.4 NW      310.4  52.4061   -2.7900   217.4 lit   max
05:27:40   0.0  23.0 NE     1798.7  65.3494   14.7032   230.8 lit   set

1980/10/17     88888 -
05:13:26   0.0 221.0 SW     1706.4  39.3182  -12.6738   208.3 shdw  rise
05:16:45  28.6 273.8 W       433.1  51.5795   -5.3038   217.8 lit   lit
05:17:08  31.7 301.4 NW      400.0  52.9477   -4.1788   219.1 lit   max
05:21:03   0.0  21.0 N      1809.7  65.7310   13.7503   232.9 lit   set

1980/10/18     88888 -
05:06:44   0.0 226.2 SW     1708.2  40.0617  -14.1335   209.7 shdw  rise
05:10:23  24.5 302.6 NW      495.7  53.4634   -5.5405   220.8 shdw  max
05:10:50  22.3 327.2 NW      537.6  55.0439   -4.0816   222.4 lit   lit
05:14:16   0.0  19.0 N      1814.7  66.0412   12.6971   234.9 lit   set
EOD
    'Calculate passes over Greenwich';

call_m  set => pass_threshold => 60, undef,
    q{Set pass_threshold to 60 degrees};

execute 'pass 19801012T000000Z', <<'EOD',
    Time Eleva  Azimuth      Range Latitude Longitude Altitud Illum Event

1980/10/14     88888 -
05:32:49   0.0 204.8 SW     1691.2  37.6261   -7.7957   205.5 lit   rise
05:36:32  85.6 111.4 E       215.0  51.4245    0.2141   214.4 lit   max
05:40:27   0.0  27.3 NE     1782.5  64.5101   16.6694   226.8 lit   set

1980/10/15     88888 -
05:26:29   0.0 210.3 SW     1693.5  38.1313   -9.4884   206.3 shdw  rise
05:27:33   4.7 212.0 SW     1220.0  42.1574   -7.5648   208.7 lit   lit
05:30:12  63.7 297.6 NW      239.9  51.8981   -1.3250   215.8 lit   max
05:34:08   0.0  25.1 NE     1789.5  64.9426   15.6750   228.8 lit   set
EOD
    'Calculate passes over Greenwich which are over 60 degrees';

call_m  set => pass_threshold => undef, undef,
    q{Set pass_threshold to undef};

execute 'pass -noillumination 19801015T000000Z +1', <<'EOD',
    Time Eleva  Azimuth      Range Latitude Longitude Altitud Illum Event

1980/10/15     88888 -
05:26:29   0.0 210.3 SW     1693.5  38.1313   -9.4884   206.3 shdw  rise
05:30:12  63.7 297.6 NW      239.9  51.8981   -1.3250   215.8 lit   max
05:34:08   0.0  25.1 NE     1789.5  64.9426   15.6750   228.8 lit   set
EOD
    'Calculate passes over Greenwich, without illumination events';

execute 'pass -events 19801015T000000Z +1', <<'EOD',
Date       Time     OID    Event Illum Eleva  Azimuth      Range
1980/10/15 05:26:29  88888 rise  shdw    0.0 210.3 SW     1693.5
1980/10/15 05:27:33  88888 lit   lit     4.7 212.0 SW     1220.0
1980/10/15 05:30:12  88888 max   lit    63.7 297.6 NW      239.9
1980/10/15 05:34:08  88888 set   lit     0.0  25.1 NE     1789.5
EOD
    'Calculate pass events over Greenwich';

execute 'pass -horizon -transit 19801015T000000Z +1', <<'EOD',
    Time Eleva  Azimuth      Range Latitude Longitude Altitud Illum Event

1980/10/15     88888 -
05:26:29   0.0 210.3 SW     1693.5  38.1313   -9.4884   206.3 shdw  rise
05:30:12  63.7 297.6 NW      239.9  51.8981   -1.3250   215.8 lit   max
05:34:08   0.0  25.1 NE     1789.5  64.9426   15.6750   228.8 lit   set
EOD
    'Calculate passes over Greenwich';

execute 'set local_coord equatorial_rng', undef, 'Specify equatorial + range';

execute 'pass 19801013T000000Z +1', <<'EOD',
            Right
    Time Ascensio Decli      Range Latitude Longitude Altitud Illum Event

1980/10/13     88888 -
05:39:02 05:30:58 -36.6     1687.8  37.2228   -6.0197   204.9 lit   rise
05:42:43 09:33:08  29.8      255.5  50.9259    1.7791   213.1 lit   max
05:46:37 16:51:14  32.2     1778.5  64.0515   17.6896   224.9 lit   set
EOD
    'Ensure we get equatorial + range';

execute 'set local_coord azel_rng', undef, 'Specify azel + range';

execute 'pass 19801013T000000Z +1', <<'EOD',
    Time Eleva  Azimuth      Range Latitude Longitude Altitud Illum Event

1980/10/13     88888 -
05:39:02   0.0 199.0 S      1687.8  37.2228   -6.0197   204.9 lit   rise
05:42:43  55.9 115.6 SE      255.5  50.9259    1.7791   213.1 lit   max
05:46:37   0.0  29.7 NE     1778.5  64.0515   17.6896   224.9 lit   set
EOD
    'Ensure we get azel + range';

execute 'set local_coord azel', undef, 'Specify azel only';

execute 'pass 19801013T000000Z +1', <<'EOD',
    Time Eleva  Azimuth Latitude Longitude Altitud Illum Event

1980/10/13     88888 -
05:39:02   0.0 199.0 S   37.2228   -6.0197   204.9 lit   rise
05:42:43  55.9 115.6 SE  50.9259    1.7791   213.1 lit   max
05:46:37   0.0  29.7 NE  64.0515   17.6896   224.9 lit   set
EOD
    'Ensure we get azel only';

execute 'set local_coord az_rng', undef, 'Specify azimuth + range';

execute 'pass 19801013T000000Z +1', <<'EOD',
    Time  Azimuth      Range Latitude Longitude Altitud Illum Event

1980/10/13     88888 -
05:39:02 199.0 S      1687.8  37.2228   -6.0197   204.9 lit   rise
05:42:43 115.6 SE      255.5  50.9259    1.7791   213.1 lit   max
05:46:37  29.7 NE     1778.5  64.0515   17.6896   224.9 lit   set
EOD
    'Ensure we get azimuth + range';

execute 'set local_coord equatorial', undef, 'Specify equatorial only';

execute 'pass 19801013T000000Z +1', <<'EOD',
            Right
    Time Ascensio Decli Latitude Longitude Altitud Illum Event

1980/10/13     88888 -
05:39:02 05:30:58 -36.6  37.2228   -6.0197   204.9 lit   rise
05:42:43 09:33:08  29.8  50.9259    1.7791   213.1 lit   max
05:46:37 16:51:14  32.2  64.0515   17.6896   224.9 lit   set
EOD
    'Ensure we get equatorial only';

execute 'set local_coord', undef, 'Clear local coordinates';

execute 'pass 19801013T000000Z +1', <<'EOD',
    Time Eleva  Azimuth      Range Latitude Longitude Altitud Illum Event

1980/10/13     88888 -
05:39:02   0.0 199.0 S      1687.8  37.2228   -6.0197   204.9 lit   rise
05:42:43  55.9 115.6 SE      255.5  50.9259    1.7791   213.1 lit   max
05:46:37   0.0  29.7 NE     1778.5  64.0515   17.6896   224.9 lit   set
EOD
    'Ensure we get old coordinates back';

execute 'pass -chronological 19801013T000000Z +1', <<'EOD',
    Time Eleva  Azimuth      Range Latitude Longitude Altitud Illum Event

1980/10/13     88888 -
05:39:02   0.0 199.0 S      1687.8  37.2228   -6.0197   204.9 lit   rise
05:42:43  55.9 115.6 SE      255.5  50.9259    1.7791   213.1 lit   max
05:46:37   0.0  29.7 NE     1778.5  64.0515   17.6896   224.9 lit   set
EOD
    'Pass in chronological format';

SKIP: {
    HAVE_TLE_IRIDIUM
	or skip 'Astro::Coord::ECI::TLE::Iridium not installed', 3;

    execute 'set pass_variant brightest', undef, 'Set pass variant brightest';

    execute 'pass 19801013T000000Z +1', <<'EOD',
    Time Eleva  Azimuth      Range Latitude Longitude Altitud Illum Magn Event

1980/10/13     88888 -
05:39:02   0.0 199.0 S      1687.8  37.2228   -6.0197   204.9 lit    7.9 rise
05:42:43  55.9 115.6 SE      255.5  50.9259    1.7791   213.1 lit    3.5 max
05:43:25  30.5  48.7 NE      406.2  53.4292    3.8299   215.0 lit   -0.4 brgt
05:46:37   0.0  29.7 NE     1778.5  64.0515   17.6896   224.9 lit        set
EOD
    'Pass with brightest event';

    execute 'pass -nobrightest 19801013T000000Z +1', <<'EOD',
    Time Eleva  Azimuth      Range Latitude Longitude Altitud Illum Event

1980/10/13     88888 -
05:39:02   0.0 199.0 S      1687.8  37.2228   -6.0197   204.9 lit   rise
05:42:43  55.9 115.6 SE      255.5  50.9259    1.7791   213.1 lit   max
05:46:37   0.0  29.7 NE     1778.5  64.0515   17.6896   224.9 lit   set
EOD
    'Pass without brightest, via -nobrightest';
}

execute 'set pass_variant nobrightest', undef, 'Clear pass variant brightest';

execute 'show pass_variant', <<'EOD',
set pass_variant none
EOD
    'Ensure pass_variant is clear';

SKIP:{
    HAVE_TLE_IRIDIUM
	or skip 'Astro::Coord::ECI::TLE::Iridium not installed', 1;

    execute 'pass -brightest 19801013T000000Z +1', <<'EOD',
    Time Eleva  Azimuth      Range Latitude Longitude Altitud Illum Magn Event

1980/10/13     88888 -
05:39:02   0.0 199.0 S      1687.8  37.2228   -6.0197   204.9 lit    7.9 rise
05:42:43  55.9 115.6 SE      255.5  50.9259    1.7791   213.1 lit    3.5 max
05:43:25  30.5  48.7 NE      406.2  53.4292    3.8299   215.0 lit   -0.4 brgt
05:46:37   0.0  29.7 NE     1778.5  64.0515   17.6896   224.9 lit        set
EOD
    'Pass with brightest event via -brightest';
}

# TODO pass -events

execute q{phase '20090401T000000Z'}, <<'EOD', 'Phase of moon April 1 2009';
      Date     Time     Name Phas Phase             Lit
2009/04/01 00:00:00     Moon   69 waxing crescent    32%
EOD

{
    my $warning;
    local $SIG{__WARN__} = sub {$warning = $_[0]};

    execute 'clear', undef, 'Clear observing list';

    execute 'load t/data.tle', undef, 'Load observing list';

    execute 'choose 88888', undef, 'Restrict ourselves to body 88888';

    execute q{position '20090401T000000Z'}, <<'EOD',
2009/04/01 00:00:00
            Name Eleva  Azimuth      Range               Epoch Illum
             Sun -34.0 358.8 N   1.495e+08
            Moon   8.3 302.0 NW   369373.2
EOD
	'Position of things in sky on 01-Apr-2009 midnight UT';

    like $warning,
	qr{ \QMean eccentricity < 0 or > 1\E }smx,
	'Expect warning on 888888';

    execute 'set local_coord equatorial_rng', undef,
	'Set local_coord to \'equatorial_rng\'';

    execute q{position '20090401T000000Z'}, <<'EOD',
2009/04/01 00:00:00
                    Right
            Name Ascensio Decli      Range               Epoch Illum
             Sun 00:41:56   4.5  1.495e+08
            Moon 05:13:53  26.0   369373.2
EOD
	'Position of things in sky on 01-Apr-2009 midnight UT, equatorial';

    execute 'set local_coord', undef, 'Clear local_coord';

    execute q{position '20090401T000000Z'}, <<'EOD',
2009/04/01 00:00:00
            Name Eleva  Azimuth      Range               Epoch Illum
             Sun -34.0 358.8 N   1.495e+08
            Moon   8.3 302.0 NW   369373.2
EOD
	'Position of things in sky on 01-Apr-2009 midnight UT, in azel again';

}

execute 'pwd', cwd() . "\n", 'Print working directory';

TODO: {
    local $TODO = 'Change in equinox algorithm in Astro::Coord::ECI::Sun';
    execute q{quarters '20090301T000000Z'}, <<'EOD',
2009/03/04 07:45:18 First quarter Moon
2009/03/11 02:37:41 Full Moon
2009/03/18 17:47:34 Last quarter Moon
2009/03/20 11:43:48 Spring equinox
2009/03/26 16:05:47 New Moon
EOD
	'Quarters of Moon and Sun, Mar 1 2009';
}

execute 'sky list', <<'EOD', 'List what is in the sky';
sky add Moon
sky add Sun
EOD

execute 'sky drop moon', undef, 'Get rid of the Moon';

execute 'sky list', 'sky add Sun', 'Confirm the Moon is gone';

execute 'sky add moon', undef, 'Add the Moon back again';

execute 'sky list', <<'EOD', 'Confirm that both sun and moon are in the sky';
sky add Moon
sky add Sun
EOD

execute 'sky clear', undef, 'Remove all bodies from the sky';

execute 'sky list', undef, 'Confirm that there is nothing in the sky';

execute 'sky add sun', undef, 'Add the sun back again';

execute 'sky add moon', undef, 'Add the moon back yet again';

execute 'sky add fubar',
    'You must give at least right ascension and declination',
    'Add unknown body (fails)';

execute q{sky add 'Epsilon Leonis' 9:45:51 23.774 76.86 -0.0461 -0.00957 4.3},
    undef, 'Add Epsilon Leonis';

execute 'sky list', <<'EOD',
sky add 'Epsilon Leonis'  9:45:51  23.774 76.86 -0.0461 -0.00957 4.3
sky add Moon
sky add Sun
EOD
    'Confirm Sun, Moon, and Epsilon Leonis are in the sky';

execute 'source t/source.dat Able was I, ere I saw Elba',
    'Able was I, ere I saw Elba', 'Echo from a source file';

execute 'source -optional t/source.dat There was a young lady named Bright,',
    'There was a young lady named Bright,',
    'Echo from an optional source file';

execute 'source t/missing.dat', 'Failed to open t/missing.dat',
    'Source from a missing file';

execute 'source -optional t/missing.dat', undef,
    'Optional source from a missing file.';

execute 'set horizon 20 geometric 0', undef, 'Set horizon and geometric';

execute 'pass 19801013T000000Z +1', <<'EOD',
    Time Eleva  Azimuth      Range Latitude Longitude Altitud Illum Event

1980/10/13     88888 -
05:41:38  20.0 188.3 S       555.1  46.9747   -0.9601   210.3 lit   rise
05:42:42  55.8 119.1 SE      255.7  50.8560    1.7257   213.1 lit   apls
          49.6 118.3 SE  2.372e+15   6.2 degrees from Epsilon Leonis
05:42:43  55.9 115.6 SE      255.5  50.9259    1.7791   213.1 lit   max
05:43:51  19.9  40.0 NE      572.3  54.9549    5.2332   216.3 lit   set
EOD
    'Calculate pass over Greenwich with appulsed body';

execute 'clear', undef, 'Clear the observing list for validate() check';

execute 'load t/data.tle', undef, 'Load a TLE file for validate() check';

execute 'list', <<'EOD', 'List the loaded items';
   OID Name                     Epoch               Period
 88888                          1980/10/01 23:41:24 01:29:37
 11801                          1980/08/17 07:06:40 10:30:08
EOD

execute 'validate -quiet "19810101T120000Z"', undef, 'Validate for 01-Jan-1981';

execute 'list', <<'EOD', 'List the valid items';
   OID Name                     Epoch               Period
 88888                          1980/10/01 23:41:24 01:29:37
EOD

# TODO test spacetrack (how?)

SKIP: {

    my $tests = 3;

    load_or_skip 'Time::HiRes', $tests;

    my $time = 0;

    no warnings qw{ redefine };

    # Poor man's mock time().
    local *Time::HiRes::time = sub {
	return $time;
    };

    execute 'time begin', undef, 'Begin timed block';

    execute 'echo Hello world', "Hello world\n", 'Execute random command';

    $time = 10;

    execute 'end', "10.000 seconds\n", 'End timed block';
}

execute  'status drop 88888', undef, 'OID 88888 no longer Iridium';

execute  'formatter format position 19801013T054326Z', <<'EOD',
1980/10/13 05:43:26
            Name Eleva  Azimuth      Range               Epoch Illum
           88888  29.9  48.2 NE      412.1 1980/10/01 23:41:24 lit
             Sun  -6.6  94.4 E   1.492e+08
            Moon -41.4  61.1 NE   406131.2
  Epsilon Leonis  49.7 118.5 SE  2.372e+15
EOD
    'Position run from template';

my $dist_dir = cwd();

SKIP: {

    my $tests = 2;

    load_or_skip 'File::Spec', $tests;

    -d 't' or skip 'No t directory found', $tests;
    my $t = File::Spec->catfile( cwd(), 't');

    execute 'cd t', undef, 'Change to t directory';

    same_path cwd(), $t, 'Change to t directory succeeded';

}

SKIP: {

    my $tests = 1;

    my $home;
    eval {
	$home = File::HomeDir->my_home();
	1;
    } or skip "File::HomeDir->my_home() failed: $@", $tests;

    execute 'cd', undef, 'Change to directory, no argument';

    my $got_home = cwd();

    same_path $got_home, $home,
	"Change to home directory succeeded. \$^O = '$^O'";
}

chdir $dist_dir
    or BAIL_OUT "Can not get back to directory '$dist_dir': $!";

call_m clear => undef, 'Clear the observing list';

{
    my $tle = Astro::Coord::ECI::TLE->new(
	name	=> 'Dummy',
	id	=> 666,
    )->geodetic( deg2rad( 40 ), deg2rad( -75 ), 200 );

    call_m add => $tle, TRUE, 'Add a TLE';

    call_m list => <<'EOD', 'Our object is in the list';
   OID Name                     Epoch               Period
   666 Dummy                     40.0000  -75.0000   200.0
EOD

}

execute 'perl -eval Fubar', '"Fubar"', 'perl -eval';

execute 'perl t/whole_app_file', 'OK', 'perl -noeval';

call_m __TEST__frame_stack_depth => 1, 'Object frame stack is clean';

done_testing;

1;

# ex: set textwidth=72 :
