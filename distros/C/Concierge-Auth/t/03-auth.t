#!/usr/bin/env perl

use v5.36;

use strict;
use warnings;
use Test2::V0;
use File::Temp qw/tempdir/;

use Concierge::Auth;
use Concierge::Auth::Pwd;

my $dir  = tempdir( CLEANUP => 1 );
my $file = "$dir/auth.pwd";
my $auth = Concierge::Auth->new( backend_class => 'Concierge::Auth::Pwd', file => $file );

# ========== enroll (was setPwd) ==========

subtest 'enroll - create user' => sub {
    my $result = $auth->enroll('alice', 'password123');
    ok( $result->{success}, 'enroll succeeds for new user' );
    is( $result->{user_id}, 'alice', 'result carries the user ID' );
    is( $result->{status}, 'created', 'status is created' );
};

subtest 'enroll - duplicate ID rejected' => sub {
    my $result = $auth->enroll('alice', 'otherpassword');
    ok( !$result->{success}, 'enroll rejects duplicate ID' );
    like( $result->{message}, qr/previously used/i, 'message mentions previously used' );
};

# ========== is_id_known (was checkID) ==========

subtest 'is_id_known - existing user' => sub {
    my $result = $auth->is_id_known('alice');
    ok( $result->{success}, 'is_id_known succeeds' );
    ok( $result->{known}, 'is_id_known finds existing user' );
};

subtest 'is_id_known - missing user' => sub {
    my $result = $auth->is_id_known('nonexistent');
    ok( $result->{success}, 'is_id_known still succeeds (no I/O error)' );
    ok( !$result->{known}, 'is_id_known reports missing user as not known' );
};

# ========== authenticate (was checkPwd) ==========

subtest 'authenticate - correct password' => sub {
    my $result = $auth->authenticate('alice', 'password123');
    ok( $result->{success}, 'authenticate succeeds with correct password' );
};

subtest 'authenticate - wrong password' => sub {
    my $result = $auth->authenticate('alice', 'wrongpassword');
    ok( !$result->{success}, 'authenticate rejects wrong password' );
    like( $result->{message}, qr/Invalid password/i, 'message mentions invalid password' );
};

subtest 'authenticate - missing user' => sub {
    my $result = $auth->authenticate('nonexistent', 'password123');
    ok( !$result->{success}, 'authenticate rejects missing user' );
    like( $result->{message}, qr/not found/i, 'message mentions not found' );
};

# ========== change_credentials (was resetPwd) ==========

subtest 'change_credentials - change password' => sub {
    my $result = $auth->change_credentials('alice', 'newpassword456');
    ok( $result->{success}, 'change_credentials succeeds' );
    is( $result->{user_id}, 'alice', 'result carries the user ID' );

    # Old password should fail
    my $old = $auth->authenticate('alice', 'password123');
    ok( !$old->{success}, 'old password fails after change' );

    # New password should succeed
    my $new = $auth->authenticate('alice', 'newpassword456');
    ok( $new->{success}, 'new password succeeds after change' );
};

subtest 'change_credentials - missing user' => sub {
    my $result = $auth->change_credentials('nonexistent', 'password123');
    ok( !$result->{success}, 'change_credentials rejects missing user' );
    like( $result->{message}, qr/not found/i, 'message mentions not found' );
};

# ========== revoke (was deleteID) ==========

subtest 'revoke - remove user' => sub {
    # First confirm user exists
    my $exists = $auth->is_id_known('alice');
    ok( $exists->{known}, 'user exists before revoke' );

    my $result = $auth->revoke('alice');
    ok( $result->{success}, 'revoke succeeds' );
    is( $result->{user_id}, 'alice', 'result carries the user ID' );

    # Confirm user is gone
    my $gone = $auth->is_id_known('alice');
    ok( !$gone->{known}, 'user is gone after revoke' );
};

subtest 'revoke - missing user' => sub {
    my $result = $auth->revoke('nonexistent');
    ok( !$result->{success}, 'revoke rejects missing user' );
    like( $result->{message}, qr/not found/i, 'message mentions not found' );
};

# ========== Validation failures passed through ==========

subtest 'validation failures - bad ID' => sub {
    my $result = $auth->enroll('', 'password123');
    ok( !$result->{success}, 'enroll rejects empty ID' );

    $result = $auth->is_id_known('x');
    ok( !$result->{known}, 'is_id_known reports too-short ID as not known' );

    $result = $auth->authenticate('', 'password123');
    ok( !$result->{success}, 'authenticate rejects empty ID' );

    $result = $auth->change_credentials('', 'password123');
    ok( !$result->{success}, 'change_credentials rejects empty ID' );

    $result = $auth->revoke('');
    ok( !$result->{success}, 'revoke rejects empty ID' );
};

subtest 'validation failures - bad password' => sub {
    my $result = $auth->enroll('bob', 'short');
    ok( !$result->{success}, 'enroll rejects short password' );

    $result = $auth->authenticate('bob', 'short');
    ok( !$result->{success}, 'authenticate rejects short password (no match found)' );

    $result = $auth->change_credentials('bob', 'short');
    ok( !$result->{success}, 'change_credentials rejects short password' );
};

subtest 'validation failures - undef/empty password arg' => sub {
    my $result = $auth->enroll('someuser', '');
    ok( !$result->{success}, 'enroll rejects empty string password' );
    like( $result->{message}, qr/empty/i, 'message mentions empty' );

    $result = $auth->change_credentials('someuser', '');
    ok( !$result->{success}, 'change_credentials rejects empty string password' );
    like( $result->{message}, qr/empty/i, 'message mentions empty' );
};

# ========== confirm/reject/reply response helpers ==========
# These backend-specific helpers remain on Concierge::Auth::Pwd (they
# back its file-management and generator wrapper methods, which retain
# the old dual-return convention). Tested here to cover their
# default-message branches.

subtest 'confirm - default message' => sub {
    my ($ok, $msg) = Concierge::Auth::Pwd::confirm();
    ok( $ok, 'confirm() with no arg returns true' );
    like( $msg, qr/confirmation/i, 'default confirmation message used' );
};

subtest 'reject - default message' => sub {
    my ($ok, $msg) = Concierge::Auth::Pwd::reject();
    ok( !$ok, 'reject() with no arg returns false' );
    like( $msg, qr/rejection/i, 'default rejection message used' );
};

subtest 'reply - single-arg forms' => sub {
    # With no message arg, the ternary picks the default based on $bool
    my ($r1, $m1) = Concierge::Auth::Pwd::reply(1);
    ok( $r1, 'reply(1) returns true' );
    like( $m1, qr/confirmation/i, 'truthy bool gives confirmation default' );

    my ($r0, $m0) = Concierge::Auth::Pwd::reply(0);
    ok( !$r0, 'reply(0) returns false' );
    like( $m0, qr/rejection/i, 'falsy bool gives rejection default' );

    # No args at all — $bool defaults to 0 via //
    my ($rn, $mn) = Concierge::Auth::Pwd::reply();
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

subtest 'is_id_known - no file configured' => sub {
    my $nf;
    my $w = warnings { $nf = Concierge::Auth->new( backend_class => 'Concierge::Auth::Pwd', no_file => 1 ) };
    like( $w->[0], qr/Utilities only/i, 'constructor warns when no_file' );
    my $result = $nf->is_id_known('alice');
    ok( $result->{success}, 'is_id_known still succeeds when no file is set' );
    ok( !$result->{known}, 'ID reported not known when no file is set' );
};

subtest 'authenticate - no file configured' => sub {
    my $nf;
    my $w = warnings { $nf = Concierge::Auth->new( backend_class => 'Concierge::Auth::Pwd', no_file => 1 ) };
    like( $w->[0], qr/Utilities only/i, 'constructor warns when no_file' );
    my $result;
    my $pw = warnings { $result = $nf->authenticate('alice', 'password123') };
    ok( !$result->{success}, 'authenticate fails when no file is set' );
};

subtest 'revoke - no file configured' => sub {
    my $nf;
    my $w = warnings { $nf = Concierge::Auth->new( backend_class => 'Concierge::Auth::Pwd', no_file => 1 ) };
    like( $w->[0], qr/Utilities only/i, 'constructor warns when no_file' );
    my $result = $nf->revoke('alice');
    ok( !$result->{success}, 'revoke fails when no file is set' );
};

subtest 'change_credentials - no file configured' => sub {
    my $nf;
    my $w = warnings { $nf = Concierge::Auth->new( backend_class => 'Concierge::Auth::Pwd', no_file => 1 ) };
    like( $w->[0], qr/Utilities only/i, 'constructor warns when no_file' );
    my $result = $nf->change_credentials('alice', 'password123');
    ok( !$result->{success}, 'change_credentials fails when no file is set' );
    like( $result->{message}, qr/Not OK/i, 'message reflects file validation failure' );
};

done_testing;
