use ExtUtils::MakeMaker;

use Lite ;
my %defaults = @BerkeleyDB::Lite::defaults ;
print "NOTE:\n" ;
print "  BerkeleyDB::Lite currently has the following default values:\n" ;
print join "", map { "    $_ => $defaults{$_}\n" } keys %defaults ;
print "\n  Edit Lite.pm and change these values appropriately\n\n" ;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'BerkeleyDB::Lite',
    'VERSION_FROM'	=> 'Lite.pm', # finds $VERSION
    'PREREQ_PM'		=> { BerkeleyDB => 0,
			Storable => 0,
			}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Lite.pm', # retrieve abstract from module
       AUTHOR     => 'Jim Schueler <jschueler@tqis.com>') : ()),
);
