use strict;
use warnings;
use Test::More;

use DBIO::MySQL::Storage;
use DBIO::MySQL::Storage::MariaDB;

# OFFLINE half of karr k123 (t/174 has the live half).
#
# WHY IT MATTERS. Core (k373) gives a driver one seam, _adjust_bind_values, for
# changing values before they are bound, and runs both ways to the server
# through it: _bind_sth_params (create, search, update) and the row loop of
# populate in void context. The text rule lived in an override of
# _bind_sth_params and so missed the second way. Claims:
#   a. DBIO::MySQL::Storage defines _adjust_bind_values and no longer
#      _bind_sth_params of its own (nor does the MariaDB binding);
#   b. under DBD::mysql with the utf8 attribute the seam upgrades "\x{fc}" in a
#      copy -- the caller's list, pairs and value are untouched;
#   c. a scalar reference (bind_param_inout target) stays the very same
#      reference; a value bound as binary stays bytes;
#   d. a handle without the attribute, or another DBD, gets $bind back as it is;
#   e. _bind_sth_params of core reaches the rule through the seam.

for my $class (qw(DBIO::MySQL::Storage DBIO::MySQL::Storage::MariaDB)) {
  no strict 'refs';
  ok !defined &{"${class}::_bind_sth_params"}, "a: $class does not override _bind_sth_params";
}
ok defined &DBIO::MySQL::Storage::_adjust_bind_values, 'a: DBIO::MySQL::Storage defines _adjust_bind_values';

sub storage {
  my ($driver, $attrs) = @_;
  return bless { _dbh => { Driver => { Name => $driver }, %$attrs } }, 'DBIO::MySQL::Storage';
}

my $latin = "\x{fc}";
my $target = "\x{fc}";
my $inout = \$target;
my @bind = ([ {}, $latin ], [ {}, $latin ], [ {}, $inout ]);
my @attrs = (undef, { TYPE => 1 }, undef);

my $got = storage(mysql => { mysql_enable_utf8mb4 => 1 })->_adjust_bind_values(undef, \@bind, \@attrs);
isnt $got, \@bind, 'b: a new list is answered';
ok utf8::is_utf8($got->[0][1]) && $got->[0][1] eq $latin, 'b: the text is upgraded to characters';
ok !utf8::is_utf8($bind[0][1]) && !utf8::is_utf8($latin), '... the caller\'s value is not changed';
ok !utf8::is_utf8($got->[1][1]), 'c: a value bound as binary stays bytes';
is $got->[2][1], $inout, 'c: a scalar reference stays the very same reference';

is storage(mysql => {})->_adjust_bind_values(undef, \@bind, \@attrs), \@bind, 'd: no utf8 attribute: untouched';
is storage(MariaDB => { mysql_enable_utf8mb4 => 1 })->_adjust_bind_values(undef, \@bind, \@attrs), \@bind,
  'd: DBD::MariaDB: untouched';

{
  package FakeSth;
  sub bind_param { push @{ $_[0]{got} }, $_[2]; 1 }
}
my $sth = bless { got => [] }, 'FakeSth';
storage(mysql => { mysql_enable_utf8mb4 => 1 })->_bind_sth_params($sth, [ [ {}, $latin ] ], [undef]);
ok utf8::is_utf8($sth->{got}[0]), 'e: _bind_sth_params binds the upgraded value';

done_testing;
