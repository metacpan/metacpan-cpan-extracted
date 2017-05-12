
use 5.008;
use ExtUtils::MakeMaker;

our $EUMM_VERSION = eval $ExtUtils::MakeMaker::VERSION;

WriteMakefile(
    NAME              => 'Data::VString',
    VERSION_FROM      => 'lib/Data/VString.pm', 
    PREREQ_PM         => {
        Carp                     => 0,
        Test::More               => 0,
    }, 
    ($] >= 5.005 ? (
      ABSTRACT_FROM  => 'lib/Data/VString.pm', 
      AUTHOR         => 'A. R. Ferreira <ferreira@cpan.org>',
     ) : ()),
     ($EUMM_VERSION >= 6.31 ? (
       LICENSE        => 'perl',
       EXTRA_META     => "recommends:\n    Test::Pod:  1.18\n", # XXX
     ) : ()),
);
