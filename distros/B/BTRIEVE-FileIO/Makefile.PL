use ExtUtils::MakeMaker;

WriteMakefile
(
  NAME          => 'BTRIEVE::FileIO'
, VERSION_FROM  => 'FileIO.pm'
, ABSTRACT_FROM => 'FileIO.pm'
, AUTHOR        => 'Steffen Goeldner'
, PREREQ_PM     => { 'BTRIEVE::Native' => 0 }
);
