use ExtUtils::MakeMaker;
WriteMakefile(
    NAME             => 'D64::Disk::Layout::Sector',
    VERSION_FROM     => 'Sector.pm',
    PREREQ_PM        => {
                            Data::Dumper           => 0,
                            IO::Scalar             => 0,
                            Readonly               => 0,
                            Storable               => 0,
                            Test::Deep             => 0,
                            Test::Exception        => 0,
                            Test::More             => 0,
                            Text::Convert::PETSCII => 0,
                            XSLoader               => 0,
                        },
    ($] >= 5.005 ?
      (ABSTRACT_FROM => 'Sector.pm',
       AUTHOR        => 'Pawel Krol <pawelkrol@cpan.org>') : ()),
       OBJECT        => 'Sector.o',
       OPTIMIZE      => '-O2',
);
