use strict;
use warnings;
use lib 't/lib';
use Test::More tests => 8;
use Test::Exception;

use Dancer2;
use Dancer2::Plugin::DBIC;
use DBI;
use File::Temp qw(tempfile);

eval { require DBD::SQLite };
plan skip_all => 'DBD::SQLite required to run these tests' if $@;

my (undef, $dbfile1) = tempfile(SUFFIX => '.db');
my (undef, $dbfile2) = tempfile(SUFFIX => '.db');

set plugins => {
    DBIC => {
        foo => {
            schema_class => 'Foo',
            dsn =>  "dbi:SQLite:dbname=$dbfile1",
        },
        bar => {
            schema_class => 'Foo',
            dsn =>  "dbi:SQLite:dbname=$dbfile2",
        },
    }
};

my $dbh1 = DBI->connect("dbi:SQLite:dbname=$dbfile1");
my $dbh2 = DBI->connect("dbi:SQLite:dbname=$dbfile2");

ok $dbh1->do(q{
    create table user (name varchar(100) primary key, age int)
}), 'Created sqlite test db.';

my @users = ( ['bob', 30] );
for my $user (@users) { $dbh1->do('insert into user values(?,?)', {}, @$user) }

ok $dbh2->do(q{
    create table user (name varchar(100) primary key, age int)
}), 'Created sqlite test db.';

@users = ( ['sue', 20] );
for my $user (@users) {
    $dbh2->do(q{ insert into user values(?,?) }, {}, @$user);
}

my $user = schema('foo')->resultset('User')->find('bob');
ok $user, 'Found bob.';
is $user->age => '30', 'Bob is getting old.';

$user = schema('bar')->resultset('User')->find('sue');
ok $user, 'Found sue.';
is $user->age => '20', 'Sue is the right age.';

throws_ok { schema('poo')->resultset('User')->find('bob') }
    qr/schema poo is not configured/, 'Missing schema error thrown';

throws_ok { schema->resultset('User')->find('bob') }
    qr/The schema default is not configured/,
    'Missing default schema error thrown';

unlink $dbfile1, $dbfile2;
