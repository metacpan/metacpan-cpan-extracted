
use strict;
use warnings;

use ExtUtils::MakeMaker;

#-----------------------------------------------------------------------------

WriteMakefile(
     NAME         => 'App::Cleo::Patra',
     VERSION_FROM => 'lib/App/Cleo/Patra.pm',
     LICENSE      => 'perl_5',
     PREREQ_PM    => {
        'Term::ReadKey'   => '0',
        'Term::ANSIColor' => '0',
        'File::Slurp'     => '0',
        'Time::HiRes'     => '0',
        'strict'          => '0',
        'warnings'        => '0',
    },
    EXE_FILES   => ['bin/patra'],
    META_MERGE    => {
        resources   => {
            repository => {
                type => 'git',
                url  => 'git@github.com:borisdaeppen/App-Cleo.git',
                web  => 'https://github.com/borisdaeppen/App-Cleo',
            },
        },
        'meta-spec' => { version => 2 },
    },
);
