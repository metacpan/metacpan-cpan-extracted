use strict;
use warnings;
use lib './lib';
use DBI;
use DBD::Crate;
use Test::More;
use Data::Dumper;

if (!$ENV{CRATE_HOST}) {
    plan skip_all => 'You need to set $ENV{CRATE_HOST} to run tests';
}

my $dbh = DBI->connect( 'dbi:Crate:' . $ENV{CRATE_HOST} );

ok($dbh);
my $sth;

{ #delete table
    $sth = $dbh->prepare("drop table if exists my_crate_test_table1");
    $sth->execute();
}

$sth = $dbh->prepare(qq~
    create table my_crate_test_table1 (
        id int primary key,
        content string,
        INDEX content_ft using fulltext (content)
    ) with (number_of_replicas = '0-all', column_policy = 'dynamic')
~);

ok($sth);

my $r = $sth->execute();
is($r, 1);

my $i = 0;
{ ##insert some data    
    $sth = $dbh->prepare("insert into my_crate_test_table1 (id, content) values (?, ?)");
    my $r = $sth->execute($i++, "Hello There");
    is($r, 1);
    my $r2 = $sth->execute($i++, "Hello There 2");
    is($r2, 1);
    sleep 2; #give crate some time to index
}

{ ##get table data
    my $i = 0;
    $sth = $dbh->prepare("select id, content from my_crate_test_table1 where id = ?");
    my $r = $dbh->selectrow_hashref($sth, { Slice => {} }, 0);
    is(ref $r, "HASH");
    is($r->{id}, 0);
    is($r->{content}, "Hello There");
}


{ ##get table data 2
    my $i = 0;
    $sth = $dbh->prepare("select id, content from my_crate_test_table1 where id >= ? ORDER BY id");
    my $r = $dbh->selectall_arrayref($sth, { Slice => {} }, 0);
    is(scalar @{$r}, 2);

    is($r->[0]->{id}, 0);
    is($r->[1]->{id}, 1);

    is($r->[0]->{content}, "Hello There");
    is($r->[1]->{content}, "Hello There 2");
}

{ ## this is a dynamic table we can add new columns on fly
    $sth = $dbh->prepare("insert into my_crate_test_table1 (id, content, new_field) values (?, ?, ?)");
    my $ret = $sth->execute($i++, "Hello There 3", "New Content Here");
    is($ret, 1);
    sleep 1; #give crate some time to index

    $sth = $dbh->prepare("select id, content, new_field from my_crate_test_table1 where id >= ? ORDER BY id");
    my $r = $dbh->selectall_arrayref($sth, { Slice => {} }, 0);
    is(scalar @{$r}, 3);

    is($r->[0]->{id}, 0);
    is($r->[1]->{id}, 1);
    is($r->[2]->{id}, 2);

    is($r->[0]->{content}, "Hello There");
    is($r->[1]->{content}, "Hello There 2");
    is($r->[2]->{content}, "Hello There 3");

    is($r->[0]->{new_field}, undef);
    is($r->[1]->{new_field}, undef);
    is($r->[2]->{new_field}, "New Content Here");
}

{ #delete table
    my $sth = $dbh->prepare("drop table if exists my_crate_test_table1");
    ok($sth->execute());
}

done_testing(25);
