use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );
use Cwd qw( abs_path getcwd );
use IPC::Open3 qw( open3 );
use Symbol qw( gensym );
use Path::Tiny qw( path );

use App::karr::Cmd::Init;
use App::karr::Cmd::Skill;

# Ticket #145: the half of ticket #142 that was left standing one command over.
#
# `karr init --claude-skill` installs .claude/skills/karr/SKILL.md -- the very
# file `karr skill install --agent claude-code` installs -- and did it with the
# spew_utf8 that #142 removed from Cmd::Skill. spew_utf8 writes a temp file and
# renames it over the target, so the path comes back on a *new* inode. A
# SKILL.md is usually one link of a manage-skills hardlink chain (one inode
# behind the same relative path in dozens of checkouts), so the rename breaks
# this project out of the chain: it gets the new text, every other project keeps
# the old inode with the old text, link count silently down by one.
#
# What is pinned here is the property the other projects care about -- after an
# install, the target path is still the inode it was -- plus the fact that
# there is now one implementation of that rule rather than a copy per command,
# which is how the first copy came to drift.

my $ROOT = abs_path('.');
my $BIN  = "$ROOT/bin/karr";

# Non-ASCII on purpose: the in-place write must keep the single UTF-8 encode
# spew_utf8 did (App::karr::Encoding: files are character-level, nothing may
# encode on top). Spelled with \x{} so this file needs no source encoding.
my $OLD = "# karr skill \x{2014} old\n";
my $NEW = "# karr skill \x{2014} new\n\nBl\x{00f6}cke \x{2026} \x{00fc}ml\x{00e4}ute\n";

# (dev, inode, link count) of a path, without following the last symlink.
sub ident {
    my ($path) = @_;
    my @st = stat "$path" or return;
    return { dev => $st[0], ino => $st[1], nlink => $st[3] };
}

# A project root whose .claude/skills/karr/SKILL.md is already hardlinked to a
# second path, i.e. the manage-skills situation this ticket is about.
sub chained_install {
    my ( $root, $content ) = @_;
    my $installed = path($root)->child('.claude/skills/karr/SKILL.md');
    $installed->parent->mkpath;
    $installed->spew_utf8($content);
    my $elsewhere = path($root)->child('elsewhere/SKILL.md');
    $elsewhere->parent->mkpath;
    link( "$installed", "$elsewhere" ) or return;
    return ( $installed, $elsewhere );
}

# Run _install_claude_skill against a share dir we control, with its
# "Installed ..." line and any warnings captured rather than dumped into the
# TAP stream.
sub install_into {
    my ( $root, $content ) = @_;
    my $share = path( tempdir( CLEANUP => 1 ) );
    $share->child('claude-skill.md')->spew_utf8($content);

    require File::ShareDir;
    no warnings 'redefine';
    local *File::ShareDir::dist_dir = sub { return "$share" };

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    my $out = '';
    my $err = do {
        open my $fh, '>', \$out or die "open scalar: $!";
        local *STDOUT = $fh;
        local $@;
        eval { App::karr::Cmd::Init->new->_install_claude_skill( path($root) ); 1 };
        $@;
    };
    return { stdout => $out, error => $err, warnings => \@warnings };
}

subtest 'the premise: spew_utf8 really does rehome the inode' => sub {
    # Without this, the subtests below could pass against a broken
    # implementation on a system where the hazard does not exist at all.
    my $dir = tempdir( CLEANUP => 1 );
    my ( $installed, $elsewhere ) = chained_install( $dir, $OLD );
    plan skip_all => 'filesystem does not support hardlinks' unless $installed;

    my $before = ident($installed);
    is( $before->{nlink}, 2, 'the two paths start out as one inode with two links' );

    $installed->spew_utf8($NEW);

    isnt( ident($installed)->{ino}, $before->{ino}, 'spew_utf8 leaves the path on a different inode' );
    is( ident($elsewhere)->{ino}, $before->{ino}, 'the other link keeps the original inode' );
    is( $elsewhere->slurp_utf8, $OLD, 'and therefore still holds the old content' );
    is( ident($elsewhere)->{nlink}, 1, 'link count dropped, with nothing said' );
};

subtest 'init and skill write through one implementation, not a copy each' => sub {
    # The copy is the actual defect: #142 fixed the rule in Cmd::Skill and
    # Cmd::Init kept its own spew_utf8 for another three days. If someone
    # re-inlines a private _write_skill into either command, this fails.
    ok( App::karr::Cmd::Init->does('App::karr::Role::SkillFile'),
        'karr init composes the shared skill-writing role' );
    ok( App::karr::Cmd::Skill->does('App::karr::Role::SkillFile'),
        'karr skill composes it too' );
    is( App::karr::Cmd::Init->can('_write_skill'),
        App::karr::Cmd::Skill->can('_write_skill'),
        'and both reach the same code, so the rule cannot be fixed in one of them only' );
};

subtest 'init keeps the inode, so every link in the chain updates' => sub {
    my $dir = tempdir( CLEANUP => 1 );
    my ( $installed, $elsewhere ) = chained_install( $dir, $OLD );
    plan skip_all => 'filesystem does not support hardlinks' unless $installed;

    my $before = ident($installed);
    my $r = install_into( $dir, $NEW );
    is( $r->{error}, '', 'the install succeeds' );

    my $after = ident($installed);
    is( $after->{dev}, $before->{dev}, 'same device' );
    is( $after->{ino}, $before->{ino}, 'same inode: the write went through the existing file' );
    is( $after->{nlink}, 2, 'link count is untouched' );
    is( ident($elsewhere)->{ino}, $before->{ino}, 'the second path is still that same inode' );

    is( $installed->slurp_utf8, $NEW, 'the installed path has the new skill' );
    is( $elsewhere->slurp_utf8, $NEW, 'and so does every other project on the chain' );

    like( $r->{stdout}, qr/Installed Claude Code skill/, 'and it still says so' );
    is( scalar( @{ $r->{warnings} } ), 0, 'an in-place write says nothing' )
        or diag "warnings emitted: @{ $r->{warnings} }";

    # Truncation, not overwrite-in-front: a shorter skill must not leave a tail
    # of the previous one behind.
    install_into( $dir, "short\n" );
    is( $elsewhere->slurp_utf8, "short\n", 'a shorter install truncates rather than overwriting in place' );
    is( ident($installed)->{ino}, $before->{ino}, 'still the same inode afterwards' );
};

subtest 'the content is encoded exactly once' => sub {
    my $dir = tempdir( CLEANUP => 1 );
    install_into( $dir, $NEW );
    my $installed = path($dir)->child('.claude/skills/karr/SKILL.md');

    my $raw = do {
        open my $fh, '<:raw', "$installed" or die "open $installed: $!";
        local $/;
        <$fh>;
    };
    is( $raw, "# karr skill \xe2\x80\x94 new\n\nBl\xc3\xb6cke \xe2\x80\xa6 \xc3\xbcml\xc3\xa4ute\n",
        'UTF-8 on disk, encoded once' );
    is( $installed->slurp_utf8, $NEW, 'and it reads back as the characters that went in' );
};

subtest 'a project without .claude yet still gets the skill installed' => sub {
    my $dir = tempdir( CLEANUP => 1 );
    my $installed = path($dir)->child('.claude/skills/karr/SKILL.md');
    ok( !$installed->exists, 'nothing there to begin with' );

    my $r = install_into( $dir, $NEW );
    is( $r->{error}, '', 'the install succeeds' );

    ok( $installed->exists, 'the file was created' );
    is( $installed->slurp_utf8, $NEW, 'with the right content' );
    is( ident($installed)->{nlink}, 1, 'one link, as a fresh file should have' );
};

subtest 'a read-only installed skill is still updated, and a broken chain is reported' => sub {
    plan skip_all => 'running as root: a read-only file is still writable'
        if $> == 0;

    my $dir = tempdir( CLEANUP => 1 );
    my ( $installed, $elsewhere ) = chained_install( $dir, $OLD );
    plan skip_all => 'filesystem does not support hardlinks' unless $installed;
    chmod 0444, "$installed" or plan skip_all => "cannot chmod the target: $!";
    plan skip_all => 'the target is writable despite mode 0444' if -w "$installed";

    my $before = ident($installed);
    my $r = install_into( $dir, $NEW );
    chmod 0644, "$installed", "$elsewhere";

    # Before the fix this case worked (the rename only needs a writable
    # directory), so it keeps working -- but it is the one path where the chain
    # cannot survive, and that is said out loud rather than done quietly.
    is( $r->{error}, '', 'the install still succeeds' );
    is( $installed->slurp_utf8, $NEW, 'the read-only target was updated, as it was before' );
    isnt( ident($installed)->{ino}, $before->{ino}, 'by replacement: in-place was impossible here' );
    is( $elsewhere->slurp_utf8, $OLD, 'so the other link is left on the old content' );

    is( scalar( @{ $r->{warnings} } ), 1, 'exactly one warning' )
        or diag "warnings emitted: @{ $r->{warnings} }";
    like( $r->{warnings}[0], qr/could not be written in place/, 'it says the write was not in place' );
    like( $r->{warnings}[0], qr/hardlink/, 'and that a hardlink is affected' );
    unlike( $r->{warnings}[0], qr/ at \S+ line \d+/, 'no karr source location in it' )
        or diag "warning was: $r->{warnings}[0]";
};

subtest 'an unwritable .claude is still the one-line error of ticket #77' => sub {
    plan skip_all => 'running as root: an unwritable directory is still writable'
        if $> == 0;

    # t/120-error-message-sweep.t pins this end to end; repeated here because
    # routing the write through the shared role is exactly the change that could
    # have swapped this message for the role's own "Could not write ...".
    my $dir    = tempdir( CLEANUP => 1 );
    my $claude = path($dir)->child('.claude');
    $claude->mkpath;
    chmod 0500, "$claude" or plan skip_all => "cannot chmod the directory: $!";

    my $r = install_into( $dir, $NEW );
    chmod 0700, "$claude";

    like( $r->{error}, qr/^Could not create /, 'the directory is what karr could not make' );
    like( $r->{error}, qr/Permission denied/,  'with the reason from the OS' );
    unlike( $r->{error}, qr/ at \S+ line \d+/, 'and no source location' )
        or diag "error was: $r->{error}";
    my @lines = split /\n/, $r->{error};
    is( scalar(@lines), 1, 'exactly one line' ) or diag "error was: $r->{error}";
};

subtest 'karr init --claude-skill through the real CLI keeps the inode' => sub {
    my $repo = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', $repo ) == 0
        or plan skip_all => 'git init failed';
    system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
    system( 'git', '-C', $repo, 'config', 'user.name',  'Test User' );

    my ( $installed, $elsewhere ) = chained_install( $repo, $OLD );
    plan skip_all => 'filesystem does not support hardlinks' unless $installed;

    # A share dir of our own, ahead of everything else in @INC, so the child
    # reads a skill we control rather than an installed App::karr's (t/65 has
    # the long version of why this matters).
    my $share_lib = path( tempdir( CLEANUP => 1 ) );
    my $share_dir = $share_lib->child(qw( auto share dist App-karr ));
    $share_dir->mkpath;
    $share_dir->child('claude-skill.md')->spew_utf8($NEW);

    my $before = ident($installed);

    my $old_cwd = getcwd();
    chdir $repo or die "chdir $repo: $!";
    my $err_fh = gensym;
    my $pid = open3( my $in, my $out_fh, $err_fh,
        $^X, "-I$share_lib", "-I$ROOT/lib", $BIN, 'init', '--claude-skill' );
    close $in;
    my $out = do { local $/; <$out_fh> };
    my $err = do { local $/; <$err_fh> };
    waitpid( $pid, 0 );
    my $exit = $? >> 8;
    chdir $old_cwd or die "chdir $old_cwd: $!";

    is( $exit, 0, 'karr init --claude-skill exits 0' ) or diag "stderr: $err";
    like( $out, qr/Installed Claude Code skill/, 'and reports the install' );
    is( ident($installed)->{ino}, $before->{ino}, 'it wrote through the existing inode' );
    is( ident($installed)->{nlink}, 2, 'the chain still has both links' );
    is( $installed->slurp_utf8, $NEW, 'the project got the new skill' );
    is( $elsewhere->slurp_utf8, $NEW, 'and so did every other project on the chain' );
};

done_testing;
