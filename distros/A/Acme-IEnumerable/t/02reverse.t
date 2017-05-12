use strict;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok('Acme::IEnumerable') };

my @sorted = Acme::IEnumerable
  ->from_list(qw/1 2 3/)
  ->reverse
  ->to_perl;

is_deeply \@sorted, [qw/3 2 1/];
