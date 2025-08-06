#!perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Business::Westpac',
    VERSION_FROM     => 'lib/Business/Westpac.pm',
    AUTHOR           => 'Lee Johnson <leejo@cpan.org>',
    LICENSE          => 'perl',
    MIN_PERL_VERSION => '5.32.0',
    PREREQ_PM => {
        'Moose'                        => 2.2012,
        'Moose::Role'                  => 2.2012,
        'Moose::Util::TypeConstraints' => 2.2012,
        'DateTime::Format::DateParse'  => 0.05,
        'Exporter::Easy'               => 0.18,
        'Module::Load'                 => 0.34,
        'Text::CSV'                    => 2.00,
        'Types::Standard'              => 2.006000,
        'Mojolicious'                  => 8.52, 
        'Carp'                 => 0, # Carp was first released with perl 5
    },
    BUILD_REQUIRES => {
        'Test::Most'       => 0.31,
        'Test::Warnings'   => 0.038,
    },
    META_MERGE => {
        resources => {
            license    => 'http://dev.perl.org/licenses/',
            homepage   => 'https://metacpan.org/module/Business::Westpac',
            bugtracker => 'https://github.com/Humanstate/business-westpac/issues',
            repository => 'https://github.com/Humanstate/business-westpac'
        },
    },
    test => {
        RECURSIVE_TEST_FILES => 1,
    },
);
