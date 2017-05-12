#
# $Id$

use strict;

use Test::More tests => 3;

use_ok( "Clusterize" );
my $clusterize = Clusterize->new;
isa_ok( $clusterize, 'Clusterize');
ok(defined $clusterize);
