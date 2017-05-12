# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl DBIx-BulkLoader-Mysql.t'

#########################


#use Test::More tests => 7;
use Test::More tests => 1;
BEGIN { use_ok('DBIx::BulkLoader::Mysql') };
# use strict;
# use warnings;
# eval {use DBI;use DBD::mysql};
# my $eval=$@;
# 
# my @env_keys=qw(TEST_DB TEST_HOST TEST_USER TEST_PASSWORD);
# SKIP: {
# 	my $tests=5;
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
# 		,placeholder_count=>3
# 		,bulk_insert_count=>5
# 		,prepare_args=>{}
# 	);
# 	ok($bulk,'bulk loader should exist');
# 	#print $bulk->bulk_sql,"\n";
# 	for(1 .. 6) {
# 		$bulk->insert(qw(a b c));
# 	}
# 	$bulk->flush;
# 	ok(scalar($bulk->get_buffered_data)==0,
# 		'make sure the buffered data is gone 1');
# 
# 	($bulk,$error)=DBIx::BulkLoader::Mysql->new(
# 		dbh=>$dbh
# 		,sql_insert=>$insert
# 		,placeholders=>$placeholders
# 	);
# 	ok($bulk,'min arg constructor check');
# 	for(1 .. 150) {
# 		$bulk->insert(qw(a b c));
# 	}
# 	ok(scalar($bulk->get_buffered_data)==0,
# 		'make sure the buffered data is gone 2');
# 	my $sth=$dbh->prepare('select count(*) from bulk_insert');
# 	$sth->execute;
# 	my ($count)=$sth->fetchrow_array;
# 	ok($count==156,'total rows inserted should be 156');
# 
# }
# 
# ## OO constructor fail tests ( no need for dbi  )
# {
# 	my ($bulk,$fail)=DBIx::BulkLoader::Mysql->new;
# 	ok((!$bulk and defined($fail))
# 		,'constructor call with no args should fail');
# 
# }
# #########################
# 
# # Insert your test code below, the Test::More module is use()ed here so read
# # its man page ( perldoc Test::More ) for help writing this test script.
# 
__END__
