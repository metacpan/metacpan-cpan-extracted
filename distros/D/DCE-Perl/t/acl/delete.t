use ExtUtils::testlib;
use DCE::test;
use DCE::ACL ();

$object = "/.:/subsys/dce/";

print "1..4\n";

($aclh, $status) = DCE::ACL->bind($object);
test ++$i, $status;
 
$mgr = $aclh->get_manager_types->[0];

($list, $status) = $aclh->lookup($mgr); #$list is a sec_acl_list_t *
test ++$i, $status;

$acl = $list->acls; #$acl is a sec_acl_t *

$status = $acl->delete; #delete all entries except 'user_obj' if it exists
test ++$i, $status;

$e = $acl->new_entry; #$e is a sec_acl_entry_t *

$e->entry_info({
    entry_type => $aclh->type_user,
    id => {
	name => "",
	uuid => "",
    },
});

$bits = 0;
for (qw(perm_read perm_write perm_control perm_insert)) {
    $bits |= $aclh->$_();
}

$e->perms($bits);

$status = $acl->add($e);
test ++$i, $status;

#$status = $aclh->replace($mgr, $aclh->type_object, $list);
#test ++$i, $status;
