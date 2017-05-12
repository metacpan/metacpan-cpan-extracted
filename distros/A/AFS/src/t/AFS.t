# -*-cperl-*-
use strict;

use lib qw(../../inc ../inc ./inc);
use blib;

use Test::More tests => 10;

BEGIN {
    use_ok('AFS', qw (
                      error_message constant
                     )
          );
}

sub foo { return &AFS::KA_USERAUTH_DOSETPAG }

# test error_message
is(error_message(&AFS::PRNOMORE), 'may not create more groups', 'Return Code AFS::PRNOMORE');
is(error_message(180502), 'too many Ubik security objects outstanding', 'Return Code 180502');

# test subroutine returning a constant
is(foo(42,17), 65536, 'Sub Foo returns constant (2 args)');
is(foo(42), 65536, 'Sub Foo returns constant (1 arg)');
is(foo(), 65536, 'Sub Foo returns constant (no args)');

# test constant
is(constant('PRIDEXIST'), 267265, 'Constant PRIDEXIST');
is(constant('PRIDEXIST', 2), 267265, 'Constant PRIDEXIST with argument');
isnt(constant('zzz'), 267265, 'Unknown Constant zzz');

# test AUTOLOAD running function "constant"
is(&AFS::PRIDEXIST, 267265, 'AutoLoad Constant PRIDEXIST');
