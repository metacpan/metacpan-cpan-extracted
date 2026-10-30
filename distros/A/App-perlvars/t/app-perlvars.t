use strict;
use warnings;

use lib 'test-data/lib';

use App::perlvars ();
use Test::More import => [qw( done_testing is like ok subtest unlike )];

subtest 'pkg with unused vars' => sub {
    my ( $exit_code, $msg, @errors )
        = App::perlvars->new->validate_file('test-data/lib/Local/Unused.pm');
    ok( $exit_code, 'non-zero exit code' );
    is( scalar @errors, 4, 'found all errors' );
};

subtest 'pkg without unused vars' => sub {
    my ( $exit_code, $msg, @errors )
        = App::perlvars->new->validate_file(
        'test-data/lib/Local/NoUnused.pm');
    is( $exit_code,     0, '0 exit code' );
    is( scalar @errors, 0, 'found no errors' );
};

subtest 'file not found' => sub {
    my ( $exit_code, $msg, @errors )
        = App::perlvars->new->validate_file('test-data/oops');
    is( $exit_code,     1, 'exit code 1' );
    is( scalar @errors, 0, 'found no errors' );
};

subtest 'package-less file skipped without lint_scripts' => sub {

    # Opt-in: without lint_scripts the file is not analyzed.
    my ( $exit_code, $msg, @errors )
        = App::perlvars->new->validate_file('test-data/scripts/unused.pl');
    is( $exit_code, 0, '0 exit code' );
    is(
        $msg, 'test-data/scripts/unused.pl contains no package',
        'reports that the file has no package'
    );
    is( scalar @errors, 0, 'no findings without opt-in' );
};

subtest 'package-less file with unused vars' => sub {
    my ( $exit_code, $msg, @errors )
        = App::perlvars->new( lint_scripts => 1 )
        ->validate_file('test-data/scripts/unused.pl');
    ok( $exit_code, 'non-zero exit code' );
    is( scalar @errors, 2, 'found both unused vars' );

    # Diagnostics point at the real source/lines, not the temp wrapper.
    like( "@errors", qr{\Qtest-data/scripts/unused.pl\E}, 'names real file' );
    like( "@errors", qr/\$unused_in_anon\b/,  'reports var in anon sub' );
    like( "@errors", qr/\$unused_in_named\b/, 'reports var in named sub' );
    like( "@errors", qr/\bline 7\b/,          'anon-sub var at real line 7' );
    like( "@errors", qr/\bline 12\b/, 'named-sub var at real line 12' );
    unlike(
        "@errors",
        qr/PerlvarsSyntheticPackage|__perlvars_wrapper__|__ANON__\[|\.tmp/,
        'no synthetic wrapper details leak',
    );

    # Top-level lexicals read only from a nested sub ($shared, $handler) must
    # not be flagged -- that would be a false positive.
    unlike(
        "@errors",
        qr/\$shared\b|\$handler\b/,
        'no false positive on top-level lexicals used in subs',
    );
};

subtest 'package-less file with an ignore file' => sub {

    # Findings are reported under "main", so an ignore file keyed on "main"
    # (by name and by regex) must suppress them.
    my $vars = App::perlvars->new(
        ignore_file  => 'test-data/ignore-file-main',
        lint_scripts => 1,
    );
    my ( $exit_code, $msg, @errors )
        = $vars->validate_file('test-data/scripts/unused.pl');
    is( $exit_code,     0, '0 exit code once both vars are ignored' );
    is( scalar @errors, 0, 'both unused vars suppressed' );
};

subtest 'package-less file without unused vars' => sub {
    my ( $exit_code, $msg, @errors )
        = App::perlvars->new( lint_scripts => 1 )
        ->validate_file('test-data/scripts/no-unused.pl');
    is( $exit_code,     0, '0 exit code' );
    is( scalar @errors, 0, 'found no errors' );
};

subtest 'package-less file with a heredoc' => sub {
    my ( $exit_code, $msg, @errors )
        = App::perlvars->new( lint_scripts => 1 )
        ->validate_file('test-data/scripts/heredoc.pl');

    # Slicing raw source (not the PPI tree, which drops heredoc bodies) keeps
    # the heredoc intact so the file compiles and the unused var is found.
    ok( $exit_code, 'non-zero exit code' );
    is( scalar @errors, 1, 'found the one unused var' );
    like(
        "@errors", qr/\$unused_in_heredoc_file\b/,
        'reports the unused var'
    );
    like( "@errors", qr/\bline 5\b/, 'maps to the real line' );
};

subtest 'package-less file with an __END__ block' => sub {
    my ( $exit_code, $msg, @errors )
        = App::perlvars->new( lint_scripts => 1 )
        ->validate_file('test-data/scripts/with-end.pl');

    # __END__ onward is stripped before wrapping; the trailing block's stray
    # brace would otherwise close the synthetic sub early.
    ok( $exit_code, 'non-zero exit code' );
    is( scalar @errors, 1, 'found the one unused var' );
    like( "@errors", qr/\$unused_after_end\b/, 'reports the unused var' );
    like( "@errors", qr/\bline 5\b/,           'maps to the real line' );
};

subtest 'package-less file that cannot compile in isolation' => sub {
    my ( $exit_code, $msg, @errors )
        = App::perlvars->new( lint_scripts => 1 )
        ->validate_file('test-data/scripts/skipped-missing-module.pl');

    # The file uses an uninstalled module, so the wrapper won't compile and
    # Test::Vars inspects nothing: skip silently, leak no wrapper details.
    is( $exit_code,     0, '0 exit code (skipped, not failed)' );
    is( scalar @errors, 0, 'no errors emitted' );
    unlike(
        "@errors",
        qr/PerlvarsSyntheticPackage|__perlvars_wrapper__|ignores/,
        'no synthetic wrapper details leak',
    );
};

subtest 'ignored file that exits non-zero is still skipped' => sub {
    my ( $exit_code, $msg, @errors )
        = App::perlvars->new( lint_scripts => 1 )
        ->validate_file('test-data/scripts/missing-module-nonzero-exit.pl');

    # The wrapper cannot compile (missing module), so Test::Vars inspects
    # nothing -- but an END block makes the analyzer child exit non-zero. That
    # must not turn "could not be analyzed" into a reported finding.
    is( $exit_code,     0,     '0 exit code (skipped, not failed)' );
    is( $msg,           undef, 'no message' );
    is( scalar @errors, 0,     'no findings leak' );
    unlike(
        "@errors",
        qr/Test::Vars ignores|PerlvarsSyntheticPackage|__perlvars_wrapper__/,
        'no synthetic wrapper details leak',
    );
};

subtest 'package-less UTF-8 file is parsed and linted' => sub {
    my ( $exit_code, $msg, @errors )
        = App::perlvars->new( lint_scripts => 1 )
        ->validate_file('test-data/scripts/utf8.pl');

    # A Unicode identifier in code trips PPI's raw-byte lexer; we retry against
    # UTF-8-decoded source so the file is still analyzed.
    ok( $exit_code, 'non-zero exit code' );
    is( scalar @errors, 1, 'found the one unused var' );
    like( "@errors", qr/\$unused_utf8\b/, 'reports the unused var' );
    like( "@errors", qr/\bline 10\b/,     'maps to the real line' );
    like( "@errors", qr{\Qtest-data/scripts/utf8.pl\E}, 'names real file' );
    unlike(
        "@errors",
        qr/PerlvarsSyntheticPackage|__perlvars_wrapper__/,
        'no synthetic wrapper details leak',
    );
};

subtest 'package-less file PPI cannot parse is skipped under lint_scripts' =>
    sub {
    my ( $exit_code, $msg, @errors )
        = App::perlvars->new( lint_scripts => 1 )
        ->validate_file('test-data/scripts/unparseable.pl');

    # PPI cannot lex this file even decoded, so we cannot analyze it. Under
    # lint_scripts that is a silent skip, consistent with other unanalyzable
    # files -- not an error that would abort a batch run.
    is( $exit_code,     0,     '0 exit code (skipped, not failed)' );
    is( $msg,           undef, 'no message' );
    is( scalar @errors, 0,     'no findings' );
    };

subtest 'unparseable file without lint_scripts is reported' => sub {
    my ( $exit_code, $msg, @errors )
        = App::perlvars->new->validate_file(
        'test-data/scripts/unparseable.pl');

    # Without opt-in the old contract stands: an unparseable file is an error.
    is( $exit_code, 1, 'exit code 1' );
    like(
        $msg, qr{could not be parsed as Perl},
        'reports the parse failure'
    );
};

subtest 'package-less file that is not valid UTF-8' => sub {
    my ( $exit_code, $msg, @errors )
        = App::perlvars->new( lint_scripts => 1 )
        ->validate_file('test-data/scripts/latin1.pl');

    # Raw Latin-1 byte: copying the body as raw bytes lets analysis proceed;
    # decoding as UTF-8 would die "Can't decode ill-formed UTF-8".
    ok( $exit_code, 'non-zero exit code' );
    is( scalar @errors, 1, 'found the one unused var' );
    like( "@errors", qr/\$unused_latin1\b/, 'reports the unused var' );
    like( "@errors", qr/\bline 7\b/,        'maps to the real line' );
};

done_testing();
