use ExtUtils::MakeMaker;
WriteMakefile(
    NAME             => 'D64::Disk::Layout',
    VERSION_FROM     => 'Layout.pm',
    PREREQ_PM        => {
                            D64::Disk::Layout::Base   => 0.03,
                            D64::Disk::Layout::Sector => 0.02,
                            File::Temp                => 0,
                            IO::Scalar                => 0,
                            List::MoreUtils           => 0.426,
                            Test::Deep                => 0,
                            Test::More                => 0,
                        },
    ($] >= 5.005 ?
      (ABSTRACT_FROM => 'Layout.pm',
       AUTHOR        => 'Pawel Krol <pawelkrol@cpan.org>') : ()),
);
