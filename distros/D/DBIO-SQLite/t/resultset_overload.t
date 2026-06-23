use strict;
use warnings;

use Test::More;
use DBIO::SQLite::Test;
my $schema = DBIO::SQLite::Test->init_schema();

{
  my $rs = $schema->resultset("CD")->search({});

  ok $rs->count;
  is $rs, $rs->count, "resultset as number with results";
  ok $rs,             "resultset as boolean always true";
}

{
  my $rs = $schema->resultset("CD")->search({ title => "Does not exist" });

  ok !$rs->count;
  is $rs, $rs->count, "resultset as number without results";
  ok $rs,             "resultset as boolean always true";
}

done_testing;
