use strict;
use warnings;
use Test::More 'no_plan';

my $Class   = 'Config::Auto';
my $Method  = 'score';
my $Data    = <<'.';
[part one]
This: is garbage
.

use_ok( $Class );

{   my $obj = $Class->new( source => $Data );
    ok( $obj,                   "Object created" );
    isa_ok( $obj, $Class,       "   Object" );

    {   my $warnings = '';
        local $SIG{__WARN__} = sub { $warnings .= "@_" };

        my $rv = $obj->$Method;
        ok( scalar(keys %$rv),  "   Got return value from '$Method'" );
        is( $warnings, '',      "   No warnings recorded" );
    }
}
