use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::SQLite::Test;

my $schema = DBIO::SQLite::Test->init_schema();

# make sure proper exceptions are thrown on unbalanced use
{
  my $rs = $schema->resultset('CD')->search({}, { select => \'count(me.cdid)'});

  lives_ok(sub {
    $rs->search({}, { '+select' => 'me.cdid' })->next
  }, 'Two dark selectors are ok');

  throws_ok(sub {
    $rs->search({}, { '+select' => 'me.cdid', '+as' => 'cdid' })->next
  }, qr/resultset contains an unnamed selector/, 'Unnamed followed by named is not');

  throws_ok(sub {
    $rs->search_rs({}, { prefetch => 'tracks' })->next
  }, qr/resultset contains an unnamed selector/, 'Throw on unaliased selector followed by prefetch');

  throws_ok(sub {
    $rs->search_rs({}, { '+select' => 'me.title', '+as' => 'title'  })->next
  }, qr/resultset contains an unnamed selector/, 'Throw on unaliased selector followed by +select/+as');
}

done_testing;
