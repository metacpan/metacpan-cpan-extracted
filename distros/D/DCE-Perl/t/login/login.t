use ExtUtils::testlib;
use DCE::test;

use DCE::Login;

($pname, $password) = ("cell_admin", "");
$pname ||= (getpwuid($<))[0];
$password ||= $ENV{DCE_PERL_TEST_PW};

unless ($password) {
    warn "Skipping tests: no password to certify identity";
    print "1..1\nok 1\n";
    exit(0);
}

print "1..10\n";

($l, $status) = DCE::Login->setup_identity($pname);
test ++$i, $status;

#($valid, $reset_passwd, $auth_src, $status) = 
#    $l->valid_and_cert_ident($password);
#test ++$i, $status;

($valid, $reset_passwd, $auth_src, $status) = 
    $l->validate_identity($password);
test ++$i, $status;
trace "validate_identity: ($valid, $reset_passwd, $auth_src)\n";

($ok, $status) = $l->certify_identity;
test ++$i, $status;
trace "certify_identity: $ok\n";

($exp, $status) = $l->get_expiration;
test ++$i, $status;
$exp = undef;
#print "expiration: $exp\n";

#($reset_passwd, $auth_src, $status) = $l->valid_from_keytable($keyfile);
#test ++$i, $status;

($pwent, $status) = $l->get_pwent;
test ++$i, $status;
dump_hash $pwent;

$status = $l->purge_context;
test ++$i, $status;

($l, $status) = DCE::Login->get_current_context;
test ++$i, $status;

$status = $l->refresh_identity;
test ++$i, $status;

($buf,$len_used,$len_needed,$status) = $l->export_context(128);
test ++$i, $status;
trace "[$len_used,$len_needed]$buf\n";

($l, $status) = DCE::Login->import_context($len_needed, $buf);
test ++$i, $status;

__END__
