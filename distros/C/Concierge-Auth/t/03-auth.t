#!/usr/bin/env perl

use v5.36;

use strict;
use warnings;
use Test2::V0;
use File::Temp qw/tempdir/;

use Concierge::Auth;

my $dir  = tempdir( CLEANUP => 1 );
my $file = "$dir/auth.pwd";
my $auth = Concierge::Auth->new({ file => $file });

# ========== setPwd ==========

subtest 'setPwd - create user' => sub {
    my ($ok, $msg) = $auth->setPwd('alice', 'password123');
    ok( $ok, 'setPwd succeeds for new user' );
    is( $msg, 'alice', 'message returns user ID' );
};

subtest 'setPwd - duplicate ID rejected' => sub {
    my ($ok, $msg) = $auth->setPwd('alice', 'otherpassword');
    ok( !$ok, 'setPwd rejects duplicate ID' );
    like( $msg, qr/previously used/i, 'message mentions previously used' );
};

# ========== checkID ==========

subtest 'checkID - existing user' => sub {
    my ($ok, $msg) = $auth->checkID('alice');
    ok( $ok, 'checkID finds existing user' );
    like( $msg, qr/OK/i, 'message confirms ID OK' );
};

subtest 'checkID - missing user' => sub {
    my ($ok, $msg) = $auth->checkID('nonexistent');
    ok( !$ok, 'checkID rejects missing user' );
    like( $msg, qr/not confirmed/i, 'message mentions not confirmed' );
};

# ========== checkPwd ==========

subtest 'checkPwd - correct password' => sub {
    my ($ok, $msg) = $auth->checkPwd('alice', 'password123');
    ok( $ok, 'checkPwd succeeds with correct password' );
};

subtest 'checkPwd - wrong password' => sub {
    my ($ok, $msg) = $auth->checkPwd('alice', 'wrongpassword');
    ok( !$ok, 'checkPwd rejects wrong password' );
    like( $msg, qr/Invalid password/i, 'message mentions invalid password' );
};

subtest 'checkPwd - missing user' => sub {
    my ($ok, $msg) = $auth->checkPwd('nonexistent', 'password123');
    ok( !$ok, 'checkPwd rejects missing user' );
    like( $msg, qr/not found/i, 'message mentions not found' );
};

# ========== resetPwd ==========

subtest 'resetPwd - change password' => sub {
    my ($ok, $msg) = $auth->resetPwd('alice', 'newpassword456');
    ok( $ok, 'resetPwd succeeds' );
    is( $msg, 'alice', 'message returns user ID' );

    # Old password should fail
    my ($ok2, $msg2) = $auth->checkPwd('alice', 'password123');
    ok( !$ok2, 'old password fails after reset' );

    # New password should succeed
    my ($ok3, $msg3) = $auth->checkPwd('alice', 'newpassword456');
    ok( $ok3, 'new password succeeds after reset' );
};

subtest 'resetPwd - missing user' => sub {
    my ($ok, $msg) = $auth->resetPwd('nonexistent', 'password123');
    ok( !$ok, 'resetPwd rejects missing user' );
    like( $msg, qr/not found/i, 'message mentions not found' );
};

# ========== deleteID ==========

subtest 'deleteID - remove user' => sub {
    # First confirm user exists
    my ($exists) = $auth->checkID('alice');
    ok( $exists, 'user exists before delete' );

    my ($ok, $msg) = $auth->deleteID('alice');
    ok( $ok, 'deleteID succeeds' );

    # Confirm user is gone
    my ($gone) = $auth->checkID('alice');
    ok( !$gone, 'user is gone after delete' );
};

subtest 'deleteID - missing user' => sub {
    my ($ok, $msg) = $auth->deleteID('nonexistent');
    ok( !$ok, 'deleteID rejects missing user' );
    like( $msg, qr/not found/i, 'message mentions not found' );
};

# ========== Validation failures passed through ==========

subtest 'validation failures - bad ID' => sub {
    my ($ok, $msg) = $auth->setPwd('', 'password123');
    ok( !$ok, 'setPwd rejects empty ID' );

    ($ok, $msg) = $auth->checkID('x');
    ok( !$ok, 'checkID rejects too-short ID' );

    ($ok, $msg) = $auth->checkPwd('', 'password123');
    ok( !$ok, 'checkPwd rejects empty ID' );

    ($ok, $msg) = $auth->resetPwd('', 'password123');
    ok( !$ok, 'resetPwd rejects empty ID' );

    ($ok, $msg) = $auth->deleteID('');
    ok( !$ok, 'deleteID rejects empty ID' );
};

subtest 'validation failures - bad password' => sub {
    my ($ok, $msg) = $auth->setPwd('bob', 'short');
    ok( !$ok, 'setPwd rejects short password' );

    ($ok, $msg) = $auth->checkPwd('bob', 'short');
    ok( !$ok, 'checkPwd rejects short password' );

    ($ok, $msg) = $auth->resetPwd('bob', 'short');
    ok( !$ok, 'resetPwd rejects short password' );
};

subtest 'validation failures - undef/empty password arg' => sub {
    # Exercises the `my $passwd = shift || ''` branch in setPwd/resetPwd
    # when the caller passes an empty string or no second argument.
    my ($ok, $msg) = $auth->setPwd('someuser', '');
    ok( !$ok, 'setPwd rejects empty string password' );
    like( $msg, qr/empty/i, 'message mentions empty' );

    ($ok, $msg) = $auth->resetPwd('someuser', '');
    ok( !$ok, 'resetPwd rejects empty string password' );
    like( $msg, qr/empty/i, 'message mentions empty' );
};

# ========== confirm/reject/reply response helpers ==========
# These are undocumented package functions used internally;
# tested here to cover their default-message branches.

subtest 'confirm - default message' => sub {
    my ($ok, $msg) = Concierge::Auth::confirm();
    ok( $ok, 'confirm() with no arg returns true' );
    like( $msg, qr/confirmation/i, 'default confirmation message used' );
};

subtest 'reject - default message' => sub {
    my ($ok, $msg) = Concierge::Auth::reject();
    ok( !$ok, 'reject() with no arg returns false' );
    like( $msg, qr/rejection/i, 'default rejection message used' );
};

subtest 'reply - single-arg forms' => sub {
    # With no message arg, the ternary picks the default based on $bool
    my ($r1, $m1) = Concierge::Auth::reply(1);
    ok( $r1, 'reply(1) returns true' );
    like( $m1, qr/confirmation/i, 'truthy bool gives confirmation default' );

    my ($r0, $m0) = Concierge::Auth::reply(0);
    ok( !$r0, 'reply(0) returns false' );
    like( $m0, qr/rejection/i, 'falsy bool gives rejection default' );

    # No args at all — $bool defaults to 0 via //
    my ($rn, $mn) = Concierge::Auth::reply();
    ok( !$rn, 'reply() with no args returns false' );
};

# ========== encryptPwd ==========

subtest 'encryptPwd - valid password' => sub {
    my $hash = $auth->encryptPwd('password123');
    ok( $hash, 'encryptPwd returns a truthy value' );
    like( $hash, qr/^\$argon2/, 'hash has Argon2 format' );
};

subtest 'encryptPwd - invalid password rejected' => sub {
    my $result = $auth->encryptPwd('short');
    ok( !$result, 'encryptPwd returns falsy for invalid password' );

    my ($ok, $msg) = $auth->encryptPwd('short');
    ok( !$ok, 'list context: encryptPwd returns false for invalid password' );
    like( $msg, qr/between/i, 'message mentions length requirement' );
};

# ========== no-file error paths ==========

subtest 'checkID - no file configured' => sub {
    my $nf;
    my $w = warnings { $nf = Concierge::Auth->new({ no_file => 1 }) };
    my ($ok, $msg) = $nf->checkID('alice');
    ok( !$ok, 'checkID fails when no file is set' );
    like( $msg, qr/No auth file/i, 'message mentions no auth file' );
};

subtest 'checkPwd - no file configured' => sub {
    my $nf;
    my $w = warnings { $nf = Concierge::Auth->new({ no_file => 1 }) };
    my ($ok, $msg) = $nf->checkPwd('alice', 'password123');
    ok( !$ok, 'checkPwd fails when no file is set' );
};

subtest 'deleteID - no file configured' => sub {
    my $nf;
    my $w = warnings { $nf = Concierge::Auth->new({ no_file => 1 }) };
    my ($ok, $msg) = $nf->deleteID('alice');
    ok( !$ok, 'deleteID fails when no file is set' );
};

subtest 'resetPwd - no file configured' => sub {
    my $nf;
    my $w = warnings { $nf = Concierge::Auth->new({ no_file => 1 }) };
    my ($ok, $msg) = $nf->resetPwd('alice', 'password123');
    ok( !$ok, 'resetPwd fails when no file is set' );
    like( $msg, qr/Not OK/i, 'message reflects file validation failure' );
};

done_testing;
