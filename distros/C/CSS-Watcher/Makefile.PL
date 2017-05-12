use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => "CSS::Watcher",
    ABSTRACT         => "CSS parser, data generator for ac-html-csswatcher.el",
    VERSION_FROM     => "lib/CSS/Watcher.pm",
    AUTHOR           => 'Olexandr Sydorchuk',
    EXE_FILES        => ['csswatcher'],
    MIN_PERL_VERSION => '5.10.1',
    PREREQ_PM        => {
        'PID::File'             => 0,
        'Carp'                  => '0',
        'CSS::Selector::Parser' => '0',
        'Log::Log4perl'         => 0,
        'File::Slurp'           => 0,
        'Path::Tiny'            => 0,
        'File::Which'           => 0,
        'IPC::Run3'             => 0,
        'List::MoreUtils'       => 0,
    },
    "TEST_REQUIRES" => {
        'File::Copy::Recursive' => '0.38',
    },
    (
        eval { ExtUtils::MakeMaker->VERSION(6.46) }
        ? (
            META_MERGE => {
                'meta-spec' => { version => 2 },
                resources   => {
                    repository => {
                        type => 'git',
                        url  => 'https://github.com/osv/csswatcher.git',
                        web  => 'https://github.com/osv/csswatcher',
                    },
                }
            }
          )
        : ()
    ),
);
