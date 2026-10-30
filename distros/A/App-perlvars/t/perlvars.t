#!perl

use strict;
use warnings;

use App::perlvars ();
use Test::More import => [qw( done_testing subtest )];
use Test::Script qw(
    script_compiles
    script_fails
    script_runs
    script_stderr_like
    script_stderr_unlike
    script_stdout_like
);

script_compiles('script/perlvars');

subtest 'version' => sub {
    script_runs( [ 'script/perlvars', '--version' ] );
    script_stdout_like(qr{\Aperlvars \Q$App::perlvars::VERSION\E$});
};

subtest 'file not found' => sub {
    script_fails( [ 'script/perlvars', 'Moose' ], { exit => 1 } );
    script_stderr_like(qr{Moose could not be found});
};

subtest 'file has errors' => sub {
    script_fails(
        [ 'script/perlvars', 'test-data/lib/Local/Unused.pm' ],
        { exit => 255 },
    );
    script_stderr_like(qr{\$unused});
    script_stderr_like(qr{\$one});
    script_stderr_like(qr{\$two});
    script_stderr_like(qr{\$three});
};

subtest 'package-less file that cannot compile in isolation is skipped' =>
    sub {
    # Uninstalled module -> wrapper won't compile -> skipped silently, no
    # wrapper details on stderr.
    script_runs(
        [
            'script/perlvars', '--scripts',
            'test-data/scripts/skipped-missing-module.pl'
        ]
    );
    script_stderr_unlike(qr{PerlvarsSyntheticPackage|__perlvars_wrapper__});
    script_stderr_unlike(qr{\$unused});
    };

subtest 'arg is a dir' => sub {
    script_fails( [ 'script/perlvars', 't' ], { exit => 1 }, );
    script_stderr_like(qr{t is a dir});
};

subtest 'ignore file is used' => sub {
    script_runs(
        [
            'script/perlvars',
            '--ignore-file', 'test-data/ignore-file',
            'test-data/lib/Local/Unused.pm'
        ]
    );
};

subtest 'file has no errors' => sub {
    script_runs(
        [ 'script/perlvars', 'test-data/lib/Local/NoUnused.pm' ],
    );
};

subtest 'multiple files are checked' => sub {
    script_runs(
        [
            'script/perlvars',
            '--ignore-file', 'test-data/ignore-file',
            'test-data/lib/Local/Unused.pm',
            'test-data/lib/Local/NoUnused.pm',
        ]
    );
};

subtest 'package-less file is skipped without --scripts' => sub {

    # Opt-in: without --scripts the file gets the "contains no package" note
    # and none of its variables are reported.
    script_runs( [ 'script/perlvars', 'test-data/scripts/unused.pl' ] );
    script_stderr_like(qr{contains no package});
    script_stderr_unlike(qr{\$unused_in_anon});
};

subtest 'package-less file with unused vars' => sub {
    script_fails(
        [ 'script/perlvars', '--scripts', 'test-data/scripts/unused.pl' ],
        { exit => 255 },
    );
    script_stderr_like(qr{\$unused_in_anon});
    script_stderr_like(qr{\$unused_in_named});
    script_stderr_like(qr{\Qtest-data/scripts/unused.pl\E});
};

subtest 'package-less file with no unused vars' => sub {
    script_runs(
        [ 'script/perlvars', '--scripts', 'test-data/scripts/no-unused.pl' ]
    );

    # Top-level lexical read only from a nested sub must not be flagged.
    script_stderr_unlike(qr{\$copy});
};

subtest 'multiple package-less files produce no stray stderr' => sub {

    # Same synthetic package reused across files: no "redefined" warning or
    # temp wrapper path may leak to stderr.
    script_runs(
        [
            'script/perlvars', '--scripts',
            'test-data/scripts/no-unused.pl',
            'test-data/scripts/no-unused.pl',
        ]
    );
    script_stderr_unlike(
        qr{redefined|PerlvarsSyntheticPackage|__perlvars_wrapper__});
};

subtest 'package-less file that exits at compile time is skipped' => sub {

    # "skip_all" exits at compile time, killing Test::Vars' forked child before
    # it writes its pipe -> parent would die thawing an empty Storable string.
    # Must skip cleanly. Only reproduces in a fresh process, hence a CLI test.
    script_runs(
        [ 'script/perlvars', '--scripts', 'test-data/scripts/skip-all.pl' ] );
    script_stderr_unlike(qr{Magic number|Storable});
};

subtest 'package-less file that is not valid UTF-8' => sub {

    # Raw Latin-1 byte: body is copied as raw bytes, not decoded as UTF-8
    # (which would die "ill-formed UTF-8"), so the unused var is still found.
    script_fails(
        [ 'script/perlvars', '--scripts', 'test-data/scripts/latin1.pl' ],
        { exit => 255 },
    );
    script_stderr_like(qr{\$unused_latin1});
    script_stderr_unlike(qr{ill-formed|decode});
};

subtest 'compile-time output from an analyzed file does not leak' => sub {

    # The wrapped file's compile-time code runs during analysis. Its output --
    # and the synthetic wrapper path -- must be suppressed; only the real
    # finding should reach stderr.
    script_fails(
        [
            'script/perlvars', '--scripts',
            'test-data/scripts/noisy-stderr.pl'
        ],
        { exit => 255 },
    );
    script_stderr_like(qr{\$unused_noisy});
    script_stderr_unlike(qr{compile-time noise});
    script_stderr_unlike(qr{PerlvarsSyntheticPackage|__perlvars_wrapper__});
};

subtest 'packaged file that exits at compile time is skipped' => sub {

    # A file with a package statement is analyzed directly, not wrapped. If it
    # exits at compile time ("plan skip_all"), Test::Vars' forked child dies
    # before writing its pipe -> parent would die thawing an empty Storable
    # string. Must skip cleanly, same as the package-less case above.
    script_runs(
        [ 'script/perlvars', 'test-data/scripts/lib/Local/PkgSkip.pm' ] );
    script_stderr_unlike(qr{Magic number|Storable});
};

subtest 'compile-time output from a packaged file does not leak' => sub {

    # Same suppression as the package-less path: the packaged file's
    # compile-time output -- and any stray TAP -- must not reach stderr, only
    # the genuine finding.
    script_fails(
        [ 'script/perlvars', 'test-data/scripts/lib/Local/PkgNoisy.pm' ],
        { exit => 255 },
    );
    script_stderr_like(qr{\$unused_pkg_var});
    script_stderr_unlike(qr{compile-time noise});
    script_stderr_unlike(qr{PerlvarsSyntheticPackage|__perlvars_wrapper__});
};

subtest
    'a packaged file that exits at compile time does not abort the batch' =>
    sub {

    # The first file opts out at compile time (the uncaught thaw die used to
    # abort the whole run here); the second file's finding must still be
    # reported.
    script_fails(
        [
            'script/perlvars',
            'test-data/scripts/lib/Local/PkgSkip.pm',
            'test-data/scripts/lib/Local/PkgNoisy.pm',
        ],
        { exit => 255 },
    );
    script_stderr_like(qr{\$unused_pkg_var});
    script_stderr_unlike(qr{Magic number|Storable});
    };

subtest 'ignored file that exits non-zero leaks nothing' => sub {

    # The wrapper cannot compile (missing module) and an END block makes the
    # analyzer child exit non-zero. perlvars must still skip it cleanly rather
    # than leaking the Test::Vars "ignores ... because" note to stderr.
    script_runs(
        [
            'script/perlvars', '--scripts',
            'test-data/scripts/missing-module-nonzero-exit.pl'
        ]
    );
    script_stderr_unlike(
        qr{Test::Vars ignores|PerlvarsSyntheticPackage|__perlvars_wrapper__});
};

subtest 'a file that cannot be processed does not abort the batch' => sub {

    # The first argument errors (not found); the run must still check the later
    # file and report its findings rather than exiting on the first error.
    script_fails(
        [
            'script/perlvars', '--scripts',
            'test-data/scripts/does-not-exist.pl',
            'test-data/scripts/unused.pl',
        ],
        { exit => 255 },
    );
    script_stderr_like(qr{could not be found});
    script_stderr_like(qr{\$unused_in_anon});
};

done_testing();
