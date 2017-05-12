###############################################################################
# Authen::Krb5::Simple Test Script
#
# File: 02-ops.t
#
# Purpose: Make sure we can create and use an Authen::Krb5::Simple object.
#
###############################################################################
#
use strict;
use Test::More tests => 16;
use Authen::Krb5::Simple;

# Get test user params (if any)
#
my $tdata = get_test_data();

my $krb = Authen::Krb5::Simple->new();

# (1) Valid object.
#
isa_ok($krb, 'Authen::Krb5::Simple', 'Valid object check');

my $errcode;
my $errstr;
my $ret;

# (2-7) Good pw
#
my $no_user_data = (!defined($tdata->{user}) and !defined($tdata->{password}));

SKIP: {
    skip "No user/password data provided", 6 if($no_user_data);

    my $tuser = $tdata->{user};
    my $tpass = $tdata->{password};

    $tuser .= "\@$tdata->{realm}" if(defined($tdata->{realm}));

    $ret = $krb->authenticate($tuser, $tpass) unless($no_user_data);

    $errcode = $krb->errcode();
    $errstr  = $krb->errstr();

    ok($ret, 'Good username and password authentication');

    # Valid error conditions
    #
    ok($errcode == 0, "Error code 0 check: Got '$errcode'");
    ok($errstr eq '', "Error string empty check: Got '$errstr'");

    # Now munge the pw and make sure we get the expected responses
    #
    $ret = $krb->authenticate($tuser, "x$tpass") unless($no_user_data);

    $errcode = $krb->errcode();
    $errstr  = $krb->errstr();

    ok(!$ret, "Return value 'true' check: Got '$ret'");

    ok($errcode != 0, "Non-zero error code check: Got '$errcode'");
    ok($errstr ne '', "Non-empty error string check: Got '$errstr'");
}

# (8-13) Null and Empty password
#
$ret = $krb->authenticate('_not_a_user_');
ok($ret==0, "Null password returns 0 check: Got '$ret'");

$errcode = $krb->errcode();
$errstr  = $krb->errstr();

ok($errcode eq 'e1', "Null password error code of 'e1' check: Got '$errcode'");
ok($errstr =~ /Null or empty password not supported/,
   "Null password error string check: Got '$errstr'");

$ret = $krb->authenticate('_not_a_user_', '');
ok($ret==0, "Empty password should return 0: Got '$ret'");

$errcode = $krb->errcode();
$errstr  = $krb->errstr();

ok($errcode eq 'e1', "Empty password error code of 'e1' check: Got '$errcode'");
ok($errstr =~ /Null or empty password not supported/,
   "Null password error string check: Got '$errstr'");

# (14) Bad user and pw
#
$ret = $krb->authenticate('_xxx', '_xxx');
ok($ret == 0, "Bad user and PW Check returns '0': Got '$ret'");

$errcode = $krb->errcode();
$errstr  = $krb->errstr();

# (15-16) Valid error conditions
#
ok($errcode != 0, "Bad user and PW check non-zero error code: Got '$errcode'");
ok($errstr, "Bad user and PW error string check");

### End of Tests ###

sub get_test_data {
    my %tdata;

    unless(open(CONF, "< CONFIG")) {
        diag("** Unable to read CONFIG file: $!");
        diag("** Skipping user auth tests");
        return undef;
    }

    while(<CONF>) {
        chomp;
        next if(/^\s*#|^\s*$/);

        $tdata{user} = $1 if(/^\s*TEST_USER\s+(.*)/);
        $tdata{password} = $1 if(/^\s*TEST_PASS\s+(.*)/);
        $tdata{realm} = $1 if(/^\s*TEST_REALM\s+(.*)/);
    }
    close(CONF);

    return(\%tdata);  
}

###EOF###
