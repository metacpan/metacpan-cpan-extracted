# Astro::Aladin test harness

# strict
use strict;

#load test
use Test;
BEGIN { plan tests => 2 };

unless ( defined $ENV{ALADIN_JAR} ) {
  for (1..2) {
    skip("Skiping environment variable \$ALADIN_JAR not defined", 1);
  }
  exit;
}

# load modules
use Astro::Aladin;

# debugging
use Data::Dumper;

# Check for threading
use Config;
print "# Config: useithreads = " . $Config{'useithreads'} . "\n";
print "# Config: threads::shared loaded\n" if($threads::shared::threads_shared);

# T E S T   H A R N E S S --------------------------------------------------

# Check Perl version number
print "# Perl Version $]\n";
print "# \$ALADIN_JAR $ENV{ALADIN_JAR}\n" if defined $ENV{ALADIN_JAR};

# test the test system
ok(1);

print "#\n# Buidling Astro::Aladin object\n";
my $aladin = new Astro::Aladin(  );

                              
print "# Querying Edinburgh SuperCOSMOS catalogue server...\n";
my $file;
ok ( $file = $aladin->supercos_catalog( RA     => "15 16 06.9",
                                        Dec    => "-60 57 26.1",
                                        Radius => "2",
                                        File   => "./tmp.cat", 
                                        Band   => "UKST Blue" ) );
                                      
print "# Returned \$file = $file \n";
