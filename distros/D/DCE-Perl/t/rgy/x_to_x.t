use ExtUtils::testlib;
use DCE::Registry ();
use DCE::test;

print "1..7\n";
trace "\n";

($rgy, $status) = DCE::Registry->site_bind;
test ++$i, $status;

$domain = $rgy->domain_person();

$unix_num = 0; #root

($uuid, $status) = $rgy->pgo_unix_num_to_id($domain, $unix_num);
trace "$unix_num -> $uuid\n";
test ++$i, $status;

($name, $status) = $rgy->pgo_unix_num_to_name($domain, $unix_num);
trace "$unix_num -> $name\n";
test ++$i, $status;

($name, $status) = $rgy->pgo_id_to_name($domain, $uuid);
trace "$uuid -> $name\n";
test ++$i, $status;

($unix_num, $status) = $rgy->pgo_id_to_unix_num($domain, $uuid);
trace "$uuid -> $unix_num\n";
test ++$i, $status;


($unix_num, $status) = $rgy->pgo_name_to_unix_num($domain, $name);
trace "$name -> $unix_num\n";
test ++$i, $status;

($uuid, $status) = $rgy->pgo_name_to_id($domain, $name);
trace "$name -> $uuid\n";
test ++$i, $status;




