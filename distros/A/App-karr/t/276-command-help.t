use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestKarr qw( run_karr );
use File::Temp qw( tempdir );
use Cwd qw( abs_path getcwd );
use IPC::Open3 qw( open3 );
use Symbol qw( gensym );

# Ticket #276: per-command --help output.
#
# MooX::Options' default long help spelled every option with the underscored
# form MooX::Options hands Getopt::Long (`--claimed_by`), listed the four
# built-ins (--usage, -h, --help, --man) on the per-command page where they
# are noise, and inserted the two blank lines that surrounded them. None of
# that matched what the user types (the README spells them with dashes, every
# existing per-command USAGE line spells them with dashes), and a help page
# listing `claimed_by` next to a USAGE line listing `claimed-by` was a
# contradiction a screen apart.
#
# The fix:
#
#   * the per-command help block is hyphenated end-to-end,
#   * the four built-ins are dropped (they have a separate `karr --help` page
#     that lists them once),
#   * --dir and --quiet are dropped from every page that carries them
#     (`hidden => 1`),
#   * --help and -h render the SAME block (one option per line),
#   * karr-foundation does the same for its options (the only underscored one
#     was --dry_run).
#
# These are the four properties the README pinned and the rendering used to
# fail. RED before the renderer in App::karr::Role::ExitCodes/_render_help_long
# existed; GREEN after.

my $TMP = tempdir( CLEANUP => 1 );

sub _help {
    my (@argv) = @_;
    return run_karr( $TMP, @argv, '--help' );
}

# A help page is allowed to mention --help / -h / --usage / --man only as the
# description of one of its own options (none here does); never as a row of
# its own. --dir and --quiet are the two hidden ones every board command
# carries and are the same rule.
subtest 'built-in and shared options are not listed' => sub {
    my $rv = _help('move');
    is( $rv->{exit}, 0, 'karr move --help exits 0' ) or diag $rv->{stderr};

    my $out = $rv->{stdout};
    unlike( $out, qr/^    --(?:usage|help|man)\b/m,
        'no --usage/--help/--man row in per-command help' );
    unlike( $out, qr/^    -h\b/m, 'no -h row in per-command help' );
    unlike( $out, qr/^    --dir\b/m,
        'no --dir row on a board command that would carry it' );
};

# A help page must not contain whitespace-only lines, ever. MooX inserted two
# blank lines before its built-in rows (the divider the README complained
# about); the new block has no built-ins, so the only blanks left are the
# ones between the USAGE line and the option table, and those carry a row.
subtest 'no whitespace-only lines, ever' => sub {
    my $rv = _help('move');
    is( $rv->{exit}, 0, 'karr move --help exits 0' ) or diag $rv->{stderr};

    unlike( $rv->{stdout}, qr/^[ \t]*\n/m,
        'no whitespace-only lines in per-command help' )
      or diag $rv->{stdout};
};

# The compact one-line-per-option form was previously the -h form and the
# long form (paragraphs) was --help. The ticket asked for one rendering, the
# compact one, on both. The two streams must be byte-identical.
subtest '-h and --help render the same page' => sub {
    my $long  = _help('move');
    my $short = run_karr( $TMP, 'move', '-h' );
    is( $long->{exit},  0, 'karr move --help exits 0' ) or diag $long->{stderr};
    is( $short->{exit}, 0, 'karr move -h exits 0' )      or diag $short->{stderr};
    is( $short->{stdout}, $long->{stdout},
        'karr move -h and --help print byte-identical pages' );
};

# Hyphenation end-to-end. The list covers one underscored option per command
# class: a board-side filter (list), a writing command (edit).
subtest 'every option name is hyphenated' => sub {
    my $rv = _help('list');
    is( $rv->{exit}, 0, 'karr list --help exits 0' ) or diag $rv->{stderr};

    my $out = $rv->{stdout};
    like( $out, qr/^    --claimed-by=String\b/m,
        'list: --claimed-by (was --claimed_by)' );
    like( $out, qr/^    --not-blocked\b/m,
        'list: --not-blocked (was --not_blocked)' );
    like( $out, qr/^    --group-by=String\b/m,
        'list: --group-by (was --group_by)' );

    # And nothing underscored survives.
    unlike( $out, qr/^    --[a-z]+_[a-z_]+/m,
        'list: no underscored option name in the rendered page' );

    my $edit = _help('edit');
    is( $edit->{exit}, 0, 'karr edit --help exits 0' ) or diag $edit->{stderr};
    my $eout = $edit->{stdout};
    like( $eout, qr/^    --add-tag=String\b/m,
        'edit: --add-tag (was --add_tag)' );
    like( $eout, qr/(?:^|\s)--append-body=String\b/,
        'edit: --append-body (was --append_body)' );
    like( $eout, qr/^    --add-depends-on=String\b/m,
        'edit: --add-depends-on (was --add_depends_on)' );
    unlike( $eout, qr/^    --[a-z]+_[a-z_]+/m,
        'edit: no underscored option name in the rendered page' );
};

# A syncing command carries --quiet. The page must not list it.
subtest '--quiet is hidden on the syncing commands' => sub {
    my $rv = _help('sync');
    is( $rv->{exit}, 0, 'karr sync --help exits 0' ) or diag $rv->{stderr};
    unlike( $rv->{stdout}, qr/^    --quiet\b/m,
        'sync: --quiet not on the per-command page' );
};

# USAGE line first, option table second. The ticket's second complaint: two
# blank lines before the built-ins. There are no built-ins now, and the only
# newline between sections is the one that ends the USAGE line.
subtest 'the USAGE line is the first line' => sub {
    my $rv = _help('move');
    is( $rv->{exit}, 0, 'karr move --help exits 0' ) or diag $rv->{stderr};
    like( $rv->{stdout}, qr/\AUSAGE: karr move ID\[,ID,\.\.\.\] STATUS /,
        'stdout opens with the USAGE line' );
};

# karr-foundation is its own command class composing the same role, and
# carries the only underscored option name karr-foundation has (--dry_run).
# The same renderer reaches it, but a bug in the rendering would surface here
# first since the page is small.
subtest 'karr-foundation renders --dry-run and the same hygiene rules' => sub {
    my $ROOT = abs_path('.');
    my $BIN  = "$ROOT/bin/karr-foundation";
    my $old  = getcwd();
    chdir $TMP;
    my $errfh = gensym;
    my $pid = open3( undef, my $outfh, $errfh,
        $^X, '-I', $ROOT, $BIN, '--help' );
    my $out = do { local $/; <$outfh> };
    my $err = do { local $/; <$errfh> };
    waitpid( $pid, 0 );
    my $exit = $? >> 8;
    chdir $old;

    is( $exit, 0, 'karr-foundation --help exits 0' ) or diag $err;
    like( $out, qr/^    --dry-run\b/m,
        'karr-foundation: --dry-run (was --dry_run)' );
    unlike( $out, qr/^    --dry_run\b/m,
        'karr-foundation: --dry_run is not on the page' );
    unlike( $out, qr/^    --(?:usage|help|man)\b/m,
        'karr-foundation: no built-ins on the page' );
    unlike( $out, qr/^    -h\b/m,
        'karr-foundation: no -h on the page' );
    unlike( $out, qr/^[ \t]*\n/m,
        'karr-foundation: no whitespace-only lines' );
};

done_testing;
