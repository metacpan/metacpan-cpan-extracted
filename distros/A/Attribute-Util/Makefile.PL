use 5.008001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'         => 'Attribute::Util',
    'VERSION_FROM' => 'lib/Attribute/Util.pm',    # finds $VERSION
    'PREREQ_PM'    => {
        'Attribute::Handlers' => '0.61',
        'Memoize'             => 0,
    },
    dist => {

        # don't ask about existing .tar.gz files
        COMPRESS => 'gzip --force --best'
    },
    (
        $] >= 5.005
        ?    ## Add these new keywords supported since 5.005
          (
            ABSTRACT_FROM =>
              'lib/Attribute/Util.pm',    # retrieve abstract from module
            AUTHOR => 'Dan Kogai <dankogai+cpan@gmail.com>'
          )
        : ()
    ),
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Digest-SipHash-*' },

);
