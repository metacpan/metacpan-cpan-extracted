use strict;
use warnings;
use Test::More 'no_plan';
use DBICx::TestDatabase;
use DateTime;

BEGIN { use_ok('DBIx::Class::ColumnDefault') }

use FindBin;
use lib "$FindBin::Bin/lib";

my $schema = DBICx::TestDatabase->new('TestSchema');
my $rs     = $schema->resultset('Table');
my $parser = $schema->storage->datetime_parser;

{
  my $now = DateTime->now;
  my $row = $rs->create({});
  is($row->str, 'aaa', 'default str inserted');

  ok(my $dt = $parser->parse_datetime($row->dt), 'datetime parses');

  my $delta = $dt->delta_ms($now);
  cmp_ok($delta->minutes, '==', 0, 'now minute delta');
  cmp_ok($delta->seconds, '<=', 1, 'now second delta');
}

{
  my $row = $rs->create({str => undef, dt => undef});

  is($row->str, undef, 'NULL str inserted');
  is($row->dt,  undef, 'NULL datetime inserted');
}

{
  my $when = DateTime->now->add(days => 10);
  my $row = $rs->create({str => 'xxx', dt => $when});

  ok(my $dt = $parser->parse_datetime($row->dt), 'datetime parses');

  is($row->str, 'xxx', 'given str inserted');
  cmp_ok($dt, '==', $when, 'given dt inserted');
}
