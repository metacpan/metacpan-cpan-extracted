use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Catalyst::TraitFor::Controller::Breadcrumb::Followed',
    VERSION_FROM      => 'lib/Catalyst/TraitFor/Controller/Breadcrumb/Followed.pm', # finds $VERSION
    PREREQ_PM         => {
        'Test::More'            => 0,
        'Data::Dumper'          => 0,
        'FindBin'               => 0,
        'Test::Exception'       => 0,
        'Moose::Role'           => 0,
        'namespace::autoclean'  => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Catalyst/TraitFor/Controller/Breadcrumb/Followed.pm', # retrieve abstract from module
       AUTHOR         => 'Ian Docherty <pause@icydee.com>') : ()),
);
