use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'D64::File::PRG',
    VERSION_FROM      => 'lib/D64/File/PRG.pm',
    PREREQ_PM         => {
                             IO::Scalar      => 0,
                             Scalar::Util    => 0,
                             Test::Deep      => 0,
                             Test::Exception => 0,
                             Test::More      => 0,
                         },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/D64/File/PRG.pm',
       AUTHOR         => 'Pawel Krol <pawelkrol@cpan.org>') : ()),
);
