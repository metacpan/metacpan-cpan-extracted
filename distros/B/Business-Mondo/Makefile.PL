#!perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Business::Mondo',
    VERSION_FROM     => 'lib/Business/Mondo/Version.pm',
    AUTHOR           => 'Lee Johnson <leejo@cpan.org>',
    LICENSE          => 'perl',
    MIN_PERL_VERSION => '5.10.1',
    PREREQ_PM => {
        'Moo'                  => 2.001001,
        'Carp'                 => 0, # Carp was first released with perl 5
        'Throwable'            => 0.200011,
        'Mojolicious'          => 6.62,
        'Try::Tiny'            => 0.22,
        'Types::Standard'      => 1.000005,
        'Data::Currency'       => 0.06000,
        'DateTime'             => 1.26,
        'DateTime::Format::DateParse' => 0.05,
        'Locale::Currency::Format' => 1.35,
    },
    TEST_REQUIRES => {
        'Test::Most'       => 0.31,
        'Test::Deep'       => 0.112,
        'Test::Exception'  => 0.32,
        'Test::MockObject' => 1.20140408,
    },
    META_MERGE => {
        resources => {
            license    => 'http://dev.perl.org/licenses/',
            homepage   => 'https://metacpan.org/module/Business::Mondo',
            bugtracker => 'https://github.com/leejo/business-mondo/issues',
            repository => 'https://github.com/leejo/business-mondo'
        },
        repository => {
            type => 'git',
            url  => 'https://github.com/leejo/business-mondo.git',
            web  => 'https://github.com/leejo/business-mondo',
        },
    },
    test => {
        TESTS                => 't/*.t t/*/*.t t/*/*/*.t',
        RECURSIVE_TEST_FILES => 1,
    },
);

# vim: ts=4:sw=4:et
