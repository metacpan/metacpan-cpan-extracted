#!perl
# Tests that require Astro::PAL.

use strict;
use Test::More;

# Now try to load Astro::PAL.
eval { require Astro::PAL; };
if( $@ ) {
  print $@;
  plan skip_all => 'Test requires Astro::PAL module';
} else {
  plan tests => 26;
}

require_ok( "Astro::Telescope" );

# Test a PAL telescope.
my $tel = new Astro::Telescope( "JCMT" );

is($tel->name, "JCMT","compare short name");
is($tel->fullname, "JCMT 15 metre","compare long name");
is($tel->lat("s"), "19 49 22.21","compare lat");
is($tel->long("s"), "-155 28 37.30","compare long");
is($tel->alt, 4124.75,"compare alt");
is($tel->obscode, 568,"compare obs code");

# Change telescope to something wrong
$tel->name("blah");
is($tel->name, "JCMT","compare shortname to unknown");

# To something valid
$tel->name("JODRELL1");
is($tel->name, "JODRELL1","switch to Jodrell");
is($tel->obscode, undef,"no obs code");

# Full list of telescope names
my @list = Astro::Telescope->telNames;
ok(scalar(@list),"Count names");

# Check limits of JCMT
$tel->name( 'JCMT' );
my %limits = $tel->limits;

is( $limits{type}, "AZEL","Mount type");
ok(exists $limits{el}{max},"Have max el" );
ok(exists $limits{el}{min},"Have min el" );

# Switch telescope
$tel->name( "UKIRT" );
is( $tel->name, "UKIRT","switch to UKIRT");
is( $tel->fullname, "UK Infra Red Telescope","Long UKIRT name");
is( sprintf("%.9f", $tel->geoc_lat), sprintf("%.9f", "0.343830843"),"UKIRT Geocentric Lat" );
is( $tel->geoc_lat("s"), "19 42 0.20","compare string form of Geo lat");

%limits = $tel->limits;
is( $limits{type}, "HADEC","Mount type");
ok(exists $limits{ha}{max},"Max ha" );
ok(exists $limits{ha}{min},"Min HA" );
ok(exists $limits{dec}{max},"Max dec" );
ok(exists $limits{dec}{min},"Min dec" );

# test constructor that takes a hash
my $new = new Astro::Telescope( Name => $tel->name,
                                Long => $tel->long,
                                Lat  => $tel->lat,
                                Alt => 0,
                              );
ok($new,"Created from long/lat");

is($new->name, $tel->name,"compare name");
is($new->long, $tel->long,"compare long");
