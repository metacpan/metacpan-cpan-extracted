# -*- perl -*-
use strict;
use warnings;
use Test::More tests => 125;

BEGIN { use_ok( 'DBIx::Array' ); }


SKIP: {
    eval "require SQL::Abstract";
    skip "SQL::Abstract not installed", 124 if $@;
    my $dba=DBIx::Array->new;
    isa_ok($dba, 'DBIx::Array');
    my $sabs=$dba->abs;
    isa_ok($sabs, 'SQL::Abstract');

    my $connection={"DBD::XBase"=>"dbi:XBase:."};
    my $driver="DBD::XBase";
    eval "require $driver";
    skip "Database driver $driver not installed", 122 if $@;
    diag("Found database driver $driver");
  
    die("connection not defined for $driver") unless $connection->{$driver};
    $dba->connect($connection->{$driver}, "", "", {RaiseError=>0, AutoCommit=>1});
    my $table="dbixarray";
  
   #$dba->dbh->do("DROP TABLE $table");
    $dba->dbh->do("CREATE TABLE $table (F1 INTEGER,F2 CHAR(1),F3 VARCHAR(10))");
    is($dba->absinsert($table, {F1=>0,F2=>1,F3=>2}), 1, 'insert');
    is($dba->absinsert($table, {F1=>1,F2=>2,F3=>3}), 1, 'insert');
    is($dba->absinsert($table, {F1=>2,F2=>3,F3=>4}), 1, 'insert');
    isa_ok($dba->sqlcursor($sabs->select($table)), 'DBI::st', 'sqlcursor');
    
    my $array=$dba->sqlarray($sabs->select($table, [qw{F1 F2 F3}], {F1=>0}));
    isa_ok($array, "ARRAY", '$dba->sqlarray scalar context');
    is(scalar(@$array), 3, 'scalar(@$array)');
    is($array->[0], 0, '$dba->sqlarray->[0]');
    is($array->[1], 1, '$dba->sqlarray->[1]');
    is($array->[2], 2, '$dba->sqlarray->[2]');

    my @array=$dba->sqlarray($sabs->select($table, [qw{F1 F2 F3}], {F1=>0}));
    is(scalar(@array), 3, 'scalar(@$array)');
    is($array[0], 0, '$dba->sqlarray[0]');
    is($array[1], 1, '$dba->sqlarray[1]');
    is($array[2], 2, '$dba->sqlarray[2]');
    
    my $hash=$dba->sqlhash($sabs->select($table, [qw{F1 F2}]));
    isa_ok($hash, "HASH", 'sqlarray scalar context');
    is($hash->{'0'}, 1, 'sqlhash');
    is($hash->{'1'}, 2, 'sqlhash');
    is($hash->{'2'}, 3, 'sqlhash');
    
    my %hash=$dba->sqlhash($sabs->select($table, [qw{F1 F2}]));
    is($hash{'0'}, 1, 'sqlhash');
    is($hash{'1'}, 2, 'sqlhash');
    is($hash{'2'}, 3, 'sqlhash');
    
    $array=$dba->sqlarrayarray($sabs->select($table, [qw{F1 F2 F3}], {}, [qw{F1}]));
    isa_ok($array, "ARRAY", 'sqlarrayarray scalar context');
    isa_ok($array->[0], "ARRAY", 'sqlarrayarray row 1');
    isa_ok($array->[1], "ARRAY", 'sqlarrayarray row 2');
    isa_ok($array->[2], "ARRAY", 'sqlarrayarray row 3');
    is($array->[0]->[0], 0, 'data');
    is($array->[0]->[1], 1, 'data');
    is($array->[0]->[2], 2, 'data');
    is($array->[1]->[0], 1, 'data');
    is($array->[1]->[1], 2, 'data');
    is($array->[1]->[2], 3, 'data');
    is($array->[2]->[0], 2, 'data');
    is($array->[2]->[1], 3, 'data');
    is($array->[2]->[2], 4, 'data');
    
    @array=$dba->sqlarrayarray($sabs->select($table, [qw{F1 F2 F3}], {}, [qw{F1}]));
    isa_ok($array[0], "ARRAY", 'sqlarrayarray row 1');
    isa_ok($array[1], "ARRAY", 'sqlarrayarray row 2');
    isa_ok($array[2], "ARRAY", 'sqlarrayarray row 3');
    is($array[0]->[0], 0, 'data');
    is($array[0]->[1], 1, 'data');
    is($array[0]->[2], 2, 'data');
    is($array[1]->[0], 1, 'data');
    is($array[1]->[1], 2, 'data');
    is($array[1]->[2], 3, 'data');
    is($array[2]->[0], 2, 'data');
    is($array[2]->[1], 3, 'data');
    is($array[2]->[2], 4, 'data');
    
    $array=$dba->sqlarrayarrayname($sabs->select($table, [qw{F1 F2 F3}], {}, [qw{F1}]));
    isa_ok($array, "ARRAY", 'sqlarrayarrayname scalar context');
    isa_ok($array->[0], "ARRAY", 'sqlarrayarrayname header');
    isa_ok($array->[1], "ARRAY", 'sqlarrayarrayname row 1');
    isa_ok($array->[2], "ARRAY", 'sqlarrayarrayname row 2');
    isa_ok($array->[3], "ARRAY", 'sqlarrayarrayname row 3');
    is($array->[0]->[0], 'F1', 'data');
    is($array->[0]->[1], 'F2', 'data');
    is($array->[0]->[2], 'F3', 'data');
    is($array->[1]->[0], 0, 'data');
    is($array->[1]->[1], 1, 'data');
    is($array->[1]->[2], 2, 'data');
    is($array->[2]->[0], 1, 'data');
    is($array->[2]->[1], 2, 'data');
    is($array->[2]->[2], 3, 'data');
    is($array->[3]->[0], 2, 'data');
    is($array->[3]->[1], 3, 'data');
    is($array->[3]->[2], 4, 'data');
    
    @array=$dba->sqlarrayarrayname($sabs->select($table, [qw{F1 F2 F3}], {}, [qw{F1}]));
    isa_ok($array[0], "ARRAY", 'sqlarrayarrayname header');
    isa_ok($array[1], "ARRAY", 'sqlarrayarrayname row 1');
    isa_ok($array[2], "ARRAY", 'sqlarrayarrayname row 2');
    isa_ok($array[3], "ARRAY", 'sqlarrayarrayname row 3');
    is($array[0]->[0], 'F1', 'data');
    is($array[0]->[1], 'F2', 'data');
    is($array[0]->[2], 'F3', 'data');
    is($array[1]->[0], 0, 'data');
    is($array[1]->[1], 1, 'data');
    is($array[1]->[2], 2, 'data');
    is($array[2]->[0], 1, 'data');
    is($array[2]->[1], 2, 'data');
    is($array[2]->[2], 3, 'data');
    is($array[3]->[0], 2, 'data');
    is($array[3]->[1], 3, 'data');
    is($array[3]->[2], 4, 'data');
    
    $array=$dba->sqlarrayhashname($sabs->select($table, [qw{F1 F2 F3}], {}, [qw{F1}]));
    isa_ok($array, "ARRAY", 'sqlarrayhashname scalar context');
    isa_ok($array->[0], "ARRAY", 'sqlarrayhashname header');
    isa_ok($array->[1], "HASH", 'sqlarrayhashname row 1');
    isa_ok($array->[2], "HASH", 'sqlarrayhashname row 2');
    isa_ok($array->[3], "HASH", 'sqlarrayhashname row 3');
    is($array->[0]->[0], 'F1', 'data');
    is($array->[0]->[1], 'F2', 'data');
    is($array->[0]->[2], 'F3', 'data');
    is($array->[1]->{'F1'}, 0, 'data');
    is($array->[1]->{'F2'}, 1, 'data');
    is($array->[1]->{'F3'}, 2, 'data');
    is($array->[2]->{'F1'}, 1, 'data');
    is($array->[2]->{'F2'}, 2, 'data');
    is($array->[2]->{'F3'}, 3, 'data');
    is($array->[3]->{'F1'}, 2, 'data');
    is($array->[3]->{'F2'}, 3, 'data');
    is($array->[3]->{'F3'}, 4, 'data');
    
    @array=$dba->sqlarrayhashname($sabs->select($table, [qw{F1 F2 F3}], {}, [qw{F1}]));
    isa_ok($array[0], "ARRAY", 'sqlarrayhashname header');
    isa_ok($array[1], "HASH", 'sqlarrayhashname row 1');
    isa_ok($array[2], "HASH", 'sqlarrayhashname row 2');
    isa_ok($array[3], "HASH", 'sqlarrayhashname row 3');
    is($array[0]->[0], 'F1', 'data');
    is($array[0]->[1], 'F2', 'data');
    is($array[0]->[2], 'F3', 'data');
    is($array[1]->{'F1'}, 0, 'data');
    is($array[1]->{'F2'}, 1, 'data');
    is($array[1]->{'F3'}, 2, 'data');
    is($array[2]->{'F1'}, 1, 'data');
    is($array[2]->{'F2'}, 2, 'data');
    is($array[2]->{'F3'}, 3, 'data');
    is($array[3]->{'F1'}, 2, 'data');
    is($array[3]->{'F2'}, 3, 'data');
    is($array[3]->{'F3'}, 4, 'data');
    
    is($dba->absupdate($table, {F2=>8,F3=>9}, {F1=>1}),1,'update');
    $array=$dba->sqlarray($sabs->select($table, [qw{F1 F2 F3}], {F1=>1}));
    isa_ok($array, "ARRAY", '$dba->sqlarray scalar context');
    is(scalar(@$array), 3, 'scalar(@$array)');
    is($array->[0], 1, '$dba->sqlarray->[0]');
    is($array->[1], 8, '$dba->sqlarray->[1]');
    is($array->[2], 9, '$dba->sqlarray->[2]');
    
    is($dba->absdelete($table, {F1=>1}),1,'delete');
    $array=$dba->sqlarrayarray($sabs->select($table, [qw{F1 F2 F3}], {F1=>1}));
    isa_ok($array, "ARRAY", '$dba->sqlarray scalar context');
    is(scalar(@$array), 0, 'scalar(@$array)');

    $array=$dba->sqlarrayarray($sabs->select($table, [qw{F1 F2 F3}]));
    isa_ok($array, "ARRAY", '$dba->sqlarray scalar context');
    is(scalar(@$array), 2, 'scalar(@$array)');

    $dba->dbh->do("DROP TABLE $table");
}
