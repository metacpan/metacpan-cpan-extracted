#/usr/bin/env perl
###############################################################################
#
# @file Print.pm
#
# @brief Eulerian Data Warehouse Peer Print Hook class Module definition.
#
# This module is aimed to print Eulerian Data Warehouse Analytics Results into
# the terminal.
#
# @author Thorillon Xavier:x.thorillon@eulerian.com
#
# @date 26/11/2021
#
# @version 1.0
#
###############################################################################
package API::Eulerian::EDW::Hook::Noop;
use strict;
#
# Inherited interface from API::Eulerian::EDW::Hook
#
#use parent 'API::Eulerian::EDW::Hook';

use API::Eulerian::EDW::Hook();

our @ISA = qw/ API::Eulerian::EDW::Hook /;

#
# @brief Allocate a new Eulerian Data Warehouse Peer Hook.
#
# @param $class - Eulerian Data Warehouse Peer Hook Class.
# @param $setup - Setup attributes.
#
# @return Eulerian Data Warehouse Peer Hook instance.
#
sub new
{
  my ( $class, $setup ) = @_;
  return $class->SUPER::new( $setup );
}
#
# @brief Setup Eulerian Data Warehouse Peer Hook.
#
# @param $self - Eulerian Data Warehouse Peer Hook.
# @param $setup - Setup entries.
#
sub setup
{
  my ( $self, $setup ) = @_;
  return $self;
}
#
# @brief Start a new Analysis.
#
# @param $self - Eulerian Data Warehouse Peer Hook.
# @param $uuid - UUID of Eulerian Analytics Analysis.
# @param $start - Timerange begin.
# @param $end - Timerange end.
# @param $columns - Array of Columns definitions.
#
sub on_headers
{
  my ( $self, $uuid, $start, $end, $columns ) = @_;
  return $self;
}
#
# @brief Analysis reply rows on Row outputs analysis.
#
# @param $self - Eulerian Data Warehouse Peer Hook.
# @param $uuid - UUID of Eulerian Analytics Analysis.
# @param $rows - Array of Array of Columns values.
#
sub on_add
{
  my ( $self, $uuid, $rows ) = @_;
  return $self;
}
#
# @brief Analysis reply rows on Distinct/Pivot analysis.
#
# @param $self - Eulerian Data Warehouse Peer Hook.
# @param $uuid - UUID of Eulerian Analytics Analysis.
# @param $rows - Array of Array of Columns values.
#
sub on_replace
{
  my ( $self, $uuid, $rows ) = @_;
  return $self;

}
#
# @brief Analysis progression callback.
#
# @param $self - Eulerian Data Warehouse Peer Hook.
# @param $uuid - UUID of Eulerian Analytics Analysis.
# @param $progress - Progression value.
#
sub on_progress
{
  my ( $self, $uuid, $progress ) = @_;
  return $self;
}
#
# @brief End of Eulerian Data Warehouse Analysis.
#
# @param $self - Eulerian Data Warehouse Peer Hook.
# @param $uuid - UUID of Eulerian Analytics Analysis.
# @param $token - AES Token or Bearer.
# @param $errnum - Error number.
# @param $err - Error description.
# @param $updated - Count of updates on server.
#
sub on_status
{
  my ( $self, $uuid, $token, $errnum, $err, $updated ) = @_;
  return $self;
}

#
# Endup module properly
#
1;
