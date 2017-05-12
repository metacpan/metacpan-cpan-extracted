use Test::Modern;

use DBI;
use DBICx::Sugar qw(config rset schema);
use File::Temp qw(tempfile);
use Test::Requires {
    'DBD::SQLite'                  => 0,
    'Moose'                        => 0.98,
    'MooseX::Types'                => 0.21,
    'MooseX::Types::LoadableClass' => 0.011,
};

plan tests => 8;

my @dbfiles = map { (tempfile SUFFIX => '.db' )[1] } 1..3;

my @dbh = (
    DBI->connect("dbi:SQLite:dbname=$dbfiles[1]"),
    DBI->connect("dbi:SQLite:dbname=$dbfiles[2]")
);

ok $dbh[0]->do('create table user (name varchar(100) primary key, age int)');
ok $dbh[1]->do('create table user (name varchar(100) primary key, age int)');

$dbh[0]->do('insert into user values(?,?)', {}, 'bob', 20);
$dbh[1]->do('insert into user values(?,?)', {}, 'bob', 30);

config({
    default => {
        dsn          => "dbi:SQLite:dbname=$dbfiles[0]",
        schema_class => 'Foo',
        replicated => {
            balancer_type => '::Random',
            replicants => [
                [ "dbi:SQLite:dbname=$dbfiles[1]" ],
                [ "dbi:SQLite:dbname=$dbfiles[2]" ],
            ],
        },
    },
});

schema->deploy;

# add a 10 year old bob to master
ok rset('User')->create({ name => 'bob', age => 10 });

# should find an older bob from one of the replicants
is rset('User')->count({ name => 'bob', age => { '>=', 20 } }), 1,
    'found older bob in one of the replicants';

# now force the query to use the master db, which has the 10 year old bob
is rset('User')->count({ name => 'bob', age => 10 }, {force_pool => 'master'}),
    1, 'found the 30 year old bob in the master db';

my %set = ();
for (1 .. 100) {
    my $bob = rset('User')->single({ name => 'bob' });
    $set{$bob->age}++;
}
is keys %set => 2, 'random balancer accessed both replicants'
    or diag explain \%set;
ok $set{20} && $set{30};

unlink @dbfiles;
