use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'App::REPL',
    AUTHOR              => 'Julian Fondren <ayrnieu@cpan.org>',
    ABSTRACT            => 'A read-eval-print-loop for Perl',
    VERSION_FROM        => 'lib/App/REPL.pm',
    ABSTRACT            => 'A read-eval-print-loop for Perl',
    EXE_FILES           => [ 'iperl' ],
    PREREQ_PM => {
        'Test::More'      => 0,
        'Term::ANSIColor' => 0,
        'PadWalker'       => 1.5,
        'PPI'             => 1.118,  # buggy, but we monkeypatch it
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'App-REPL-*' },
);
