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
);
