# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.96;
use Test::MockObject 1.09 ();

my $tt = Test::MockObject->new;
$tt->fake_module(Template => new => sub { bless $_[1], $_[0] }, VERSION => sub { 1 });

my $qmod = 'DBIx::RoboQuery';
eval "require $qmod" or die $@;

my $sql = 'SELECT * FROM table';
my $query = new_ok($qmod, [sql => $sql]);

ok !$query->{tt}->{INCLUDE_PATH}, 'no include path by default';

$query = new_ok($qmod, [sql => $sql, template_options => {INCLUDE_PATH => 'C:\who\cares'}]);
is  $query->{tt}->{INCLUDE_PATH}, 'C:\who\cares', 'specified include path';

is_deeply
  $query->{tt}->{VARIABLES},
  {
    query => $query,
  },
  'default template variables';

$query = new_ok($qmod, [sql => $sql, variables => {robo => 'query'}]);
is_deeply
  $query->{tt}->{VARIABLES},
  {
    query => $query,
    robo  => 'query',
  },
  'additional template variables';

$query = new_ok($qmod, [sql => $sql, template_options => {VARIABLES => {}}]);
is_deeply $query->{tt}->{VARIABLES}, {}, 'no template variables';

done_testing;
