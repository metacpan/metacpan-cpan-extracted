use strict;
use warnings;
use Test::More tests => 3;

use_ok('Clustericious::Client::Object::DateTime');

my $obj = Clustericious::Client::Object::DateTime->new('2000-01-01');

isa_ok($obj, 'DateTime');
is("$obj", '2000-01-01T00:00:00', 'Check DateTime value');

