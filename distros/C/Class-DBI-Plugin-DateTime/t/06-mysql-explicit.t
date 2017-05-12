use strict;
BEGIN
{
    my @args;
    if (grep { ! exists $ENV{$_} }
        map { "MYSQL_${_}" } qw(DSN USER PASSWORD))
    {
        push @args, (skip_all => "Need to define MYSQL_DSN MYSQL_USER MYSQL_PASSWORD");
    } else {
        @args = (tests => 11);
    }

    require Test::More;
    Test::More->import(@args);
}

package PluginTest::MySQL;
use strict;
use base qw(Class::DBI);
use Class::DBI::Plugin::DateTime 'MySQL';

my $table    = "cdbi_plugin_dt_mysql";
my $dsn      = 'dbi:mysql:' . $ENV{MYSQL_DSN};
my $user     = $ENV{MYSQL_USER};
my $password = $ENV{MYSQL_PASSWORD};

PluginTest::MySQL->set_db(Main => ($dsn, $user, $password));
PluginTest::MySQL->db_Main->do(qq{
    CREATE TABLE $table (
        id INTEGER,
        a_datetime  DATETIME,
        a_date      DATE,
        a_timestamp TIMESTAMP,
        PRIMARY KEY(id)
    )
});

PluginTest::MySQL->table($table);
PluginTest::MySQL->columns(All => qw(id a_timestamp a_date a_datetime));
PluginTest::MySQL->has_timestamp('a_timestamp');
PluginTest::MySQL->has_datetime('a_datetime');
PluginTest::MySQL->has_date('a_date');

package main;
use strict;

eval {
    my $dt  = DateTime->now;
    my $obj = PluginTest::MySQL->create({
        id => 1,
        a_timestamp => $dt,
        a_datetime  => $dt,
        a_date      => $dt
    });
    ok($obj, "Object creation");
    is($obj->a_timestamp, $dt, "Timestamp match");
    is($obj->a_date, $dt->clone->truncate(to => 'day'), "date match");
    is($obj->a_datetime, $dt, "Datetime match");

    my $dt2 = DateTime->new(year => 2005, month => 7, day => 13, hour => 7, minute => 13, second => 20);
    ok($obj->a_timestamp($dt2));
    ok($obj->a_datetime($dt2));
    ok($obj->a_date($dt2));
    ok($obj->update);
    is($obj->a_timestamp, $dt2, "Timestamp match");
    is($obj->a_date, $dt2->clone->truncate(to => 'day'), "date match");
    is($obj->a_datetime, $dt2, "Datetime match");
};
die if $@;

PluginTest::MySQL->db_Main->do("DROP TABLE $table");
