use 5.010000;
use strict;
use warnings;

use Test::CheckManifest;

ok_manifest( { filter => [ qr/\.git/ ] } );
