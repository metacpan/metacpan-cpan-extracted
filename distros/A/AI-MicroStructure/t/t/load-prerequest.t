use warnings;
use Test::More tests =>2;

BEGIN {
  ok("require basedep.$_.t" ) for(qw/dodo santex/);

}


1;

