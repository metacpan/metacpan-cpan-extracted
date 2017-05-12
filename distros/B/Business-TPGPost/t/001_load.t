# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Business::TPGPost' ); }

my $object = Business::TPGPost->new ();
isa_ok ($object, 'Business::TNTPost::NL');

print STDERR <<"EOF";

==========================================================================
PLEASE NOTE:
==========================================================================
This module went through a name change. This script is now merely a
wrapper around the new Business::TNTPost::NL.

Don't expect wonders of this wrapper, it's likely to break your scripts
(in the future)! Please update your scripts to use Business::TNTPost::NL
==========================================================================
EOF
sleep 5;
