use strict;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok('Acme::IEnumerable') };

my @sorted = Acme::IEnumerable
  ->from_list(qw/zzz z zz/)
  ->order_by(sub { length })
  ->to_perl;

is_deeply \@sorted, [qw/z zz zzz/];
