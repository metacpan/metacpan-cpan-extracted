use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'D64::Disk::BAM',
    VERSION_FROM      => 'BAM.pm',
    PREREQ_PM         => { 'Capture::Tiny'          => 0,
                           'IO::Scalar'             => 0,
                           'Text::Convert::PETSCII' => 0,
                         },
    ($] >= 5.005 ?
      (ABSTRACT_FROM => 'BAM.pm',
       AUTHOR        => 'Pawel Krol <pawelkrol@cpan.org>') : ()),
    DEFINE            => '',
    OPTIMIZE          => '-O2',
    META_MERGE        => {
        'meta-spec' => {
            'version' => 2,
        },
        'resources' => {
            'bugtracker' => {
                'web' => 'https://github.com/pawelkrol/D64-Disk-BAM/issues',
            },
            'repository' => {
                'type' => 'git',
                'url'  => 'git://github.com/pawelkrol/D64-Disk-BAM.git',
                'web'  => 'https://github.com/pawelkrol/D64-Disk-BAM.git',
            },
        },
    },
);
