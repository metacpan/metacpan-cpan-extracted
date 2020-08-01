package Test;

use strict;
use Test::More 0.98 tests => 4;

use lib 'lib';
use Caller::Easy;
{
    no strict 'refs';
    is &{ __PACKAGE__ . "::caller" }, __PACKAGE__,    # 1
        'succeed to import caller() to ' . __PACKAGE__;
}

my $caller = caller();
is $caller->package(), __PACKAGE__, 'succeed to get package name';    # 2
is $caller->filename(), $0, 'succeed to get filename';                # 3
is $caller->line(), __LINE__ - 3, 'succeed to get line number';       # 4

done_testing;
