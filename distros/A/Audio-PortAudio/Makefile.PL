#!/usr/bin/perl -w
use strict;

use ExtUtils::MakeMaker;

my $fallbacklibs = "-lportaudio -lm -lpthread";
my $libs = "";

print "Testing for pkg-config...";
my $pcversion =  `pkg-config --version`;
if ($pcversion) {
  print "ok ($pcversion)\n";
  my $paversion;
  for (qw(portaudio-2.0 portaudio)) {
    print "Testing for $_...";
    chomp($paversion = `pkg-config --modversion $_`);
    if ($paversion && $paversion >= 19) {
      print "found (v$paversion)\n";
      chomp($libs = `pkg-config --libs $_`);
      last;
    }
    print $paversion ? "unsuitable (v$paversion)\n" : "not found\n";
  }
  if (!$paversion || $paversion < 19) {
    die "\nNo suitable portaudio library found.\nYou need at least portaudio v19 or higher to install this module\nSee http://www.portaudio.com/\n";
  }
}

if (!$libs) {
  my $r = prompt("You don't have pkg-config installed. I can't test if you have
portaudio installed.

If you do have portaudio v19 or higher installed you can continue anyway
Do you want to continue? (y/n)","n");
  if ($r =~ /^n$/i) {
    warn "Exiting\n";
    exit 0;
  }
  $libs = prompt("Please specify your portaudio linker flags",$fallbacklibs);
}




open my $f,">","stream-constants.xs" or die "Can't make stream-constants.xs: $!";
for (qw(paFloat32 paInt16 paInt32 paInt24 paInt8 paUInt8)) {
    (my $perlname = lc($_)) =~ s/^pa//;
    print $f <<ENDC;

unsigned long
$perlname()
    CODE:
    RETVAL = $_;
    OUTPUT:
    RETVAL

ENDC
}

for (qw(paClipOff paDitherOff paNeverDropInput)) {
    my $perlname = $_;
    $perlname =~ s/^pa//;
    $perlname =~ s/([a-z])([A-Z])/${1}_${2}/;
    $perlname = uc($perlname);

    print $f <<ENDC;

unsigned long
$perlname()
    CODE:
    RETVAL = $_;
    OUTPUT:
    RETVAL

ENDC
}
close $f;

WriteMakefile(
    'NAME'		=> 'Audio::PortAudio',
    'VERSION_FROM'	=> 'PortAudio.pm', # finds $VERSION
    'PREREQ_PM'		=> {
			    'Test::More' => 0, 
    }, # e.g., Module::Name => 1.i
    
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
       (AUTHOR     => 'Joost Diepenmaat <jdiepen AT cpan.org>') : ()),
    LIBS              => [$libs], # e.g., '-lm'
    'EXE_FILES'		=> [],
    'OPTIMIZE'		=> '-O',
);

