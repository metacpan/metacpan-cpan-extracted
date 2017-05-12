use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'API::ISPManager',
    VERSION_FROM      => 'lib/API/ISPManager.pm',
    PREREQ_PM         => {
        'Exporter::Lite' => '0',
        # 'XML::LibXML'    => '0',
        'Crypt::SSLeay'  => '0',
        # 'LWP::Protocol::https::Socket' => '0',
        'XML::Simple'    => '0',
        'Getopt::Long'   => '0',
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/API/ISPManager.pm', # retrieve abstract from module
        'EXE_FILES' => [
            'vdsmanager.pl',
            'add_database.pl',
            'add_www_domain.pl',
            'add_mailbox.pl',
        ],
        AUTHOR         => 'nrg <nrg@cpan.org>') : ()),
);
