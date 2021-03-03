use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

use File::ShareDir::Install;

#$File::ShareDir::Install::INCLUDE_DOTFILES = 0;
#$File::ShareDir::Install::INCLUDE_DOTDIRS = 0;
install_share 'share';

WriteMakefile(
    NAME               => 'CLI::Driver',
    AUTHOR             => q{John Gravatt <john.gravatt@act.org>},
    VERSION_FROM       => 'lib/CLI/Driver.pm',
    ABSTRACT_FROM      => 'lib/CLI/Driver.pm',
    LICENSE            => 'artistic_2',
    PL_FILES           => {},
    EXE_FILES          => ['bin/clidriver.pl'],
    MIN_PERL_VERSION   => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker'     => '0',
        "File::ShareDir::Install" => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'Data::Printer'        => 0,
        'Devel::Confess'       => 0,
        'Capture::Tiny'        => 0,
        'File::Basename'       => 0,
        'File::ShareDir'       => 0,
        'Kavorka'              => 0,
        'Modern::Perl'         => 0,
        'Module::Load'         => 0,
        'Moose'                => 0,
        'namespace::autoclean' => 0,
        'Time::localtime'      => 0,
        'Sort::Naturally'      => 0,
        'YAML::Syck'           => '1.31',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'CLI-Driver-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/gravattj/CLI-Driver-perl.git',
                web  => 'https://github.com/gravattj/CLI-Driver-perl',
            },
            bugtracker => {
                web => 'https://github.com/gravattj/CLI-Driver-perl/issues'
            },
            homepage => 'https://github.com/gravattj/CLI-Driver-perl',
        },
    },
);

package MY;
use File::ShareDir::Install qw( postamble );
