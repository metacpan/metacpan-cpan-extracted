use strict;
use warnings;
use 5.008001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Acme::Math::Google',
    VERSION_FROM => 'lib/Acme/Math/Google.pm',    # finds $VERSION
    PREREQ_PM    => {
        'URI'            => 0,
        'LWP::UserAgent' => 0,
    },    # e.g., Module::Name => 1.1
    (
        $] >= 5.005
        ?    ## Add these new keywords supported since 5.005
          (
            ABSTRACT_FROM =>
              'lib/Acme/Math/Google.pm',    # retrieve abstract from module
            AUTHOR => 'Dan Kogai <dankogai@dan.co.jp>'
          )
        : ()
    ),
);
