use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'API::CPanel',
    VERSION_FROM      => 'lib/API/CPanel.pm',
    PREREQ_PM         => {
        'Exporter::Lite' => '0',
        'XML::Simple'    => '0',
        'Getopt::Long'   => '0',
        'LWP::UserAgent' => '0',
        'Data::Dumper'   => '0',
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/API/CPanel.pm', # retrieve abstract from module
       AUTHOR         => 'Konstantin Vlasov <knvlasov@reg.ru>') : ()),
);
