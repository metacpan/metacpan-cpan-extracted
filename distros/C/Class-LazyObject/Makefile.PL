use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Class::LazyObject',
    VERSION_FROM => 'lib/Class/LazyObject.pm', # finds $VERSION
    AUTHOR       => 'Daniel C. Axelrod (daxelrod@cpan.org)',
    ABSTRACT     => 'Deferred object construction',
    PREREQ_PM    => {
                     'Carp::Clan'       => 5.0 ,
                     'Class::Data::TIN' => 0.02,
                     'Class::ISA'       => 0   ,
                     'Test::More'       => 0.47,
                     'Test::Exception'  => 0.15,
                    },
);
