use Test::More tests => 3;
use warnings;
use strict;
use lib "t/lib";
use TestSchema;
use DBICx::TestDatabase;

my $NOW = \"datetime('now')";

my $schema = DBICx::TestDatabase->new("TestSchema");

my $root = $schema->resultset('TreeData2')->create({ content => 'root' });
my $last = $root;

for (1 .. 10) {
  $last = $schema->resultset('TreeData2')->create({ content => $_, parent => $last });
}

my $middle = $schema->resultset('TreeData2')->search({ content => 5 })->first;

my @found = $root->grandchildren;
is(scalar @found, 10, 'root has 10 grandchildren');

@found = $middle->grandchildren;
is(scalar @found, 5, 'middle has 5 grandchildren');

@found = $last->grandchildren;
is(scalar @found, 0, 'leaf has 0 grandchildren');
