use strict;
use warnings;
use lib 't/lib';
use Test::More tests => 5;
use Test::Exception;

use Dancer2;
use Dancer2::Plugin::DBIC;
use DBI;
use File::Temp qw(tempfile);

eval { require DBD::SQLite };
plan skip_all => 'DBD::SQLite required to run these tests' if $@;

my (undef, $dbfile) = tempfile(SUFFIX => '.db');

my (undef, $dbfile2) = tempfile(SUFFIX => '.db');

set plugins => {
    DBIC => {
        foo => {
            schema_class => 'Foo',
            dsn =>  "dbi:SQLite:dbname=$dbfile",
        },
    }
};

my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile");
ok $dbh->do(q{
    create table user (name varchar(100) primary key, age int)
}), 'Created sqlite test db.';

my @users = ( ['bob', 2] );
for my $user (@users) { $dbh->do('insert into user values(?,?)', {}, @$user) }

subtest 'schema' => sub {
    my $user = schema->resultset('User')->find('bob');
    is $user->age => '2', 'Bob is a baby.';
    $user = schema('foo')->resultset('User')->find('bob');
    is $user->age => '2', 'Found Bob via explicit schema name.';
};

subtest 'schema with special config' => sub {
    my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile2");
    ok $dbh->do(q{
        create table user (name varchar(100) primary key, age int)
    }), 'Created another sqlite test db.';

    my @schema_args = (
        'foo',
        {
            'schema_class' => 'Foo',
            'dsn'          => "dbi:SQLite:dbname=$dbfile2",
        },
    );

    my $user = schema(@schema_args)->resultset('User')->find('bob');
    is( $user, undef, 'Could not find user yet.');
};

subtest 'resultset' => sub {
    my $user = resultset('User')->find('bob');
    is $user->age => '2', 'Found Bob via resultset.';
    $user = rset('User')->find('bob');
    is $user->age => '2', 'Found Bob via rset.';
};

subtest 'invalid schema name' => sub {
    throws_ok { schema('bar')->resultset('User')->find('bob') }
        qr/schema bar is not configured/, 'Missing schema error thrown';
};

unlink $dbfile;
unlink $dbfile2;
