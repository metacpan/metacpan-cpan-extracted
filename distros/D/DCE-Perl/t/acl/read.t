use ExtUtils::testlib;
use DCE::test;
use DCE::Status ();
use DCE::ACL ();
use DCE::Registry ();

tie $status => DCE::Status;

$entry = shift || "/.:/subsys/dce";

print "1..5\n";
($aclh, $status) = DCE::ACL->bind($entry);

test ++$i, $status;
die "$status" if $status != 0;

$mgr = $aclh->get_manager_types->[0];
trace "mgr: $mgr\n";

($permset, $status) = $aclh->get_access($mgr);
test ++$i, $status;

$printstrings = $aclh->get_printstring($mgr); 
test ++$i, $status;

($list, $status) = $aclh->lookup($mgr);
test ++$i, $status;

$acl = $list->acls;

$name = $acl->default_realm->{name};
trace "default realm name: $name\n";

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
    my $domain = $rgy->domain($typestr);
    if (defined($domain)) {
        ($nm, $status) = 
	    $rgy->pgo_id_to_name($domain, 
				 $e->entry_info->{id}{uuid});
    }

    @print = ();
    push @print, $typestr;
    push @print, $nm if(defined $nm);
    push @print, $permstr;
    trace join ":", @print;
    trace "\n";
}

#$permset = $aclh->perm_write;

($ok, $status) = $aclh->test_access($mgr, $permset);
trace $ok ? "access granted\n" : "access denied\n";
test ++$i, $status;


