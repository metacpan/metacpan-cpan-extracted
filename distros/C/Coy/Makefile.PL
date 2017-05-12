#!/usr/bin/perl -w

use ExtUtils::MakeMaker;

my $mm_ver = ExtUtils::MakeMaker->VERSION;
$mm_ver =~ s/_//;       # numify alpha versions

WriteMakefile(
    NAME                => 'Coy',
    VERSION_FROM        => 'lib/Coy.pm',
    ABSTRACT_FROM       => 'lib/Coy.pm',

    PREREQ_PM           => {
        'Lingua::EN::Inflect'   => '1.89',
        'Test::More'            => '0.47',
    },


    ($mm_ver >= 6.31 ? (LICENSE => 'perl') : ()),

    ($mm_ver <= 6.45 ? () : (
        META_MERGE => {
            author    => [
                'Damian Conway <dconway@cpan.org>',
                'Michael G Schwern <schwern@pobox.com>',
            ],
            resources => {
                license     =>      'http://dev.perl.org/licenses/',
                homepage    =>      'http://search.cpan.org/dist/Coy',
                bugtracker  =>      'http://rt.cpan.org/Public/Dist/Display.html?Name=Coy',
                repository  =>      'http://github.com/schwern/coy/tree/master',
            },
        },
    )),

    ($mm_ver <= 6.48 ? () : (MIN_PERL_VERSION => '5.6.1')),
);
