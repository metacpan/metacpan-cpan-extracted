use warnings;
use strict;

use Bit::Manip::PP qw(:all);
use Test::More;

my $mod = 'Bit::Manip::PP';

{ # bad param

    my $ok = eval { $mod->_check_value(-1); 1; };
    is $ok, undef, "_check_value() dies if parameter is < 0";
    like $@, qr/must be zero or greater/, "...with ok error msg";
}

done_testing();
