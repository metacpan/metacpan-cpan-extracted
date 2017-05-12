use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

use lib qw(./src/inc);

# provide the POD documentation
mkdir('./lib');
mkdir('./lib/AFS');
system("cp ./pod/v2/afsperl.pod lib/AFS.pod");
system("cp ./pod/v2/afsperlacl.pod lib/AFS/ACL.pod");
system("cp ./pod/v2/afsperlbase.pod lib/AFS/Base.pod");
system("cp ./pod/v2/afsperlbos.pod lib/AFS/BOS.pod");
system("cp ./pod/v2/afsperlcell.pod lib/AFS/Cell.pod");
system("cp ./pod/v2/afsperlcm.pod lib/AFS/CM.pod");
system("cp ./pod/v2/afsperlfs.pod lib/AFS/FS.pod");
system("cp ./pod/v2/afsperlkas.pod lib/AFS/KAS.pod");
system("cp ./pod/v2/afsperlktck.pod lib/AFS/KTC_EKEY.pod");
system("cp ./pod/v2/afsperlktcp.pod lib/AFS/KTC_PRINCIPAL.pod");
system("cp ./pod/v2/afsperlktct.pod lib/AFS/KTC_TOKEN.pod");
system("cp ./pod/v2/afsperlpts.pod lib/AFS/PTS.pod");
system("cp ./pod/v2/afsperlutils.pod lib/AFS/Utils.pod");
system("cp ./pod/v2/afsperlvldb.pod lib/AFS/VLDB.pod");
system("cp ./pod/v2/afsperlvos.pod lib/AFS/VOS.pod");

my $VERSION = '2.6.4';
WriteMakefile(
              'NAME'         => 'AFS',
              'VERSION'      => $VERSION,
              ($] >= 5.005 ?
                   ('AUTHOR'   => 'Norbert E Gruener <nog@MPA-Garching.MPG.de>',
                    'ABSTRACT' => 'Perl interface to AFS programming APIs',
                   ) : () ),
              'realclean'  => {FILES => "Makefile.bak lib" },
             );

sub MY::postamble {
        '
html:
	cp ./pod/v2/Makefile.inp lib/Makefile
	cp ./pod/v2/zpod2html lib/
	cd lib && $(MAKE) html

';
}

