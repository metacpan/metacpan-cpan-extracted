use Test::More tests => 3;

require_ok('Algorithm::Merge');

eval { Algorithm::Merge -> import('diff3'); };

ok !$@;

eval { Algorithm::Merge -> import('merge'); };

ok !$@;

exit 0;

