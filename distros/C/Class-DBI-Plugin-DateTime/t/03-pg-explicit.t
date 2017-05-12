use strict;
BEGIN
{
    my @args;
    if (grep { ! exists $ENV{$_} }
        map { "POSTGRES_${_}" } qw(DSN USER PASSWORD))
    {
        push @args, (skip_all => "Need to define POSTGRES_DSN POSTGRES_USER POSTGRES_PASSWORD");
    } else {
        @args = (tests => 11);
    }

    require Test::More;
    Test::More->import(@args);
}

package PluginTest::Pg;
use strict;
use base qw(Class::DBI);
use Class::DBI::Plugin::DateTime 'Pg';

my $table    = "cdbi_plugin_dt_pg";
my $dsn      = 'dbi:Pg:' . $ENV{POSTGRES_DSN};
my $user     = $ENV{POSTGRES_USER};
my $password = $ENV{POSTGRES_PASSWORD};

PluginTest::Pg->set_db(Main => ($dsn, $user, $password));
PluginTest::Pg->db_Main->do(qq{
    CREATE TABLE $table (
        id INTEGER PRIMARY KEY,
        a_timestamp TIMESTAMP,
        a_date      DATE,
        a_time      TIME
    )
});

PluginTest::Pg->table($table);
PluginTest::Pg->columns(All => qw(id a_timestamp a_date a_time));
PluginTest::Pg->has_timestamp('a_timestamp');
PluginTest::Pg->has_date('a_date');
PluginTest::Pg->has_time('a_time');

package main;
use strict;

eval {
    my $dt  = DateTime->now;
    my $obj = PluginTest::Pg->create({
        id => 1,
        a_timestamp => $dt,
        a_date      => $dt,
        a_time      => $dt
    });
    ok($obj, "Object creation");
    is($obj->a_timestamp, $dt, "Timestamp match");
    is($obj->a_date, $dt->clone->truncate(to => 'day'), "date match");
    is($obj->a_time, $dt->clone->set(year => 1970, month => 1, day => 1), "time match");

    my $dt2 = DateTime->new(year => 2005, month => 7, day => 13, hour => 7, minute => 13, second => 20);
    ok($obj->a_timestamp($dt2));
    ok($obj->a_date($dt2));
    ok($obj->a_time($dt2));
    ok($obj->update);
    is($obj->a_timestamp, $dt2, "Timestamp match");
    is($obj->a_date, $dt2->clone->truncate(to => 'day'), "date match");
    is($obj->a_time, $dt2->clone->set(year => 1970, month => 1, day => 1), "time match");
};

PluginTest::Pg->db_Main->do("DROP TABLE $table");
