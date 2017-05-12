use warnings;
use strict;

use Bit::Manip::PP qw(:all);
use Test::More;

my $mod = 'Bit::Manip::PP';

{ # bad param

    my $ok;

    $ok = eval { $mod->_ref('a9'); 1; };
    is $ok, undef, "can't contain alpha";
    like $@, qr/integer or a SCALAR/, "...with ok error msg";

    $ok = eval { $mod->_ref({}); 1; };
    is $ok, undef, "can't be a hash reference";
    like $@, qr/integer or a SCALAR/, "...with ok error msg";

    $ok = eval { $mod->_ref([]); 1; };
    is $ok, undef, "can't be an array reference";
    like $@, qr/integer or a SCALAR/, "...with ok error msg";

    my $x = 'a9';

    $ok = eval { $mod->_ref(\$x); 1; };
    is $ok, undef, "reference must be an integer only";
    like $@, qr/contain only an integer/, "...with ok error msg";
}

{ # ok operation

    is $mod->_ref(5), 0, "single digit is ok, but isn't a ref";
    is $mod->_ref(55), 0, "double digit is ok, but isn't a ref";
    is $mod->_ref(255), 0, "triple digit is ok, but isn't a ref";

    is $mod->_ref(\5), 1, "single digit ref is ok, so is return";
    is $mod->_ref(\55), 1, "double digit ref is ok, so is return";
    is $mod->_ref(\255), 1, "triple digit ref is ok, so is return";
}

done_testing;
