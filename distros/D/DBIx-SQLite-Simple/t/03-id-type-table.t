use Test;
BEGIN { plan(tests => 1) }

package TPub;

require DBIx::SQLite::Simple::Table;
require Class::Gomor::Array;
our @ISA = qw(DBIx::SQLite::Simple::Table Class::Gomor::Array);

our @AS = qw(
   idPub
   pub
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

our $Id     = $AS[0];
our @Fields = @AS[1..$#AS];

1;

package main;

require DBIx::SQLite::Simple;
my $db = DBIx::SQLite::Simple->new(db => 'test-file.db');

my $tPub = TPub->new;
$tPub->create unless $tPub->exists;

my @entries;
for (qw(corner friends)) {
   push @entries, TPub->new(pub => $_);
}

$tPub->insert(\@entries);
$tPub->commit;
$tPub->delete(\@entries);
$tPub->commit;
$tPub->insert(\@entries);
$tPub->commit;

print 'id=1 entry: ', $tPub->lookupString('pub', idPub => 1), "\n";
print 'id=2 entry: ', $tPub->lookupString('pub', idPub => 2), "\n";

my $new = $tPub->select(idPub => 2);
$new->[0]->pub('newFriends');
$tPub->update($new);
$tPub->commit;

print 'corner id:     ', $tPub->lookupId(pub => 'corner'),     "\n";
print 'newFriends id: ', $tPub->lookupId(pub => 'newFriends'), "\n";

my $content = $tPub->select;
for (@$content) {
   print 'id=', $_->idPub, ' entry: ', $_->pub, "\n";
}

unlink('test-file.db');

ok(1);
