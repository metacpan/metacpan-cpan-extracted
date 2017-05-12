use ExtUtils::testlib;
use DCE::test;
use DCE::Registry;

print "1..3\n";

($rgy, $status) = DCE::Registry->site_bind;
$org = "";

test ++$i, $status;

($policy_data, $status) = $rgy->plcy_get_effective($org);

test ++$i, $status;
dump_hash $policy_data;

($policy_data, $status) = $rgy->plcy_get_info($org);

test ++$i, $status;
dump_hash $policy_data;

#$status = $rgy->plcy_set_info($org, $policy_data);
#test ++$i, $status;
