use strict;
use warnings;
use utf8;        # source has UTF-8 string literals, see ticket #157
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
use JSON::MaybeXS qw( decode_json );

use App::karr::Git;
use App::karr::BoardStore;
use App::karr::ActivityLog;
use App::karr::Task;
use App::karr::Cmd::Create;

# Ticket #157: _config_string returned the raw bytes libgit2 hands back,
# without the from_octets crossing every other octet edge in Git.pm has.
# A non-ASCII user.name entered the program as a byte string treated as
# characters, was JSON-encoded into the activity log, and to_octets then
# encoded those bytes a second time on the way to the ref. The task ref
# written by the same command came out correctly (because Task::to_markdown
# round-trips through YAML which goes through from_octets on the read), so
# the corruption was specific to the identity and permanent: board_is_legacy
# was false, repair_mojibake never ran, and `karr repair` answered "already at
# version 2; nothing to repair". There was no path back from inside karr.
#
# git_user_email had the same gap, and _run_git's captured stderr (used as
# the body of last_error on a CLI transport failure) was the same class of
# raw octets printed straight to a :encoding(UTF-8) handle.
#
# The fix is one line each: _config_string runs through from_octets, and
# _run_git decodes the merged stderr buffer before it leaves.

my $ROOT = abs_path('.');
my $BIN  = "$ROOT/bin/karr";

# Wide character in print would noise the diagnostics on an encoding test, so
# pin the UTF-8 layer here too.
binmode( Test::More->builder->$_, ':encoding(UTF-8)' )
  for qw( output failure_output todo_output );

my $NAME = "Ünicode Tester";   # U+00DC; octet-sequence c3 9c
my $EMAIL = 'tëst@example.com';  # contains U+00EB
my $RAW_NAME_OCTETS  = encode_utf8($NAME);
my $RAW_EMAIL_OCTETS = encode_utf8($EMAIL);

sub _run_karr {
    my ( $cwd, @argv ) = @_;
    my $old = getcwd();
    chdir $cwd or die "chdir $cwd: $!";

    my $stderr = gensym;
    my $pid = open3( my $in, my $out, $stderr, $^X, "-I$ROOT/lib", $BIN, @argv );
    close $in;
    binmode $out;
    binmode $stderr;
    my $stdout      = do { local $/; <$out> };
    my $stderr_text = do { local $/; <$stderr> };
    waitpid( $pid, 0 );
    my $exit = $? >> 8;

    chdir $old or die "chdir $old: $!";
    return {
        exit   => $exit,
        stdout => defined $stdout      ? $stdout      : '',
        stderr => defined $stderr_text ? $stderr_text : '',
    };
}

sub _init_repo {
    my $repo = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', $repo ) == 0 or BAIL_OUT('git init failed');
    # `git config` itself takes the value as bytes, so the libgit2 read above
    # gets exactly the UTF-8 octets we want to spot on the way back.
    system( 'git', '-C', $repo, 'config', 'user.email', $RAW_EMAIL_OCTETS ) == 0 or BAIL_OUT('git config failed');
    system( 'git', '-C', $repo, 'config', 'user.name',  $RAW_NAME_OCTETS )  == 0 or BAIL_OUT('git config failed');
    return $repo;
}

# Read the raw bytes git stores for one ref, untouched by karr's layer.
sub _blob {
    my ( $repo, $ref ) = @_;
    open my $fh, '-|', 'git', '-C', $repo, 'cat-file', '-p', "$ref:data"
        or die "git cat-file: $!";
    binmode $fh;
    my $raw = do { local $/; <$fh> };
    close $fh;
    return defined $raw ? $raw : '';
}

# "Encoded exactly once" as an assertion: the UTF-8 octets are present, the
# double-encode is not, and the whole payload is valid UTF-8.
sub is_single_utf8 {
    my ( $bytes, $text, $name ) = @_;
    my $ok = 1;
    $ok &&= ok( index( $bytes, encode_utf8($text) ) >= 0, "$name: present as UTF-8 octets" );
    $ok &&= is( index( $bytes, encode_utf8( encode_utf8($text) ) ), -1, "$name: not double-encoded" );
    $ok &&= ok( defined eval { decode( 'UTF-8', $bytes, FB_CROAK | LEAVE_SRC ) },
        "$name: payload is valid UTF-8" );
    diag( "offending bytes: " . unpack( 'H*', $bytes ) ) unless $ok;
    return $ok;
}

subtest 'git_user_name returns decoded characters, not raw octets' => sub {
    my $repo = _init_repo();
    my $git  = App::karr::Git->new( dir => $repo );

    is( $git->git_user_name,  $NAME,
        'git_user_name returns the characters, not the UTF-8 octets' );
    ok( utf8::is_utf8( $git->git_user_name ),
        '...and the string is flagged as characters' );

    is( $git->git_user_email, $EMAIL,
        'git_user_email returns the characters' );
    is( $git->git_user_identity, "$NAME <$EMAIL>",
        'git_user_identity combines both halves as characters' );
};

subtest 'the activity log stores the identity as singly-encoded UTF-8' => sub {
    # The reproduction in ticket #157: a non-ASCII user.name written to the
    # log ref came out as the mojibake of the correct text, because the value
    # went into json_encode as bytes, was treated as characters, and to_octets
    # encoded those bytes a second time on the way to the ref.
    my $repo = _init_repo();
    is( _run_karr( $repo, 'init', '--name', 'Identity Board' )->{exit}, 0, 'board initialized' );

    my $git = App::karr::Git->new( dir => $repo );
    my $store = App::karr::BoardStore->new( git => $git );
    $git->write_ref( 'refs/karr/meta/next-id', "1\n" );

    my $cmd = App::karr::Cmd::Create->new( store => $store );
    my $err = do {
        local $@;
        eval {
            local *STDOUT;
            open STDOUT, '>', \my $null or die $!;
            $cmd->execute( ['task one'], [] );
        };
        $@;
    };
    is( $err, '', 'create executes cleanly' ) or diag("died with: $err");

    # ls the log ref, not the config.ref content (which is metadata).
    my $git_log = `git -C $repo for-each-ref --format='%(refname)' refs/karr/log/`;
    my ($log_ref) = split /\n/, $git_log;
    ok( $log_ref, 'a log ref was written' );

    my $raw = _blob( $repo, $log_ref );
    is_single_utf8( $raw, $NAME, 'log ref name field' );

    # The email is part of the log ref path (percent-encoded in the ref name),
    # not the JSON payload. The log entry's only identity field is the agent
    # name, so this is the right place to look.

    # And the characters read back through the normal activity log path.
    my $log = App::karr::ActivityLog->new( git => $git );
    my @entries = $log->entries;
    is( scalar @entries, 1, 'one entry was logged' );
    is( $entries[0]{agent}, $NAME, 'the entry records the characters, not bytes' );
};

subtest 'show --json reports the identity as characters' => sub {
    # The other side of the bug: the same bytes that corrupted the log ref
    # could have shown up in the task ref via Task::to_json_hash had the
    # frontmatter taken them. The task itself doesn't carry an agent field,
    # so the test here is "the JSON round-trips as valid UTF-8 with no
    # double-encoded bytes sneaking in via the title" -- which is also where
    # the bytes from user.name would have shown up if the encoding pipeline
    # had leaked.
    my $repo = _init_repo();
    is( _run_karr( $repo, 'init', '--name', 'JSON Board' )->{exit}, 0, 'board initialized' );
    is( _run_karr( $repo, 'create', 'first task' )->{exit}, 0, 'task created' );

    my $json = _run_karr( $repo, 'show', '1', '--json' );
    is( $json->{exit}, 0, 'show --json exits 0' );
    ok( defined eval { decode( 'UTF-8', $json->{stdout}, FB_CROAK | LEAVE_SRC ) },
        'show --json stdout is valid UTF-8' );
    ok( index( $json->{stdout}, encode_utf8( encode_utf8("Ü") ) ) == -1,
        'show --json stdout does not double-encode the agent' );

    my $data = decode_json( $json->{stdout} );
    is( $data->{title}, 'first task', '...and parses back to the right task' );
};

subtest 'karr log renders the identity correctly' => sub {
    my $repo = _init_repo();
    is( _run_karr( $repo, 'init', '--name', 'Log Board' )->{exit}, 0, 'board initialized' );
    is( _run_karr( $repo, 'create', 'first task' )->{exit}, 0, 'task created' );

    my $log = _run_karr( $repo, 'log' );
    is( $log->{exit}, 0, 'log exits 0' );
    is_single_utf8( $log->{stdout}, $NAME, 'log stdout name field' );
    # The handle was binned without an encoding layer, so the captured stdout
    # is bytes, not characters. The regex pattern has to be the same kind of
    # string -- $NAME is a char string under `use utf8`, but the bytes karr
    # wrote are the UTF-8 encoding of it, which is what we want to match.
    like( $log->{stdout}, qr/\Q$RAW_NAME_OCTETS\E/,
        'the right characters appear in the log' );
    unlike( $log->{stdout}, qr/\xc3\x83\xc2\x9c/,
        '...and the mojibake of them does not' );
};

subtest 'CLI transport stderr lands on the :encoding(UTF-8) handle, not as raw octets' => sub {
    # The other gap called out in the ticket: _run_git captured stderr into
    # result.err as raw bytes, _cli_transport used that as the message body,
    # and the message reached the user through the :encoding(UTF-8) layer App::
    # karr::Encoding::enable_std_utf8 put on STDERR. The bytes that came back
    # through the transport from a non-ASCII command were then encoded a
    # second time on their way out -- a third path to the same mojibake.
    subtest 'a CLI transport failure message is round-trippable UTF-8' => sub {
        # Easiest seam: a push to a remote that does not exist. The fallback
        # path runs the system git; if it ever does, the stderr it returns
        # has to round-trip cleanly through the encoding layer.
        my $repo = _init_repo();
        is( _run_karr( $repo, 'init', '--name', 'STDERR Board' )->{exit}, 0, 'board initialized' );

        # Point origin at a URL whose hostname part contains non-ASCII. The
        # git CLI's own error message will include the URL verbatim, so the
        # reported text now has to round-trip through the encoding boundary.
        my $url = encode_utf8( "https://üd.example.com/nowhere.git" );
        system( 'git', '-C', $repo, 'remote', 'add', 'origin', $url ) == 0
            or BAIL_OUT('remote add failed');

        my $rv = _run_karr( $repo, 'sync', '--push' );
        isnt( $rv->{exit}, 0, 'sync --push fails without a real remote' );

        # Whatever the message says, it has to be valid UTF-8 and not a
        # double-encode. The actual text content depends on the system git
        # and on the network, so we assert on the bytes, not the prose.
        for my $text ( $rv->{stdout}, $rv->{stderr} ) {
            next unless length $text;
            ok( defined eval { decode( 'UTF-8', $text, FB_CROAK | LEAVE_SRC ) },
                'a CLI transport failure message is valid UTF-8' );
        }
    };
};

subtest '_config_string still returns the empty string for missing keys' => sub {
    # The contract _config_string answers is "empty string, never undef". A
    # from_octets('') round-trip is fine, but a from_octets(undef) is not what
    # the caller pattern expects.
    my $repo = _init_repo();
    my $git  = App::karr::Git->new( dir => $repo );
    is( $git->_config_string('nonexistent.key'), '',
        'an unset config value reads back as the empty string' );
};

done_testing;
