#!/usr/bin/perl
use Test::More tests => 27;
use strict;
use warnings;

my $conn = { dsn => "dbi:SQLite:dbname=testfile.sql" };

unlink "testfile.sql";
END { unlink "testfile.sql" }

use DBIx::Abstract;

my $dsn;

my $dbh;
eval {
    $dbh = DBIx::Abstract->connect($conn);
}; is(ref($dbh), 'DBIx::Abstract', 'connect dbname');


eval {
    $dbh->disconnect if $dbh;
    my $dbi = DBI->connect($conn->{'dsn'},$conn->{'user'},$conn->{'password'});
    $dbh = DBIx::Abstract->connect($dbi);
}; is(ref($dbh), 'DBIx::Abstract', 'connect with dbi object');

unlink('test.log');

eval {
    $dbh->disconnect if $dbh;
    $dbh = DBIx::Abstract->connect($conn,{
        loglevel=>5,
        logfile=>'test.log',
        });
}; is($@ || ref($dbh), 'DBIx::Abstract', 'connect db');

eval {
    $dbh->disconnect if $dbh;
    $dbh->reconnect if $dbh;
};

ok( ! $@, "Reconnect: No error");
ok( $dbh, "Reconnect: Database handle exists");
ok( $dbh->connected(), "Reconnect: We are indeed connected." );

eval {
    my $dbih = $dbh->{'dbh'};
    my $dbh2 = DBIx::Abstract->connect($dbih);
    $dbh2->DESTROY();
};
ok( ! $@, "connect w/dbhandle and destroy: No error");
ok( $dbh, "connect w/dbhandle and destroy: Database handle exists");
ok( $dbh->connected(), "connect w/dbhandle and destroy: We are indeed connected." );

is( @{$dbh->{'CLONES'}}, 0, "no clones yet");
eval {
   eval {
       my $dbh2 = $dbh->clone();
       is( @{$dbh->{'CLONES'}}, 1, "one clone now");
   };
   is( @{$dbh->{'CLONES'}}, 0, "clone cleaned up");
};
ok( ! $@, "clone without error");

eval {
    $dbh->query('create table foo (id int null,name char(30) not null,value char(30) null)');
    $dbh->query('create table bar (id int null,foo_id int null,name char(30) not null)');
}; is($@,'','create');

my $test_rows = 4;
eval {
    for ( 1..$test_rows ) {
        $dbh->insert('foo',{id=>$_,name=>"test$_",value=>"value$_"});
        $dbh->insert('bar',{id=>$_,foo_id=>($test_rows+1)-$_,name=>"test$_"});
    }
}; is($@,'','insert');

eval {
    $dbh->update('foo',{name=>'blat', value=>'bonk'},{id=>2});
}; is($@,'','update');

my $count = 0;
eval {
    $dbh->select('*','foo',{id=>['<',10]});
    $dbh->rows;
    while (my @foo = $dbh->fetchrow_array) { $count ++ }
}; 
ok( !$@, "select without exception" );
is( $count, $test_rows, "select ($count==$test_rows)" );


eval {
    my @foo; @foo = ({id=>['<',10]},'and',\@foo);
    $dbh->select('*','foo',\@foo);
    if ($dbh->rows) {
        while (my @foo = $dbh->fetchrow_array) {  }
    }
}; is($@?1:0,1,'circular where');

eval {
    $dbh->select('*','foo',[{id=>['<',10]},'and',[{name=>'blat'},'or',{value=>'bonk'}]]);
    $dbh->rows;
    while (my @foo = $dbh->fetchrow_array) { }
}; is($@,'','select with complex where');

eval {
    $dbh->select({
        fields=>'count(foo.id)',
        tables=>'foo,bar',       
        'join'=>[
                 'foo.id = bar.foo_id', 
                 ],
        where=>{'foo.id'=>['<',10]},
        group=>'bar.name',
        });
    if ($dbh->rows) {
        while (my @foo = $dbh->fetchrow_array) { }
    }
}; is($@,'','select with join');

eval {
    $dbh->delete('foo',{id=>['like','%']});
}; is((!$@ and $test_rows==$dbh->rows)?1:0,1,'delete');

eval {
    $dbh->query('drop table foo');
    $dbh->query('drop table bar');
}; ok( !$@,'drop');

ok( $dbh->connected, "verified connection" );

eval { 
    $dbh->disconnect;
}; ok( ! $@,'disconnect');

ok( ! $dbh->connected, "verified disconnection" );

if (open(LOG,'test.log')) {
    my @log = <LOG>;
    close(LOG);
    my @data;
    my $ignore = 0;
    while (<DATA>) {
        if (/^[^\t]+\t0\t([^\t]+)\tSTART\n$/ and $1 ne $$conn{'dialect'}) {
            $ignore = $1;
        } elsif ($ignore and /^[^\t]+\t0\t$ignore\tEND\n$/) {
            $ignore = 0;
        } elsif (!$ignore) {
            push(@data,$_);
        }
    }
    s/^[^\t]+/DATE/g for @log, @data;
    s/^(DATE\t5\t(?:Rec|C)onnect\t).*$/$1CONNECT ARGS/ for @log, @data;
    s/^(DATE\t5\tconnected\t)\n$/${1}0\n/ for @log, @data;
    if (is_deeply( \@log, \@data, "SQL log matches expectations" )) {
        unlink('test.log');
    }
}

__DATA__
Tue Jan 14 12:42:50 2014	5	Option change	loglevel		5
Tue Jan 14 12:42:50 2014	5	Connect	dsn=>dbi:SQLite:dbname=testfile.sql
Tue Jan 14 12:42:50 2014	5	connected	
Tue Jan 14 12:42:50 2014	5	reconnect	success
Tue Jan 14 12:42:50 2014	5	Reconnect
Tue Jan 14 12:42:50 2014	5	connected	1
Tue Jan 14 12:42:50 2014	5	connected	1
Tue Jan 14 12:42:50 2014	5	Cloned
Tue Jan 14 12:42:50 2014	3	create table foo (id int null,name char(30) not null,value char(30) null)
Tue Jan 14 12:42:50 2014	3	create table bar (id int null,foo_id int null,name char(30) not null)
Tue Jan 14 12:42:50 2014	1	INSERT INTO foo ( id, name, value) VALUES ('1', 'test1', 'value1')
Tue Jan 14 12:42:50 2014	1	INSERT INTO bar ( foo_id, id, name) VALUES ('4', '1', 'test1')
Tue Jan 14 12:42:50 2014	1	INSERT INTO foo ( id, name, value) VALUES ('2', 'test2', 'value2')
Tue Jan 14 12:42:50 2014	1	INSERT INTO bar ( foo_id, id, name) VALUES ('3', '2', 'test2')
Tue Jan 14 12:42:50 2014	1	INSERT INTO foo ( id, name, value) VALUES ('3', 'test3', 'value3')
Tue Jan 14 12:42:50 2014	1	INSERT INTO bar ( foo_id, id, name) VALUES ('2', '3', 'test3')
Tue Jan 14 12:42:50 2014	1	INSERT INTO foo ( id, name, value) VALUES ('4', 'test4', 'value4')
Tue Jan 14 12:42:50 2014	1	INSERT INTO bar ( foo_id, id, name) VALUES ('1', '4', 'test4')
Tue Jan 14 12:42:50 2014	1	UPDATE foo SET name='blat', value='bonk' WHERE id = '2'
Tue Jan 14 12:42:50 2014	2	SELECT * FROM foo WHERE id < '10'
Tue Jan 14 12:42:50 2014	5	rows
Tue Jan 14 12:42:50 2014	4	fetchrow_array
Tue Jan 14 12:42:50 2014	4	fetchrow_array
Tue Jan 14 12:42:50 2014	4	fetchrow_array
Tue Jan 14 12:42:50 2014	4	fetchrow_array
Tue Jan 14 12:42:50 2014	4	fetchrow_array
Tue Jan 14 12:42:50 2014	0	Where parser iterated too deep (limit of 20)
Tue Jan 14 12:42:50 2014	2	SELECT * FROM foo WHERE (id < '10') and ((name = 'blat') or (value = 'bonk'))
Tue Jan 14 12:42:50 2014	5	rows
Tue Jan 14 12:42:50 2014	4	fetchrow_array
Tue Jan 14 12:42:50 2014	4	fetchrow_array
Tue Jan 14 12:42:50 2014	2	SELECT count(foo.id) FROM foo,bar WHERE (foo.id < '10') and ( foo.id = bar.foo_id ) GROUP BY bar.name
Tue Jan 14 12:42:50 2014	5	rows
Tue Jan 14 12:42:50 2014	1	DELETE FROM foo WHERE id like '%'
Tue Jan 14 12:42:50 2014	5	rows
Tue Jan 14 12:42:50 2014	3	drop table foo
Tue Jan 14 12:42:50 2014	3	drop table bar
Tue Jan 14 12:42:50 2014	5	connected	1
Tue Jan 14 12:42:50 2014	5	connected	
