#!perl

use 5.010;
use strict;
use warnings;

use Clone::Util qw(clone modclone sclone);
use Test::More 0.98;

subtest "clone" => sub {
    is_deeply(clone([1,2,3]), [1,2,3]);
};

subtest "modclone" => sub {
    my $data = [1,2,3];
    is_deeply((modclone { push @$_, 4 } $data), [1,2,3,4], '$_ in code');
    is_deeply((modclone { splice @{$_[0]}, 0, 0, 0 } $data), [0,1,2,3], '$_[0] in code');
    is_deeply($data, [1,2,3], "original data is not changed");

    my $row = [1,2,3];
    is_deeply([$row, modclone {$_->[0]=2} $row, modclone {$_->[0]=3} $row],
              [[1,2,3], [2,2,3], [3,2,3]],
              "extra arguments allowed");
};

subtest "sclone" => sub {
    my $data = [0,1,2,[3]];
    my $clone = sclone $data;
    is_deeply($clone, [0,1,2,[3]]);
    $clone->[0] = 10;
    is_deeply($clone, [10,1,2,[3]]);
    is_deeply($data , [ 0,1,2,[3]]);
    $clone->[3][0] = 30;
    is_deeply($clone, [10,1,2,[30]]);
    is_deeply($data , [ 0,1,2,[30]]);
};

DONE_TESTING:
done_testing();
