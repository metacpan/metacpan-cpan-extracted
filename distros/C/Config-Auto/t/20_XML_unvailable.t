use strict;
use warnings;
use Test::More 'no_plan';

my $Class = 'Config::Auto';

### this includes a dummy XML::Simple that dies on import
use lib 't/lib';

use_ok( $Class );

{   my $obj = $Class->new( source => $$.$/, format => 'xml' );
    ok( $obj,                   "Object created" );

    eval { $obj->parse };
    ok( $@,                     "parse() on xml dies without XML::Simple" );
    like( $@, qr/XML::Simple/,  "   Error message is informative" );
}
