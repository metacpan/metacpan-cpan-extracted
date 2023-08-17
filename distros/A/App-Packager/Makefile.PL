#! perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'App::Packager',
    AUTHOR              => 'Johan Vromans <jv@cpan.org>',
    VERSION_FROM        => 'lib/App/Packager.pm',
    ABSTRACT_FROM       => 'lib/App/Packager.pm',
    LICENSE             => 'perl_5',
    PL_FILES            => {},
    MIN_PERL_VERSION    => "5.010001",
    CONFIGURE_REQUIRES => {
        "ExtUtils::MakeMaker" => 6.5503,
    },
    TEST_REQUIRES  => {
        'Test::More'  => 0,
    },
    META_MERGE => {
     resources => {
         license    => "http://dev.perl.org/licenses/",
         repository => "https://github.com/sciurius/perl-App-Packager",
         bugtracker => "https://github.com/sciurius/perl-App-Packager/issues",
     },
    },
);
