# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 00_load.t'

use Test::More tests => 1;

BEGIN {
    use_ok('DateTimeX::Fiscal::Fiscal5253')
      or BAIL_OUT('Impossible to test if module will not load');
}

exit;

__END__
