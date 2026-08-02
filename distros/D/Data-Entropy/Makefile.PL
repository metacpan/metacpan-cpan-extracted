
require 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'Data::Entropy',
    'AUTHOR'        => 'Robert Rothenberg <perl@rhizomnic.com>',
    'ABSTRACT_FROM' => 'lib/Data/Entropy.pm',
    'VERSION_FROM'  => 'lib/Data/Entropy.pm',
    "LICENSE"       => 'perl_5',
    'PREREQ_PM'     => {
        'Carp'             => 0,
        'Crypt::Rijndael'  => 0,
        'Crypt::URandom'   => '0.36',
        'Data::Float'      => '0.008',
        'Devel::Deprecate' => 0,
        'Errno'            => '1.00',
        'Exporter'         => 0,
        'HTTP::Tiny'       => '0.096',
        'IO::File'         => '1.03',
        'Module::Build'    => 0,
        'Params::Classify' => 0,
        'Test::More'       => 0,
        'constant'         => 0,
        'integer'          => 0,
        'parent'           => 0,
        'strict'           => 0,
        'warnings'         => 0
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
    },
    'INSTALLDIRS' => 'site',
    'EXE_FILES'   => [],
    'PL_FILES'    => {},
    'SIGN'        => 0,
    'META_MERGE'  => {
        x_deprecated => 1,
        resources    => {
            repository => 'git://github.com/robrwo/Data-Entropy.git',
            bugtracker => 'https://github.com/robrwo/Data-Entropy/issues',
            license    => 'https://dev.perl.org/licenses/',
        },
    }
);
