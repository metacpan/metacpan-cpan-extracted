

#use Test::More tests => 16;
use Test::More tests => 1;
BEGIN { use_ok('DBIx::SimpleGoBetween') };
# use strict;
# use warnings;
# eval "use DBI;use DBD::mysql;use  DBIx::BulkLoader::Mysql";
# my $eval=$@;
# 
# my @env_keys=qw(TEST_DB TEST_HOST TEST_USER TEST_PASSWORD);
# SKIP: {
# 	my $tests=15;
# 	skip $eval,$tests if $eval;
# 	skip "Env variables not set!", $tests unless
# 		4==grep {defined($ENV{$_})} @env_keys;
# 
# my $dsn = "DBI:mysql:database=$ENV{TEST_DB};host=$ENV{TEST_HOST}";
# 	my $dbh=eval{ DBI->connect($dsn,$ENV{TEST_USER},$ENV{TEST_PASSWORD})};
# 	skip "failed to connect",$tests if $@ || !$dbh;
# 	$dbh->do('drop table if exists bulk_insert;');
# 	$dbh->do('create table bulk_insert (col_a varchar(100) , col_b varchar(100), col_c varchar(100));');
# 
# 	my $insert='insert into bulk_insert (col_a,col_b,col_c) values ';
# 	my $placeholders='(?,?,?)';
# 	my ($bulk,$error)=DBIx::BulkLoader::Mysql->new(
# 		dbh=>$dbh
# 		,sql_insert=>$insert
# 		,placeholders=>$placeholders
# 	);
# 	for(1 .. 150) {
# 		$bulk->insert(qw(a b c));
# 	}
# 
# 	my $db=DBIx::SimpleGoBetween->new(\$dbh);
# 	ok($db,'constructor instance test');
# 	ok($db->dbh eq $dbh,'$db->dbh should return the same instance as $dbh');
# 
# 	my $sth=$db->prep('select * from bulk_insert');
# 	ok(ref($sth), 'should get a prepared statement handle back');
# 	my $re_prep=$db->prep($sth);
# 	ok($sth eq $re_prep,'should have the same 2 db instances');
# 
# 	my $count=0;
# 	$db->callback($sth,[],[],'array',sub { ++$count if @_==3 });
# 	ok($count==150,'should have 150 rows with 3 columnns');
# 	$count=0;
# 	$db->callback(
# 		'select * from bulk_insert where col_a=?'
# 		,['a']
# 		,[]
# 		,'array'
# 		,sub { ++$count if @_==3 }
# 	);
# 	ok($count==150,'placeholder check');
# 
# 	$count=0;
# 	$db->callback($sth,[],[],'hash',sub { ++$count if @_==6 });
# 	ok($count==150,'callback hash: should have 150 rows with 6 columnns');
# 
# 	$count=0;
# 	$db->callback($sth,[],[],'hash_ref',
# 		sub { ++$count if @_==1 and ref($_[0]) eq 'HASH' }
# 	);
# 
# 	$count=0;
# 	$db->callback($sth,[],[],'array_ref',
# 		sub { ++$count if @_==1 and ref($_[0]) eq 'ARRAY' }
# 	);
# 	ok($count==150,'callback array_ref: should have 150 rows of arrays');
# 	ok((450==$db->get_list($sth)),'should have 450 columns');
# 	my @list=$db->get_scalar($sth);
# 	ok(1==scalar(@list),'should have just 1 scalar');
# 
# 	my $ref=$db->get_list_of_lists($sth);
# 	ok(ref($ref) eq 'ARRAY','list of lists check 1');
# 	ok(scalar(grep {ref($_) eq 'ARRAY' } @$ref)==150
# 		,'list of lists check 2');
# 	
# 	$ref=$db->get_list_of_hashes($sth);
# 	ok(ref($ref) eq 'ARRAY','list of hashes check 1');
# 	ok(scalar(grep {ref($_) eq 'HASH' } @$ref)==150
# 		,'list of hashes check 2');
# 	ok($db->sql_do('drop table if exists bulk_insert'),'sql_do check');
# }
# 
# #########################
# 
# # Insert your test code below, the Test::More module is use()ed here so read
# # its man page ( perldoc Test::More ) for help writing this test script.
# 
__END__
