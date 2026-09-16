use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use Data::HashMap::Shared::II;

# freeze() seals a sharded map's shards one after another.  A freezer killed
# between two of them leaves the first shards sealed and the rest not: every
# mutator already refuses the set, since shard 0 answers for it, and
# new_readonly refuses the unsealed shards.  freeze on a handle still open to
# the set must finish the job, and with none open, freezing each unsealed shard
# by name must.  seal_shard writes the state such a kill leaves -- a shard's
# seal byte, at offset 96.

my $dir = tempdir(CLEANUP => 1);

sub seal_shard {
    open my $fh, '+<:raw', $_[0] or die $!;
    seek $fh, 96, 0 or die $!;
    print $fh "\1";
    close $fh or die $!;
}

my $prefix = "$dir/set";
my $m = Data::HashMap::Shared::II->new_sharded($prefix, 4, 64);
$m->put($_, $_) for 1 .. 100;
my $other = Data::HashMap::Shared::II->new_sharded($prefix, 4, 64);
seal_shard("$prefix.0");

sub refusal { my $code = shift; eval { $code->(); 1 } ? 'no error' : $@ }
my $FROZEN = qr/is frozen \(read-only\)/;

ok $m->frozen, 'the set reads as frozen once shard 0 is sealed';
like refusal(sub { $m->put(1000, 1) }), $FROZEN, '  ... and refuses writes';
like refusal(sub { Data::HashMap::Shared::II->new_readonly("$prefix.3") }), qr/is not frozen/,
    '  ... while its unsealed shards still refuse a read-only open';

ok eval { $m->freeze; 1 }, 'freeze finishes a partly sealed set' or diag $@;
ok $m->readonly, '  ... and marks the handle read-only';
for my $i (0 .. 3) {
    ok eval { Data::HashMap::Shared::II->new_readonly("$prefix.$i"); 1 },
        "  ... shard $i now opens read-only" or diag $@;
}

ok !$other->readonly, 'a second handle opened before the freeze is not read-only';
like refusal(sub { $other->freeze }), $FROZEN, '  ... yet its freeze refuses a set sealed throughout';

my $lone = "$dir/lone";
{
    my $s = Data::HashMap::Shared::II->new_sharded($lone, 4, 64);
    $s->put($_, $_) for 1 .. 100;
}
seal_shard("$lone.$_") for 0, 1;
like refusal(sub { Data::HashMap::Shared::II->new_sharded($lone, 4, 64) }), $FROZEN,
    'with no handle left open, new_sharded refuses the partial set';
Data::HashMap::Shared::II->new("$lone.$_", 64)->freeze for 2, 3;
my $n = 0;
$n += keys %{ Data::HashMap::Shared::II->new_readonly("$lone.$_")->to_hash } for 0 .. 3;
is $n, 100, '  ... and freezing each unsealed shard by name finishes it, every entry intact';

done_testing;
