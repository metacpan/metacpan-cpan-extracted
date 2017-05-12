#! /usr/bin/perl -w

use strict;

use Test::More tests=>35;
use Test::Group;
use Test::Differences;

use DBI;

# 1
BEGIN {
	use_ok('DBIx::Compare');
}

my $user_name = 'test';
my $user_pass = '';
my $dsn1 = "DBI:mysql:test:localhost";
my $dsn2 = "DBI:mysql:test2:localhost";
my ($to_test,$dbh1,$dbh2,$oDB_Content);

eval {
	require DBD::mysql;
};
if ($@){
	diag("Skipping 19 tests: Could not create the test databases because the driver 'DBD::mysql' is not installed");
} else {
	$dbh1 = DBI->connect($dsn1, $user_name, $user_pass);
	$dbh2 = DBI->connect($dsn2, $user_name, $user_pass);
	if ($dbh1 && $dbh2 && create_test_db($dbh1) && create_test_db($dbh2)){
		$to_test = 1;
	} else {
		# because Test::Harness doesn't seem to want to output my skips!
		diag("Skipping 19 tests: Could not create the test databases");
	}
}

SKIP: {
	skip("Could not create the test databases", 19) unless ($to_test);
	
	#2
	test 'object init' => sub {
		ok($oDB_Content = db_comparison->new($dbh1,$dbh2),'init');
		isa_ok($oDB_Content,'mysql_comparison','DBIx::Compare::mysql object');
		isa_ok($oDB_Content,'db_comparison','DBIx::Compare object');
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
	test 'table lists' => sub {
		ok(my @aTables = $oDB_Content->get_tables,'get_tables 1 & 2');
		eq_or_diff \@aTables,[['filter','fluorochrome','laser','procedure_info','protocol_type'],['filter','fluorochrome','laser','procedure_info','protocol_type']],'table lists';
		ok(my $aTable1 = $oDB_Content->get_tables,'get_tables 1');
		eq_or_diff $aTable1,$aTables[0],'tables vs tables1';
	};

	#5
	test 'primary keys' => sub {
		ok(my $keys = $oDB_Content->get_primary_keys('filter',$dbh1),'get_primary_keys');
		cmp_ok($keys,'eq','filter_id','primary key string');
		ok(my @aKeys = $oDB_Content->get_primary_keys('filter',$dbh1),'get_primary_keys');
		eq_or_diff \@aKeys,['filter_id'],'primary key list';
	};

	#6
	test 'row counts' => sub {
		cmp_ok($oDB_Content->row_count('protocol_type',$dbh1),'==',4,'protocol_type row_count');
		cmp_ok($oDB_Content->row_count('filter',$dbh1),'==',3,'filter row_count');
		cmp_ok($oDB_Content->row_count('procedure_info',$dbh1),'==',3,'procedure_info row_count');
		cmp_ok($oDB_Content->row_count('laser',$dbh1),'==',3,'laser row_count');
		cmp_ok($oDB_Content->row_count('fluorochrome',$dbh1),'==',3,'fluorochrome row_count');
	};

	#7
	test 'the comparisons' => sub {
		ok($oDB_Content->compare_table_lists,'compare_table_lists');
		ok($oDB_Content->compare_table_fields,'compare_table_fields');
		ok($oDB_Content->compare_row_counts,'compare_row_counts');
		ok($oDB_Content->compare_table_stats,'compare_table_stats');
		
		cmp_ok($oDB_Content->compare,'==',1,'compare');	# just re-does the above
		
		ok(my $hDiffs = $oDB_Content->get_differences,'get_differences');
		eq_or_diff $hDiffs,{},'differences hashref';

		cmp_ok($oDB_Content->deep_compare,'==',1,'deep_compare');
		ok(my $hDiffs1 = $oDB_Content->get_differences,'get_differences');
		eq_or_diff $hDiffs1,{},'differences hashref';
	};

	#8
	test 'field lists' => sub {	
		# these are fields common to the tables from both databases
		# list context
		ok(my @aFilter = $oDB_Content->field_list('filter'),'field_list(filter)');	
		eq_or_diff \@aFilter,[ 'filter_id','nm_peak','nm_width' ],'filter field list';
		ok(my @aFluor = $oDB_Content->field_list('fluorochrome'),'field_list(fluorochrome)');
		eq_or_diff \@aFluor,[ 'cf260','emission_nm','excitation_nm','extinction_coefficient','filter_id','fluorochrome_id','lambda_max','laser_id','manufacturer','name' ],'fluorochrome field list';
		ok(my @aLaser = $oDB_Content->field_list('laser'),'field_list(laser)');
		eq_or_diff \@aLaser,[ 'colour_name','laser_id','nm_wavelength' ],'laser field list';
		ok(my @aProtocol = $oDB_Content->field_list('protocol_type'),'field_list(protocol_type)');
		eq_or_diff \@aProtocol,[ 'description','protocol_type_id','type_name' ],'protocol_type field list';

		# scalar context
		ok(my $filter = $oDB_Content->field_list('filter'),'scalar field_list(filter)');
		cmp_ok($filter,'eq','filter_id,nm_peak,nm_width','scalar filter field list');
		ok(my $fluor = $oDB_Content->field_list('fluorochrome'),'scalar field_list(fluorochrome)');
		cmp_ok($fluor,'eq','cf260,emission_nm,excitation_nm,extinction_coefficient,filter_id,fluorochrome_id,lambda_max,laser_id,manufacturer,name','scalar fluorochrome field list');
		ok(my $laser = $oDB_Content->field_list('laser'),'scalar field_list(laser)');
		cmp_ok($laser,'eq','colour_name,laser_id,nm_wavelength','scalar laser field list');
		ok(my $protocol = $oDB_Content->field_list('protocol_type'),'scalar field_list(protocol_type)');
		cmp_ok($protocol,'eq','description,protocol_type_id,type_name','scalar protocol_type field list');

		# these are the sorted fields for each table in each database
		# these should still be the same
		ok(my $aFilter = $oDB_Content->get_fields('filter',$dbh1),'get_fields(filter)');	
		eq_or_diff $aFilter,[ 'filter_id','nm_peak','nm_width' ],'filter field list';
		ok(my $aFluor = $oDB_Content->get_fields('fluorochrome',$dbh1),'get_fields(fluorochrome)');
		eq_or_diff $aFluor,[ 'cf260','emission_nm','excitation_nm','extinction_coefficient','filter_id','fluorochrome_id','lambda_max','laser_id','manufacturer','name' ],'fluorochrome field list';
		ok(my $aLaser = $oDB_Content->get_fields('laser',$dbh1),'get_fields(laser)');
		eq_or_diff $aLaser,[ 'colour_name','laser_id','nm_wavelength' ],'laser field list';
		ok(my $aProtocol = $oDB_Content->get_fields('protocol_type',$dbh1),'get_fields(protocol_type)');
		eq_or_diff $aProtocol,[ 'description','protocol_type_id','type_name' ],'protocol_type field list';

	};

	#9
	test 'common and similar tables' => sub {
		ok(my $aTable1 = $oDB_Content->get_tables,'scalar get_tables');
		ok(my $aCommon_Tables = $oDB_Content->common_tables,'common_tables');
		eq_or_diff $aCommon_Tables,$aTable1,'common tables vs table1';
		ok(my $aSimilar_Tables = $oDB_Content->similar_tables,'similar_tables');
		eq_or_diff $aSimilar_Tables,$aTable1,'similar tables vs table1';
		
		ok(my $oDB_Content1a = db_comparison->new($dbh1,$dbh2),'re-init');
		ok(my $aCommon_Tables2 = $oDB_Content1a->common_tables,'common_tables with no compare');
		eq_or_diff $aCommon_Tables2,$aCommon_Tables,'common tables vs common tables';

		ok(my $oDB_Content1b = db_comparison->new($dbh1,$dbh2),'re-init');
		ok(my $aSimilar_Tables2 = $oDB_Content1b->similar_tables,'similar_tables with no compare');
		eq_or_diff $aSimilar_Tables2,$aSimilar_Tables,'similar tables vs similar tables';
	};

	### now make the two databases different ###		
	if (add_differences($dbh1)){
		$to_test = 1;
	} else {
		$to_test = undef;
		# because Test::Harness doesn't seem to want to output my skips!
		diag("Skipping 11 tests: Could not update the database");
	}

	SKIP: {
		skip("Could not update the database", 11) unless ($to_test);

		#10
		test 'object re-init' => sub {
			ok($oDB_Content = db_comparison->new($dbh1,$dbh2),'init');
			isa_ok($oDB_Content,'mysql_comparison','DBIx::Compare object');
			isa_ok($oDB_Content,'db_comparison','DBIx::Compare object');
		};

		###--------------------------------------###

		#11
		test 'no primary key in table extra' => sub {
			my $keys = $oDB_Content->get_primary_keys('extra',$dbh1);
			is($keys,undef,'primary key string');
			my @aKeys = $oDB_Content->get_primary_keys('extra',$dbh1);
			cmp_ok(@aKeys,'==',0,'primary key list');
		};

		#12
		test 're-examine databases' => sub {
			# table lists
			ok(my @aTables = $oDB_Content->get_tables,'get_tables 1 & 2');
			eq_or_diff \@aTables,[['extra','filter','fluorochrome','laser','procedure_info','protocol_type'],['filter','fluorochrome','laser','procedure_info','protocol_type']],'table lists';
			
			# extra row in filter
			cmp_ok($oDB_Content->row_count('filter',$dbh1),'==',4,'row_count');
		};

		#13
		test 're-do the individual comparisons' => sub {
			is($oDB_Content->compare_table_lists,undef,'compare_table_lists');
			is($oDB_Content->compare_table_fields,undef,'compare_table_fields');
			is($oDB_Content->compare_row_counts,undef,'compare_row_counts');
			is($oDB_Content->compare_table_stats,undef,'compare_table_stats');
			
			ok(my $hDiffs2 = $oDB_Content->get_differences,'get_differences');
			eq_or_diff $hDiffs2,{ 
					'Bad fields in table fluorochrome' => ['extinction_coefficient'],
					'Bad fields in table laser' => ['colour_name'],
					'Fields unique to test2:localhost.fluorochrome' => ['cf260'],
					'Row count' => ['filter'],
					'Tables unique to test:localhost' => ['extra']
				},'differences';
				
			ok(my $aCommon_Tables = $oDB_Content->common_tables,'common_tables with diffs');
			eq_or_diff $aCommon_Tables,['filter','fluorochrome','laser','procedure_info','protocol_type'],'common tables comparison';
			ok(my $aSimilar_Tables = $oDB_Content->similar_tables,'similar_tables with diffs');
			eq_or_diff $aSimilar_Tables,['procedure_info','protocol_type'],'similar tables comparison';
				
		};

		#14
		test 'field lists' => sub {
			# these are fields common to the tables from both databases
			# fluorochrome should have lost the field 'cf260'
			# list context
			ok(my @aFluor = $oDB_Content->field_list('fluorochrome'),'field_list(fluorochrome)');
			eq_or_diff \@aFluor,[ 'emission_nm','excitation_nm','extinction_coefficient','filter_id','fluorochrome_id','lambda_max','laser_id','manufacturer','name' ],'fluorochrome field list';
			ok(my @aFilter = $oDB_Content->field_list('filter'),'field_list(filter)');	
			eq_or_diff \@aFilter,[ 'filter_id','nm_peak','nm_width' ],'filter field list';
			ok(my @aLaser = $oDB_Content->field_list('laser'),'field_list(laser)');
			eq_or_diff \@aLaser,[ 'colour_name','laser_id','nm_wavelength' ],'laser field list';
			ok(my @aProtocol = $oDB_Content->field_list('protocol_type'),'field_list(protocol_type)');
			eq_or_diff \@aProtocol,[ 'description','protocol_type_id','type_name' ],'protocol_type field list';
			
			# scalar context
			ok(my $fluor = $oDB_Content->field_list('fluorochrome'),'scalar field_list(fluorochrome)');
			cmp_ok($fluor,'eq','emission_nm,excitation_nm,extinction_coefficient,filter_id,fluorochrome_id,lambda_max,laser_id,manufacturer,name','scalar fluorochrome field list');
			ok(my $filter = $oDB_Content->field_list('filter'),'scalar field_list(filter)');
			cmp_ok($filter,'eq','filter_id,nm_peak,nm_width','scalar filter field list');
			ok(my $laser = $oDB_Content->field_list('laser'),'scalar field_list(laser)');
			cmp_ok($laser,'eq','colour_name,laser_id,nm_wavelength','scalar laser field list');
			ok(my $protocol = $oDB_Content->field_list('protocol_type'),'scalar field_list(protocol_type)');
			cmp_ok($protocol,'eq','description,protocol_type_id,type_name','scalar protocol_type field list');

			# these are the sorted fields for each table in each database
			# fluor should still be the same for $dbh2 
			ok(my $aFilter1 = $oDB_Content->get_fields('filter',$dbh1),'field_list(filter)');	
			eq_or_diff $aFilter1,[ 'filter_id','nm_peak','nm_width' ],'filter field list';
			ok(my $aFluor1 = $oDB_Content->get_fields('fluorochrome',$dbh1),'field_list(fluorochrome)');
			eq_or_diff $aFluor1,[ 'emission_nm','excitation_nm','extinction_coefficient','filter_id','fluorochrome_id','lambda_max','laser_id','manufacturer','name' ],'fluorochrome field list';
			ok(my $aFilter2 = $oDB_Content->get_fields('filter',$dbh2),'field_list(filter)');	
			eq_or_diff $aFilter2,[ 'filter_id','nm_peak','nm_width' ],'filter field list';
			ok(my $aFluor2 = $oDB_Content->get_fields('fluorochrome',$dbh2),'field_list(fluorochrome)');
			eq_or_diff $aFluor2,[ 'cf260','emission_nm','excitation_nm','extinction_coefficient','filter_id','fluorochrome_id','lambda_max','laser_id','manufacturer','name' ],'fluorochrome field list';
		};

		### re-init for another round of comparison ###
		#15
		test 'object re-init' => sub {
			ok($oDB_Content = db_comparison->new($dbh1,$dbh2),'init');
			isa_ok($oDB_Content,'mysql_comparison','DBIx::Compare object');
			isa_ok($oDB_Content,'db_comparison','DBIx::Compare object');
		};

		###--------------------------------------###
			
		#16
		test 're-do the comparison using compare' => sub {
			is($oDB_Content->compare,undef,'compare');	# just re-does the above
			ok(my $hDiffs3 = $oDB_Content->get_differences,'get_differences');
			eq_or_diff $hDiffs3,{ 
					'Bad fields in table fluorochrome' => ['extinction_coefficient'],
					'Bad fields in table laser' => ['colour_name'],
					'Fields unique to test2:localhost.fluorochrome' => ['cf260'],
					'Row count' => ['filter'],
					'Tables unique to test:localhost' => ['extra']
				},'differences';
		};

		### re-init for another round of comparison ###
		#17
		test 'object re-init' => sub {
			ok($oDB_Content = db_comparison->new($dbh1,$dbh2),'init');
			isa_ok($oDB_Content,'mysql_comparison','DBIx::Compare object');
			isa_ok($oDB_Content,'db_comparison','DBIx::Compare object');
		};

		###--------------------------------------###

		#18
		test 're-do deep_compare' => sub {
			# does not run deep compare on disimilar tables
			is($oDB_Content->deep_compare,undef,'deep_compare');
			ok(my $hDiffs4 = $oDB_Content->get_differences,'get_differences');
			eq_or_diff $hDiffs4,{ 
					'Bad fields in table fluorochrome' => ['extinction_coefficient'],
					'Bad fields in table laser' => ['colour_name'],
					'Fields unique to test2:localhost.fluorochrome' => ['cf260'],
					'Row count' => ['filter'],
					'Tables unique to test:localhost' => ['extra']
				},'differences';
		};

		### re-init for another round of comparison ###
		#19
		test 'object re-init' => sub {
			ok($oDB_Content = db_comparison->new($dbh1,$dbh2),'init');
			isa_ok($oDB_Content,'mysql_comparison','DBIx::Compare object');
			isa_ok($oDB_Content,'db_comparison','DBIx::Compare object');
		};

		###--------------------------------------###

		#20
		test 're-do deep_compare' => sub {
			# force deep compare of the tables
			is($oDB_Content->deep_compare('filter','fluorochrome','laser','procedure_info','protocol_type'),undef,'deep_compare');
			ok(my $hDiffs4 = $oDB_Content->get_differences,'get_differences');
			eq_or_diff $hDiffs4,{ 
					'Discrepancy in table filter' => [2],
					'Discrepancy in table fluorochrome' => [2],
					'Discrepancy in table laser' => [2],
					'Fields unique to test2:localhost.fluorochrome' => ['cf260']	# from compare_field_lists
				},'differences';
		};
	};
};

# tests finished - disconnect from test
$dbh1->disconnect if ($dbh1);
$dbh2->disconnect if ($dbh2);


############################
# re-test with variant DSN #
############################

my $dsn3 = "DBI:mysql:database=test:host=localhost";
my $dsn4 = "DBI:mysql:database=test2:host=localhost";
my ($to_test2,$dbh3,$dbh4,$oDB_Content2);

eval {
	require DBD::mysql;
};
if ($@){
	diag("Skipping 15 test: Could not create the test databases because the driver 'DBD::mysql' is not installed");
} else {
	$dbh3 = DBI->connect($dsn3, $user_name, $user_pass);
	$dbh4 = DBI->connect($dsn4, $user_name, $user_pass);
	if ($dbh3 && $dbh4 && create_test_db($dbh3) && create_test_db($dbh4)){
		$to_test2 = 1;
	} else {
		# because Test::Harness doesn't seem to want to output my skips!
		diag("Skipping 15 tests: Could not create the test databases");
	}
}

SKIP: {
	skip("Could not create the test databases", 15) unless ($to_test2);
	ok($oDB_Content2 = db_comparison->new($dbh3,$dbh4),'init');
	cmp_ok($oDB_Content2->compare,'==',1,'compare');	# just re-does the above
	ok(my $hDiffs = $oDB_Content2->get_differences,'get_differences');
	eq_or_diff $hDiffs,{},'differences hashref';

	cmp_ok($oDB_Content2->deep_compare,'==',1,'deep_compare');
	ok(my $hDiffs1 = $oDB_Content2->get_differences,'get_differences');
	eq_or_diff $hDiffs1,{},'differences hashref';


	### now make the two databases different ###		
	if (add_differences($dbh3)){
		$to_test2 = 1;
	} else {
		$to_test2 = undef;
		# because Test::Harness doesn't seem to want to output my skips!
		diag("Skipping 8 tests: Could not update the database");
	}

	SKIP: {
		skip("Could not update the database", 8) unless ($to_test2);
		ok($oDB_Content2 = db_comparison->new($dbh3,$dbh4),'init');
		is($oDB_Content2->compare,undef,'compare');	
		ok(my $hDiffs3 = $oDB_Content2->get_differences,'get_differences');
		eq_or_diff $hDiffs3,{ 
				'Bad fields in table fluorochrome' => ['extinction_coefficient'],
				'Bad fields in table laser' => ['colour_name'],
				'Fields unique to database=test2:host=localhost.fluorochrome' => ['cf260'],
				'Row count' => ['filter'],
				'Tables unique to database=test:host=localhost' => ['extra']
			},'differences';

		ok($oDB_Content2 = db_comparison->new($dbh3,$dbh4),'init');
		is($oDB_Content2->deep_compare,undef,'deep_compare');
		ok(my $hDiffs4 = $oDB_Content2->get_differences,'get_differences');
		eq_or_diff $hDiffs4,{ 
				'Bad fields in table fluorochrome' => ['extinction_coefficient'],
				'Bad fields in table laser' => ['colour_name'],
				'Fields unique to database=test2:host=localhost.fluorochrome' => ['cf260'],
				'Row count' => ['filter'],
				'Tables unique to database=test:host=localhost' => ['extra']
			},'differences';
	}
}


sub create_test_db {
	my $dbh = shift;
	if (drop_tables($dbh)){
		my %hTables = return_tables();
		while (my ($table,$create) = each %hTables){
			$dbh->do($create) or return undef;
		}
		return insert_data($dbh);
	} else {
		return;
	}
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
		$dbh->do("drop table $table") or return undef;
	}
	return 1;
}
sub insert_data {
	my $dbh = shift;
	$dbh->do("insert into filter values('1','522',NULL),('3','570',NULL),('8','670',NULL)") or return undef;
	$dbh->do("insert into laser values('0','Red','633'),('2','Green','543'),('3','Blue','488')") or return undef;
	$dbh->do("insert into fluorochrome values('11','Cyanine 5','649','670','0','8',NULL,250000,649,0.25),('3','Cyanine 3','550','570','2','3',NULL,150000,550,0.15),('13','Alexa 488','490','519','3','1',NULL,62000,492,0.30)") or return undef;
	$dbh->do("insert into protocol_type values(1,'Other','Other types of protocol'),(2,'Hybridisation','CGH Microarray hybridisation protocol'),(3,'Labelling','DNA labelling reaction'),(4,'Plate manipulation','Transfer of samples from one plate to another, or joining/splitting of plates')") or return undef;
	$dbh->do("insert into procedure_info values(1,'1995-08-27','05:15:31','1995-08-27 05:15:31','trl','chris jones'),(2,'2005-04-12','07:20:00','2005-04-12 07:20:00','abcgr','john lennon'),(3,'2001-01-08','14:50:24','2001-01-08 14:50:24','xyz','smurfy smagness')") or return undef;
	return 1;
}
sub return_tables {
	return (
		"filter",
		"CREATE TABLE filter (
			filter_id tinyint(2) unsigned NOT NULL,
			nm_peak int(3) unsigned NOT NULL,
			nm_width int(3) unsigned DEFAULT NULL,
			PRIMARY KEY (filter_id)
		)",
		"laser",
		"CREATE TABLE laser (
			laser_id tinyint(1) unsigned NOT NULL,
			colour_name varchar(20) NOT NULL,
			nm_wavelength int(3) unsigned NOT NULL,
			PRIMARY KEY (laser_id)
		)",
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
		)",
		"procedure_info",
		"CREATE TABLE procedure_info (
			procedure_id int(6) unsigned NOT NULL,
			proc_date date NOT NULL,
			proc_time time NOT NULL,
			proc_datetime datetime NOT NULL,
			procedure_location char(5) NOT NULL,
			personnel_id binary NOT NULL,
			PRIMARY KEY  (procedure_id)
		) ",
		"protocol_type",
		"CREATE TABLE protocol_type (
			protocol_type_id int(6) unsigned NOT NULL,
			type_name varchar(100) NOT NULL,
			description text,
			PRIMARY KEY (protocol_type_id)
		)"
	);
}
sub add_differences {
	my $dbh = shift;
	$dbh->do(
		"CREATE TABLE extra (
			extra_id int(1) unsigned not null, 
			KEY extra_id (extra_id) 
		) ENGINE=MyISAM"
	) or return undef;
	$dbh->do("insert into extra values(1),(2),(3),(4),(5)") or return undef;
	$dbh->do("insert into filter values('2','545',NULL)") or return undef;
	$dbh->do("update laser set colour_name = 'Greeny' where laser_id = 2") or return undef;
	$dbh->do("alter table fluorochrome drop column cf260") or return undef;
	$dbh->do("update fluorochrome set extinction_coefficient = 250001 where fluorochrome_id = 11") or return undef;
	return 1;
}

