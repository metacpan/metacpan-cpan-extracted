use Test;
BEGIN { plan(tests => 1) }

package TBeer;

require DBIx::SQLite::Simple::Table;
require Class::Gomor::Array;
our @ISA = qw(DBIx::SQLite::Simple::Table Class::Gomor::Array);

our @AS = qw(
   beer
   country
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

our @Fields = @AS;

1;

package main;

require DBIx::SQLite::Simple;
my $db = DBIx::SQLite::Simple->new(db => 'test-file.db');

my $tBeer = TBeer->new;
$tBeer->create unless $tBeer->exists;

my @entries;
for (qw(grim leffe bud)) {
   push @entries, TBeer->new(beer => $_, country => 'BE');
}

$tBeer->insert(\@entries);
$tBeer->commit;
$tBeer->delete(\@entries);
$tBeer->commit;
$tBeer->insert(\@entries);
$tBeer->commit;

my $content = $tBeer->select;
my $old = $content->[-1]->cgClone;
$content->[-1]->country('US');
$tBeer->update([ $content->[-1] ], $old);
$tBeer->commit;

$content = $tBeer->select;

print 'beer: ', $_->beer, ' country: ', $_->country, "\n"
   for @$content;

unlink('test-file.db');

ok(1);
