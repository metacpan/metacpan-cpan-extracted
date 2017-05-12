use strict;

use ExtUtils::MakeMaker;

# Commented out for distribution by Inline::Module::LeanDist
#use Inline::Module::LeanDist::MakefilePL;

WriteMakefile(
    NAME => 'Acme::Math::XS::LeanDist',
    VERSION_FROM => 'lib/Acme/Math/XS/LeanDist.pm',
    LICENSE => 'perl',
    dist => {
      PREOP => 'pod2text $(VERSION_FROM) > $(DISTVNAME)/README',
    },
    META_MERGE => {
      resources => {
        repository => 'git://github.com/hoytech/Acme-Math-XS-LeanDist.git',
        bugtracker => 'https://github.com/hoytech/Acme-Math-XS-LeanDist/issues',
      },
    },

    postamble => {
      inline => {
        file => 'lib/Acme/Math/XS/LeanDist.pm',
      },
    },
    OBJECT => 'LeanDist.o ',
);
