#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Deferred;
use Context::Vars qw($top);

# The one case where a callback on an unwired loop reads something: code
# outside any sub assigned the variable, so it has a value for everything
# that runs outside a context. Pinned, and said in the POD.

my $q = Deferred->new(wired => 0);
my @read;
sub task { $top = 'task value'; $q->later(sub { push @read, $top // 'nothing' }) }

task();
$q->run_all;
is_deeply(\@read, ['nothing'], 'before any top-level assignment, an unwired callback reads nothing');

$top = 'file value';
task();
$q->run_all;
is_deeply(\@read, ['nothing', 'file value'],
          'after one, an unwired callback reads the file\'s value: never the task\'s');

my $w = Deferred->new(wired => 1);
sub wired_task { $top = 'task value'; $w->later(sub { push @read, $top }) }
wired_task();
$w->run_all;
is($read[-1], 'task value', 'a wired callback reads its task\'s value either way');

done_testing;
