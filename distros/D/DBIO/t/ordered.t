use strict;
use warnings;

use Test::More;

use DBIO::Test;

# Exercises the DBIO::Ordered SYNOPSIS/core moves against the shared
# DBIO::Test::Schema::Employee fixture, which already loads Ordered
# (position column "position", grouping columns "group_id" et al).
#
# LIMITATION (documented per the ticket brief): DBIO::Test::Storage never
# persists rows -- every SELECT returns whatever was last registered via
# ->mock, not a live reflection of prior inserts/updates. So a *sequence*
# of moves across many independently-tracked sibling rows can't be modeled
# end-to-end purely from mock storage. What we assert instead, faithfully:
#
#   * position changes on the invoking row are real, local, and driven by
#     genuine UPDATE SQL (Ordered::move_to sets the column via a normal
#     Row update, not just bookkeeping) -- this is the actual behaviour a
#     caller observes;
#   * the SQL Ordered emits for a move (sibling-shift UPDATE, own-row
#     UPDATE, wrapped in a transaction) matches what the component
#     documents itself as doing;
#   * the boundary case (no further sibling) is honoured when the mocked
#     sibling lookup returns no rows.

my $schema  = DBIO::Test->init_schema(no_deploy => 1);
my $storage = $schema->storage;
my $rs      = $schema->resultset('Employee');

subtest 'move_next swaps with the next sibling and emits the expected SQL' => sub {
  my $e1 = $rs->new_result({ employee_id => 1, position => 1, name => 'Alice', group_id => 10 });
  $e1->insert;

  $storage->reset_captured;
  # move_next looks up the next sibling's position via a SELECT -- mock it
  # as if a sibling currently sits at position 2.
  $storage->mock(qr/SELECT.*"position".*FROM "employee"/i, [[2]]);

  my $ret = $e1->move_next;
  is $ret, 1, 'move_next reports success';
  is $e1->position, 2, 'the row moved from position 1 to 2';

  my @q = $storage->captured_queries;
  ok((grep { $_->{op} eq 'update' && $_->{sql} =~ /"position"\s*=\s*position\s*-\s*1/ } @q),
    'a sibling-shift UPDATE was emitted');
  ok((grep { $_->{op} eq 'update' && $_->{sql} =~ /SET "position" = \?.*WHERE "employee_id" = \?/ } @q),
    'the row\'s own position UPDATE was emitted');
  ok((grep { $_->{op} eq 'txn_begin' } @q) && (grep { $_->{op} eq 'txn_commit' } @q),
    'the move was wrapped in a transaction');
};

subtest 'move_previous swaps with the previous sibling' => sub {
  my $e2 = $rs->new_result({ employee_id => 2, position => 3, name => 'Bob', group_id => 10 });
  $e2->insert;

  $storage->reset_captured;
  my $ret = $e2->move_previous;
  is $ret, 1, 'move_previous reports success';
  is $e2->position, 2, 'the row moved from position 3 to 2';
};

subtest 'move_next at the end of the list is a documented no-op' => sub {
  my $e3 = $rs->new_result({ employee_id => 3, position => 1, name => 'Zed', group_id => 20 });
  $e3->insert;

  $storage->reset_captured;
  # No sibling rows at all for this group -- the mocked SELECT returns none.
  $storage->mock(qr/SELECT.*"position".*FROM "employee"/i, []);

  my $ret = $e3->move_next;
  is $ret, 0, 'move_next returns 0 when already last';
  is $e3->position, 1, 'position is unchanged when the move is a no-op';
};

subtest 'move_to a position it already occupies is a no-op' => sub {
  my $e4 = $rs->new_result({ employee_id => 4, position => 5, name => 'Moe', group_id => 30 });
  $e4->insert;

  is $e4->move_to(5), 0, 'move_to the current position returns 0';
  is $e4->position, 5, 'position is unchanged';
};

subtest 'siblings returns a resultset ordered by the position column' => sub {
  my $e5 = $rs->new_result({ employee_id => 5, position => 1, name => 'Amy', group_id => 40 });
  $e5->insert;

  my $q = ${ $e5->siblings->as_query };
  like $q->[0], qr/ORDER BY "position"/, 'siblings() orders by the position column, per the SYNOPSIS';
};

done_testing;
