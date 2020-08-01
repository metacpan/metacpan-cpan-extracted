use strict;
use Test::More 0.98 tests => 16;

use lib 'lib';

BEGIN { use_ok('Caller::Easy') }    # 1

is ::caller, __PACKAGE__, 'succeed to import caller() to main';    # 2

note 'Object Oriented';
my $caller = new_ok('Caller::Easy');                               # 3
is $caller->package(), __PACKAGE__, 'succeed to get package name'; # 4
is $caller->filename(), $0, 'succeed to get filename';             # 5
is $caller->line(), __LINE__ - 3, 'succeed to get line number';    # 6

note 'like a function';
$caller = caller();
is $caller->package(), __PACKAGE__, 'succeed to get package name';    # 7
is $caller->filename(), $0, 'succeed to get filename';                # 8
is $caller->line(), __LINE__ - 3, 'succeed to get line number';       # 9

note 'like a CORE::function';
$caller = caller;
is $caller->package(), __PACKAGE__, 'succeed to get package name';    #10
is $caller->filename(), $0, 'succeed to get filename';                #11
is $caller->line(), __LINE__ - 3, 'succeed to get line number';       #12

note 'Errors';
eval { $caller = caller("string") };
like $@, qr/^Unvalid depth was assigned/i,                            #13
    "fail to assign the string to arg";

eval { $caller = caller(-1) };
like $@, qr/^Unvalid depth was assigned/i,                            #14
    "fail to assign unvalid depth";

eval { $caller = caller( 0, 1, 2 ) };
like $@, qr/^Too many arguments for caller/i,                         #15
    "fail to assign too many arguments";
eval { $caller = caller( 0, 1 ) };
like $@, qr/^Unvalid arguments for caller/i,                          #16
    "fail to assign unvalid arguments";

done_testing;
