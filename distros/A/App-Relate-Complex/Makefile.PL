use 5.8.0;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'App::Relate::Complex',
    VERSION_FROM      => 'lib/App/Relate/Complex.pm', # finds $VERSION
    EXE_FILES           => [ 'relate_complex' ],
    PREREQ_PM         => {
                          List::Filter            => 0,
                          List::Filter::Storage   => 0,
                          List::Filter::Transform => 0,
                          List::Filter::Internal  => 0,
                          File::Locate::Harder    => 0,
                          Test::Trap           => 0,
                          Test::File::Contents => 0,
                          Carp                 => 0,
                          Data::Dumper         => 0,
                          Env                  => 0,
                          File::Copy           => 0,
                          File::Path           => 0,
                          FindBin              => 0,
                          Hash::Util           => 0,
                          Test::More           => 0,
                          strict               => 0,
                          warnings             => 0,
                         },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/App/Relate/Complex.pm', # retrieve abstract from module
       AUTHOR         => 'Joseph Brenner <doom@>') : ()),
);
