BEGIN {
foreach (qw(..  .  ../..)) {
    last if -e ($conf = "$_/config");
}
eval { require "$conf"; };
die $@ if $@;
}
use ExtUtils::testlib;
use DCE::Status ();
use DCE::ACL ();
use DCE::Registry ();

use Data::Dumper;
$Data::Dumper::Indent = 1;

tie $status => DCE::Status;

$entry = shift || "/.:/subsys/WWW/tooldev/cgi-bin/dce-perl/acls/test1";

($aclh, $status) = DCE::ACL->bind($entry);

test ++$i, $status;
die "$status" if $status != 0;

$mgr = $aclh->get_manager_types->[0];
print "mgr: $mgr\n";

($permset, $status) = $aclh->get_access($mgr);
test ++$i, $status;

$printstrings = $aclh->get_printstring($mgr); 
test ++$i, $status;

($list, $status) = $aclh->lookup($mgr);
#$acl = $list->acls;
($acl, $status) = DCE::ACL->init($mgr);
test ++$i, $status;

$status = $acl->add_any_other_entry(DCE::ACL->perm_read | DCE::ACL->perm_write);
test ++$i, $status;
__END__
$name = $acl->default_realm->{name};
print "$name\n";

($rgy,$status) = DCE::Registry->site_bind;

for $e ($acl->entries) {
    #print Data::Dumper->Dump([$e->entry_info]);
    $type = $e->entry_info->{entry_type};
    $typestr = $aclh->type($type);
    $permstr = "";
    foreach $str (@$printstrings) {
	$permstr .= 
	($str->{permissions} & $e->perms) ?  
	    $str->{printstring} : "-";
    }
    ($nm, $status) = 
	$rgy->pgo_id_to_name($rgy->domain($typestr), 
			     $e->entry_info->{id}{uuid});
    if($nm eq "dougm") {
	for (qw(perm_read perm_control perm_insert)) {
	    $bits |= $aclh->$_();
	}
	$e->perms($bits);
	$to_remove = $e;
    }

    @print = ();
    push @print, $typestr;
    push @print, $nm if $nm;
    push @print, $permstr;
    print join ":", @print;
    print "\n";
}

#__END__
#print "printstrings: \n", Data::Dumper->Dump($printstrings);

$perms = $aclh->perm_control;

($ok, $status) = $aclh->test_access($mgr, $perms);
print $ok ? "access granted\n" : "access denied $smgr\n";

($uuid,$status) = $rgy->pgo_name_to_id($rgy->p, "dougm");
test ++$i, $status;

my $pac = {
    authenticated => 1,
    realm => {
	uuid => $acl->default_realm->{uuid},
    },
    principal => {
	uuid => $uuid,
    },
    group => {
    },
};

#$perms = $aclh->perm_read;    
#($ok, $status) = $aclh->test_access_on_behalf($mgr, $pac, $perms);
#print $ok ? "access granted\n" : "access denied\n";
#test ++$i, $status;

#add_test($acl, "dougm");

#$status = $acl->remove($to_remove);
#test ++$i, $status;

#$status = $aclh->replace($mgr, $aclh->type_object, $list);
#test ++$i, $status;

sub add_test {
    my($acl, $name) = @_;
    $e = $acl->new_entry;

    my($uuid, $status) = $rgy->pgo_name_to_id($rgy->p, $name);
    test ++$i, $status;
    
    $e->entry_info({
	entry_type => DCE::ACL->type_user,
	id => {
	    uuid => $uuid,
	},
    });

    $e->perms(DCE::ACL->perm_read);
    $status = $acl->add($e);
    test ++$i, $status;
}

sub test_compare {
 
    ($e1, $e2) = map { $acl->entries($_) } 1,2;

    $match = $e1->compare($e2);
    print "e1 e2 -> $match\n";

    $match = $e1->compare($e1);
    print "e1 e1 -> $match\n";
}

