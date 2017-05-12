use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'D64::Disk::Dir',
    VERSION_FROM      => 'Dir.pm',
    PREREQ_PM         => { 'Array::Iterator'  => 0,
                           'Capture::Tiny'    => 0,
                           'D64::Disk::Image' => 0,
                           'IO::Scalar'       => 0,
                         },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'Dir.pm',
       AUTHOR         => 'Pawel Krol <pawelkrol@cpan.org>') : ()),
    DEFINE            => '',
    OPTIMIZE          => '-O2',
);
