use Test::More tests => 3;
use strict;
use warnings;

#
# 1.) Test if Alien::Jerl is available, aka test if this cpan distro works
#
BEGIN { use_ok 'Alien::Jerl' }

my $javaVersion = `java -version 2>&1` || 'missing';
my $version = jerlVersion();
my $alienJerlVersion = alienJerlVersion();
my $noJVM = 'No JVM found, please install java and have it available for execution';

#
# 2.) Run JERL if possible and get version and display
#
RUNJERL: {
if ($javaVersion eq 'missing' or $javaVersion =~ m/error/gis) {
   plan skip_all => $noJVM;
}

skip $noJVM, 1 unless ($javaVersion ne 'missing');

cmp_ok ($version, 'ne', jerlMissingJVMMessage(), 'JVM is not Missing');
}

#
# 3.) Can we run this package and get information
#
THISPKG: {
	 cmp_ok( $alienJerlVersion, '>=', '1.0'                  , 'This package exists' );
}

diag("---------------------------------------------------- [ Test Version info .. ]");
diag("\n Version Info: JERL JAR : $version \n");
diag("\n Version Info: ALIEN::JERL : $alienJerlVersion \n");
diag("---------------------------------------------------- [ .. Test Version info ]");

