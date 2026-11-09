use strict;
use warnings;
use Test::More;

use DBIO::Diff::Base;

# classify buckets every operation of a diff by what it does to existing
# data and structure (ADR 0060). A refusing operation makes the whole run
# unclassifiable; everything not known to be additive is conservative.

{
  package Test::COp;
  sub new      { my ($c, %a) = @_; bless {%a}, $c }
  sub as_sql   { 'SQL;' }
  sub summary  { $_[0]->{summary} }
  sub action   { $_[0]->{action} }

  package Test::COpReplaced;
  our @ISA = ('Test::COp');
  sub replaced { $_[0]->{replaced} }

  package Test::CDiff;
  use base 'DBIO::Diff::Base';
  sub _build_operations { $_[0]->{ops} }
}

sub op  { Test::COp->new(action => $_[0], summary => $_[1] // "op:$_[0]") }
sub cls { Test::CDiff->new(source => {}, target => {}, ops => [@_])->classify }

my $none = cls();
is_deeply $none,
  { has_changes => 0, class => 'none',
    counts => { additive => 0, changing => 0, destructive => 0 },
    refused => [] },
  'no operations: class none';

my $add = cls(map { op($_) } qw(create add add_value));
is $add->{class}, 'additive', 'create/add/add_value are additive';
is_deeply $add->{counts}, { additive => 3, changing => 0, destructive => 0 }, 'additive counts';
ok $add->{has_changes}, 'has_changes set';

my $chg = cls(map { op($_) } qw(alter modify change update replace move own
  enable_rls disable_rls set_persistence somethingnew));
is $chg->{class}, 'changing', 'everything else is changing';
is $chg->{counts}{changing}, 11, 'all counted as changing';

my $nact = cls(Test::COp->new(summary => 'no action'));
is $nact->{class}, 'changing', 'op without an action is changing';

my $drop = cls(op('drop'));
is $drop->{class}, 'destructive', 'drop is destructive';
is $drop->{counts}{destructive}, 1, 'destructive counted';

my $rep = cls(
  Test::COpReplaced->new(action => 'drop',   replaced => 1, summary => 'd'),
  Test::COpReplaced->new(action => 'create', replaced => 0, summary => 'c'),
);
is $rep->{class}, 'changing', 'replaced drop + create: changing, not destructive';
is_deeply $rep->{counts}, { additive => 1, changing => 1, destructive => 0 },
  'replaced pair counts 1 changing + 1 additive';

my $plain = cls(Test::COpReplaced->new(action => 'drop', replaced => 0, summary => 'd'));
is $plain->{class}, 'destructive', 'drop with replaced false stays destructive';

my $mix = cls(op('create'), op('alter'), op('drop'));
is $mix->{class}, 'destructive', 'mixture: maximum severity';
is_deeply $mix->{counts}, { additive => 1, changing => 1, destructive => 1 }, 'mixture counts';

my $ref = cls(op('create'), op('drop'), op('refuse', 'cannot do X'), op('refuse', 'cannot do Y'));
ok $ref->{has_changes}, 'refusing run still has changes';
ok !defined $ref->{class},  'refusing run: class undef';
ok !defined $ref->{counts}, 'refusing run: counts undef';
is_deeply $ref->{refused}, ['cannot do X', 'cannot do Y'], 'refused holds summaries';

done_testing;
