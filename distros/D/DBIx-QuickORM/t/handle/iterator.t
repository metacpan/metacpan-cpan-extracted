use Test2::V0 -target => 'DBIx::QuickORM', '!meta', '!pass';
use DBIx::QuickORM;
use Carp::Always;
use Scalar::Util qw/blessed/;
use Time::HiRes qw/sleep/;

use lib 't/lib';
use DBIx::QuickORM::Test;

sub SCHEMA_DIR { 't/handle/schema' }

do_for_all_dbs {
    my $db = shift;

    db mydb => sub {
        dialect curdialect();
        db_name 'quickdb';
        connect sub { $db->connect };
    };

    orm my_orm => sub {
        db 'mydb';
        autofill;
    };

    ok(my $orm = orm('my_orm')->connect, "Got a connection");
    my $h = $orm->handle('example');
    ok($h->insert({name => 'a'}), "Inserted a row");
    ok($h->insert({name => 'b'}), "Inserted a row");
    ok($h->insert({name => 'c'}), "Inserted a row");
    ok($h->insert({name => 'd'}), "Inserted a row");
    ok($h->insert({name => 'e'}), "Inserted a row");

    subtest rows => sub {
        my @all;
        my $iter = $h->iterator;
        while (my $i = $iter->next) { push @all => $i }
        is(@all, 5, "Got all 5 items");
        isa_ok($_, ['DBIx::QuickORM::Row'], "Row is of correct type") for @all;
    };

    subtest data_only => sub {
        my @all;
        my $iter = $h->data_only->iterator;
        while (my $i = $iter->next) { push @all => $i }
        is(@all, 5, "Got all 5 items");
        ok(!blessed($_), "Data, not blessed") for @all;
    };

    # sqlite does not support async
    unless (curdialect() =~ m/sqlite/i) {
        subtest async => sub {
            my $iter = $h->async->iterator;
            sleep 0.2 until $iter->ready;
            my @all;
            while (my $i = $iter->next) { push @all => $i }
            is(@all, 5, "Got all 5 items");
            isa_ok($_, ['DBIx::QuickORM::Row'], "Row is of correct type") for @all;
        };

        subtest aside => sub {
            my $iter = $h->aside->iterator;
            sleep 0.2 until $iter->ready;
            my @all;
            while (my $i = $iter->next) { push @all => $i }
            is(@all, 5, "Got all 5 items");
            isa_ok($_, ['DBIx::QuickORM::Row'], "Row is of correct type") for @all;
        };

        subtest forked => sub {
            my $iter = $h->forked->iterator;
            sleep 0.2 until $iter->ready;
            my @all;
            while (my $i = $iter->next) { push @all => $i }
            is(@all, 5, "Got all 5 items");
            isa_ok($_, ['DBIx::QuickORM::Row'], "Row is of correct type") for @all;
        };
    }
};

done_testing;

