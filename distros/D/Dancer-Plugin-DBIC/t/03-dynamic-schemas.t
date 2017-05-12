# Test dynamic schema loading by not providing a schema_class config option.
# These tests require DBIx::Class::Schema::Loader to be installed

use strict;
use warnings;
use Test::More tests => 3;

use Dancer qw(:syntax !pass);
use Dancer::Plugin::DBIC;
use DBI;
use File::Temp qw(tempfile);
use Test::Requires qw(
    DBD::SQLite DBIx::Class::Schema::Loader
);

my (undef, $dbfile) = tempfile SUFFIX => '.db';

set plugins => {
    DBIC => {
        foo => {
            dsn =>  "dbi:SQLite:dbname=$dbfile",
        }
    }
};

my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile");
ok $dbh->do(q{
    create table user (name varchar(100) primary key, age int)
}), 'Created sqlite test db.';

my @users = ( ['bob', 40] );
for my $user (@users) { $dbh->do('insert into user values(?,?)', {}, @$user) }

my $user = schema('foo')->resultset('User')->find('bob');

ok $user, 'Found bob.';
is $user->age => '40', 'bob is even older';

unlink $dbfile;
