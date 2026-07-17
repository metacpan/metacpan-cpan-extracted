#!/usr/bin/env perl

use v5.36;

use strict;
use warnings;
use Test2::V0;
use File::Temp qw/tempdir/;
use lib 't/lib';
use MockBuiltins;

use Concierge::Auth;
use Concierge::Auth::Base;
use Concierge::Auth::Pwd;
use Concierge::Auth::Generators qw(gen_word_phrase);

# This file covers I/O failure branches that the rest of the suite can't
# reach without forcing flock/open/chmod/unlink to fail -- see
# t/lib/MockBuiltins.pm. Real filesystem tricks (deleting a file behind an
# object's back) are used instead of mocking wherever that's simpler.
#
# $MockBuiltins::FAIL_OPEN_PATH scopes the injected open() failure to one
# specific path, so it doesn't also break unrelated opens happening in the
# same call (e.g. Crypt::Passphrase::Argon2's own use of /dev/urandom,
# which would otherwise be permanently poisoned for the rest of the
# process the first time it's touched).

my $dir = tempdir( CLEANUP => 1 );

# Warm up Crypt::Passphrase::Argon2 (and its /dev/urandom access) before
# any mocking is active, so its own one-time module-load I/O is never at
# risk of being caught by a FAIL_OPEN toggle below.
Concierge::Auth::Pwd->new( no_file => 1 )->encryptPwd('warm-up-password');

# ========== Concierge::Auth::Base - required-method stubs ==========

subtest 'Base - unimplemented contract methods die' => sub {
    for my $method (qw(new authenticate is_id_known enroll change_credentials revoke)) {
        like(
            dies { Concierge::Auth::Base->$method() },
            qr/Subclass must implement $method/,
            "$method stub dies with expected message",
        );
    }
};

# ========== new() - file open/chmod failures ==========

subtest 'new - open failure on existing file (read check)' => sub {
    my $file = "$dir/new_read_fail.pwd";
    open my $fh, '>', $file or die $!;
    close $fh;

    local $MockBuiltins::FAIL_OPEN      = 1;
    local $MockBuiltins::FAIL_OPEN_PATH = $file;
    like(
        dies { Concierge::Auth::Pwd->new( file => $file ) },
        qr/Can't read auth file/,
        'croaks when the existing file cannot be opened for reading',
    );
};

subtest 'new - open failure on new file (create)' => sub {
    my $file = "$dir/new_create_fail.pwd";

    local $MockBuiltins::FAIL_OPEN      = 1;
    local $MockBuiltins::FAIL_OPEN_PATH = $file;
    like(
        dies { Concierge::Auth::Pwd->new( file => $file ) },
        qr{Can't open/create auth file},
        'croaks when a new file cannot be created',
    );
};

subtest 'new - chmod failure is non-fatal' => sub {
    my $file = "$dir/new_chmod_fail.pwd";
    my $auth;

    local $MockBuiltins::FAIL_CHMOD = 1;
    my $w = warnings { $auth = Concierge::Auth::Pwd->new( file => $file ) };
    ok( $auth, 'object is still constructed despite chmod failure' );
    ok( scalar @$w, 'a warning was issued for the chmod failure' );
};

# ========== authenticate() ==========

subtest 'authenticate - open failure' => sub {
    my $file = "$dir/auth_open.pwd";
    my $auth = Concierge::Auth::Pwd->new( file => $file );
    $auth->enroll('alice', 'password123');

    local $MockBuiltins::FAIL_OPEN      = 1;
    local $MockBuiltins::FAIL_OPEN_PATH = $file;
    my $result = $auth->authenticate('alice', 'password123');
    ok( !$result->{success}, 'authenticate fails when file cannot be opened' );
    like( $result->{message}, qr/Cannot open auth file/, 'message reflects open failure' );
};

subtest 'authenticate - flock failure' => sub {
    my $file = "$dir/auth_flock.pwd";
    my $auth = Concierge::Auth::Pwd->new( file => $file );
    $auth->enroll('alice', 'password123');

    local $MockBuiltins::FAIL_FLOCK = 1;
    my $result = $auth->authenticate('alice', 'password123');
    ok( !$result->{success}, 'authenticate fails when file cannot be locked' );
    like( $result->{message}, qr/Cannot lock file for reading/, 'message reflects lock failure' );
};

# ========== is_id_known() ==========

subtest 'is_id_known - open failure' => sub {
    my $file = "$dir/known_open.pwd";
    my $auth = Concierge::Auth::Pwd->new( file => $file );
    $auth->enroll('alice', 'password123');

    local $MockBuiltins::FAIL_OPEN      = 1;
    local $MockBuiltins::FAIL_OPEN_PATH = $file;
    my $result = $auth->is_id_known('alice');
    ok( !$result->{success}, 'is_id_known fails when file cannot be opened' );
    like( $result->{message}, qr/Cannot open auth file/, 'message reflects open failure' );
};

subtest 'is_id_known - flock failure' => sub {
    my $file = "$dir/known_flock.pwd";
    my $auth = Concierge::Auth::Pwd->new( file => $file );
    $auth->enroll('alice', 'password123');

    local $MockBuiltins::FAIL_FLOCK = 1;
    my $result = $auth->is_id_known('alice');
    ok( !$result->{success}, 'is_id_known fails when file cannot be locked' );
    like( $result->{message}, qr/Cannot lock file for reading/, 'message reflects lock failure' );
};

subtest 'is_id_known - pfile set but file missing' => sub {
    my $file = "$dir/known_missing.pwd";
    my $auth = Concierge::Auth::Pwd->new( file => $file );
    unlink $file;

    my $result = $auth->is_id_known('alice');
    ok( $result->{success}, 'still succeeds (no I/O error) when file has vanished' );
    ok( !$result->{known}, 'reports not known when file has vanished' );
};

# ========== enroll() ==========

subtest 'enroll - no file configured' => sub {
    my $nf;
    my $w = warnings { $nf = Concierge::Auth::Pwd->new( no_file => 1 ) };
    my $result = $nf->enroll('alice', 'password123');
    ok( !$result->{success}, 'enroll fails when no file is set' );
};

subtest 'enroll - pfile set but file missing (skips duplicate check)' => sub {
    my $file = "$dir/enroll_missing.pwd";
    my $auth = Concierge::Auth::Pwd->new( file => $file );
    unlink $file;

    my $result = $auth->enroll('alice', 'password123');
    ok( $result->{success}, 'enroll succeeds, recreating the file' );
    ok( -e $file, 'file exists again after enroll' );
};

subtest 'enroll - open failure on duplicate check' => sub {
    my $file = "$dir/enroll_open_check.pwd";
    my $auth = Concierge::Auth::Pwd->new( file => $file );
    $auth->enroll('alice', 'password123');

    local $MockBuiltins::FAIL_OPEN      = 1;
    local $MockBuiltins::FAIL_OPEN_PATH = $file;
    my $result = $auth->enroll('bob', 'password123');
    ok( !$result->{success}, 'enroll fails when duplicate-check open fails' );
    like( $result->{message}, qr/Cannot open auth file/, 'message reflects open failure' );
};

subtest 'enroll - flock failure on duplicate check' => sub {
    my $file = "$dir/enroll_flock_check.pwd";
    my $auth = Concierge::Auth::Pwd->new( file => $file );
    $auth->enroll('alice', 'password123');

    local $MockBuiltins::FAIL_FLOCK = 1;
    my $result = $auth->enroll('bob', 'password123');
    ok( !$result->{success}, 'enroll fails when duplicate-check lock fails' );
    like( $result->{message}, qr/Cannot lock file for reading/, 'message reflects lock failure' );
};

subtest 'enroll - open failure on write (fresh file)' => sub {
    my $file = "$dir/enroll_open_write.pwd";
    my $auth = Concierge::Auth::Pwd->new( file => $file );
    unlink $file;    # skip the duplicate-check block entirely

    local $MockBuiltins::FAIL_OPEN      = 1;
    local $MockBuiltins::FAIL_OPEN_PATH = $file;
    my $result = $auth->enroll('alice', 'password123');
    ok( !$result->{success}, 'enroll fails when the write-open fails' );
    like( $result->{message}, qr/Cannot open auth file/, 'message reflects open failure' );
};

subtest 'enroll - flock failure on write' => sub {
    my $file = "$dir/enroll_flock_write.pwd";
    my $auth = Concierge::Auth::Pwd->new( file => $file );
    unlink $file;    # skip the duplicate-check block entirely

    local $MockBuiltins::FAIL_FLOCK = 1;
    my $result = $auth->enroll('alice', 'password123');
    ok( !$result->{success}, 'enroll fails when the write-lock fails' );
    like( $result->{message}, qr/Cannot lock file for writing/, 'message reflects lock failure' );
};

# ========== change_credentials() ==========

subtest 'change_credentials - pfile set but file missing' => sub {
    my $file = "$dir/change_missing.pwd";
    my $auth = Concierge::Auth::Pwd->new( file => $file );
    $auth->enroll('alice', 'password123');
    unlink $file;

    my $result = $auth->change_credentials('alice', 'newpassword456');
    ok( !$result->{success}, 'change_credentials fails when file has vanished' );
    like( $result->{message}, qr/Auth file not OK/, 'message reflects file check failure' );
};

subtest 'change_credentials - open failure' => sub {
    my $file = "$dir/change_open.pwd";
    my $auth = Concierge::Auth::Pwd->new( file => $file );
    $auth->enroll('alice', 'password123');

    local $MockBuiltins::FAIL_OPEN      = 1;
    local $MockBuiltins::FAIL_OPEN_PATH = $file;
    my $result = $auth->change_credentials('alice', 'newpassword456');
    ok( !$result->{success}, 'change_credentials fails when file cannot be opened' );
    like( $result->{message}, qr/Cannot open file/, 'message reflects open failure' );
};

subtest 'change_credentials - flock failure' => sub {
    my $file = "$dir/change_flock.pwd";
    my $auth = Concierge::Auth::Pwd->new( file => $file );
    $auth->enroll('alice', 'password123');

    local $MockBuiltins::FAIL_FLOCK = 1;
    my $result = $auth->change_credentials('alice', 'newpassword456');
    ok( !$result->{success}, 'change_credentials fails when file cannot be locked' );
    like( $result->{message}, qr/Cannot lock file/, 'message reflects lock failure' );
};

# ========== revoke() ==========

subtest 'revoke - pfile set but file missing' => sub {
    my $file = "$dir/revoke_missing.pwd";
    my $auth = Concierge::Auth::Pwd->new( file => $file );
    $auth->enroll('alice', 'password123');
    unlink $file;

    my $result = $auth->revoke('alice');
    ok( !$result->{success}, 'revoke fails when file has vanished' );
    like( $result->{message}, qr/no good/, 'message reflects file check failure' );
};

subtest 'revoke - open failure' => sub {
    my $file = "$dir/revoke_open.pwd";
    my $auth = Concierge::Auth::Pwd->new( file => $file );
    $auth->enroll('alice', 'password123');

    local $MockBuiltins::FAIL_OPEN      = 1;
    local $MockBuiltins::FAIL_OPEN_PATH = $file;
    my $result = $auth->revoke('alice');
    ok( !$result->{success}, 'revoke fails when file cannot be opened' );
    like( $result->{message}, qr/Cannot open file/, 'message reflects open failure' );
};

subtest 'revoke - flock failure' => sub {
    my $file = "$dir/revoke_flock.pwd";
    my $auth = Concierge::Auth::Pwd->new( file => $file );
    $auth->enroll('alice', 'password123');

    local $MockBuiltins::FAIL_FLOCK = 1;
    my $result = $auth->revoke('alice');
    ok( !$result->{success}, 'revoke fails when file cannot be locked' );
    like( $result->{message}, qr/Cannot lock file/, 'message reflects lock failure' );
};

subtest 'revoke - preserves unrelated records' => sub {
    my $file = "$dir/revoke_preserve.pwd";
    my $auth = Concierge::Auth::Pwd->new( file => $file );
    $auth->enroll('alice', 'password123');
    $auth->enroll('bob', 'password456');

    my $result = $auth->revoke('alice');
    ok( $result->{success}, 'revoke succeeds' );

    my $bob_known = $auth->is_id_known('bob');
    ok( $bob_known->{known}, 'unrelated record for bob is preserved' );
};

# ========== confirm/reject/reply - remaining branches ==========

subtest 'reply - scalar context with explicit message' => sub {
    my $scalar = Concierge::Auth::Pwd::reply(1, 'custom message');
    ok( $scalar, 'scalar context returns the bool value' );
};

# ========== setFile() ==========

subtest 'setFile - open failure on existing file (read check)' => sub {
    my $file = "$dir/setfile_read.pwd";
    open my $fh, '>', $file or die $!;
    close $fh;

    my $auth = Concierge::Auth::Pwd->new( no_file => 1 );
    local $MockBuiltins::FAIL_OPEN      = 1;
    local $MockBuiltins::FAIL_OPEN_PATH = $file;
    my ($ok, $msg) = $auth->setFile($file);
    ok( !$ok, 'setFile fails when existing file cannot be opened for reading' );
    like( $msg, qr/Can't read auth file/, 'message reflects open failure' );
};

subtest 'setFile - open failure on new file (create)' => sub {
    my $file = "$dir/setfile_create.pwd";

    my $auth = Concierge::Auth::Pwd->new( no_file => 1 );
    local $MockBuiltins::FAIL_OPEN      = 1;
    local $MockBuiltins::FAIL_OPEN_PATH = $file;
    my ($ok, $msg) = $auth->setFile($file);
    ok( !$ok, 'setFile fails when new file cannot be created' );
    like( $msg, qr{Can't open/create auth file}, 'message reflects open failure' );
};

subtest 'setFile - chmod failure is non-fatal' => sub {
    my $file = "$dir/setfile_chmod.pwd";
    my $auth = Concierge::Auth::Pwd->new( no_file => 1 );

    local $MockBuiltins::FAIL_CHMOD = 1;
    my ($ok, $w);
    $w = warnings { ($ok) = $auth->setFile($file) };
    ok( $ok, 'setFile still succeeds despite chmod failure' );
    ok( scalar @$w, 'a warning was issued for the chmod failure' );
};

# ========== rmFile() ==========

subtest 'rmFile - unlink failure' => sub {
    my $file = "$dir/rmfile_unlink.pwd";
    my $auth = Concierge::Auth::Pwd->new( file => $file );

    local $MockBuiltins::FAIL_UNLINK = 1;
    my ($result, $msg) = $auth->rmFile();
    ok( !$result, 'rmFile fails when unlink fails' );
    like( $msg, qr/Unable to unlink file/, 'message reflects unlink failure' );
};

# ========== Generators.pm - dictionary-file fallback ==========

subtest 'gen_word_phrase - fallback when dictionary file cannot be opened' => sub {
    local $MockBuiltins::FAIL_OPEN      = 1;
    local $MockBuiltins::FAIL_OPEN_PATH = '/usr/share/dict/web2';
    my ($phrase, $msg) = gen_word_phrase(4, 4, 7, '-');
    ok( defined $phrase, 'fallback still produces a phrase' );
    like( $msg, qr/fallback mode/i, 'message indicates fallback mode was used' );
};

subtest 'gen_word_phrase - fallback exercised repeatedly (dedup branch)' => sub {
    # The dedup branch (skip an already-picked word index) only triggers
    # probabilistically; repeating with a tiny wordlist makes a collision
    # all but certain across many calls. Not a hard assertion on the
    # branch itself -- just exercises it under Devel::Cover.
    local $MockBuiltins::FAIL_OPEN      = 1;
    local $MockBuiltins::FAIL_OPEN_PATH = '/usr/share/dict/web2';
    for (1 .. 100) {
        my ($phrase) = gen_word_phrase(3, 4, 5, '-');
        ok( defined $phrase, 'fallback phrase generated' ) if $_ == 1;
    }
    ok( 1, 'completed repeated fallback generation' );
};

done_testing;
