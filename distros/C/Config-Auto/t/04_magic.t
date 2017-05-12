use strict;
use warnings;
use Test::More 'no_plan';

BEGIN { chdir 't' if -d 't'; }


my $Class   = 'Config::Auto';

use_ok( $Class );

### find a config file based on $0
{   my $obj = $Class->new( path => ['src'] );
    ok( $obj,                   "Object created" );
    isa_ok( $obj, $Class,       "   Object" );

    my $file = $obj->file;
    ok( $file,                  "   File found: $file" );
    ok( -e $file,               "   File exists" );
}
