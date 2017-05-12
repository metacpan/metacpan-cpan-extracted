use strict;
use warnings;

use lib q(lib);

use Test::More tests => 2;
use Data::AsObject qw(dao);

my $dao = dao { foo => [1,2,3] };
is(eval { $dao->croak('bar') }, undef, 'croak does not exist in config');
like($@, qr{attempting to access}i, 'croak is cleaned out of namespace');

