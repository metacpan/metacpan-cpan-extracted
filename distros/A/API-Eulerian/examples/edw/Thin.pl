#/usr/bin/env perl
###############################################################################
#
# @file Thin.pl
#
# @brief Example of Eulerian Data Warehouse Peer performing an Analysis using
#        Thin Protocol.
#
# @author Thorillon Xavier:x.thorillon@eulerian.com
#
# @date 25/11/2021
#
# @version 1.0
#
###############################################################################
#
# Enforce compilor rules
#
use strict; use warnings;
#
# Import API::Eulerian::EDW::Peer instance factory
#
use API::Eulerian::EDW::Peer;
#
# Import API::Eulerian::EDW::Hook::Print
#
use API::Eulerian::EDW::Hook::Print;
#
# Sanity check mandatory command file
#
unless( defined( $ARGV[ 0 ] ) ) {
  die "Mandatory argument command file path is missing";
}
#
# Create a user specific Hook used to handle Analysis replies.
#
my $hook = new API::Eulerian::EDW::Hook::Print();
#
# Setup Peer options
#
my $path = $ARGV[ 0 ];
my %setup = (
  class => 'API::Eulerian::EDW::Peer::Thin',
  hook => $hook,
  grid => '', # TODO
  ip => '', # TODO
  token => '', # TODO
);
my $status;
my $peer;
my $cmd;

# Read command from File
$status = Eulerian::File->read( $path );
if( $status->error() ) {
  $status->dump();
} else {
  # Get command from file
  $cmd = $status->{ data };
  # Create Peer instance
  $peer = new API::Eulerian::EDW::Peer( \%setup );
  # Send Command, call hook
  $status = $peer->request( $cmd );
  if( $status->error() ) {
    $status->dump();
  } else {
    # Dump stages durations
    $status->{ bench }->dump();
    # Cancel the command
    $peer->cancel();
  }
}
