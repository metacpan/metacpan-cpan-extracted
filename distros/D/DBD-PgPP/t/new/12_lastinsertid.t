# Test fetching

use Test::More;
use DBI;
use strict;

if (defined $ENV{DBI_DSN}) {
    plan tests => 5;
}
else {
    plan skip_all => 'Cannot run test unless DBI_DSN is defined. See the README file.';
}

my $db = DBI->connect($ENV{DBI_DSN}, $ENV{DBI_USER}, $ENV{DBI_PASS},
                       {RaiseError => 1, PrintError => 0, AutoCommit => 1});

$db->do($_) for (
    'CREATE TEMPORARY TABLE t (id serial primary key, s text not null)',
    'CREATE TEMPORARY TABLE bad (id int primary key)',
);

insert($db, 'foo');
is(id($db), 1, "First last_insert_id works");

insert($db, 'bar');
is(id($db), 2, "Second last_insert_id works");

is(id($db), 2, "Repeated last_insert_id works");

my $bad_id = eval { id($db, 'bad') };
like($@, qr/\bNo suitable column /,
     "Exception for last_insert_id on serial-free tables");
is($bad_id, undef, "Undefined last_insert_id for serial-free tables");

sub insert {
    my ($db, $s) = @_;
    $db->do('INSERT INTO t (s) VALUES (?)', undef, $s);
}

sub id {
    my ($db, $table) = @_;
    return $db->last_insert_id(undef, '', $table || 't', undef);
}
