#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Deferred;
use Context::Vars qw($id $step);

# A callback that queues another, three deep. The id follows the chain. A
# link that assigns a second variable passes it to the links it queues, and
# to nothing else.

my $q = Deferred->new(wired => 1);
my @read;
sub d { $_[0] // 'nothing' }

sub link3 { push @read, "$id link3 step " . d($step) }
sub link2 {
    push @read, "$id link2 step " . d($step);
    $step = "set by $id link2";
    $q->later(\&link3);
}
sub link1 { push @read, "$id link1 step " . d($step); $q->later(\&link2) }
sub task  { $id = shift; $q->later(\&link1) }

task('A');
task('B');
$q->drain;

is_deeply([sort @read], [sort
    'A link1 step nothing', 'A link2 step nothing', 'A link3 step set by A link2',
    'B link1 step nothing', 'B link2 step nothing', 'B link3 step set by B link2',
], 'the id follows each chain, and each chain\'s third link reads what its own second link set');
ok(!defined $step, 'the top level never sees the assignment made in a link');
is(Context::Vars::_depth(), 0, 'no context is left entered');
is(Context::Vars::_live_holders(), 0, 'and no holder is out');

done_testing;
