use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use File::Temp qw( tempdir );
use Cwd qw( abs_path getcwd );
use IPC::Open3 qw( open3 );
use Symbol qw( gensym );
use Path::Tiny qw( path );
use Encode qw( encode_utf8 decode FB_CROAK LEAVE_SRC );

use App::karr::Cmd::Skill;

# The bundled skill file is real Markdown prose and legitimately contains
# non-ASCII (em dashes, ellipses, umlauts). _skill_content hands it back
# decoded (slurp_utf8), so exactly one encode must happen between there and the
# terminal.
#
# Ticket #33 put that encode inside the command, because the rest of the CLI
# handed raw octets to print and a UTF-8 layer on STDOUT would have
# double-encoded them. Ticket #53 moved the boundary: F<bin/karr> now installs
# the layer (App::karr::Encoding::enable_std_utf8) and every command prints
# characters, so the encode in the command became the double encode #33 was
# avoiding and was removed. This file pins the property both fixes were after --
# stdout carries singly-encoded UTF-8 -- rather than either implementation of
# it, so it stays honest across the move.
#
# Written with \x{} escapes so the expectation does not depend on the source
# encoding of this test file.
my $SKILL_TEXT = "# karr \x{2014} skill\n\nBl\x{00f6}cke \x{2026} \x{00fc}ml\x{00e4}ute\n";

my $ROOT = abs_path('.');
my $BIN  = "$ROOT/bin/karr";

sub run_skill_show {
    my ($share_dir) = @_;

    require File::ShareDir;
    no warnings 'redefine';
    local *File::ShareDir::dist_dir = sub { return $share_dir };

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    # The same layer F<bin/karr> puts on the real STDOUT. Reopening STDOUT drops
    # whatever layers the script installed, so an in-process capture has to
    # restore it or it is not capturing what the CLI would emit.
    open my $capture, '>:encoding(UTF-8)', \my $out
        or die "cannot open in-memory handle: $!";
    my $prev = select $capture;
    my $ok   = eval { App::karr::Cmd::Skill->new->execute( ['show'], [] ); 1 };
    my $err  = $@;
    select $prev;
    close $capture;

    die $err unless $ok;
    return ( $out, \@warnings );
}

subtest 'skill show prints UTF-8 bytes without a wide character warning' => sub {
    my $dir = tempdir( CLEANUP => 1 );
    path($dir)->child('claude-skill.md')->spew_utf8($SKILL_TEXT);

    my ( $out, $warnings ) = run_skill_show($dir);

    my @wide = grep { /Wide character/ } @$warnings;
    is( scalar(@wide), 0, 'no "Wide character in print" warning' )
        or diag "warnings emitted: @$warnings";
    is( scalar(@$warnings), 0, 'no warnings at all' )
        or diag "warnings emitted: @$warnings";

    is( $out, encode_utf8($SKILL_TEXT), 'stdout carries the correctly encoded UTF-8 bytes' );
    ok( !utf8::is_utf8($out) || $out !~ /[^\x00-\xff]/,
        'nothing wider than a byte reached the output handle' );

    # The failure mode the removed encode_utf8 would now produce: bytes that are
    # still valid UTF-8, but decode to the mojibake of the real text rather than
    # to the text.
    my $decoded = eval { decode( 'UTF-8', $out, FB_CROAK | LEAVE_SRC ) };
    is( $decoded, $SKILL_TEXT, 'decoding the output once gives the text back (encoded exactly once)' );
    isnt( $out, encode_utf8( encode_utf8($SKILL_TEXT) ), 'output is not double-encoded' );
};

subtest '_skill_content stays decoded so check/update comparisons keep working' => sub {
    # Guards the tempting wrong fix of slurping raw: that would silence the
    # warning but make _check/_update compare bytes against slurp_utf8 text
    # (always "outdated") and make _install spew_utf8 a double-encoded file.
    my $dir = tempdir( CLEANUP => 1 );
    path($dir)->child('claude-skill.md')->spew_utf8($SKILL_TEXT);

    require File::ShareDir;
    no warnings 'redefine';
    local *File::ShareDir::dist_dir = sub { return $dir };

    my $content = App::karr::Cmd::Skill->new->_skill_content;

    is( $content, $SKILL_TEXT, '_skill_content returns decoded characters' );
    is( length($content), length($SKILL_TEXT), 'character length matches (not byte-inflated)' );
};

subtest 'karr skill show through the real CLI emits the bundled file verbatim' => sub {
    my $bundled = path($ROOT)->child('share/claude-skill.md');
    plan skip_all => "no share/claude-skill.md in this checkout" unless $bundled->exists;

    my $raw = do {
        open my $fh, '<:raw', "$bundled" or die "open $bundled: $!";
        local $/;
        <$fh>;
    };
    ok( $raw =~ /[\x80-\xff]/, 'the bundled skill really does contain non-ASCII bytes' );

    # Hand the child a share dir of our own, ahead of everything else in @INC.
    #
    # _skill_content asks File::ShareDir for the *installed* dist first and only
    # falls back to the checkout, so on a machine with App::karr installed this
    # compared `karr skill show`'s output against a file the child never read.
    # It passed only for as long as the installed copy happened to be
    # byte-identical to the checkout -- i.e. it broke on any edit to
    # share/claude-skill.md, reporting it as an encoding bug. dist_dir resolves
    # auto/share/dist/<dist> against @INC in order, so a -I in front of the rest
    # pins it deterministically.
    my $share_lib = path( tempdir( CLEANUP => 1 ) );
    my $share_dir = $share_lib->child(qw( auto share dist App-karr ));
    $share_dir->mkpath;
    $bundled->copy( $share_dir->child('claude-skill.md') );

    my $err_fh = gensym;
    my $pid = open3( my $in, my $out_fh, $err_fh,
        $^X, "-I$share_lib", "-I$ROOT/lib", $BIN, 'skill', 'show' );
    close $in;
    binmode $out_fh;
    my $stdout = do { local $/; <$out_fh> };
    my $stderr = do { local $/; <$err_fh> };
    waitpid( $pid, 0 );
    my $exit = $? >> 8;

    is( $exit, 0, 'karr skill show exits 0' ) or diag $stderr;
    is( $stdout, $raw, 'stdout is byte-identical to the bundled file' );
    unlike( $stderr, qr/Wide character/, 'no wide-character warning on the CLI path' );
};

done_testing;
