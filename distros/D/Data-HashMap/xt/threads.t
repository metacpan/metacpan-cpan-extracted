use strict;
use warnings;
use Config;
use Test::More;

BEGIN {
    plan skip_all => 'perl built without ithreads' unless $Config{useithreads};
}

use threads;
use Scalar::Util qw(blessed);
use Data::HashMap::II;
use Data::HashMap::SS;


my $ii = Data::HashMap::II->new();
$ii->put(1, 100);
my $ss = Data::HashMap::SS->new();
$ss->put("a", "alpha");

ok(Data::HashMap::II->CLONE_SKIP, 'II inherits CLONE_SKIP');

my $thr = threads->create(sub {
    return join ',', (blessed($ii) ? 'ii-cloned' : 'ii-skipped'),
                     (blessed($ss) ? 'ss-cloned' : 'ss-skipped'),
                     (defined($$ii) ? 'ii-set'   : 'ii-undef');
});
is $thr->join, 'ii-skipped,ss-skipped,ii-undef',
    'maps are not cloned into the child thread';

is $ii->get(1), 100, 'II still usable in the parent after the thread exits';
is $ss->get("a"), 'alpha', 'SS still usable in the parent after the thread exits';

# A thread that builds its own maps must work normally.
my $own = threads->create(sub {
    my $m = Data::HashMap::II->new();
    $m->put($_, $_ * 2) for 1 .. 100;
    return $m->size + $m->get(50);
});
is $own->join, 200, 'a map created inside a thread works';

done_testing;
