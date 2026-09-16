use 5.016;
use strict;
use warnings;
use Test::More tests => 37;
use File::Temp qw(tempdir);
use File::Path qw(make_path remove_tree);

use AmberDB;

my $tmp = tempdir( CLEANUP => 1 );
my $db_dir = "$tmp/testdb";
make_path($db_dir);

# 1. Cryptographic Password Hashing & Verification
{
    my $adb = AmberDB->new( path => { dbase_dir => $db_dir } );
    my $plain = 'MyS3cretP@ss';
    my $shadow = $adb->hash_password($plain);
    like( $shadow, qr/^sha256\$[0-9a-fA-F]{16}\$[0-9a-fA-F]{64}$/, "hash_password generates salted sha256 shadow format" );

    ok( $adb->verify_password( $plain, $shadow ), "verify_password matches correct password" );
    ok( !$adb->verify_password( "WrongPass", $shadow ), "verify_password rejects incorrect password" );
    ok( !$adb->verify_password( "", $shadow ), "verify_password rejects empty password when shadow is set" );

    # Passwordless behavior (backwards compatibility)
    ok( $adb->verify_password( "", "" ), "verify_password accepts empty password when shadow is empty (passwordless)" );
    ok( $adb->verify_password( "any", "" ), "verify_password accepts any password when shadow is empty" );
    ok( $adb->verify_password( "", undef ), "verify_password accepts empty password when shadow is undef" );
}

# 2. Auto-Upgrade Plain-Text Passwords to Salted Shadow in connect.pl
{
    my $conf_dir = "$db_dir/config";
    make_path($conf_dir);
    my $conn_file = "$conf_dir/connect.pl";

    my $initial_content = <<'PERL';
return {
    database => 'testdb',
    users => {
        legacy_admin => {
            password   => 'admin_plain_pass',
            role       => 'admin',
            created_at => 1234567890,
        },
        passwordless_web => {
            shadow     => '',
            role       => 'web',
            created_at => 1234567890,
        },
    },
};
PERL
    open my $fh, '>', $conn_file or die $!;
    print $fh $initial_content;
    close $fh;

    my $adb = AmberDB->new( path => { dbase_dir => $db_dir } );
    my $cfg = $adb->_load_connect_config();

    is( $cfg->{users}->{legacy_admin}->{password}, undef, "Plain-text password removed from in-memory config" );
    like( $cfg->{users}->{legacy_admin}->{shadow}, qr/^sha256\$/, "Plain-text password upgraded to shadow in memory" );

    # Check that connect.pl on disk was updated
    my $disk_cfg = do $conn_file;
    is( $disk_cfg->{users}->{legacy_admin}->{password}, undef, "Plain-text password deleted from connect.pl file on disk" );
    like( $disk_cfg->{users}->{legacy_admin}->{shadow}, qr/^sha256\$/, "Salted shadow saved to connect.pl file on disk" );

    ok( $adb->verify_password( 'admin_plain_pass', $disk_cfg->{users}->{legacy_admin}->{shadow} ), "Upgraded shadow verifies against original password" );
}

# 3. Connection Lifecycle, Authentication & Token Generation
{
    my $adb = AmberDB->new(
        path => { dbase_dir => $db_dir },
        connect => {
            database => 'testdb',
            username => 'legacy_admin',
            password => 'admin_plain_pass',
        }
    );

    is( $adb->connect('database'), 'testdb', "Connected database attribute getter" );
    is( $adb->connect('username'), 'legacy_admin', "Connected username attribute getter" );
    is( $adb->config('user'), 'legacy_admin', "config('user') aligned with connect username" );

    my $token = $adb->connect();
    like( $token, qr/^\d{4}$/, "connect() returns 4-digit session token" );
    is( $adb->connect('token'), $token, "connect('token') matches returned session token" );

    # Session file verification
    my $sess_file = $adb->session_file($token);
    ok( -f $sess_file, "Session file created in database session directory" );

    # Resuming session with another AmberDB instance
    my $adb2 = AmberDB->new( path => { dbase_dir => $db_dir } );
    my $resumed = $adb2->connect( token => $token );
    is( $resumed, $token, "Second instance resumes session via token" );
    is( $adb2->connect('username'), 'legacy_admin', "Resumed instance has authenticated user" );
    is( $adb2->connect('database'), 'testdb', "Resumed instance has correct database" );

    # Connecting with passwordless user
    my $token_web = $adb2->connect( username => 'passwordless_web', password => '' );
    like( $token_web, qr/^\d{4}$/, "Passwordless user connects without password" );

    # Connecting with invalid password fails
    eval {
        $adb2->connect( username => 'legacy_admin', password => 'wrong_pass' );
    };
    ok( $@, "Authentication fails with incorrect password" );

    # Disconnect
    ok( $adb->disconnect($token), "disconnect() successfully clears session" );
    ok( ! -f $sess_file, "Session file deleted upon disconnect" );
}

# 4. User Management API (user_add, user_passwd, user_list, user_del)
{
    my $adb = AmberDB->new( path => { dbase_dir => $db_dir } );

    # user_add
    ok( $adb->user_add( 'new_operator', 'operator123', role => 'cli' ), "user_add adds new user" );
    ok( $adb->user_verify( 'new_operator', 'operator123' ), "user_verify confirms new user credentials" );
    ok( !$adb->user_verify( 'new_operator', 'badpass' ), "user_verify rejects bad password" );

    # user_list
    my @users = $adb->user_list();
    my ($op) = grep { $_->{username} eq 'new_operator' } @users;
    ok( $op, "user_list includes new user" );
    is( $op->{role}, 'cli', "user_list provides user role" );
    is( $op->{has_password}, 1, "user_list indicates password is set" );
    ok( !exists $op->{shadow}, "user_list does not expose shadow hash" );

    # user_passwd
    ok( $adb->user_passwd( 'new_operator', 'new_pass_456' ), "user_passwd updates password" );
    ok( !$adb->user_verify( 'new_operator', 'operator123' ), "Old password no longer works" );
    ok( $adb->user_verify( 'new_operator', 'new_pass_456' ), "New password verified successfully" );

    # user_del
    ok( $adb->user_del('new_operator'), "user_del removes user" );
    my @after_del = $adb->user_list();
    my ($del_op) = grep { $_->{username} eq 'new_operator' } @after_del;
    ok( !$del_op, "User removed from user_list after user_del" );
}
