use ExtUtils::testlib;
use DCE::test;
use DCE::Registry ();

print "1..3\n";
my($rgy, $status) = DCE::Registry->site_bind;
test ++$i, $status;

my $cursor = $rgy->cursor;

my $name = "cell_admin";
my $login_name = { 
    pname => $name,
    gname => "",
    oname => "",
};
my($id_sid, $unix_sid, $user_part, $admin_part);

($id_sid, $unix_sid, $user_part, $admin_part, $status) = 
    $rgy->acct_lookup($login_name, $cursor);

test ++$i, $status;
for ($id_sid, $unix_sid, $user_part, $admin_part, $login_name) {
    #dump_hash $_;
}

$uuid = $admin_part->{last_changer}->{principal};
$cursor->reset;
#$scope = $allow_alias = undef;
$domain = 0;
#($pgo_item, $pgo_name, $status) = 
#    $rgy->pgo_get_by_id($domain, $scope, $uuid, $allow_alias, $cursor);
#dump_hash $pgo_item;
#trace "$pgo_name $pgo_item->{unix_num}\n";
($name, $status) = $rgy->pgo_id_to_name($domain, $uuid);
test ++$i, $status;


