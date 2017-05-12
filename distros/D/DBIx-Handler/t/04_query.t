use strict;
use warnings;
use DBIx::Handler;
use Test::More;
use Test::Requires 'DBD::SQLite';

unlink './query_test.db';
my $handler = DBIx::Handler->new('dbi:SQLite:./query_test.db','','');
isa_ok $handler, 'DBIx::Handler';
isa_ok $handler->dbh, 'DBI::db';

$handler->dbh->do(q{
    create table query_test (
        name varchar(10) NOT NULL,
        PRIMARY KEY (name)
    );
});

subtest 'query' => sub {
    $handler->query(q{insert into query_test (name) values (?)}, 'nekokak');
    my $sth = $handler->query('select * from query_test order by name asc');
    ok $sth;
    is_deeply $sth->fetchrow_hashref, +{name => 'nekokak'};

    $handler->query(q{insert into query_test (name) values (?)}, ['zigorou']);
    $sth = $handler->query('select * from query_test order by name asc');
    ok $sth;
    is_deeply $sth->fetchrow_hashref, +{name => 'nekokak'};
    is_deeply $sth->fetchrow_hashref, +{name => 'zigorou'};

    $handler->query(q{insert into query_test (name) values (:name)}, +{name => 'xaicron'});
    $sth = $handler->query('select * from query_test order by name asc');
    ok $sth;
    is_deeply $sth->fetchrow_hashref, +{name => 'nekokak'};
    is_deeply $sth->fetchrow_hashref, +{name => 'xaicron'};
    is_deeply $sth->fetchrow_hashref, +{name => 'zigorou'};

    $sth = $handler->query('select * from query_test where name = :name', +{name => 'nekokak'});
    ok $sth;
    is_deeply $sth->fetchrow_hashref, +{name => 'nekokak'};
    ok not $sth->fetchrow_hashref;
};

{
    package Mock::Result;
    sub new {
        my ($class, $handler, $sth) = @_;
        bless {
            handler => $handler,
            sth     => $sth,
        }
    }
    sub get_row { $_[0]->{sth}->fetchrow_hashref }
}

subtest 'query with result_class' => sub {
    $handler->query(q{insert into query_test (name) values ('tomita')});
    $handler->result_class('Mock::Result');
    my $obj = $handler->query('select * from query_test where name = :name', +{name => 'tomita'});
    isa_ok $obj, 'Mock::Result';
    is_deeply $obj->get_row, +{name => 'tomita'};
};

subtest 'query with trace_query' => sub {
    $handler->trace_query(1);
    my $sql = $handler->trace_query_set_comment('select * from query_test where name = ?');
    note $sql;
    like $sql, qr/.+at line.+/;
};

subtest 'query with trace_query and trace_ignore_if' => sub {
    my $called = 0;
    $handler->trace_query(1);
    $handler->trace_ignore_if(sub {
        my (undef, $file, $line) = @_;
        $called++;
        return $file eq __FILE__ && $line == __LINE__+3;
    });

    my $code = sub { $handler->query('select * from query_test where name = ?'); }; # ignore this
    $code->(); my ($line, $file) = (__LINE__, __FILE__);
    my $sql = $DBI::lasth->{Statement};
    note $sql;
    like $sql, qr!^/\* \Q$file\E at line \Q$line\E \*/!;
    is $called, 2;
};

unlink './query_test.db';

done_testing;
