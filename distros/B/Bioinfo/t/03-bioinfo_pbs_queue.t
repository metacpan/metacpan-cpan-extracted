#!/usr/bin/env perl
use Modern::Perl;
use Test::More;
use IO::All;

my $module;
BEGIN {
  $module = 'Bioinfo::PBS::Queue';
  use_ok($module);
}
my @attrs = qw(tasks name run_queue finished_queue stage);
my @methods = qw(execute);
can_ok($module, $_) for @attrs;
can_ok($module, $_) for @methods;

done_testing
