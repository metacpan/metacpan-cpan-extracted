#! /usr/bin/perl -w

use strict;

use Test::More tests=>18;
use Test::Group;
use Test::Differences;

use DBI;

# 1
BEGIN {
	use_ok('DBIx::Compare::ContentChecksum::mysql');
}

my $user_name = 'test';
my $user_pass = '';
my $dsn1 = "DBI:mysql:test:localhost";
my $dsn2 = "DBI:mysql:test2:localhost";
my ($to_test,$oDB_Content,$dbh1,$dbh2);

eval {
	require DBD::mysql;
};
if ($@){
	diag("Skipping 17 tests: Could not create the test databases because the driver 'DBD::mysql' is not installed");
} else {
	$dbh1 = DBI->connect($dsn1, $user_name, $user_pass);
	$dbh2 = DBI->connect($dsn2, $user_name, $user_pass);
	if ($dbh1 && $dbh2 && create_test_db($dbh1) && create_test_db($dbh2)){
		$to_test = 1;
	} else {
		# because Test::Harness doesn't seem to want to output my skips!
		diag("Skipping 17 tests: Could not create the test databases");
	}
}

SKIP: {
	skip("Could not create the test databases", 17) unless ($to_test);

	#2
	test 'object init' => sub {
		ok($oDB_Content = compare_mysql_checksum->new($dbh1,$dbh2),'init');
		isa_ok($oDB_Content,'db_comparison','DBIx::Compare object');
		isa_ok($oDB_Content,'compare_mysql_checksum','DBIx::Compare::ContentChecksum::mysql object');
	};

	#3
	test 'dbh stuff' => sub {
		my ($dbh1b,$dbh2b) = $oDB_Content->get_dbh;
		isa_ok($dbh1b,'DBI::db','dbh1 after set');
		isa_ok($dbh2b,'DBI::db','dbh2 after set');
		ok(my @aNames = $oDB_Content->get_db_names,'get_db_names');
		eq_or_diff \@aNames,['test:localhost','test2:localhost'],'database names';
		cmp_ok($oDB_Content->get_db_driver,'eq','mysql','get_db_driver');
	};

	#4
	test 'group_concat_max_len' => sub {
		ok(my @aLengths = $oDB_Content->mysql_group_concat_max_len,'mysql_group_concat_max_len 1');
		eq_or_diff \@aLengths,[1024,1024],'mysql_group_concat_max_len default';
		cmp_ok($oDB_Content->group_concat_max_len,'==',1024,'group_concat_max_len at init');
		$oDB_Content->group_concat_max_len(2048);
		cmp_ok($oDB_Content->group_concat_max_len,'==',2048,'group_concat_max_len after set');
		ok(@aLengths = $oDB_Content->mysql_group_concat_max_len,'mysql_group_concat_max_len 2');
		eq_or_diff \@aLengths,[2048,2048],'mysql_group_concat_max_len set';
	};

	#5
	test 'table lists' => sub {
		ok(my @aTables = $oDB_Content->get_tables,'get_tables 1 & 2');
		eq_or_diff \@aTables,[['filter','fluorochrome','laser','protocol_type'],['filter','fluorochrome','laser','protocol_type']],'table lists';
		ok(my $aTables1 = $oDB_Content->get_tables,'get_tables 1');
		eq_or_diff $aTables1,$aTables[0],'tables vs tables1';
	};

	#6
	test 'primary keys' => sub {
		ok(my $keys = $oDB_Content->get_primary_keys('filter',$dbh1),'get_primary_keys');
		cmp_ok($keys,'eq','filter_id','primary key string');
		ok(my @aKeys = $oDB_Content->get_primary_keys('filter',$dbh1),'get_primary_keys');
		eq_or_diff \@aKeys,['filter_id'],'primary key list';
	};

	#7
	test 'row counts' => sub {
		cmp_ok($oDB_Content->row_count('protocol_type',$dbh1),'==',4,'row_count');
		cmp_ok($oDB_Content->row_count('filter',$dbh1),'==',3,'row_count');
		cmp_ok($oDB_Content->row_count('laser',$dbh1),'==',3,'row_count');
		cmp_ok($oDB_Content->row_count('fluorochrome',$dbh1),'==',3,'row_count');
	};

	#8
	test 'checksums' => sub {
		# a text field
		ok(my @aChecksum = $oDB_Content->field_checksum('protocol_type','description'),"field_checksum('protocol_type','description')");
		eq_or_diff \@aChecksum,['026c991aead235493031010d66f9b342d0126146e437c33a19881984529a57ef','026c991aead235493031010d66f9b342d0126146e437c33a19881984529a57ef'],'protocol_type.description checksums';
		
		# an int field
		ok(@aChecksum = $oDB_Content->field_checksum('filter','filter_id'),"field_checksum('filter','filter_id')");
		eq_or_diff \@aChecksum,['766cf85a89d87f5bca3c9b5793b456831a45ed8a388e4b644044d238cde0a9f4','766cf85a89d87f5bca3c9b5793b456831a45ed8a388e4b644044d238cde0a9f4'],'filter.filter_id checksums';

		# a varchar field
		ok(@aChecksum = $oDB_Content->field_checksum('laser','colour_name'),"field_checksum('laser','colour_name')");
		eq_or_diff \@aChecksum,['e235f3560a066a5d5bd51d2ebe81813ae18af807eb7a24cf8f796af719ddca1f','e235f3560a066a5d5bd51d2ebe81813ae18af807eb7a24cf8f796af719ddca1f'],'laser.colour_name checksums';

		# a varchar field returning NULL
		ok(@aChecksum = $oDB_Content->field_checksum('fluorochrome','manufacturer'),"field_checksum('fluorochrome','manufacturer')");
		#eq_or_diff \@aChecksum,[undef,undef],'fluorochrome.manufacturer';	# Test::Differences throws warning at this test
		is($aChecksum[0],undef,'fluorochrome.manufacturer');
		is($aChecksum[1],undef,'fluorochrome.manufacturer');
	};

	#9
	test 'the comparisons' => sub {
		cmp_ok($oDB_Content->compare_table_lists,'==',1,'compare_table_lists');
		cmp_ok($oDB_Content->compare_row_counts,'==',1,'compare_row_counts');
		cmp_ok($oDB_Content->compare_fields_checksum,'==',1,'compare_fields_checksum');
		
		cmp_ok($oDB_Content->compare,'==',1,'compare');	# just re-does the above
		
		ok(my $hDiffs = $oDB_Content->get_differences,'get_differences');
		eq_or_diff $hDiffs,{},'differences hashref';
	};

	#10
	test 'deep_compare' => sub {
		cmp_ok($oDB_Content->deep_compare,'==',1,'deep_compare');
	};

	### now make the two databases different ###		
	if (add_differences($dbh1)){
		$to_test = 1;
	} else {
		$to_test = undef;
		# because Test::Harness doesn't seem to want to output my skips!
		diag("Skipping 8 tests: Could not update the database");
	}

	SKIP: {
		skip("Could not update the database", 8) unless ($to_test);

		#11
		test 'object RE-init' => sub {
			ok($oDB_Content = compare_mysql_checksum->new($dbh1,$dbh2),'init');
			isa_ok($oDB_Content,'db_comparison','DBIx::Compare object');
			isa_ok($oDB_Content,'compare_mysql_checksum','DBIx::Compare::ContentChecksum::mysql object');
		};

		#12
		test 'no primary key in table extra' => sub {
			my $keys = $oDB_Content->get_primary_keys('extra',$dbh1);
			is($keys,undef,'primary key string');
			my @aKeys = $oDB_Content->get_primary_keys('extra',$dbh1);
			cmp_ok(@aKeys,'==',0,'primary key list');
		};

		#13
		test 're-examine databases' => sub {
			# table lists
			ok(my @aTables = $oDB_Content->get_tables,'get_tables 1 & 2');
			eq_or_diff \@aTables,[['extra','filter','fluorochrome','laser','protocol_type'],['filter','fluorochrome','laser','protocol_type']],'table lists';
			
			# extra row in filter
			cmp_ok($oDB_Content->row_count('filter',$dbh1),'==',4,'row_count');

			# different checksums for laser.colour_name
			ok(my @aChecksum = $oDB_Content->field_checksum('laser','colour_name'),"field_checksum('laser','colour_name')");
			eq_or_diff \@aChecksum,['9c4926911e466e889af52bb345859f1f3aa0245b2c384e908544a31c730995f0','e235f3560a066a5d5bd51d2ebe81813ae18af807eb7a24cf8f796af719ddca1f'],'laser.colour_name checksums';
		};

		#14
		test 're-do the individual comparisons' => sub {
			is($oDB_Content->compare_table_lists,undef,'compare_table_lists');
			is($oDB_Content->compare_row_counts,undef,'compare_row_counts');
			is($oDB_Content->compare_fields_checksum,undef,'compare_fields_checksum');
			
			ok(my $hDiffs2 = $oDB_Content->get_differences,'get_differences');
			eq_or_diff $hDiffs2,{ 
					'Fields unique to test2:localhost.fluorochrome' => ['cf260'],
					'Row count' => ['filter'],
					'Table laser fields' => ['colour_name'],
					'Tables unique to test:localhost' => ['extra']
				},'differences';
		};	

		#15
		test 're-do the comparison using compare in scalar context' => sub {
			ok($oDB_Content = compare_mysql_checksum->new($dbh1,$dbh2),'re-init');
			isa_ok($oDB_Content,'db_comparison','DBIx::Compare object');
			isa_ok($oDB_Content,'compare_mysql_checksum','DBIx::Compare::ContentChecksum::mysql object');
			is($oDB_Content->compare,undef,'compare');	# just re-does the above
			ok(my $hDiffs3 = $oDB_Content->get_differences,'get_differences');
			eq_or_diff $hDiffs3,{ 
					'Fields unique to test2:localhost.fluorochrome' => ['cf260'],
					'Row count' => ['filter'],
					'Table laser fields' => ['colour_name'],
					'Tables unique to test:localhost' => ['extra']
				},'differences';
		};

		#16
		test 're-do deep_compare' => sub {
			ok($oDB_Content = compare_mysql_checksum->new($dbh1,$dbh2),'re-init');
			isa_ok($oDB_Content,'db_comparison','DBIx::Compare object');
			isa_ok($oDB_Content,'compare_mysql_checksum','DBIx::Compare::ContentChecksum::mysql object');
			is($oDB_Content->deep_compare,undef,'deep_compare');
		};

		#17
		test 're-do compare with dbh in reverse' => sub {
			ok($oDB_Content = compare_mysql_checksum->new($dbh2,$dbh1),'re-init');
			isa_ok($oDB_Content,'db_comparison','DBIx::Compare object');
			isa_ok($oDB_Content,'compare_mysql_checksum','DBIx::Compare::ContentChecksum::mysql object');
			is($oDB_Content->compare,undef,'compare');	# just re-does the above
			ok(my $hDiffs4 = $oDB_Content->get_differences,'get_differences');
			eq_or_diff $hDiffs4,{ 
					'Fields unique to test2:localhost.fluorochrome' => ['cf260'],
					'Row count' => ['filter'],
					'Table laser fields' => ['colour_name'],
					'Tables unique to test:localhost' => ['extra']
				},'differences';
		};

		#18
		test 're-do deep_compare with dbh in reverse' => sub {
			ok($oDB_Content = compare_mysql_checksum->new($dbh2,$dbh1),'init');
			isa_ok($oDB_Content,'db_comparison','DBIx::Compare object');
			isa_ok($oDB_Content,'compare_mysql_checksum','DBIx::Compare::ContentChecksum::mysql object');
			is($oDB_Content->deep_compare,undef,'deep_compare');
		};
	};
};
# tests finished - disconnect from test
$dbh1->disconnect if ($dbh1);
$dbh2->disconnect if ($dbh2);



sub create_test_db {
	my $dbh = shift;
	drop_tables($dbh);
	my %hTables = return_tables();
	while (my ($table,$create) = each %hTables){
		$dbh->do("DROP TABLE IF EXISTS $table");
		$dbh->do($create);
	}
	insert_data($dbh);
	return 1;
}
sub drop_tables {
	my $dbh = shift;
	my (@aTables,$value);
	my $sth = $dbh->prepare('show tables');
	$sth->execute(); 
	$sth->bind_columns(undef, \$value);
	while($sth->fetch()) {
		push @aTables, $value;
	}
	$sth->finish(); 
	for my $table (@aTables){
		$dbh->do("drop table $table"); 
	}
}
sub insert_data {
	my $dbh = shift;
	$dbh->do("insert into filter values('1','522',NULL),('3','570',NULL),('8','670',NULL)");
	$dbh->do("insert into laser values('0','Red','633'),('2','Green','543'),('3','Blue','488')");
	$dbh->do("insert into fluorochrome values('11','Cyanine 5','649','670','0','8',NULL,250000,649,0.25),('3','Cyanine 3','550','570','2','3',NULL,150000,550,0.15),('13','Alexa 488','490','519','3','1',NULL,62000,492,0.30)");
	$dbh->do("insert into protocol_type values(1,'Other','Other types of protocol'),(2,'Hybridisation','CGH Microarray hybridisation protocol'),(3,'Labelling','DNA labelling reaction'),(4,'Plate manipulation','Transfer of samples from one plate to another, or joining/splitting of plates')");
}
sub return_tables {
	return (
		"filter",
		"CREATE TABLE filter (
			filter_id tinyint(2) unsigned NOT NULL,
			nm_peak int(3) unsigned NOT NULL,
			nm_width int(3) unsigned DEFAULT NULL,
			PRIMARY KEY (filter_id)
		) ENGINE=MyISAM",
		"laser",
		"CREATE TABLE laser (
			laser_id tinyint(1) unsigned NOT NULL,
			colour_name varchar(20) NOT NULL,
			nm_wavelength int(3) unsigned NOT NULL,
			PRIMARY KEY (laser_id)
		) ENGINE=MyISAM",
		"fluorochrome",
		"CREATE TABLE fluorochrome (
			fluorochrome_id tinyint(2) unsigned NOT NULL,
			name varchar(30) NOT NULL,
			excitation_nm int(3) unsigned NOT NULL,
			emission_nm int(3) unsigned NOT NULL,
			laser_id tinyint(1) unsigned NOT NULL,
			filter_id tinyint(2) unsigned NOT NULL,
			manufacturer varchar(30) DEFAULT NULL,
			extinction_coefficient int(7) unsigned NOT NULL,
			lambda_max int(3) unsigned NOT NULL,
			cf260 double(3,2) unsigned NOT NULL,
			PRIMARY KEY (fluorochrome_id)
		) ENGINE=MyISAM",
		"protocol_type",
		"CREATE TABLE protocol_type (
			protocol_type_id int(6) unsigned NOT NULL,
			type_name varchar(100) NOT NULL,
			description text,
			PRIMARY KEY (protocol_type_id)
		) ENGINE=MyISAM"
	);
}
sub add_differences {
	my $dbh = shift;
	$dbh->do(
		"CREATE TABLE extra (
			extra_id int(1) unsigned not null, 
			KEY extra_id (extra_id) 
		) ENGINE=MyISAM"
	);
	$dbh->do("insert into extra values(1),(2),(3),(4),(5)");
	$dbh->do("insert into filter values('2','545',NULL)");
	$dbh->do("update laser set colour_name = 'Greeny' where laser_id = 2");
	$dbh->do("alter table fluorochrome drop column cf260");
}

