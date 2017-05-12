use ExtUtils::testlib;
use DCE::Registry ();
use DCE::test;


$pgo_get_next = 4; 
$get_members = 1;

print "1..11\n";
#print dump_inc;
($rgy, $status) = DCE::Registry->site_bind;
test ++$i, $status;

$domain = $rgy->domain_person();
$scope = "";
$test = {
    get_next => 1,
    get_by_name => 1,
    get_by_id => 0,
    get_by_unix_num => 0,
    get_members => 1,
};

{
    #cursors will be destroyed once we leave this block
    #freeing the malloc'd sec_rgy_cursor_t's
    my($next_cursor,$name_cursor) = map {$rgy->cursor} 1,2;

    while($pgo_get_next--) {
	#last;
	$pgo_item = $pgo_name = "";
	($pgo_item, $pgo_name, $status) = 
	    $rgy->pgo_get_next($domain,$scope,$next_cursor);

	#last if $status == $rgy->no_more_entries();

	test ++$i, $status;
	($pgo_item, $status) = 
	    $rgy->pgo_get_by_name($domain,$pgo_name,$name_cursor);

	last unless $test->{get_by_name};
	test ++$i, $status;
	trace "by_name($pgo_name) -> \n";
	dump_hash $pgo_item;
    }

}

$uuid = $pgo_item->{id}; 
$unix_num = $pgo_item->{unix_num};

if($test->{get_by_id}){
    my $pgo_item = {};         
    my $pgo_name = "";
    my $cursor = $rgy->cursor;

    ($pgo_item, $pgo_name, $status) = 
	$rgy->pgo_get_by_id($domain, $scope, $uuid, $allow_alias, $cursor);

    test ++$i, $status;
    trace "by_id($uuid) -> $pgo_name\n";
    dump_hash $pgo_item;
}

if($test->{get_by_unix_num}){
    my $pgo_item = {};         
    my $pgo_name = "";
    my $cursor = $rgy->cursor;

    ($pgo_item, $pgo_name, $status) = 
	$rgy->pgo_get_by_unix_num($domain, $scope, $unix_num, 
				  $allow_alias, $cursor);
    test ++$i, $status;
    trace "by_unix_num($unix_num) -> $pgo_name\n";
    dump_hash $pgo_item;
}

if($test->{get_members}){
    my $max_members = 5;  
    my $status = 0;
    my $domain = $rgy->domain_group;
    my $name = "";
    my $cursor = $rgy->cursor;
    ($pgo_item, $name, $status) = 
	    $rgy->pgo_get_next($domain,$scope,$cursor);

    test ++$i, $status;
    $cursor->reset;

    my $total = 0;
    my($list,$number_supplied,$number_members);

    while($get_members--) { 
	($list,$number_supplied,$number_members,$status) =
	    $rgy->pgo_get_members($domain,$name,$cursor,$max_members);
	$total += $number_supplied;

	test ++$i, $status;
	last if $status == $rgy->no_more_entries();
	last if $number_members == 0;
	trace " [$number_supplied,$number_members,$total]list: @$list\n";
	last if $total >= $number_members;
    }
}

