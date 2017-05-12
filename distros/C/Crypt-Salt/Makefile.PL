use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Crypt::Salt',
    VERSION_FROM => 'lib/Crypt/Salt.pm', # finds $VERSION
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
    ( $] >= 5.005 ?
      (
        AUTHOR       => 'Jonathan Steinert (hachi@cpan.org)',
        ABSTRACT_FROM => 'lib/Crypt/Salt.pm',
      ) : ()),
    dist => {
      COMPRESS => 'gzip -9',
      SUFFIX   => 'gz',
      PREOP    => q{pod2text lib/Crypt/Salt.pm > ./$(DISTNAME)-$(VERSION)/README},
    },
);
