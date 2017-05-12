use strict;
use Test;

BEGIN { plan tests => 1 }
use Business::3DSecure;

my $tx = new Business::3DSecure( "Cardinal" );
ok ( ref $tx , "Business::3DSecure::Cardinal" )