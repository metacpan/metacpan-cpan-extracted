use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Data::HashMap::Shared::SI;
use Data::HashMap::Shared::II;
use Data::HashMap::Shared::SS;

# Anonymous mmap (undef path) must work and expose undef path/accessor.
{
    my $m = Data::HashMap::Shared::SI->new(undef, 64);
    ok !defined $m->path, 'anon: path is undef';
    ok $m->put("hello", 42), 'anon: put ok';
    is $m->get("hello"), 42, 'anon: get ok';
    is $m->size, 1, 'anon: size';

    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        _exit($m->get("hello") == 42 ? 0 : 1);
    }
    waitpid $pid, 0;
    is $? >> 8, 0, 'anon: fork-inherited mmap visible in child';
}

# Integer-key variant also works anonymously.
{
    my $m = Data::HashMap::Shared::II->new(undef, 64);
    ok !defined $m->path, 'II anon: path undef';
    $m->put(7, 777);
    is $m->get(7), 777, 'II anon: round-trip';
}

# String-key/string-value variant (has_arena) also works anonymously.
{
    my $m = Data::HashMap::Shared::SS->new(undef, 64);
    ok !defined $m->path, 'SS anon: path undef';
    $m->put("k", "v");
    is $m->get("k"), "v", 'SS anon: round-trip';
}

# Calling unlink() on anon returns false (no path to unlink).
{
    my $m = Data::HashMap::Shared::SI->new(undef, 16);
    ok !$m->unlink, 'anon: unlink returns false (no path)';
}

done_testing;
