use strict;
use warnings;

use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";

# use checkster with check sub
use Checkster 'check';

subtest 'testing opetator not' => sub {
    my $true  = check->not->true(0);
    my $false = check->not->true(1);

    is $true, 1;
    is $false, 0;
};

subtest 'testing operator all' => sub {
    my $all       = check->true(1, 2, 'foo');
    my $all_true  = check->all->true(1, 2, 'foo');
    my $all_false = check->all->true(0, '', undef, 1);

    is $all, 1;
    is $all_true, 1;
    is $all_false, 0;
};

subtest 'testing operator any' => sub {
    my $any_true  = check->any->true(1, 'foo', 0, '');
    my $any_false = check->any->true(0, '', undef);

    is $any_true, 1;
    is $any_false, 0;
};


done_testing;
