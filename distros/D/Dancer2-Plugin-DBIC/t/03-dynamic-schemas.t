# Test dynamic schema loading by not providing a schema_class config option.
# These tests require DBIx::Class::Schema::Loader to be installed

use strict;
use warnings;
use Test::More;

use Dancer2;
use Dancer2::Plugin::DBIC;
use DBI;
use File::Temp qw(tempfile);

eval { require DBD::SQLite; require DBIx::Class::Schema::Loader };
if ($@) {
    plan skip_all =>
        'DBD::SQLite and DBIx::Class::Schema::Loader required for these tests';
} else {
    plan tests => 3;
}

my (undef, $dbfile) = tempfile(SUFFIX => '.db');

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
is $user->age => '40', 'Bob is even older.';

unlink $dbfile;
