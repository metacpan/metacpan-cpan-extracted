# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

use strict;
use warnings FATAL => 'all';

use ExtUtils::MakeMaker 6.59;

WriteMakefile(
    NAME               => 'Acme::Thoroughly::Modern::Perl',
    AUTHOR             => 'Jim Bacon <jim@nortx.com>',
    VERSION_FROM       => 'lib/Acme/Thoroughly/Modern/Perl.pm',
    ABSTRACT_FROM      => 'lib/Acme/Thoroughly/Modern/Perl.pm',
    LICENSE            => 'Perl',
    PL_FILES           => {},    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 6.59,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        # NOTE the use of quotes around non-numeric strings!
        #'ABC'              => 0,
        #'Foo::Bar::Module' => 5.004001,
        #'Foo::Bar::Module' => '5.4_1',
        #'Foo::Bar::Module' => '5.4.1',
        #'Foo::Bar::Module' => 'v5.4_1',
        #'Foo::Bar::Module' => 'v5.4.1',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Acme-Thoroughly-Modern-Perl-*' },
);
