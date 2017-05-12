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

my $table_name = "my_crate_test_table_error";

{ #delete table
    $sth = $dbh->prepare("drop table if exists $table_name");
    $sth->execute();
}

{ #execute on unknown table
    $sth = $dbh->prepare("select * from $table_name");
    my $r = $sth->execute();
    ok(!$r);
    is($sth->err, 4041);
    like  ($sth->errstr, qr/doc\.my_crate_test_table_error.*unknown/, "select from unknown table");
}

{
    $sth = $dbh->prepare("create table $table_name (id int primary key)");
    my $ret = $sth->execute();
    is($ret, 1);
    is($sth->errstr, undef);
}

{
    $sth = $dbh->prepare("create table $table_name (id int primary key)");
    my $ret = $sth->execute();
    is($ret, undef);
    like  ($sth->errstr, qr/doc\.my_crate_test_table_error.*already exists/, "create already exist table");
    is($sth->err, 4093);
}

{ #create invalid table name

    $sth = $dbh->prepare("create table _XXY (id int primary key)");
    my $ret = $sth->execute();
    ok(!$ret);
    is($sth->err, 4002);
    like  ($sth->errstr, qr/_xxy.*?is invalid/, "invalid table name");
}

{ #delete table
    $sth = $dbh->prepare("drop table if exists $table_name");
    $sth->execute();
}

done_testing(12);
