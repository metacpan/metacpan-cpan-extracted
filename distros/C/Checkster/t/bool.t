use strict;
use warnings;

use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";

# use checkster with check sub
use Checkster 'check';

subtest 'test bool param' => sub {
    my $true  = check->true(1);
    my $false = check->false(0);

    is $true, 1;
    is $false, 1;
};

subtest 'test multi bool param' => sub {
    my $true  = check->true(1, 1);
    my $false = check->false(0, 0);

    is $true, 1;
    is $false, 1;

   $false = check->false(0, 1);
   is $false, 1;

   $false = check->false(1, 0);
   is $false, 1;
};

subtest 'no numeric bool param' => sub {
    my $true  = check->true('foo');
    my $false = check->true('');

    is $true, 1;
    is !$false, 1;

    $true  = check->true('foo', 'bar');
    $false = check->true('foo', '');

    is $true, 1;
    is !$false, 1;
};

subtest 'undef as bool param' => sub {
    my $false = check->true(undef);

    is !$false, 1;
};

done_testing;
