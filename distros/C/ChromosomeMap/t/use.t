# $Id: use.t,v 1.0 2010/01/02
use Test;
use strict;

BEGIN { plan tests => 5 }

use Chromosome::Map;
ok(1);
use Chromosome::Map::Block;
ok(1);
use Chromosome::Map::Element;
ok(1);
use Chromosome::Map::Feature;
ok(1);
use Chromosome::Map::Track;
ok(1);
