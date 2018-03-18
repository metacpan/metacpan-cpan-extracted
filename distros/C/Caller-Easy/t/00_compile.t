use strict;
use Test::More 0.98 tests => 13;

use lib 'lib';

BEGIN{ use_ok( 'Caller::Easy' ) }                                       # 1

is ::caller, __PACKAGE__,                                               # 2
'succeed to import caller() to main';

note 'Object Oriented';
my $caller = new_ok('Caller::Easy');                                    # 3
is $caller->package(), __PACKAGE__, 'succeed to get package name';      # 4
is $caller->filename(), $0, 'succeed to get filename';                  # 5
is $caller->line(), __LINE__ - 3, 'succeed to get line number';         # 6




note 'like a function';
$caller = caller();
is $caller->package(), __PACKAGE__, 'succeed to get package name';      # 7
is $caller->filename(), $0, 'succeed to get filename';                  # 8
is $caller->line(), __LINE__ - 3, 'succeed to get line number';         # 9

note 'Errors';
eval{ $caller = caller("string") };
 like $@, qr/^Unvalid depth was assigned/i,                             #10
"fail to assign the string to arg";

eval { $caller = caller(-1) };
 like $@, qr/^Unvalid depth was assigned/i,                             #11
"fail to assign unvalid depth";

eval { $caller = caller( 0, 1, 2 ) };
 like $@, qr/^Too many arguments for caller/i,                          #12
"fail to assign too many arguments";
eval { $caller = caller( 0, 1 ) };
 like $@, qr/^Unvalid arguments for caller/i,                           #13
"fail to assign unvalid arguments";

done_testing();
