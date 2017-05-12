#!perl
use Test::More tests => 127;

use Astro::WaveBand;
use warnings;
use strict;

use_ok("Astro::WaveBand");

print "# ====== Test constructor ======\n";

# First test that we can not construct a bad object
my $w = new Astro::WaveBand( Wavelength => 850,
			     Instrument => 'SCUBA');

isa_ok($w, "Astro::WaveBand");

# These will return undef and raise an warning
{
  no warnings 'Astro::WaveBand';
  $w = new Astro::WaveBand( Wavelength => 850, Frequency => 345E9);
  is($w, undef, "Test fail modes");

  $w = new Astro::WaveBand();
  is($w, undef, "Test fail modes");

  $w = new Astro::WaveBand( Instrument => 'UFTI');
  is($w, undef, "Test fail modes");
}


# Set up the tests
my @tests = (
             {
              _init => { Wavelength => '1.635',
                         Instrument => 'UFTI'
                       },
              filter => 'H98',
              wavelength => '1.635',
              natural => 'H98',
              waveband => 'infrared',
             },
             {
              _init => { Wavelength => '1.634999999',
                         Instrument => 'UFTI'
                       },
              filter => 'H98',
              wavelength => '1.635',
              natural => 'H98',
              waveband => 'infrared',
             },
             {
              _init => { Filter => 'BrG',
                         Instrument => 'IRCAM'
                       },
              filter => 'BrG',
              wavelength => '2.0',
              natural => 'BrG',
              waveband => 'infrared',
             },
             {
              _init => { Filter => 'BGamma',
                         Instrument => 'WFCAM'
                       },
              filter => 'BGamma',
              wavelength => '2.155',
              natural => 'BGamma',
              waveband => 'infrared',
             },
             {
              _init => { Wavelength => 2.226,
                         Instrument => 'IRCAM'
                       },
              filter => undef,
              wavelength => 2.226,
              natural => 2.226,
              waveband => 'infrared',
             },
             {
              _init => { Filter => '450W',
                         Instrument => 'SCUBA'
                       },
              filter => '450W',
              wavelength => '443',
              frequency => 676732410835.214,
              natural => '450W',
              waveband => 'submm',
             },
             {
              _init => { Frequency => 22E9,
                       },
              filter => undef,
              wavelength => 13626.9299090909,
              frequency => 22E9,
              natural => 13626.9299090909,
              waveband => 'radio',
             },
             {
              _init => { Filter => 'I',
                       },
              filter => 'I',
              wavelength => 0.90,
              wavenumber => 11111.1111111111,
              natural => 'I',
              waveband => 'optical',
             },
             {
              _init => { Filter => 'U',
                       },
              filter => 'U',
              wavelength => 0.365,
              wavenumber => 27397.2602739726,
              natural => 'U',
              waveband => 'optical',
             },
             {
              _init => { Wavenumber => 1500,
                       },
              filter => undef,
              wavelength => 6.66666666666667,
              wavenumber => 1500,
              natural => 6.66666666666667,
              waveband => 'infrared',
             },
             {
              _init => { Filter => "F79B10",
                         Instrument => 'MICHELLE',
                       },
              filter => "F79B10",
              wavelength => 7.9,
              wavenumber => 1265.82278481013,
              natural => "F79B10",
              waveband => 'infrared',
             },
             {
              _init => { Filter => "F79B10",
                         Instrument => 'MICHELLE',
                       },
              filter => "F79B10",
              wavelength => 7.9,
              wavenumber => 1265.82278481013,
              natural => "F79B10",
              waveband => 'infrared',
             },
             {
              _init => { Wavelength => 3.367,
                         Instrument => 'CGS4',
                       },
              filter => undef,
              wavelength => 3.367,
              wavenumber => 2970.00297000297,
              frequency => 89038449064449.1,
              natural => 3.367,
              waveband => 'infrared',
             },
             {
              _init => { Wavelength => 7.9,
                         Instrument => 'MICHELLE',
                       },
              filter => "F79B10",
              wavelength => 7.9,
              wavenumber => 1265.82278481013,
              natural => "F79B10",
              waveband => 'infrared',
             },
             {
              _init => {Frequency => 345.0E9,
                        Instrument => 'RXA3',
                       },
              filter => undef,
              wavelength => 868.9636,
              waveband => 'submm',
              natural => 345E9,
             },
             {
              _init => {Frequency => 345.0E9,
                        Instrument => 'HARP',
                       },
              filter => undef,
              wavelength => 868.9636,
              waveband => 'submm',
              natural => 345E9,
             },
             {
              _init => { Filter => "Z",
                         Instrument => 'WFCAM',
                       },
              filter => "Z",
              wavelength => 0.83,
              wavenumber => 12048.1927711,
              natural => "Z",
              waveband => 'optical',
             },
             {
              _init => { Wavelength => 0.830,
                         Instrument => 'WFCAM',
                       },
              filter => "Z",
              wavelength => 0.83,
              wavenumber => 12048.1927711,
              natural => "Z",
              waveband => 'optical',
             },
             {
              _init => { Filter => "Y_MK",
                         Instrument => 'UFTI',
                       },
              filter => "Y_MK",
              wavelength => 1.022,
              wavenumber => 9784.73581213,
              waveband => 'infrared',
             },
            );

print "# ====== Test behaviour ======\n";

for my $test (@tests) {
  my $obj = new Astro::WaveBand( %{ $test->{_init} });
  print "# Object creation\n";

  isa_ok($obj,"Astro::WaveBand");

  for my $key (keys %$test) {
    next if $key eq '_init';
    unless (defined $obj) {
      skip("skip Object could not be instantiated so no point trying",1);
      next;
    }

    # Correct for significant figures since we have problems
    # with precision. The problem is that natural can be either
    # number or string. Hope there is no problem with 5.5E257 
    # matching as a string...
    my $correct = $test->{$key};
    $correct = sprintf("%7e", $correct) 
      if (defined $correct and $correct !~ /[A-Za-z]/);

    my $fromobj = $obj->$key;
    $fromobj = sprintf("%7e", $fromobj) 
      if (defined $fromobj and $fromobj !~ /[A-Za-z]/);

    # print $obj->$key,"\n";
    print "# $key: ",( defined $correct ? $correct : "<UNDEF>" ) , "\n";

    is($fromobj, $correct,"Compare key $key");
  }

}

print "# ====== Test Alasdair's Modifications ======\n";

# static methods Astro::WaveBand

ok( Astro::WaveBand::has_filter( UIST => 'J98') ,"UIST has J98");
ok( !Astro::WaveBand::has_filter( UIST => 'Kprime'), 
    "UIST does not have Kprime" );
ok(Astro::WaveBand::has_filter( UIST => 'J98', IRCAM => 'K98'),
  "UIST has J98 and IRCAM has K98");
ok(!Astro::WaveBand::has_filter( UIST => 'H98', IRCAM => 'K97'),
  "UIST = H98 and IRCAM=K97 fails");

ok( Astro::WaveBand::has_instrument( UKIRT => 'UIST' ),
  "UKIRT has UIST");
ok( !Astro::WaveBand::has_instrument( UKIRT => 'SCUBA' ),
  "UKIRT does not have SCUBA");

ok( Astro::WaveBand::is_observable( UKIRT => 'Kprime' ),
  "UKIRT has Kprime");
ok( !Astro::WaveBand::is_observable( UKIRT => '850N' ),
  "UKIRT does not have 850N");
ok( Astro::WaveBand::is_observable( JCMT => '850N' ),
  "JCMT has 850N");

print "# ====== Test Brad's Modifications ======\n";

my $wb1 = new Astro::WaveBand( Filter => 'K' );
my $wb2 = new Astro::WaveBand( Wavelength => '2.2' );
my $wb3 = new Astro::WaveBand( Filter => 'J' );
ok( $wb1->equals($wb2), "K is 2.2 microns" );
ok( $wb1 == $wb2, "K is 2.2 microns (using overloaded equality operator)");
ok( $wb1 > $wb3, "K is longer wavelength than J (using overloaded greater than operator)");
ok( $wb3 < $wb1, "J is shorter wavelength than K (using overloaded less than operator)");

# Check equality with same filter but different instrument.
my $wb_ufti = new Astro::WaveBand( Filter => 'Z',
                                   Instrument => 'UFTI' );
my $wb_wfcam = new Astro::WaveBand( Filter => 'Z',
                                    Instrument => 'WFCAM' );
ok( $wb_ufti != $wb_wfcam, "UFTI Z is not equal to WFCAM Z");
ok( ! ( $wb_ufti == $wb_wfcam ), "UFTI Z is not equal to WFCAM Z");

exit;
