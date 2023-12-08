#!perl

use strict;
use warnings;
use Test::More 0.98;

use Array::Util::MultiTarget qw(
                                   mtpop
                                   mtpush
                                   mtsplice
                                   mtremovestr
                                   mtremoveallstr
                                   mtremovenum
                                   mtremoveallnum
                           );

subtest mtpop => sub {
    my $ary1 = [1,2,3];
    my $ary2 = [4,5,6];
    is_deeply([mtpop([$ary1,$ary2])], [3,6]);
    is_deeply($ary1, [1,2]);
    is_deeply($ary2, [4,5]);
};

subtest mtpush => sub {
    my $ary1 = [1,2,3];
    my $ary2 = [4,5,6];
    mtpush([$ary1,$ary2], 7,8);
    is_deeply($ary1, [1,2,3,7,8]);
    is_deeply($ary2, [4,5,6,7,8]);
};

subtest mtsplice => sub {
    my $ary1 = [1,2,3];
    my $ary2 = [4,5,6];
    mtsplice([$ary1,$ary2], 1,2,7,8,9);
    is_deeply($ary1, [1,7,8,9]);
    is_deeply($ary2, [4,7,8,9]);
    mtsplice([$ary1,$ary2], 1,1);
    is_deeply($ary1, [1,8,9]);
    is_deeply($ary2, [4,8,9]);
    mtsplice([$ary1,$ary2], 1);
    is_deeply($ary1, [1]);
    is_deeply($ary2, [4]);
};

subtest mtremovestr => sub {
    my $ary1 = [qw/a b c/];
    my $ary2 = [qw/d e f/];
    is_deeply([mtremovestr([$ary1,$ary2], "d")], []);
    is_deeply($ary1,[qw/a b c/]);
    is_deeply($ary2,[qw/d e f/]);
    is_deeply([mtremovestr([$ary1,$ary2], "b")], [1]);
    is_deeply($ary1,[qw/a c/]);
    is_deeply($ary2,[qw/d f/]);
};

subtest mtremoveallstr => sub {
    my $ary1 = [qw/a b c b/];
    my $ary2 = [qw/d e f e/];
    is_deeply([mtremoveallstr([$ary1,$ary2], "d")], []);
    is_deeply($ary1,[qw/a b c b/]);
    is_deeply($ary2,[qw/d e f e/]);
    is_deeply([mtremoveallstr([$ary1,$ary2], "b")], [1,3]);
    is_deeply($ary1,[qw/a c/]);
    is_deeply($ary2,[qw/d f/]);
};

subtest mtremovenum => sub {
    my $ary1 = [qw/1 2.0 3/];
    my $ary2 = [qw/4 5.0 6/];
    is_deeply([mtremovenum([$ary1,$ary2], 4)], []);
    is_deeply($ary1,[qw/1 2.0 3/]);
    is_deeply($ary2,[qw/4 5.0 6/]);
    is_deeply([mtremovenum([$ary1,$ary2], 2)], [1]);
    is_deeply($ary1,[qw/1 3/]);
    is_deeply($ary2,[qw/4 6/]);
};

subtest mtremoveallnum => sub {
    my $ary1 = [qw/1 2.0 3 2/];
    my $ary2 = [qw/4 5.0 6 5/];
    is_deeply([mtremoveallnum([$ary1,$ary2], 4)], []);
    is_deeply($ary1,[qw/1 2.0 3 2/]);
    is_deeply($ary2,[qw/4 5.0 6 5/]);
    is_deeply([mtremoveallnum([$ary1,$ary2], 2)], [1,3]);
    is_deeply($ary1,[qw/1 3/]);
    is_deeply($ary2,[qw/4 6/]);
};

DONE_TESTING:
done_testing;
