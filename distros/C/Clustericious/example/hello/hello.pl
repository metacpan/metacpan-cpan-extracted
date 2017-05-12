use strict;
use warnings;
use Clustericious::HelloWorld;
use Path::Class qw( file );

# This example uses Clustericious::HelloWorld which lives in the
# main distribution as lib/Clustericious/HelloWorld.pm
# see also the client in helloclient.pl

$ENV{CLUSTERICIOUS_CONF_DIR} = file(__FILE__)->parent->absolute->stringify;

$ENV{MOJO_APP} = 'Clustericious::HelloWorld';
Clustericious::Commands->start;

