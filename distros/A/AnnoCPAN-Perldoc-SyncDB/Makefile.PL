use ExtUtils::MakeMaker;
WriteMakefile(
   'NAME'		=> 'AnnoCPAN::Perldoc::SyncDB',
   'VERSION_FROM'	=> 'lib/AnnoCPAN/Perldoc/SyncDB.pm',
   'PREREQ_PM'	=> {
      'Test::More'               => 0,
      'LWP::UserAgent'           => 0,
      'File::Spec'               => 0,
   },
   'EXE_FILES'       => ["script/syncannopod"],
   'PL_FILES'        => {},
   ($] >= 5.005 ?
    (ABSTRACT_FROM => 'lib/AnnoCPAN/Perldoc/SyncDB.pm',
     AUTHOR     => 'Clotho Advanced Media Inc., <cpan@clotho.com>') : ()),
);
