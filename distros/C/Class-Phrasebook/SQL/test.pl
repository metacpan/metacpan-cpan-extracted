# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..17\n"; }
END {print "not ok 1\n" unless $loaded;}
use Class::Phrasebook::SQL;
use Log::LogLite;
$loaded = 1;
print "ok 1\n";

my $log = new Log::LogLite("test.log");
my $sql = new Class::Phrasebook::SQL($log, "test.xml");
###$sql->debug_prints(1);
print_ok($sql->load("Pg"), 2, "load");

my $statement;

$statement = $sql->get("GET_SEQUENCE", { name => "cookie" } );
print_ok(clean_whites($statement) eq 
	 clean_whites(q(select val from t_seq where name = 'cookie')), 3, 
	 "select with one placeholder");

$statement = $sql->get("INCREMENT_SEQUENCE", { name => "cookie" } ); 
print_ok(clean_whites($statement) eq 
	 clean_whites(q(update t_seq set val = val + 1 where name = 'cookie')),
	 4, "simple update with one column to update and one placeholder");

$statement = $sql->get("GET_LEVEL_OF_CONFIG", { id => 88 } );
print_ok(clean_whites($statement) eq 
	 clean_whites(q(select level from t_config where id = 88)), 5,
	 "select with one place holder");

$statement = $sql->get("INSERT_INTO_CONFIG_ROW", 
		       { id => 88,
			 parent => 77,
			 level => 5 });
print_ok(clean_whites($statement) eq 
	 clean_whites(q(insert into t_config (id, parent_id, level)
			values(88, 77, 5))), 6, 
	 "insert with three placeholders");

$statement = $sql->get("INSERT_INTO_CONFIG_PARENTS_PARENTS_OF_ID_FOR_NEW_ID", 
		       { new_id => 89,
			 id => 88});
print_ok(clean_whites($statement) eq 
	 clean_whites(q(insert into t_config_parents (config_id, parent_id)
			select 89, t_config_parents.parent_id
			from t_config_parents 
			where (t_config_parents.config_id = 88))), 7,
	 "insert with two placeholders");

$statement = $sql->get("ORDERED_CONFIGS_ITEMS_OF_THIS_AND_ITS_PARENTS", 
		       { id => 88 });
print_ok(clean_whites($statement) eq 
    clean_whites(q(select t_config.id, t_config.level, t_config_item.name, 
		   t_config_item.value, t_config_item.overwritable
		   from t_config, t_config_item, t_config_config_item 
		   where 
		   t_config_item.id = t_config_config_item.config_item_id and 
		   t_config_config_item.config_id = t_config.id and 
		   (t_config.id = 88 or 
		    t_config.id = 
                    (select t_config_parents.parent_id 
		     from t_config_parents 
		     where (t_config_parents.config_id = 88)))
		   order by t_config.level)), 8, 
	 "complex select with one placeholder");

$statement = $sql->get("UPDATE_LAST_EDITED_DATE", 
		       { id => 88});
print_ok(clean_whites($statement) eq 
	 clean_whites(q(update t_dates set edited = 'NOW' 
			where id = 88)), 9, "simple update");

$statement = $sql->get("UPDATE_ACCOUNT_WITH_SPECIFIC_ID", 
		       { login => "MyLogin",
			 description => "MyDescription",
			 dates_id => 55,
			 groups => 4,
			 owners => 3,
			 id => 88 });
print_ok(clean_whites($statement) eq 
	 clean_whites(q(update t_account set
			login = 'MyLogin',
			description = 'MyDescription', 
			dates_id = 55, 
			groups = 4,
			owners = 3
			where id = 88)), 10, 
	 "complex update with 6 placeholders");
$statement = $sql->get("UPDATE_ACCOUNT_WITH_SPECIFIC_ID", 
		       { login => "MyLogin",
			 description => "MyDescription",
			 id => 88 });
print_ok(clean_whites($statement) eq 
	 clean_whites(q(update t_account set
			login = 'MyLogin',
			description = 'MyDescription' 
			where id = 88)), 11, 
	 "the same complex update with only 3 placeholders set");

$statement = $sql->get("UPDATE_ACCOUNT_WITH_SPECIFIC_ID", 
		       { description => "MyDescription",
			 id => 88 });
print_ok(clean_whites($statement) eq 
	 clean_whites(q(update t_account set
			description = 'MyDescription' 
			where id = 88)), 12, 
	 "the same complex update with only 2 placeholders set");

# test the update with the where clouse separation. 
$statement = $sql->get("UPDATE_ACCOUNT_WITH_SPECIFIC_ID_AND_LOGIN", 
		       { description => "MyDescription
with several new 
lines!!!
here we will put a line that start with
where",
			 dates_id => 55,
			 id => 88 });

print_ok(clean_whites($statement) eq 
	 clean_whites(q(            update t_account set
				    description = 'MyDescription
with several new 
lines!!!
here we will put a line that start with
where', 
				    dates_id = 55
				    where id = 88 and
				    login = '')), 13, 
	 "complex update with several lines in one placeholder");

$statement = $sql->get("DELETE_USER", { account_id => 40});
print_ok(clean_whites($statement) eq 
         clean_whites(q(delete from t_user
                        where account_id = 40)), 14, "simple delete");

$statement = $sql->get("UPDATE_NO_WHERE");
print_ok(clean_whites($statement) eq 
	 clean_whites(q(update table set i=1)), 15, "short update");


$statement = $sql->get("GET_SEQUENCE", { name => '$cookie' } );
print_ok(clean_whites($statement) eq 
	 clean_whites(q(select val from t_seq where name = '')), 16, 
	 "placeholder contains \$ and place_holders_conatain_dollars(0)");


$sql->place_holders_conatain_dollars(1);
$statement = $sql->get("GET_SEQUENCE", { name => '$cookie' } );
print_ok(clean_whites($statement) eq 
	 clean_whites(q(select val from t_seq where name = '$cookie')), 17, 
	 "placeholder contains \$ and place_holders_conatain_dollars(1)");






#######################
# clean_whites
#######################
sub clean_whites {
    my $str = shift;
    $str =~ s/\s+/ /goi;
    $str =~ s/^\s//;
    $str =~ s/\s$//;
    return $str;
} # of clean_whites

#############################################
# print_ok ($expression, $number, $comment)
#############################################
sub print_ok {
    my $expression = shift;
    my $number =shift;
    my $string = shift || "";

    $string = "ok " . $number . " " . $string . "\n";
    if (! $expression) {
        $string = "not " . $string;
    }
    print $string;
} # print_ok



