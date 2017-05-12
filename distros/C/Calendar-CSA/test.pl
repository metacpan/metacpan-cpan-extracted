
#    This file is public domain and is not placed under any copyright


# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use Calendar::CSA;

$user = scalar getpwuid($>);
$host = "localhost";

print "Attempting to open database $user\@$host...\n";

$caladdr = "$user\@$host";

($user, $host) = split(/@/, $caladdr);

print "Logging on...\n";
$session = Calendar::CSA::logon("",
	{	user_name => $caladdr,
		user_type => 'INDIVIDUAL',
		calendar_address => $caladdr
	} );

# Turn long standard names into short non-standard names
$session->short_entry_names(1);

# Turn ISO times into UNIX times
$session->unix_times(1);

print "VER SPEC: ",$session->query_configuration("VER SPEC"),"\n";
print "UI AVAIL: ",$session->query_configuration("UI AVAIL"),"\n";

eval
{
    print "Calendars: ", join(", ", Calendar::CSA::list_calendars($host)),"\n";
};
print ($@) if ($@);

print "Calendar attributes: ",join(", ", $session->list_calendar_attributes),"\n";

print "Number of entries: ", $session->read_calendar_attributes("Number Entries")->{value},"\n";

$entrylist = $session->list_entries(
	'Start Date' => {
    	type => 'DATE TIME',
       value => '19940101T010654Z',
        match => 'GREATER THAN'
    },
	'Start Date' => {
    	type => 'DATE TIME',
        value => '19991230T010654Z',
        match => 'LESS THAN'
    },
);

print "Records starting between January 1st, 1994 and and December 30th, 1990: ",scalar(@entries),"\n";
foreach ($entrylist->entries) {
	print "\tSummary of entry starting on ", scalar(localtime($_->read_entry_attributes('Start Date')->{value}));
	print ": \"", $_->read_entry_attributes('Summary')->{value},"\"\n";
}

print "Logging off.\n";

$session->logoff();

print "The test is done.\n";

__END__;

# This is the original test code

use Data::Dumper;

print "Log on...\n";
$session = Calendar::CSA::logon("",
	{	user_name => $caladdr,
		user_type => 'INDIVIDUAL',
		calendar_address => $caladdr
	} );

$session->short_entry_names(1);
$session->unix_times(1);
#Calendar::CSA::generate_numeric_enumerations(1);	# 0 is default
#Calendar::CSA::accept_numeric_enumerations(1);	# 0 is default

#$user = $session->look_up({name => $user});
#print Dumper($user);

print "SUBTYPE_APPOINTMENT = '", Calendar::CSA::SUBTYPE_APPOINTMENT, "'\n";;

print Dumper([$session->query_configuration("VER SPEC")]);
print Dumper([$session->query_configuration("UI AVAIL")]);

eval
{
    print Dumper([Calendar::CSA::list_calendars($host)]);
};
print ($@) if ($@);

print Dumper([$session->list_calendar_attributes]);

print Dumper({$session->read_calendar_attributes});

eval
{
#	Segfaults on my machine, in addition to being unimplemented!
#	print Dumper([$session->free_time_search("19970816T040205Z/19970816T040225Z","+PT300S",{user_name=>$user})]);
};
print ($@) if ($@);

# Never been able to trigger a callback.
#$session->register_callback("ENTRY ADDED", sub { print "Callback: @_\n" }, "foo", 1);
#
#$session->call_callbacks("ENTRY ADDED");

@entries = $session->list_entries(
	'-//XAPIA/CSA/ENTRYATTR//NONSGML Date Created//EN' => {
    	type => 'DATE TIME',
        value => '19970612T010654Z',
        match => 'GREATER THAN'
    },
);

if (@entries)
{
    print Dumper([@entries]);
    
    print "dumping\n";
    foreach (@entries) {
	    print Dumper({$_->read_entry_attributes()});
	}
    print "dumping2\n";
}

print "Testing match\n";
@entries = $session->list_entries(
        'Start Date' => {
	    type => 'DATE TIME',
	    value => '19970801T000000Z',
	    match => 'GREATER THAN OR EQUAL TO'
	    },
        'End Date' => {
	    type => 'DATE TIME',
	    value => '19970901T000000Z',
	    match => 'LESS THAN'
	    },
);

if (@entries)
{
    print Dumper([@entries]);

    foreach (@entries) {
	    print Dumper({$_->read_entry_attributes()});
	}
}
print "Done matching\n";

#$entry = $session->add_entry( $entries[0]->read_entry_attributes());

#print Dumper($entry);
#print Dumper($entry->read_entry_attributes());

$next = $session->read_next_reminder("19960812T010654Z");

print Dumper($next);

$session->logoff();

__END__;

print "Retrieve...";
$ret = Calendar::CSA::lookup($session, 870478200, 881478200);
if ($ret == Calendar::CSA::CSA_SUCCESS)
{
    print "ok\n";
}
else
{
    print "not ok [error $ret]\n";
}

print "Log off...";
$ret = Calendar::CSA::logoff($session);
if ($ret == Calendar::CSA::CSA_SUCCESS)
{
    print "ok\n";
}
else
{
    print "not ok [error $ret]\n";
}
