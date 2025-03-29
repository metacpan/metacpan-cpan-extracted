
require 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'Data::Float',
    'AUTHOR'        => 'Robert Rothenberg <rrwo@cpan.org>',
    'ABSTRACT_FROM' => 'lib/Data/Float.pm',
    'VERSION_FROM'  => 'lib/Data/Float.pm',
    'PREREQ_PM'     => {
        "Carp"     => 0,
        "Exporter" => 0,
        "constant" => 0,
        "integer"  => 0,
        "parent"   => 0,
        "perl"     => "5.006",
        "strict"   => 0,
        "warnings" => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
    },
    'INSTALLDIRS' => 'site',
    'EXE_FILES'   => [],
    'PL_FILES'    => {},
    'SIGN'        => 1,
    'META_MERGE'  => {
        resources    => {
            repository => 'git://github.com/robrwo/Data-Float.git',
            bugtracker => "https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Float",
        },
    }
);
