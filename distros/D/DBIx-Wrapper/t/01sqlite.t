#!/usr/local/bin/perl
# $Revision: $

use strict;
use warnings;
use File::Temp;

use Test::More;

my $have_sqlite;
{
    local($SIG{__DIE__});
    eval { require DBD::SQLite; };
    unless ($@) {
        $have_sqlite = 1;
    }
}

if ($ENV{AUTOMATED_TESTING}) {
    plan skip_all => 'skipping db tests under automated testing';
    exit 0;
}

if ($have_sqlite) {
    plan tests => 50;
}
else {
    plan skip_all => 'DBD::SQLite not installed';
    exit 0;
}

my $top_dir;

use File::Spec ();
BEGIN {
    my $path = File::Spec->rel2abs($0);
    (my $dir = $path) =~ s{(?:/[^/]+){2}\Z}{};
    # unshift @INC, $dir . "/lib";
    $top_dir = $dir;
}

use DBIx::Wrapper;

my $self = bless { };

sub my_err_handler {
    return 1;
}

sub my_debug_handler {
    my ($db, $str, $fh) = @_;
    print $fh $str, "\n";
}

my $val;
my $ok;
my $val2;

my $db_fh;
my $db_file;
my $conf_fh;
my $conf_file;

my $test_dir = "$top_dir/t";
if (-w $test_dir) {
    $db_fh = File::Temp->new(UNLINK => 0, DIR => $test_dir);
    $conf_fh = File::Temp->new(UNLINK => 1, DIR => $test_dir);
}
else {
    $db_fh = File::Temp->new(UNLINK => 0);
    $conf_fh = File::Temp->new(UNLINK => 1);
}

$db_file = $db_fh->filename;
$conf_file = $conf_fh->filename;

$db_fh->close;

# print STDERR "\n\n====================> db file=$db_file\n\n";


$self->write_config_file($conf_fh, $db_file);

# my $db = DBIx::Wrapper->connect_from_config('test_db', $conf_file,
#                                             { error_handler => \&my_err_handler,
#                                               debug_handler => \&my_debug_handler,
#                                             },
#                                            );

# print "DBG> db_file=$db_file\n";
# print "DBG> conf_file=$conf_file\n";

# print "\n\n";

# if ($db) {
#     print "Got connection!\n";
# }
# else {
#     print "Couldn't connect to db\n";
#     exit 1;
# }


# $db->disconnect;
# undef $db;

my $db = DBIx::Wrapper->connect("dbi:SQLite:dbname=$db_file", '', '');

ok($db, 'connect to db');

unless ($db) {
    BAIL_OUT("couldn't connect to db");
}

my $query = qq{SELECT * FROM test_table WHERE id=:'id' AND :: the_value=:value};
my $exec_args = { id => 5, value => 'five' };
($query, $exec_args) = $db->_bind_named_place_holders($query, $exec_args);
ok($query eq 'SELECT * FROM test_table WHERE id=? AND : the_value=?', 'bind_named_place_holders query');
ok(($exec_args->[0] == 5 and $exec_args->[1] eq 'five'), 'bind_name_place_holders args');


$db->native_query(qq{DROP TABLE IF EXISTS test_native_select_exec_loop});
$db->nativeQuery(qq{CREATE TABLE test_native_select_exec_loop (id int unsigned default 0 not null primary key, val int unsigned default 0 not null)});
$db->insert('test_native_select_exec_loop', { id => 1, val => 11 });
$db->insert('test_native_select_exec_loop', { id => 2, val => 12 });
$db->insert('test_native_select_exec_loop', { id => 3, val => 13 });
$db->insert('test_native_select_exec_loop', { id => 4, val => 14 });


my $exec_query = qq{SELECT * FROM test_native_select_exec_loop WHERE id=?};
my $loop = $db->nativeSelectExecLoop($exec_query);

for my $id (1, 2, 3, 4) {
    my $expected = $id + 10;
    my $row = $loop->next([ $id ]);
    ok($row->{val} == $expected, "test_native_select_exec_loop expect $expected");
}
undef $loop;
    

$db->insert('test_native_select_exec_loop', { id => 5, val => 11 });
$db->insert('test_native_select_exec_loop', { id => 6, val => 12 });
$db->insert('test_native_select_exec_loop', { id => 7, val => 13 });

my $multi_exec_loop_query = qq{SELECT * FROM test_native_select_exec_loop WHERE val=? order by id};
my $multi_loop = $db->nativeSelectMultiExecLoop($multi_exec_loop_query);
my $cnt = 0;
foreach my $val (11, 12, 13) {
    $cnt++;
    
    my $rows = $multi_loop->next([ $val ]);

    ok(($rows->[0]{id} == ($val - 10) and $rows->[1]{id} == ($val - 6)), "native_select_multi_exec_loop test $cnt");
}

$db->nativeQuery(qq{DROP TABLE test_native_select_exec_loop});


$db->native_query("DROP TABLE IF EXISTS test_native_select_mapping");
my $create = qq{CREATE TABLE test_native_select_mapping (id int unsigned default 0 not null primary key, val int unsigned default 0 not null)};
$db->nativeQuery($create);

$db->insert('test_native_select_mapping', { id => 1, val => 5, });
$db->insert('test_native_select_mapping', { id => 2, val => 6, });
$db->insert('test_native_select_mapping', { id => 3, val => 7 });
my $map = $db->nativeSelectDynaMapping(qq{SELECT * FROM test_native_select_mapping},
                                       [ 'id', 'val' ]);

ok($map->{'1'} eq '5', 'native_select_dyna_mapping expect 5');
ok($map->{'2'} eq '6', 'native_select_dyna_mapping expect 6');
ok($map->{'3'} eq '7', 'native_select_dyna_mapping expect 7');


$map = $db->nativeSelectMapping(qq{SELECT * FROM test_native_select_mapping},
                               );
ok($map->{'1'} eq '5', 'native_select_mapping expect 5');
ok($map->{'2'} eq '6', 'native_select_mapping expect 6');
ok($map->{'3'} eq '7', 'native_select_mapping expect 7');

# print Data::Dumper->Dump([ $map ], [ 'map' ]) . "\n";

my $row = $db->nativeSelect(qq{SELECT val FROM test_native_select_mapping WHERE id=?},
                            [ 3 ]);
ok($row->{val} == 7, 'native_select');

$row = $db->nativeSelect(qq{SELECT val FROM test_native_select_mapping WHERE id=:id},
                         { id => 3 });
ok($row->{val} == 7, 'native_select with named placeholders');

$row = $db->nativeSelect(qq{SELECT val FROM test_native_select_mapping WHERE id=:"id"},
                         { id => 3 });
ok($row->{val} == 7, 'native_select with named placeholders with double quotes');

$row = $db->nativeSelect(qq{SELECT val FROM test_native_select_mapping WHERE id=:'id'},
                         { id => 3 });
ok($row->{val} == 7, 'native_select with named placeholders with single quotes');


$db->update('test_native_select_mapping', { id => 3 }, { val => 8 });
$row = $db->nativeSelect(qq{SELECT val FROM test_native_select_mapping WHERE id=?},
                         [ 3 ]);
ok($row->{val} == 8, 'update');


$map = $db->nativeSelectRecordDynaMapping(qq{SELECT * FROM test_native_select_mapping},
                                          'id');
ok($map->{1}{val} eq '5', 'native_select_record_dynamapping 1');
ok($map->{2}{val} eq '6', 'native_select_record_dynamapping 2');
ok($map->{3}{val} eq '8', 'native_select_record_dynamapping 3');

$map = $db->nativeSelectRecordMapping(qq{SELECT * FROM test_native_select_mapping});
ok($map->{1}{val} eq '5', 'native_select_record_mapping 1');
ok($map->{2}{val} eq '6', 'native_select_record_mapping 2');
ok($map->{3}{val} eq '8', 'native_select_record_mapping 3');

$db->doQuery(qq{DROP TABLE test_native_select_mapping});


$db->native_query("DROP TABLE IF EXISTS test_table");
$db->native_query("CREATE TABLE test_table (id int unsigned auto_increment primary key, the_value varchar(32) default '' not NULL)");

# my $dbd_driver = $db->_getDbdDriver;
# print "driver=$dbd_driver\n";
# exit 0;

my $table = 'test_table';

my $rand = int(rand(100000));
my $data = { the_value => 'six' . $rand };
$db->insert($table, $data);

my $id = $db->getLastInsertId;
ok($id, 'get_last_insert_id');


$data = $db->update($table, { id => 1 }, {});
ok($data eq '0E', 'update without data');

$data = $db->smart_update($table, { id => 1 }, {});
ok($data eq '0E', 'smart_update without data');

$db->smart_update($table, { id => 10 }, { the_value => 'eleven' });
$val = $db->native_select_value("SELECT the_value FROM $table WHERE id=10");
ok($val eq 'eleven', 'smart_update_then_native_select_value 1');

$db->smart_update($table, { id => 10 }, { the_value => 'twelve' });
$val = $db->native_select_value("SELECT the_value FROM $table WHERE id=10");
ok($val eq 'twelve', 'smart_update_then_native_select_value 2');

$val = $db->select_value_from_hash($table, { id => 10 }, 'the_value');
ok($val eq 'twelve', 'select_value_from_hash');

$db->smartUpdate($table, { id => 9 }, { the_value => 'ten' });
$db->smartUpdate($table, { id => 10 }, { the_value => 'ten' });
$val = $db->select_value_from_hash_multi($table, { the_value => 'ten' }, 'id');
# ok( ($val->[0] == 9 or $val->[1] == 9) and (($val->[0] == 10 or $val->[1] == 10)),
#    'select_value_from_hash_multi');
ok( ($val->[0] == 9 and $val->[1] == 10) || ($val->[0] == 10 and $val->[1] == 9), 'select_value_from_hash_multi');


ok($db->exists($table, { the_value => 'ten' }), 'exists');

ok(! $db->exists($table, { the_value => 'never_insert_this_val' }), 'not exists');

$val = $db->native_select_values_array(qq{SELECT id FROM $table WHERE the_value="ten"});
ok( ($val->[0] == 9 and $val->[1] == 10) || ($val->[0] == 10 and $val->[1] == 9), 'native_select_values_array' );

$val = $db->selectFromHash($table, { id => 9 });
ok($val->{id} == 9 && $val->{the_value} eq 'ten', 'select_from_hash');

$val = $db->selectFromHash($table, { id => 9, the_value => 'ten' });
ok($val->{id} == 9 && $val->{the_value} eq 'ten', 'select_from_hash 2');


$val = $db->nativeSelect(qq{SELECT * FROM $table WHERE id=9});
ok($val->{the_value} eq 'ten', 'native_select');

$query = qq{SELECT * FROM $table WHERE id=? OR id=?};
$val = $db->nativeSelectMulti($query, [ 10, 9 ]);
ok( ($val->[0]{id} == 9 and $val->[1]{id} == 10) || ($val->[0]{id} == 10 and $val->[1]{id} == 9),
    'native_select_multi');

$query = qq{SELECT * FROM $table WHERE id=? OR id=?};
$loop = $db->nativeSelectLoop($query, [ 10, 9 ]);
$val = $loop->next;
$val2 = $loop->next;

ok( ($val->{id} == 10 and $val2->{id} == 9) || ($val->{id} == 9 and $val2->{id} == 10),
    'native_select_loop with placeholders');


$query = qq{SELECT * FROM $table WHERE id=9 OR id=10};
$loop = $db->nativeSelectLoop($query);
$val = $loop->next;
$val2 = $loop->next;

ok( ($val->{id} == 10 and $val2->{id} == 9) || ($val->{id} == 9 and $val2->{id} == 10),
    'native_select_loop without placeholders');

$query = qq{SELECT * FROM $table WHERE id=?};
$val = $db->nativeSelectWithArrayRef($query, [ 9 ]);

ok(($val->[0] eq '9' and $val->[1] eq 'ten'), 'native_select_with_array_ref');

$query = qq{SELECT * FROM $table WHERE id=? OR id=? order by id};
$val = $db->nativeSelectMultiWithArrayRef($query, [ 9, 10 ]);
ok( ($val->[0][0] == 9 and $val->[0][1] eq 'ten'
     and $val->[1][0] == 10 and $val->[1][1] eq 'ten'), 'native_select_multi_with_array_ref');


$db->insert($table, { id => 2, the_value => 'foo' });
$val = $db->native_select("select * from $table where id=2");
ok($val->{the_value} eq 'foo', 'insert');

$query = qq{UPDATE $table SET the_value="two two" WHERE id=?};
$val = $db->nativeQuery($query, [ 2 ]);

$val = $db->native_select(qq{select * from $table where id=?}, [ 2 ]);
ok($val->{the_value} eq 'two two', 'native_query');

$db->insert($table, { id => 3, the_value => 'foo' });
$db->insert($table, { id => 4, the_value => 'foo' });

$query = qq{UPDATE $table SET the_value=? WHERE id=?};
$loop = $db->nativeQueryLoop($query);

$loop->next([ 'three three', 3 ]);
$val = $db->native_select("select * from $table where id=3");
ok($val->{the_value} eq 'three three', 'native_query_loop 1');

$loop->next([ 'four four', 4]);
$val = $db->native_select("select * from $table where id=4");
ok($val->{the_value} eq 'four four', 'native_query_loop 2');

$val = $db->native_select_value("select the_value from $table where id=4");
ok($val eq 'four four', 'native_select_value');

# print "\n\n$num_tests tests\n\n";

unlink $db_file;

exit 0;

###############################################################################

sub write_config_file {
    my ($self, $conf_fh, $sqlite_db_path) = @_;

    my $content = $self->get_config_content($sqlite_db_path);
    print $conf_fh $content;
}

sub get_config_content {
    my ($self, $sqlite_db_path) = @_;
    
my $content = qq{<db test_db>
    dsn "dbi:SQLite:dbname=$sqlite_db_path"

    user ""
    password ""

    <attributes>
        RaiseError 1
        PrintError 1
    </attributes>
</db>
};

    return $content;
}
