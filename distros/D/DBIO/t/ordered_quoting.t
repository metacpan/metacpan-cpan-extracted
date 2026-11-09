use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBIO::Test;

# DBIO::Ordered (karr k393): the position column is an identifier, so the
# sibling shift renders it through the SQLMaker's quoting like every other
# column in the statement, and move_to takes a position, which is a
# non-negative integer and nothing else.

my $schema  = DBIO::Test->init_schema(no_deploy => 1);
my $storage = $schema->storage;
my $rs      = $schema->resultset('Employee');

subtest 'the sibling shift quotes the position column on both sides' => sub {
  my $e = $rs->new_result({ employee_id => 1, position => 1, name => 'Alice', group_id => 10 });
  $e->insert;
  $storage->reset_captured;
  $storage->mock(qr/SELECT.*"position".*FROM "employee"/i, [[2]]);
  $e->move_next;

  my @shift = grep { $_->{op} eq 'update' && $_->{sql} =~ /"position"\s*=\s*"position"\s*[-+]\s*1/ }
    $storage->captured_queries;
  ok scalar(@shift), 'the shift renders SET "position" = "position" - 1'
    or diag explain [ map { $_->{sql} } $storage->captured_queries ];
};

subtest 'the shift follows the SQLMaker\'s quote character' => sub {
  my $e = $rs->new_result({ employee_id => 2, position => 1, name => 'Bob', group_id => 10 });
  $e->insert;
  my $maker = $storage->sql_maker;
  my $old = $maker->quote_char;
  $maker->quote_char('`');
  $storage->reset_captured;
  $storage->mock(qr/SELECT.*position.*FROM/i, [[2]]);
  eval { $e->move_next };
  $maker->quote_char($old);

  ok( (grep { $_->{op} eq 'update' && $_->{sql} =~ /`position`\s*=\s*`position`\s*-\s*1/ } $storage->captured_queries),
    'the shift uses the quote character of the SQLMaker' )
    or diag explain [ map { $_->{sql} } $storage->captured_queries ];
};

subtest 'move_to takes a non-negative integer' => sub {
  my $e = $rs->new_result({ employee_id => 3, position => 5, name => 'Moe', group_id => 30 });
  $e->insert;

  my @bad = ({ '-and' => 1 }, [ 1 ], \'1', undef, '2; DROP', '1.5', '-1', '', "3\n");
  for my $bad (@bad) {
    my $label = !defined $bad ? 'undef' : ref $bad ? ref($bad) . ' reference' : "'" . ($bad =~ s/\n/\\n/r) . "'";
    throws_ok { $e->move_to($bad) } qr/position must be a non-negative integer/,
      "move_to($label) throws";
  }

  is $e->move_to(5), 0, 'a plain integer position still works (no-op on the current one)';
  is $e->move_to('5'), 0, 'an integer string works';
  is $e->move_to(0), 0, 'position 0 stays a no-op';
};

done_testing;
