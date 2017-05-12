use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Catalyst::TraitFor::Controller::jQuery::jqGrid',
    VERSION_FROM      => 'lib/Catalyst/TraitFor/Controller/jQuery/jqGrid.pm', # finds $VERSION
    PREREQ_PM         => {
        'Test::More'            => 0,
        'Data::Dumper'          => 0,
        'FindBin'               => 0,
        'Test::Exception'       => 0,
        'Moose::Role'           => 0,
        'namespace::autoclean'  => 0,
        'DBICx::TestDatabase'   => 0.04,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Catalyst/TraitFor/Controller/jQuery/jqGrid.pm', # retrieve abstract from module
       AUTHOR         => 'Ian Docherty <pause@iandocherty.com>') : ()),
);
