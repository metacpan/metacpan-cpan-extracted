use strict;
use warnings;
use Test::More;
use Time::HiRes qw(sleep clock_gettime CLOCK_MONOTONIC);

use Data::HashMap::Shared::IS;
use Data::HashMap::Shared::I16S;
use Data::HashMap::Shared::I32S;
use Data::HashMap::Shared::SS;

# Only one class-2048 value fits this arena. An overwrite stores its replacement
# before freeing the old block, and protects the old entry from its TTL scan.
# If that overwrite fails, the protected entry stays expired. A later insert
# must still reclaim it, even in the same second as the earlier scan.
my $value = 'v' x 1500;
my @cases;
for my $variant (qw(IS I16S I32S SS)) {
    for my $op (qw(put add swap get_or_set update)) {
        my $m = "Data::HashMap::Shared::$variant"->new(undef, 64, 0, 3600, 0, 4096);
        $m->put_ttl(1, $value, 1) or die 'cannot build fixture';
        $m->put(2, 'old') or die 'cannot build live target' if $op eq 'update';
        push @cases, [$variant, $op, $m];
    }
    my $m = "Data::HashMap::Shared::$variant"->new(undef, 64, 0, 3600, 0, 4096);
    $m->put_ttl(1, $value, 1) or die 'cannot build resize fixture';
    push @cases, [$variant, 'put', $m, 1];
}
sleep 1.2;

# Leave most of a clock second for the failed overwrite and the following
# insert, so the previous same-second suppression is actually exercised.
my $now = clock_gettime(CLOCK_MONOTONIC);
sleep int($now) + 1.01 - $now if $now - int($now) > 0.5;

for my $case (@cases) {
    my ($variant, $op, $m, $resize) = @$case;
    my $label = "$variant $op after a failed expired overwrite" . ($resize ? ' and resize' : '');
    subtest $label => sub {
        ok !$m->exists(1), 'the original entry has expired';
        ok !$m->put(1, $value), 'the overwrite has no room and leaves its old block alone';
        is $m->size, $op eq 'update' ? 2 : 1, 'the protected expired entry remains in the table';
        ok !$m->put(1, $value), 'another failed overwrite still protects it';
        if ($resize) {
            my $cap = $m->capacity;
            ok $m->reserve(48), 'grow between the reclamation scan and the insert';
            cmp_ok $m->capacity, '>', $cap, 'the resize invalidates saved slot positions';
        }

        $m->$op(2, $value);
        is $m->get(2), $value, 'the next insert reclaims the expired block immediately';
        is $m->size, 1, 'only the new entry remains';
        is $m->stat_expired, 1, 'the reclaimed entry is counted once';
    };
}

done_testing;
