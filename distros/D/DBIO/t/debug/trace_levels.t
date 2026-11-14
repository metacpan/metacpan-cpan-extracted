# ABSTRACT: DBIO_TRACE=1 traces the statement, 2 adds redacted, capped binds (karr k401)
use strict;
use warnings;

use Test::More;
use File::Temp ();

use DBIO::Test;
use DBIO::Storage;
use DBIO::Storage::DBI;
use DBIO::Storage::Statistics;
use DBIO::Replicated::Storage;
use DBIO::Storage::Async;

# One rule on every path: level 1 is the statement, level 2 adds the binds
# (redacted, 32 characters at most, undef as NULL); N=/path keeps the level.

for ([undef, 0], [0, 0], [1, 1], [2, 2], ['2=/tmp/x', 2], ['1=/tmp/x', 1], ['yes', 1], ['=/tmp/x', 1]) {
  is(DBIO::Storage->_trace_level_of($_->[0]), $_->[1],
    "flag '" . ($_->[0] // 'undef') . "' is level $_->[1]");
}

{ package K401::Stats; our @ISA = ('DBIO::Storage::Statistics');
  our @started;
  sub query_start { my $s = shift; push @started, [@_]; $s->SUPER::query_start(@_) } }

my $long = 'x' x 40;
my $sql  = 'SELECT * FROM artist WHERE name = ?';

sub traced {
  my ($level, $bind) = @_;
  my $storage = DBIO::Test->init_schema(no_deploy => 1)->storage;
  my $out = '';
  open my $fh, '>', \$out or die;
  my $stats = K401::Stats->new;
  $stats->debugfh($fh);
  $storage->debugobj($stats);
  $storage->debug($level);
  @K401::Stats::started = ();
  $storage->_query_start($sql, $bind);
  $storage->_query_end($sql, $bind);
  return $out;
}

my @bind = ([ { dbic_colname => 'name' }, 'plain-value' ], [ {}, $long ], [ {}, undef ]);

{
  my $out = traced(1, \@bind);
  like $out, qr/SELECT \* FROM artist WHERE name = \?/, 'level 1: the statement is traced';
  unlike $out, qr/plain-value|xxxx|NULL/, 'level 1: no bind value';
  is_deeply \@K401::Stats::started, [[ $sql, '' ]],
    'level 1: the statistics object gets one empty element, no binds';
}

{
  my $old = DBIO::Storage::DBI->redact_bind_value;
  DBIO::Storage::DBI->redact_bind_value(sub { $_[0] && $_[0] eq 'name' ? '***' : $_[1] });
  my $out = traced(2, \@bind);
  DBIO::Storage::DBI->redact_bind_value($old);
  like $out, qr/'\*\*\*'/, 'level 2: the value goes through redact_bind_value';
  unlike $out, qr/plain-value/, 'level 2: the redacted value is not shown';
  like $out, qr/'x{32}\.\.\.'/, 'level 2: a long value is cut to 32 characters, ... marks the cut';
  unlike $out, qr/x{33}/, 'level 2: nothing past 32 characters';
  like $out, qr/NULL/, 'level 2: undef is NULL';
}

# N=/path writes to the file, mode 0600
{
  my $dir  = File::Temp::tempdir(CLEANUP => 1);
  my $file = "$dir/trace.out";
  local $ENV{DBIO_TRACE} = "2=$file";
  my $storage = DBIO::Test->init_schema(no_deploy => 1)->storage;
  is $storage->debug, 2, 'DBIO_TRACE=2=file: debug holds level 2';
  $storage->debugobj(DBIO::Storage::Statistics->new);
  $storage->_query_start('SELECT 1 WHERE a = ?', [[ {}, 'in-the-file' ]]);
  open my $fh, '<', $file or die $!;
  my $trace = do { local $/; <$fh> };
  like $trace, qr/SELECT 1 WHERE a = \?: 'in-the-file'/, 'the file holds the statement and the bind';
  SKIP: {
    skip 'MSWin32 has no Unix file permissions', 1 if $^O eq 'MSWin32';
    is sprintf('%04o', (stat $file)[2] & 07777), '0600', 'the trace file is 0600';
  }
}

{
  local $ENV{DBIO_TRACE} = '1=/dev/null';
  is(DBIO::Test->init_schema(no_deploy => 1)->storage->debug, 1, 'DBIO_TRACE=1=file: level 1');
}
{
  local $ENV{DBIO_TRACE} = 'yes';
  is(DBIO::Test->init_schema(no_deploy => 1)->storage->debug, 1, 'another true value: level 1');
}

# Replicated and Async take the level
{
  local $ENV{DBIO_TRACE} = '2=/dev/null';
  is(DBIO::Replicated::Storage->new(undef)->{debug}, 2, 'Replicated: level 2');
  is(DBIO::Storage::Async->new(undef)->debug, 2, 'Async new: level 2');
  local $ENV{DBIO_TRACE} = 'on';
  is(DBIO::Storage::Async->new(undef)->debug, 1, 'Async new: another true value is level 1');
  local $ENV{DBIO_TRACE} = 0;
  is(DBIO::Storage::Async->new(undef)->debug, 0, 'Async new: false is 0');
}

# capture_executed_sql_bind still hands over the raw binds
{
  my $schema = DBIO::Test->init_schema(no_deploy => 1);
  my $cap = $schema->capture_executed_sql_bind(sub {
    $schema->storage->_query_start('SELECT ?', [[ {}, 'raw' ]]);
  });
  is_deeply $cap->[0][1][1], [ {}, 'raw' ], 'capture_executed_sql_bind hands over the raw binds';
}

done_testing;
