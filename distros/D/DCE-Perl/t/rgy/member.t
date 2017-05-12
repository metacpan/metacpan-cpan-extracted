use ExtUtils::testlib;
use DCE::test;
use DCE::Registry;
use DCE::Status 'error_string';

my($rgy, $status) = DCE::Registry->site_open_update;

if($status != DCE::Registry->status_ok) {
    warn sprintf "Skipping tests: %s\n", error_string($status);
    print "1..1\n";
    print "ok 1\n";
    exit(0);
}
print "1..5\n";

$domain = $rgy->domain_group;
$name = "dce_perl";
$person = "cell_admin";

#($is_mem,$status) = $rgy->pgo_is_member($domain, $name, $person);
#test ++$i, (not $is_mem);
#trace "is_mem $is_mem\n";

$pgo_item = {
   uuid => "",
   unix_num => -1,
   quota => -1,
   flags => 0,
   fullname => "DCE Perl",
};

$status = $rgy->pgo_add($domain, $name, $pgo_item);
test ++$i, $status;

$status = $rgy->pgo_add_member($domain, $name, $person);
test ++$i, $status;

($is_mem,$status) = $rgy->pgo_is_member($domain, $name, $person);
test ++$i, $status;
trace "is_mem $is_mem\n";

$status = $rgy->pgo_delete_member($domain, $name, $person);
test ++$i, $status;


$rgy->pgo_delete($domain, $name);

test ++$i, $status;
