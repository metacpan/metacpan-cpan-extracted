use strict;
use Test::More 0.98 tests => 3;

use lib 'lib';

use Caller::Easy;

sub test {
    my $caller = caller();
    is $caller->package(), __PACKAGE__, 'succeed to get package name';  # 1
    is $caller->filename(), $0, 'succeed to get filename';              # 2
    is $caller->line(), __LINE__ - 3, 'succeed to get line number';     # 3
}
test();

done_testing();
