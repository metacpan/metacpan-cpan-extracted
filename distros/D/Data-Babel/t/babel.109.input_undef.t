########################################
# regression test for translating all ids when input_idtype contains NULL
########################################
use t::lib;
use t::utilBabel;
use Test::More;
use Test::Deep;
use File::Spec;
use Class::AutoDB;
use Data::Babel;
use Data::Babel::Config;
use strict;

# create AutoDB database
my $autodb=new Class::AutoDB(database=>'test',create=>1); 
isa_ok($autodb,'Class::AutoDB','sanity test - $autodb');
cleanup_db($autodb);		# cleanup database from previous test
Data::Babel->autodb($autodb);
my $dbh=$autodb->dbh;

# make component objects. make Babels later
my @idtypes=map {new Data::Babel::IdType(name=>"type_$_",sql_type=>'VARCHAR(255)')} (0,1);
my @masters=map {new Data::Babel::Master(name=>$_->name.'_master',idtype=>$_)} @idtypes;
my $maptable=new Data::Babel::MapTable(name=>"maptable_0_1",idtypes=>"type_0 type_1");

# create UR
$dbh->do(qq(DROP TABLE IF EXISTS ur));
$dbh->do(qq(CREATE TABLE ur (type_0 VARCHAR(255), type_1 VARCHAR(255))));
# load data
my @data=([undef,'type_1/0'],['type_0/1','type_1/1']);
my @values=map {'('.join(', ',map {!defined($_)? 'NULL': $dbh->quote($_)} @$_).')'} @data;
my $values=join(",\n",@values);
$dbh->do(qq(INSERT INTO ur VALUES\n$values));

# load maptable
$dbh->do(qq(DROP TABLE IF EXISTS maptable_0_1));
$dbh->do(qq(CREATE TABLE maptable_0_1 AS SELECT * FROM ur));

my $correct=[['type_0/1','type_1/1']];

# test translate with implicit masters
my $babel=new Data::Babel(name=>'implicit',idtypes=>\@idtypes,maptables=>[$maptable]);
# NG 12-09-30: use load_implicit_masters
$babel->load_implicit_masters;
# map {load_master($babel,$_)} @{$babel->masters}; # creates views
my $actual=$babel->translate(input_idtype=>'type_0',output_idtypes=>[qw(type_1)]);
cmp_table($actual,$correct,'translate implicit masters');

# test translate with explicit masters
my $babel=
  new Data::Babel(name=>'explicit',idtypes=>\@idtypes,maptables=>[$maptable],masters=>\@masters);
for my $master (@{$babel->masters}) { # load explicit masters
  # code adpated from utilBabel::load_master
  my $tablename=$master->tablename;
  $dbh->do(qq(DROP VIEW IF EXISTS $tablename));
  $dbh->do(qq(DROP TABLE IF EXISTS $tablename));
  my $idtype=$master->idtype;
  my $column_name=$idtype->name;
  my $where_sql=qq($column_name IS NOT NULL);
  my $sql=qq(CREATE TABLE $tablename AS SELECT DISTINCT $column_name FROM ur WHERE $where_sql);
  $dbh->do($sql);
}
my $actual=$babel->translate(input_idtype=>'type_0',output_idtypes=>[qw(type_1)]);
cmp_table($actual,$correct,'translate explicit masters');

done_testing();
