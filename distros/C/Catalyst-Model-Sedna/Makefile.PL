use 5.010000;
use ExtUtils::MakeMaker;

WriteMakefile
  ( NAME              => 'Catalyst::Model::Sedna',
    VERSION_FROM      => 'lib/Catalyst/Model/Sedna.pm',
    PREREQ_PM         => { Sedna => 0.002, Moose => 0.90, Catalyst::Runtime => 5.8 },
    ($] >= 5.005 ?
     (ABSTRACT_FROM  => 'lib/Catalyst/Model/Sedna.pm',
      AUTHOR         => 'Daniel Ruoso <daniel@ruoso.com>') : ()),
  );
