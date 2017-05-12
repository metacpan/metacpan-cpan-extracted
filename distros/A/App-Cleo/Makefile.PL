
use strict;
use warnings;

use ExtUtils::MakeMaker;

#-----------------------------------------------------------------------------

WriteMakefile(
     NAME         => 'App::Cleo',
     VERSION_FROM => 'lib/App/Cleo.pm',
     LICENSE      => 'perl_5',
     PREREQ_PM    => {
        'Term::ReadKey'   => '0',
        'Term::ANSIColor' => '0',
        'File::Slurp'     => '0',
        'Time::HiRes'     => '0',
        'strict'          => '0',
        'warnings'        => '0',
    },
    EXE_FILES   => ['bin/cleo'],
    META_MERGE    => {
        resources   => {
            repository => {
                type => 'git',
                url  => 'git@github.com:thaljef/App-Cleo.github',
                web  => 'https://github.com/thaljef/App-Cleo',
            },
        },
        'meta-spec' => { version => 2 },
    },
);
