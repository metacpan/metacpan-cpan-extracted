use ExtUtils::MakeMaker;
WriteMakefile(
    NAME             => 'D64::Disk::Dir::Item',
    VERSION_FROM     => 'Item.pm',
    PREREQ_PM        => {
                            parent                 => 0,
                            Clone                  => 0,
                            Data::Dumper           => 0,
                            IO::Scalar             => 0,
                            Readonly               => 0,
                            Scalar::Util           => 0,
                            Test::Deep             => 0,
                            Test::Exception        => 0,
                            Test::More             => 0,
                            Text::Convert::PETSCII => 0.05,
                            Try::Tiny              => 0,
                        },
    ($] >= 5.005 ?
      (ABSTRACT_FROM => 'Item.pm',
       AUTHOR        => 'Pawel Krol <pawelkrol@cpan.org>') : ()),
       OBJECT        => 'Item.o',
       OPTIMIZE      => '-O2',
    META_MERGE        => {
        'meta-spec' => {
            'version' => 2,
        },
        'resources' => {
            'bugtracker' => {
                'web' => 'https://github.com/pawelkrol/D64-Disk-Dir-Item/issues',
            },
            'repository' => {
                'type' => 'git',
                'url'  => 'git://github.com/pawelkrol/D64-Disk-Dir-Item.git',
                'web'  => 'https://github.com/pawelkrol/D64-Disk-Dir-Item.git',
            },
        },
    },
);
