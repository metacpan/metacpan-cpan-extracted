package FOO;

use lib qw( ./lib ../lib );


sub bar {
  shift->nOfElements;
}

1;
