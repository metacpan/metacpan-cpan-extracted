#!/usr/bin/env perl

use v5.36;

use strict;
use warnings;
use Test2::V0;
use File::Temp qw/tempfile tempdir/;

use Concierge::Auth;

my $dir  = tempdir( CLEANUP => 1 );
my $file = "$dir/auth.pwd";
my $auth = Concierge::Auth->new( backend => 'Concierge::Auth::Pwd', file => $file );

# ========== validatePwd ==========
# This is the one format-check kept as a shared method on
# Concierge::Auth::Pwd (both enroll and change_credentials need it).
# It now uses the { success, message } hashref convention.

subtest 'validatePwd - valid passwords' => sub {
    for my $pwd ( 'password', 'x' x 8, 'x' x 72, 'P@ssw0rd!123' ) {
        my $result = $auth->validatePwd($pwd);
        ok( $result->{success}, "valid password (length " . length($pwd) . ")" );
    }
};

subtest 'validatePwd - empty' => sub {
    my $result = $auth->validatePwd('');
    ok( !$result->{success}, 'empty password rejected' );
    like( $result->{message}, qr/empty/i, 'message mentions empty' );

    $result = $auth->validatePwd(undef);
    ok( !$result->{success}, 'undef password rejected' );
};

subtest 'validatePwd - too short' => sub {
    my $result = $auth->validatePwd('short');
    ok( !$result->{success}, '5-char password rejected' );
    like( $result->{message}, qr/between/i, 'message mentions length requirement' );
};

subtest 'validatePwd - too long' => sub {
    my $result = $auth->validatePwd('x' x 73);
    ok( !$result->{success}, '73-char password rejected' );
    like( $result->{message}, qr/between/i, 'message mentions length requirement' );
};

# ========== ID format policy ==========
# The old validateID method no longer exists as a standalone method --
# ID format policy (length, character set) is only enforced inside
# enroll(), since that's the only contract method establishing a *new*
# ID. Exercise it there instead.

subtest 'enroll - empty ID rejected' => sub {
    my $result = $auth->enroll('', 'password123');
    ok( !$result->{success}, 'empty ID rejected' );
    like( $result->{message}, qr/empty/i, 'message mentions empty' );
};

subtest 'enroll - too-short ID rejected' => sub {
    my $result = $auth->enroll('a', 'password123');
    ok( !$result->{success}, 'single-char ID rejected' );
    like( $result->{message}, qr/between/i, 'message mentions length requirement' );
};

subtest 'enroll - too-long ID rejected' => sub {
    my $result = $auth->enroll('x' x 33, 'password123');
    ok( !$result->{success}, '33-char ID rejected' );
    like( $result->{message}, qr/between/i, 'message mentions length requirement' );
};

subtest 'enroll - invalid chars rejected' => sub {
    for my $id ( 'user name', 'user!name', 'user#name', 'user$name' ) {
        my $result = $auth->enroll($id, 'password123');
        ok( !$result->{success}, "invalid ID: '$id'" );
        like( $result->{message}, qr/invalid/i, 'message mentions invalid characters' );
    }
};

subtest 'enroll - valid ID formats accepted' => sub {
    for my $id ( 'ab', 'alice-fmt', 'user_name-fmt', 'user.name-fmt',
                 'user@host-fmt.com', 'A1-fmt', 'z' x 32 ) {
        my $result = $auth->enroll($id, 'password123');
        ok( $result->{success}, "valid ID accepted: '$id'" );
    }
};

# ========== File-related error conditions ==========
# The old validateFile method no longer exists as a standalone method
# either -- file readiness is now checked inline by each contract
# method that needs it (is_id_known, authenticate, change_credentials,
# revoke). Exercise a couple of them with no file configured.

subtest 'is_id_known - no file configured is simply "not known"' => sub {
    my $nofile_auth;
    my $w = warnings {
        $nofile_auth = Concierge::Auth->new( backend => 'Concierge::Auth::Pwd', no_file => 1 );
    };
    my $result = $nofile_auth->is_id_known('alice');
    ok( $result->{success}, 'is_id_known still succeeds (no I/O error)' );
    ok( !$result->{known}, 'ID reported as not known when no file is configured' );
};

subtest 'change_credentials - no file configured fails' => sub {
    my $nofile_auth;
    my $w = warnings {
        $nofile_auth = Concierge::Auth->new( backend => 'Concierge::Auth::Pwd', no_file => 1 );
    };
    my $result = $nofile_auth->change_credentials('alice', 'password123');
    ok( !$result->{success}, 'change_credentials fails when no file is set' );
    like( $result->{message}, qr/not OK/i, 'message indicates file not OK' );
};

done_testing;
