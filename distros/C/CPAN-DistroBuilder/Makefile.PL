use ExtUtils::MakeMaker;

use strict;

my %required =
    (
     "CPAN"       => 0,
     "File::Find" => 0,
     "File::Spec" => 0,
    );

# using bundles?
#'Bundle::libnet' => '0.1',

WriteMakefile
    (NAME         => 'CPAN-DistroBuilder',
     VERSION_FROM => 'lib/CPAN/DistroBuilder.pm',
     PREREQ_PM    => \%required,
     dist         => {
                      PREOP => 'pod2text lib/CPAN/DistroBuilder.pm > $(DISTVNAME)/README', 
                     }
    );
