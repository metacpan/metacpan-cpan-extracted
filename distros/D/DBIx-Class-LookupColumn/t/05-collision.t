use Test::More;
use Test::Exception;
use strict;
use warnings;
use Data::Dumper;

use v5.14.2;
use lib qw(t/lib);

use Smart::Comments -ENV;

# SchemaCollision defines a method called permission, and a lookup with same name
throws_ok { require SchemaCollision } qr/already defined/i, 'collision detected';


done_testing;
