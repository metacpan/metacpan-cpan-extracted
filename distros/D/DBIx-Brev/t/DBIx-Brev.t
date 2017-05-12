# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl DBIx-Brev.t'

#########################

use strict;
use warnings;

use Test::More tests => 37;
use List::Util qw(min max);
BEGIN { use_ok('DBIx::Brev') };
use File::Temp qw/ tempfile /;
use File::Copy qw(move);
use Data::Dumper;

#########################

my (undef,$db_file) = tempfile(); # this will DB name

# insert some records and test inserts as well
my $records = [sort {$a->[0] <=> $b->[0]} [1,2],[3,4],[5,6]];

test_load_config();

my $dbc = eval {db_use('dbm')};

test_dbc();
test_sql_exec();
test_transaction();
test_inserts();
test_sql_value();
test_sql_query();
test_sql_map();
test_sql_hash();
test_sql_query_hash();
test_sql_in();
test_quote();
test_without_config();
test_without_sqlsplit();
test_fork();

# destroy database
$dbc->dbh()->disconnect;    
unlink $db_file;
exit 0;

sub test_dbc {
    isa_ok($dbc,'DBIx::Connector','dbc');
    isa_ok($dbc->dbh,'DBI::db','dbh');
}

sub test_quote {
    my $q=q{'"\\};
    note 'quote:',quote($q);
    is(quote($q),$dbc->dbh()->quote($q),'quote');
}

sub test_sql_in {
    my $expected = sprintf(" in (%s)",join ",",map $_->[0],@$records);
    my $result = sql_in("select a from t1 order by a");
    is($result,$expected,'sql_in all values');
    $expected = " in (NULL)";
    $result = sql_in("select a from t1 where a is null order by a");
    is($result,$expected,'sql_in no values');
}

sub test_sql_query_hash {
    my $expected = [map {{a=>$_->[0],b=>$_->[1]}} @$records];    
    my $results = sql_query_hash q{select * from t1 order by a};
    is_deeply($results,$expected,"sql_query_hash scalar")  or diag explain $results,$expected;
    my @result = sql_query_hash q{select * from t1 order by a};
    is_deeply(\@result,$expected,"sql_query_hash array");
}

sub test_sql_hash {
    my $expected = {a=>1,b=>2};
    my $result = sql_hash q{select * from t1 where a=1};
    is_deeply($result,$expected,"sql_hash scalar");
    my %result = sql_hash q{select * from t1 where a=1};
    is_deeply(\%result,$expected,"sql_hash array");
    $result = sql_hash q{select * from t1 order by a};
    is_deeply(\%result,$expected,"sql_hash first");
}

sub test_sql_exec {
    sql_exec q{create table t1(a int primary key,b text)};
    sql_exec q{insert into t1 values(1,1)};
    my $records_affected = sql_exec "delete from t1 where a=?",1;
    is($records_affected,1,"sql_exec [simple] records_affected");
    # multiple statements
    $records_affected = sql_exec q{
        insert into t1 values(1,1);
        insert into t1 values(2,2);
        insert into t1 values(3,3);
        delete from t1;
    };
    is($records_affected,6,"sql_exec [split statements] records_affected");
    # multiple with place holders
    $records_affected = sql_exec q{
        insert into t1 values(?,1);
        insert into t1 values(?,2);
        insert into t1 values(?,3);
        delete from t1;
    },1,2,3;
    is($records_affected,6,"sql_exec [split statements placeholders] records_affected");
}

sub test_transaction {
    my $expected_after_rollback = sql_value("select count(*) from t1");
    sql_exec $dbc, {no_commit=>1}, q{
        delete from t1;
        insert into t1 values(1,99);
        insert into t1 values(2,2);        
    };
    is(sql_value($dbc,"select b from t1 where a=1"),99,"transaction in affect");
    is(sql_value($dbc,"select count(*) from t1"),2,"transaction record inserted");
    $dbc->dbh()->rollback;
    is(sql_value($dbc,"select count(*) from t1 where a=1"),$expected_after_rollback,"transaction rolled back");    
}

sub test_inserts {
    my $records_str = [map join(",",@$_), @$records];
    #print Dumper($records_str);
    my $records_affected = inserts("insert into t1",$records_str);
    is($records_affected, sql_exec("delete from t1"), "inserts string records_affected");
    $records_affected = inserts("insert into t1",$records);
    is($records_affected, @$records, "inserts records_affected");
}

sub test_sql_map {
    my ($expected,$results);

    $expected = $records;
    $results = [sql_map {$_} q{select a,b from t1 order by a}];
    is_deeply($results,$expected,"sql_map simple") or diag explain $results;   

    $expected = [map $_->[0], @$records]; # [1,3,5]
    $results = sql_map {$_} q{select a from t1 order by a};
    is_deeply($results,$expected,"sql_map scalarize") or diag explain $results;   
}

sub test_sql_query {
    my ($expected,$results);
    $expected = $records;
    $results = sql_query q{select a,b from t1 order by a};
    is_deeply($results,$expected,"sql_query scalar context");
    $results = [sql_query q{select a,b from t1 order by a}];
    is_deeply($results,$expected,"sql_query array context");
    $expected = [map $_->[0], @$expected];
    $results = sql_query q{select a from t1 order by a};
    is_deeply($results,$expected,"sql_query single column");    
}

sub test_sql_value {
    my $mina = min(map $_->[0], @$records);
    my $maxa = max(map $_->[0], @$records);
    # test sql_value
    my ($min,$max,$count) = sql_value q{select min(a),max(a),count(*) from t1};
    is($min, $mina, "sql_value min array context");
    is($max, $maxa, "sql_value max array context");
    is($count, @$records, "sql_value count array context");
    
    my $min1 = sql_value q{select min(a) from t1};
    is($min1, $mina, "sql_value scalar context min");    
  
    my $max2 = sql_value q{select max(a),min(a) from t1};
    is($max2, $maxa, "sql_value scalar2 context max");
    
    my $a_first = sql_value q{select a from t1 order by a};
    is($a_first,$records->[0][0],q{sql_value first})
}


sub test_load_config {
    # create config file on the fly
    my ($fh,$config_file) = tempfile();
    print $fh qq{<database dbm>\ndata_source=dbi:SQLite:dbname=$db_file\n</database>};
    close($fh);
    # load config using $ENV{DBI_CONF}
    $ENV{DBI_CONF} = $config_file;
    my %config = DBIx::Brev::load_config();
    ok(scalar keys %config,q{load config using $ENV{DBI_CONF}});
    # load config using explicit param
    my %config1 = DBIx::Brev::load_config($config_file);
    is_deeply(\%config,\%config1,"load config using explicit filename");
    # load config from HOME
    SKIP: {
        delete $ENV{DBI_CONF};
        my $mswin = $^O eq 'MSWin32';
        my $fd = $mswin?q{\\}:q{/};
        my ($home) = grep defined && -d, map $ENV{$_}, $mswin? qw(USERPROFILE HOME):'HOME';
        skip "was not able to find HOME directory", 1 unless defined($home);
        my $home_config = $home.$fd.q{dbi.conf};
        my $backup = -f $home_config?grep(!-f,map $home_config.substr(rand(),1),1..10):();
        my %config2;
        skip "was not able to create/replace $home_config",1 unless eval {
            move($home_config,$backup) if $backup;
            move($config_file,$home_config);
            %config2 = DBIx::Brev::load_config();
            unlink $home_config;
            move($backup,$home_config) if $backup;
            1;
        };
        is_deeply(\%config2,\%config,q{load config from HOME directory});
    };
    unlink $config_file;
    is($config{database}{dbm}{data_source},"dbi:SQLite:dbname=$db_file",'config file data_source');
}

sub test_fork {
    SKIP: {
        my $pid = eval {fork()};
        skip "can't fork()", 1 unless defined($pid);
        if ($pid == 0) {
            sql_value("select 1"); # use dbc at fork
            exit;
        }
        wait;
        is(sql_value("select 1"),1,"dbc after forked child");
    }
}

sub test_without_config {
    $DBIx::Brev::use_config = 0;
    $DBIx::Brev::use_dbc = 0;
    my $dbh = db_use("dbi:SQLite:dbname=$db_file");
    #print Dumper($dbh);
    ok($dbh,"without config");
    #ok($dbh->isa('DBI::db'),"without dbc");
    $DBIx::Brev::use_config = 1;
    $DBIx::Brev::use_dbc = 1;
}
sub test_without_sqlsplit {
    $DBIx::Brev::use_sqlsplit = 0;
    my $r = sql_exec("update t1 set a=a+1");
    ok($r==3,"without split");
    $DBIx::Brev::use_sqlsplit = 1;
}

