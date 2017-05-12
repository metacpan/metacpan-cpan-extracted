use strict;
use warnings;
use ExtUtils::MakeMaker;

use lib qw(lib);
use Module::Build::Compat;

Module::Build::Compat->run_build_pl(args => \@ARGV);
Module::Build::Compat->write_makefile(build_class => 'Module::Build');

WriteMakefile(
    NAME                => 'CSPL::Provision',
    AUTHOR              => 'Kaoru Oshita <kaoru.oshita@gmail.com>',
    VERSION_FROM        => 'lib/CSPL/Provision.pm',
    ABSTRACT_FROM       => 'lib/CSPL/Provision.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CSPL-Provision-*' },
);
