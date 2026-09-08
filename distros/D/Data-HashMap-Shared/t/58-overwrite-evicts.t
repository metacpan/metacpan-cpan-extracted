use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use Data::HashMap::Shared::SS;

# An overwrite -- put on a hit, update, swap, cas -- stores the new value before
# releasing the old one, so on a full arena it needs room for both.  An LRU map
# makes that room by evicting, and the entry being replaced is never the victim.

my $dir = tempdir(CLEANUP => 1);
my $V = 'x' x 200;
my $seq = 0;
my $full = sub {                    # class-256 entries evicting in a 4096-byte arena
    my $m = Data::HashMap::Shared::SS->new("$dir/f" . $seq++ . ".shm", 1000, 500, 0, 0, 4096);
    my $n = 0;
    while ($m->put("k$n", $V)) { last if ++$n > 100 }
    return ($m, "k" . ($n - 1));       # the newest key
};

for my $case (
    [ put    => sub { $_[0]->put($_[1], $_[2]) } ],
    [ update => sub { $_[0]->update($_[1], $_[2]) } ],
    [ swap   => sub { defined $_[0]->swap($_[1], $_[2]) } ],
    [ cas    => sub { $_[0]->cas($_[1], $V, $_[2]) } ],
) {
    my ($name, $code) = @$case;
    my ($m, $key) = $full->();
    my ($size, $ev) = ($m->size, $m->stats->{evictions});
    ok $code->($m, $key, 'y' x 200), "$name of a same-size value on a full arena succeeds by evicting";
    is $m->get($key), 'y' x 200, "  ... the entry holds the new value";
    is $m->stats->{evictions} - $ev, 1, "  ... at one eviction";
    is $m->size, $size - 1, "  ... of another entry";
}

{
    my $m = Data::HashMap::Shared::SS->new("$dir/one.shm", 1000, 500, 0, 0, 8192);
    $m->put('only', 'a' x 3000);        # one class-4096 block; a second cannot fit
    ok !$m->put('only', 'b' x 3000), 'the only entry is not evicted to make room for its own replacement';
    is $m->get('only'), 'a' x 3000, '  ... and is left as it was';
    is $m->size, 1, '  ... still present';
}

{
    my $p = Data::HashMap::Shared::SS->new("$dir/nolru.shm", 1000, 0, 0, 0, 4096);
    my $n = 0;
    while ($p->put("k$n", $V)) { last if ++$n > 100 }
    ok !$p->update('k0', 'y' x 200), 'without an LRU an overwrite on a full arena still fails';
    is $p->get('k0'), $V, '  ... leaving the entry as it was';
    is $p->stats->{evictions}, 0, '  ... evicting nothing';
}

done_testing;
