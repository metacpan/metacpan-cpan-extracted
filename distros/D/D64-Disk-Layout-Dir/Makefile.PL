use ExtUtils::MakeMaker;
WriteMakefile(
    NAME             => 'D64::Disk::Layout::Dir',
    VERSION_FROM     => 'Dir.pm',
    PREREQ_PM        => {
                            Capture::Tiny             => 0,
                            D64::Disk::Dir::Item      => 0.06,
                            D64::Disk::Layout::Sector => 0,
                            Data::Dumper              => 0,
                            IO::Scalar                => 0,
                            List::MoreUtils           => 0,
                            Readonly                  => 0,
                            Test::Deep                => 0,
                            Test::Exception           => 0,
                            Test::MockModule          => 0,
                            Test::More                => 0,
                            Text::Convert::PETSCII    => 0.04,
                            XSLoader                  => 0,
                        },
    ($] >= 5.005 ?
      (ABSTRACT_FROM => 'Dir.pm',
       AUTHOR        => 'Pawel Krol <pawelkrol@cpan.org>') : ()),
       OBJECT        => 'Dir.o',
       OPTIMIZE      => '-O2',
);
