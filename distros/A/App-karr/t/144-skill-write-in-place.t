use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );
use Cwd qw( abs_path getcwd );
use IPC::Open3 qw( open3 );
use Symbol qw( gensym );
use Path::Tiny qw( path );

use App::karr::Cmd::Skill;

# Ticket #142: `karr skill update` silently broke hardlink chains.
#
# A SKILL.md is not an ordinary file. Skills are shared between projects as a
# manage-skills hardlink chain: one inode, the same relative path under
# .claude/skills in dozens of checkouts. Path::Tiny's spew_utf8 writes a temp
# file and renames it over the target, so the updated path lands on a fresh
# inode -- it gets the new text and every other project keeps the old inode
# with the old text, link count silently down by one. Found during agent setup
# in kubernetes-ocp, where the workaround was piping `karr skill show` through
# a shell redirect.
#
# The property pinned here is the one that matters to those other projects:
# after a write, the target path is still the same inode it was before, so the
# whole chain sees the new content. The mechanism (append_utf8 with truncate)
# is deliberately not what is asserted -- any in-place write may replace it.

my $ROOT = abs_path('.');
my $BIN  = "$ROOT/bin/karr";

# Non-ASCII on purpose: an in-place write must keep the same single UTF-8
# encode spew_utf8 did (App::karr::Encoding: files are character-level, nothing
# may encode on top). Spelled with \x{} so this file needs no source encoding.
my $OLD = "# karr skill \x{2014} old\n";
my $NEW = "# karr skill \x{2014} new\n\nBl\x{00f6}cke \x{2026} \x{00fc}ml\x{00e4}ute\n";

# (dev, inode, link count) of a path, without following the last symlink.
sub ident {
    my ($path) = @_;
    my @st = stat "$path" or return;
    return { dev => $st[0], ino => $st[1], nlink => $st[3] };
}

sub linked_pair {
    my ($dir, $content) = @_;
    my $a = path($dir)->child('a/SKILL.md');
    my $b = path($dir)->child('b/SKILL.md');
    $a->parent->mkpath;
    $b->parent->mkpath;
    $a->spew_utf8($content);
    link( "$a", "$b" ) or return;
    return ( $a, $b );
}

subtest 'the premise: spew_utf8 really does rehome the inode' => sub {
    # Without this, the test below could pass against a broken implementation
    # on a system where the hazard does not exist at all.
    my $dir = tempdir( CLEANUP => 1 );
    my ( $primary, $secondary ) = linked_pair( $dir, $OLD );
    plan skip_all => 'filesystem does not support hardlinks' unless $primary;

    my $before = ident($primary);
    is( $before->{nlink}, 2, 'the two paths start out as one inode with two links' );

    $primary->spew_utf8($NEW);

    isnt( ident($primary)->{ino}, $before->{ino}, 'spew_utf8 leaves the path on a different inode' );
    is( ident($secondary)->{ino}, $before->{ino}, 'the other link keeps the original inode' );
    is( $secondary->slurp_utf8, $OLD, 'and therefore still holds the old content' );
    is( ident($secondary)->{nlink}, 1, 'link count dropped, with nothing said' );
};

subtest '_write_skill keeps the inode, so every link in the chain updates' => sub {
    my $dir = tempdir( CLEANUP => 1 );
    my ( $primary, $secondary ) = linked_pair( $dir, $OLD );
    plan skip_all => 'filesystem does not support hardlinks' unless $primary;

    my $before = ident($primary);

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    App::karr::Cmd::Skill->new->_write_skill( $primary, $NEW );

    my $after = ident($primary);
    is( $after->{dev}, $before->{dev}, 'same device' );
    is( $after->{ino}, $before->{ino}, 'same inode: the write went through the existing file' );
    is( $after->{nlink}, 2, 'link count is untouched' );
    is( ident($secondary)->{ino}, $before->{ino}, 'the second path is still that same inode' );

    is( $primary->slurp_utf8, $NEW, 'the written path has the new content' );
    is( $secondary->slurp_utf8, $NEW, 'and so does every other project on the chain' );

    # Truncation, not overwrite-in-front: $NEW is longer here, but a shorter
    # replacement must not leave a tail of the old file behind.
    App::karr::Cmd::Skill->new->_write_skill( $primary, "short\n" );
    is( $secondary->slurp_utf8, "short\n", 'a shorter write truncates rather than overwriting in place' );
    is( ident($primary)->{ino}, $before->{ino}, 'still the same inode afterwards' );

    is( scalar(@warnings), 0, 'an in-place write says nothing' )
        or diag "warnings emitted: @warnings";
};

subtest 'the content is encoded exactly once' => sub {
    my $dir  = tempdir( CLEANUP => 1 );
    my $file = path($dir)->child('SKILL.md');

    App::karr::Cmd::Skill->new->_write_skill( $file, $NEW );

    my $raw = do {
        open my $fh, '<:raw', "$file" or die "open $file: $!";
        local $/;
        <$fh>;
    };
    is( $raw, "# karr skill \xe2\x80\x94 new\n\nBl\xc3\xb6cke \xe2\x80\xa6 \xc3\xbcml\xc3\xa4ute\n",
        'UTF-8 on disk, encoded once' );
    is( $file->slurp_utf8, $NEW, 'and it reads back as the characters that went in' );
};

subtest 'a target that does not exist yet is still created' => sub {
    my $dir  = tempdir( CLEANUP => 1 );
    my $file = path($dir)->child('deep/skills/karr/SKILL.md');

    ok( !$file->exists, 'nothing there to begin with' );
    App::karr::Cmd::Skill->new->_write_skill( $file, $NEW );

    ok( $file->exists, 'the file was created' );
    is( $file->slurp_utf8, $NEW, 'with the right content' );
    is( ident($file)->{nlink}, 1, 'one link, as a fresh file should have' );
    ok( -d $file->parent, 'and its directory tree was made' );
};

subtest 'a symlinked target is written through, and stays a symlink' => sub {
    my $dir  = tempdir( CLEANUP => 1 );
    my $real = path($dir)->child('real/SKILL.md');
    $real->parent->mkpath;
    $real->spew_utf8($OLD);

    my $chained = path($dir)->child('chain/SKILL.md');
    $chained->parent->mkpath;
    plan skip_all => 'filesystem does not support hardlinks'
        unless link( "$real", "$chained" );

    my $link = path($dir)->child('link/SKILL.md');
    $link->parent->mkpath;
    plan skip_all => 'filesystem does not support symlinks'
        unless eval { symlink( "$real", "$link" ) };

    my $before = ident($real);
    App::karr::Cmd::Skill->new->_write_skill( $link, $NEW );

    ok( -l "$link", 'the symlink is still a symlink, not replaced by a regular file' );
    is( ident($real)->{ino}, $before->{ino}, 'its target kept its inode' );
    is( $real->slurp_utf8, $NEW, 'the target got the new content' );
    is( $chained->slurp_utf8, $NEW, 'and the hardlink to that target sees it too' );
};

subtest 'a read-only target is still updated, and a broken chain is reported' => sub {
    plan skip_all => 'running as root: a read-only file is still writable'
        if $> == 0;

    my $dir = tempdir( CLEANUP => 1 );
    my ( $primary, $secondary ) = linked_pair( $dir, $OLD );
    plan skip_all => 'filesystem does not support hardlinks' unless $primary;
    chmod 0444, "$primary" or plan skip_all => "cannot chmod the target: $!";
    plan skip_all => 'the target is writable despite mode 0444' if -w "$primary";

    my $before = ident($primary);
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    App::karr::Cmd::Skill->new->_write_skill( $primary, $NEW );

    # Before the fix this case worked (the rename only needs a writable
    # directory), so it keeps working -- but it is now the one path where the
    # chain cannot survive, and that is said out loud rather than done quietly.
    is( $primary->slurp_utf8, $NEW, 'the read-only target was updated, as it was before' );
    isnt( ident($primary)->{ino}, $before->{ino}, 'by replacement: in-place was impossible here' );
    is( $secondary->slurp_utf8, $OLD, 'so the other link is left on the old content' );

    is( scalar(@warnings), 1, 'exactly one warning' ) or diag "warnings emitted: @warnings";
    like( $warnings[0], qr/could not be written in place/, 'it says the write was not in place' );
    like( $warnings[0], qr/hardlink/, 'and that a hardlink is affected' );
    unlike( $warnings[0], qr/ at \S+ line \d+/, 'no karr source location in it' )
        or diag "warning was: $warnings[0]";

    chmod 0644, "$primary", "$secondary";
};

subtest 'a read-only target with no other links warns about nothing' => sub {
    plan skip_all => 'running as root: a read-only file is still writable'
        if $> == 0;

    my $dir  = tempdir( CLEANUP => 1 );
    my $file = path($dir)->child('SKILL.md');
    $file->spew_utf8($OLD);
    chmod 0444, "$file" or plan skip_all => "cannot chmod the target: $!";
    plan skip_all => 'the target is writable despite mode 0444' if -w "$file";

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    App::karr::Cmd::Skill->new->_write_skill( $file, $NEW );

    is( $file->slurp_utf8, $NEW, 'still updated' );
    is( scalar(@warnings), 0, 'no chain to break, so no noise' )
        or diag "warnings emitted: @warnings";

    chmod 0644, "$file";
};

subtest 'an unwritable directory is still a clean one-line error' => sub {
    plan skip_all => 'running as root: an unwritable directory is still writable'
        if $> == 0;

    my $dir = tempdir( CLEANUP => 1 );
    my $sub = path($dir)->child('skills');
    $sub->mkpath;
    chmod 0500, "$sub" or plan skip_all => "cannot chmod the directory: $!";

    my $err = do {
        local $@;
        eval { App::karr::Cmd::Skill->new->_write_skill( $sub->child('SKILL.md'), $NEW ); 1 };
        $@;
    };
    chmod 0700, "$sub";

    like( $err, qr/^Could not write /, 'reported as a write failure (ticket #77 wording kept)' );
    like( $err, qr/Permission denied/, 'with the reason from the OS' );
    unlike( $err, qr/ at \S+ line \d+/, 'and no source location' ) or diag "error was: $err";
    my @lines = split /\n/, $err;
    is( scalar(@lines), 1, 'exactly one line' ) or diag "error was: $err";
};

subtest 'karr skill install/update through the real CLI keep the inode' => sub {
    my $dir = tempdir( CLEANUP => 1 );

    # A share dir of our own, ahead of everything else in @INC, so the child
    # reads a skill we control rather than an installed App::karr's (t/65 has
    # the long version of why this matters).
    my $share_lib = path( tempdir( CLEANUP => 1 ) );
    my $share_dir = $share_lib->child(qw( auto share dist App-karr ));
    $share_dir->mkpath;
    $share_dir->child('claude-skill.md')->spew_utf8($NEW);

    my $installed = path($dir)->child('.claude/skills/karr/SKILL.md');
    $installed->parent->mkpath;
    $installed->spew_utf8($OLD);
    my $chained = path($dir)->child('elsewhere/SKILL.md');
    $chained->parent->mkpath;
    plan skip_all => 'filesystem does not support hardlinks'
        unless link( "$installed", "$chained" );

    my $before = ident($installed);

    my $run = sub {
        my (@args) = @_;
        my $old_cwd = getcwd();
        chdir $dir or die "chdir $dir: $!";
        my $err_fh = gensym;
        my $pid = open3( my $in, my $out_fh, $err_fh,
            $^X, "-I$share_lib", "-I$ROOT/lib", $BIN, 'skill', @args );
        close $in;
        my $out = do { local $/; <$out_fh> };
        my $err = do { local $/; <$err_fh> };
        waitpid( $pid, 0 );
        my $exit = $? >> 8;
        chdir $old_cwd or die "chdir $old_cwd: $!";
        return ( $exit, $out, $err );
    };

    my ( $exit, $out, $err ) = $run->( 'update', '--agent', 'claude-code' );
    is( $exit, 0, 'karr skill update exits 0' ) or diag "stderr: $err";
    like( $out, qr/updated/, 'and reports the update' );
    is( ident($installed)->{ino}, $before->{ino}, 'update wrote through the existing inode' );
    is( ident($installed)->{nlink}, 2, 'the chain still has both links' );
    is( $chained->slurp_utf8, $NEW, 'the other project sees the new skill' );

    # --force reinstall takes the same write path, so it must behave the same.
    $installed->append_utf8( { truncate => 1 }, $OLD );
    ( $exit, $out, $err ) = $run->( 'install', '--force', '--agent', 'claude-code' );
    is( $exit, 0, 'karr skill install --force exits 0' ) or diag "stderr: $err";
    is( ident($installed)->{ino}, $before->{ino}, 'install --force wrote through it too' );
    is( $chained->slurp_utf8, $NEW, 'and the chain carries the new skill again' );
};

done_testing;
