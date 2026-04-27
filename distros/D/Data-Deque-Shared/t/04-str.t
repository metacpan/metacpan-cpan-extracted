use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);
use Data::Deque::Shared;

# --- Str variant: basic push/pop at both ends ---
my $dq = Data::Deque::Shared::Str->new(undef, 10, 32);
ok $dq, 'created Str deque';
is $dq->size, 0;
is $dq->capacity, 10;
ok $dq->is_empty;

ok $dq->push_back("alpha"), 'push_back alpha';
ok $dq->push_back("beta"),  'push_back beta';
ok $dq->push_front("gamma"), 'push_front gamma';
is $dq->size, 3;

is $dq->pop_front, "gamma", 'pop_front returns gamma (FIFO with prepend)';
is $dq->pop_front, "alpha", 'pop_front returns alpha';
is $dq->pop_back,  "beta",  'pop_back returns beta';
ok !defined $dq->pop_front, 'pop_front on empty';
ok !defined $dq->pop_back,  'pop_back on empty';

# Fill to capacity
ok $dq->push_back("item_$_"), "push $_" for 1..10;
ok $dq->is_full, 'full after 10 pushes';
ok !$dq->push_back("overflow"), 'push_back fails when full';
ok !$dq->push_front("overflow"), 'push_front fails when full';

# Pop them back out in order
for my $i (1..10) {
    is $dq->pop_front, "item_$i", "pop_front returns item_$i";
}
ok $dq->is_empty;

# Max-len truncation
my $dq2 = Data::Deque::Shared::Str->new(undef, 5, 4);
ok $dq2->push_back("abcdefgh"), 'push long string';
is $dq2->pop_front, "abcd", 'string truncated to max_len';

# Empty string allowed
ok $dq->push_back(""), 'push empty';
is $dq->pop_front, "", 'pop empty';

# UTF-8 bytes (as-is, no flag)
my $bytes = "\xE2\x98\x83";  # snowman (UTF-8 encoded)
ok $dq->push_back($bytes), 'push UTF-8 bytes';
is $dq->pop_front, $bytes, 'pop UTF-8 bytes unchanged';

# max_len=0 rejected
eval { Data::Deque::Shared::Str->new(undef, 5, 0) };
like $@, qr/max_len/, 'max_len 0 croaks';

# File-backed persistence
my $path = tmpnam() . '.shm';
{
    my $ds = Data::Deque::Shared::Str->new($path, 5, 16);
    $ds->push_back("persist");
}
{
    my $ds = Data::Deque::Shared::Str->new($path, 5, 16);
    is $ds->pop_front, "persist", 'str deque persists across opens';
    $ds->unlink;
}

done_testing;
