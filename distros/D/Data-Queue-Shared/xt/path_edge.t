use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use Data::Queue::Shared::Int;

my $dir = tempdir(CLEANUP => 1);

# Path with spaces
{
    my $p = "$dir/q with spaces.shm";
    my $q = Data::Queue::Shared::Int->new($p, 16);
    ok $q, 'path with spaces';
    $q->push(42);
    is $q->pop, 42, 'ops work on spaced path';
}

# Path with unicode
{
    my $p = "$dir/наша_очередь.shm";
    my $q = Data::Queue::Shared::Int->new($p, 16);
    ok $q, 'path with unicode';
    $q->push(7);
    is $q->pop, 7, 'ops on unicode path';
}

# Very long path (but within PATH_MAX)
{
    my $long = 'a' x 100;
    my $p = "$dir/$long.shm";
    my $q = Data::Queue::Shared::Int->new($p, 16);
    ok $q, 'long filename';
}

# Path with newline — platform varies, just expect clean failure or success
{
    my $p = "$dir/has\nnewline.shm";
    my $q = eval { Data::Queue::Shared::Int->new($p, 16) };
    ok defined($q) || $@, 'newline path: clean success or diagnostic';
}

done_testing;
