#!perl
use strict;
use Test::More tests => 102;
use Test::Number::Delta within => 1e-9;
use Scalar::Util qw/ looks_like_number /;

require_ok('Astro::Coords');
require_ok('Astro::Telescope');
use Time::Piece ':override';

# Force stringification to use colons
Astro::Coords::Angle->DELIM(':');
Astro::Coords::Angle::Hour->DELIM(':');
Astro::Coords::Angle::Hour->NDP(2);

# Simultaneously test negative zero dec and B1950 to J2000 conversion
my $c = new Astro::Coords( ra => "15:22:33.3",
	                   dec => "-0:13:4.5",
			   type => "B1950");

ok($c, "create object");

is($c->native, 'radec1950', 'check native type');
my ($r1950, $d1950) = $c->radec1950;
is( $r1950->string, "15:22:33.30", "compare B1950 RA");
is( $d1950->string, "-00:13:04.50", "compare B1950 dec");

($r1950, $d1950) = $c->radec1950();
is( $r1950->string, "15:22:33.30", "compare B1950 RA");
is( $d1950->string, "-00:13:04.50", "compare B1950 dec");

print "#J2000: $c\n";
# Compare with J2000 values
is( $c->ra(format=>'s'), "15:25:07.35","compare J2000 RA");
is( $c->dec(format=>'s'), "-00:23:35.76","compare J2000 Dec");

# Calculate distance
my $c2 = new Astro::Coords(ra => "15:22:33.3",
	                   dec => "-0:14:4.5",
			   type => "B1950");

delta_within(scalar($c->distance($c2))*&Astro::PAL::DR2AS, '60.0',
  1.0e-4, "calculate distance");

# Set telescope
my $tel = new Astro::Telescope('JCMT');
my $ukirt = new Astro::Telescope('UKIRT');

# Date/Time
# Something we know
# Approx Fri Sep 14 02:57 2001
my $date = gmtime(1000436215);

# Configure the object
$c->telescope( $tel );
$c->datetime( $date);

# Test Az/El
is( int($c->el(format=>"d")), 67.0, "compare El");
is( int($c->az(format=>"d")), 208.0, "compare Az" );

# Get the summary
my @result = ("RADEC",4.03660853577072,-0.00686380910209873,undef,
	      undef,undef,undef,undef,undef,undef,undef);
my @summary = $c->array;
print "# Compare contents of array() method\n";
test_array_elem(\@summary,\@result);

# observability
ok( $c->isObservable );

# Change telescope and try again
$c->telescope( $ukirt );
ok( $c->isObservable );

# Now for a planet
$c = new Astro::Coords( planet => "mars" );
$c->telescope( $tel );
$c->datetime( $date);

print "# $c\n";
# Test stringify
is("$c", "MARS");

# Test Az/El
is( int($c->el(format=>"d")),  34 );
is( int($c->az(format=>"d")), 145 );

# And apparent ra/dec
is( int($c->ra_app(format=>"h")), 18);
is( int($c->dec_app(format=>"d")), -26);

# Get the summary
@result = ("mars",undef,undef,undef,undef,undef,undef,undef,undef,
	      undef,undef);
@summary = $c->array;
test_array_elem(\@summary,\@result);

# observability
ok( $c->isObservable );


# No tests for elements yet [they are later in file]

# Test Fixed on Earth coordinate frames
# and compare with the previous values for Mars

my $fc = new Astro::Coords( az => $c->az, el => $c->el );
$fc->telescope( $tel );
$fc->datetime( $date);

print "# FIXED: $fc\n";

is($fc->type, "FIXED");

# Test Az/El
is( int($fc->el(format=>"d")),  34 );
is( int($fc->az(format=>"d")), 145 );

# And apparent ra/dec
is( int($fc->ra_app(format=>"h")), 18);
is( int($fc->dec_app(format=>"d")), -26);

# Get the summary
@result = ("FIXED",$fc->az,$fc->el,undef,undef,undef,undef,undef,undef,
	      undef,undef);
@summary = $fc->array;
test_array_elem(\@summary,\@result);

# observability
ok( $fc->isObservable );


# Calibration
print "# CAL\n";
my $cal = new Astro::Coords();

is( $cal->type, "CAL");

# observability
ok( $cal->isObservable );


# Now come up with some coordinates that are not 
# always observable

print "# Observability\n";

$c = new Astro::Coords( ra => "15:22:33.3",
			dec => "-0:13:4.5",
			type => "J2000");

$c->telescope( $tel );
$c->datetime( $date ); # approximately transit
ok( $c->isObservable );

# Change the date by 12 hours
# Approx Fri Sep 14 14:57 2001
my $ndate = gmtime(1000436215 + ( 12*3600) );
$c->datetime( $ndate );
ok(! $c->isObservable );

# switch to UKIRT (shouldn't be observable either)
$c->telescope( $ukirt );
ok( ! $c->isObservable );

# Now use coordinates which can be observed with JCMT
# but not with UKIRT
$c = new Astro::Coords( ra => "15:22:33.3",
			dec => "72:13:4.5",
			type => "J2000");

$c->telescope( $tel );
$c->datetime( $date );

ok( $c->isObservable );
$c->telescope( $ukirt );
ok( !$c->isObservable );


# Verify stringification
$c = new Astro::Coords( ra => '07 42 16.939',
			dec => '-14 42 49.05',
			type => "J2000",
			name => 'OH231.8');

is( $c->dec(format => 'sex'), "-14:42:49.05","Test Dec stringification");
is( $c->ra(format => 'sex'), "07:42:16.94","Test RA stringification");

my $array = $c->dec(format => 'array');
is($array->[0],'-',"test Array sign");
is($array->[1],14, "test Array degrees");
is($array->[2],42, "test Array minutes");
is($array->[3],'49.05',"test Array seconds");

# And again with values that have caused problems in the past
$c = new Astro::Coords( ra => '07 42 16.83',
			dec => '-14 42 52.1',
			type => "J2000",
			name => 'OH231.8 [alternative]');

is( $c->dec(format => 'sex'), "-14:42:52.10","Test Dec stringification");
is( $c->ra(format => 'sex'), "07:42:16.83","Test RA stringification");

$array = $c->dec(format => 'array');
is($array->[0],'-',"test Array sign");
is($array->[1],14, "test Array degrees");
is($array->[2],42, "test Array minutes");
is($array->[3],'52.10',"test Array seconds");

$array = $c->ra(format => 'array');
is($array->[0],7, "test Array degrees");
is($array->[1],42, "test Array minutes");
is($array->[2],'16.83',"test Array seconds");

# Some random comparisons with SCUBA headers
print "# Compare with SCUBA observations\n";


$c = new Astro::Coords( planet => 'mars');
$c->telescope( $tel );

my $time = _gmstrptime("2002-03-21T03:16:36");
$c->datetime( $time);
print "#LST " . ($c->_lst * &Astro::PAL::DR2H). "\n";
is(sprintf("%.1f",$c->az(format => 'd')), '268.5');
is(sprintf("%.1f",$c->el(format => 'd')), '60.3');

# Done as planet now redo it as interpolated
$c = new Astro::Coords( mjd1 => 52354.13556712963,
			mjd2 => 52354.1459837963,
			ra1  => '02:44:26.06',
			dec1 => '016:24:56.44',
			ra2  => '+002:44:27.77',
			dec2 => '+016:25:04.61',
		      );
$c->telescope( $tel );

$time = _gmstrptime("2002-03-21T03:16:36");
$c->datetime( $time);
print "#LST " . ($c->_lst * &Astro::PAL::DR2H). "\n";
is(sprintf("%.1f",$c->az(format => 'd')), '268.5');
is(sprintf("%.1f",$c->el(format => 'd')), '60.3');


$c = new Astro::Coords( ra => '04:42:53.60',
			type => 'J2000',
			dec => '36:06:53.65',
			units => 'sexagesimal',
		      );
$c->telescope( $tel );

# Time is in UT not localtime
$time = _gmstrptime("2002-03-21T06:23:36");
$c->datetime( $time );
print "#LST " . ($c->_lst * &Astro::PAL::DR2H). "\n";

is(sprintf("%.1f",$c->az(format => 'd')), '301.7');
is(sprintf("%.1f",$c->el(format => 'd')), '44.9');

# Comet Hale Bopp
$c = new Astro::Coords( elements => {
				     # from JPL horizons
				     EPOCH => 52440.0000,
				     EPOCHPERIH => 50538.179590069,
				     ORBINC => 89.4475147* &Astro::PAL::DD2R,
				     ANODE =>  282.218428* &Astro::PAL::DD2R,
				     PERIH =>  130.7184477* &Astro::PAL::DD2R,
				     AORQ => 0.9226383480674554,
				     E => 0.9949722217794675,
				    },
		      name => "Hale-Bopp");
ok($c,"instantiate element object");
is($c->name, "Hale-Bopp","check name");
$c->telescope( $tel );

# Time is in UT not localtime
# Reference observation is 19971024_dem_0068
# Inaccuarcies in time of header make this difficult
# so test against horizons
#$time = _gmstrptime("1997-10-24T16:58:32");

# This is for Horizons testing. At this epoch
# we expect RA(2000) 08 09 07.70 DEC(2000) -47 25 27.5
$time = _gmstrptime("1997-10-24T17:00:00");

$c->datetime( $time );
print "# MJD: " . $c->datetime->mjd ."\n";
print "# LST " . ($c->_lst * &Astro::PAL::DR2H). "\n";

# Answer actually stored in the headers is 187.4az and 22.2el
is(sprintf("%.2f",$c->az(format => 'd')), '187.57',"Hale-Bopp azimuth");
is(sprintf("%.1f",$c->el(format => 'd')), '22.1',"Hale-Bopp elevation");

# Limit resolution for comparison
my ($ra_bopp, $dec_bopp) = $c->radec();
$ra_bopp->str_ndp( 0 );
$dec_bopp->str_ndp( 1 );
is($ra_bopp->string,"08:09:08","Hale-Bopp RA (J2000)");
is($dec_bopp->string,"-47:25:27.5","Hale-Bopp Dec (J2000)");

my $s = $c->status;
my @s = split /\n/,$s;
print join("\n", map { "# $_" } @s),"\n";

# and create a new elements object from the HaleBopp version
my $newbopp = new Astro::Coords( elements => [ $c->array ] );
if ($newbopp) {
  $newbopp->datetime( $c->datetime );
  $newbopp->telescope( $c->telescope );
  is( $c->az, $newbopp->az,
      "compare Azimuth from two (supposedly) identical elements");
} else {
  ok(0, "Failed to create clone of elements object");
}

# Make sure we can get a list of planet names
my @planets = Astro::Coords::Planet->planets();
my %pl = map { lc($_) => undef } @planets;
ok( exists $pl{jupiter}, "Jupiter in list of planets" );
ok( exists $pl{sun}, "Sun in list of planets" );
ok( exists $pl{moon}, "Moon in list of planets" );
is( scalar @planets, 9, "Count the number of planets" );

exit;

sub test_array_elem {
  my $ansref  = shift;  # The answer you got
  my $testref = shift;  # The answer you should have got

  # Compare sizes
  is($#$ansref, $#$testref, "Compare number of elements in array");

  for my $i (0..$#$testref) {
    if (defined $ansref->[$i] && looks_like_number($ansref->[$i])) {
      delta_ok($ansref->[$i], $testref->[$i], "Compare array element $i");
    } else {
      is($ansref->[$i], $testref->[$i], "Compare array element $i");
    }
  }

}

sub _gmstrptime {
  # parse ISO date as UT
  my $input = shift;
  my $isoformat = "%Y-%m-%dT%T";
  my $time = Time::Piece->strptime($input, $isoformat);

  # At some point Time::Piece started assuming UT from strptime
  # rather than localtime! Only add on the offset if we have a local
  # time - look inside!
  if ($time->[Time::Piece::c_islocal]) {
    my $tzoffset = $time->tzoffset;
    $time = gmtime($time->epoch() + $tzoffset->seconds);
  }
  return $time;
}
