#!perl

use strict;
use warnings;
use lib 't/tlib';
use Test::More;
use Test::Fatal;
use DBICx::Hooks::Registry;
use S;

### Setup
my $db   = S->test_db;
my $u_rs = $db->resultset('U');
my $b_rs = $db->resultset('B');


### Hook
is(
  exception {
    dbic_hooks_register('S::Result::U', 'create', \&on_create_or_update);
  },
  undef,
  'Register create hook ok'
);
is(
  exception {
    dbic_hooks_register('S::Result::U', 'update', \&on_create_or_update);
  },
  undef,
  'Register update hook ok'
);
is(
  exception {
    dbic_hooks_register('S::Result::U', 'delete', \&on_delete);
  },
  undef,
  'Register delete hook ok'
);


### Test them
my $u = $u_rs->create({u => 'Mini Me'});
my $b = $b_rs->find($u->id);
is($b->b, 'MINI ME', 'Proper slave row value after create');

$u->update({u => 'Maxi You'});
$b->discard_changes;
is($b->b, 'MAXI YOU', 'Proper slave row value after update');

$u->delete;
is($b_rs->find($u->id), undef, 'No slave row after delete');


### That's a wrap
done_testing();


### Our hooks
sub on_create_or_update {
  my ($row) = @_;

  $b_rs->update_or_create(
    { b_id => $row->u_id,
      b    => uc($row->u),
    },
    {key => 'primary'}
  );
}

sub on_delete {
  my ($row) = @_;

  $row = $b_rs->find($row->u_id);
  $row->delete if $row;
}
