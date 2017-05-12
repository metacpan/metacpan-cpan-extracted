use strict;
use warnings;
use Clustericious;
use Test::More tests => 1;

like(Clustericious->_generate_port, qr{^[0-9]+$}, "gets us a port!");
