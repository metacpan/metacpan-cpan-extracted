use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
use Config;

my $archname = $Config{'archname'};

my $VERSION = "0.3.3";

# provide the POD documentation
mkdir('./lib', 0755);
mkdir('./lib/AFS', 0755);
mkdir('./lib/AFS/Monitor', 0755);
system("cp ./pod/Monitor.pod       lib/AFS/Monitor.pod");
system("cp ./pod/afsmon_stats.pod  lib/AFS/Monitor/afsmon_stats.pod");
system("cp ./pod/afsmonitor.pod    lib/AFS/Monitor/afsmonitor.pod");
system("cp ./pod/cmdebug.pod       lib/AFS/Monitor/cmdebug.pod");
system("cp ./pod/rxdebug.pod       lib/AFS/Monitor/rxdebug.pod");
system("cp ./pod/scout.pod         lib/AFS/Monitor/scout.pod");
system("cp ./pod/udebug.pod        lib/AFS/Monitor/udebug.pod");
system("cp ./pod/xstat_cm_test.pod lib/AFS/Monitor/xstat_cm_test.pod");
system("cp ./pod/xstat_fs_test.pod lib/AFS/Monitor/xstat_fs_test.pod");


WriteMakefile(
              'NAME'       => 'AFS::Monitor',
              'VERSION'    => $VERSION,
              ($] >= 5.005 ?
                   ('AUTHOR'   => 'Alf Wachsmann, Elizabeth Cassell, and Steven Jenkins',
                    'ABSTRACT' => 'Perl interface to AFS monitoring and debugging APIs'
                   ) : () ),
              'realclean'  => {FILES => 'Makefile.bak pod/*.html pod/pod2htm* lib/AFS/*.pod lib/AFS/Monitor/*.pod examples/debug_out/debug examples/debug_out/outputfile lib'},
             );


sub MY::postamble {
	'
html: Makefile
	cd pod && $(MAKE) html

pod: blib
	cp pod/Monitor.pod       lib/AFS/Monitor.pod
	cp pod/afsmon_stats.pod  lib/AFS/Monitor/afsmon_stats.pod
	cp pod/afsmonitor.pod    lib/AFS/Monitor/afsmonitor.pod
	cp pod/cmdebug.pod       lib/AFS/Monitor/cmdebug.pod
	cp pod/rxdebug.pod       lib/AFS/Monitor/rxdebug.pod
	cp pod/scout.pod         lib/AFS/Monitor/scout.pod
	cp pod/udebug.pod        lib/AFS/Monitor/udebug.pod
	cp pod/xstat_cm_test.pod lib/AFS/Monitor/xstat_cm_test.pod
	cp pod/xstat_fs_test.pod lib/AFS/Monitor/xstat_fs_test.pod
';
}
