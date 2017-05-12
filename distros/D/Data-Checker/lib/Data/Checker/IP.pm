package Data::Checker::IP;
# Copyright (c) 2014-2016 Sullivan Beck. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

###############################################################################

require 5.008;
use warnings 'all';
use strict;
use NetAddr::IP::Lite qw(:nofqdn);
use NetAddr::IP 4.073;

our($VERSION);
$VERSION='1.08';

###############################################################################
###############################################################################

sub check {
   my($obj,$element,$desc,$check_opts) = @_;
   my $err    = [];
   my $warn   = [];
   my $info   = [];

   #
   # Must be a valid IP,
   #
   # Must be any of the forms supported by NetAddr::IP.
   #

   my $ip_obj = new NetAddr::IP $element;
   my $valid  = ($ip_obj ? 1 : 0);
   $obj->check_value($check_opts,undef,$element,$valid,
                     "Not a valid IP",undef,
                     $err,$warn,$info);
   return ($element,$err,$warn,$info)  if (@$err);

   #
   # Check IP version.
   #

   my $vers   = $ip_obj->version();
   if ($obj->check_performed($check_opts,'ipv4')) {
      my $is4  = ($vers == 4);
      $obj->check_value($check_opts,'ipv4',$element,$is4,
                        "IPv4 IP required",
                        "Non-IPv4 IP required",
                        $err,$warn,$info);
      return ($element,$err,$warn,$info)  if (@$err);
   }

   if ($obj->check_performed($check_opts,'ipv6')) {
      my $is6  = ($vers == 6);
      $obj->check_value($check_opts,'ipv6',$element,$is6,
                        "IPv6 IP required",
                        "Non-IPv6 IP required",
                        $err,$warn,$info);
      return ($element,$err,$warn,$info)  if (@$err);
   }

   #
   # in_network
   #

   my $net_obj;
   if ($obj->check_performed($check_opts,'in_network')) {
      my $val   = $obj->check_option($check_opts,'network',undef,'in_network');
      $net_obj  = new NetAddr::IP $val;

      # Must be a valid IP
      my $valid  = ($net_obj ? 1 : 0);
      $obj->check_value($check_opts,undef,$element,$valid,
                        "in_network must be a valid IP",undef,
                        $err,$warn,$info);
      return ($element,$err,$warn,$info)  if (@$err);

      # Must be the same version
      my $v     = $net_obj->version();
      if ($v != $vers) {
         $obj->check_value($check_opts,undef,$element,0,
                           "in_network and IP must both be IPv4 or IPv6",undef,
                           $err,$warn,$info);
         return ($element,$err,$warn,$info);
      }

      # Must contain network info
      my $mask  = $net_obj->masklen();
      if ( ($vers == 4  &&  $mask == 32) ||
           ($vers == 6  &&  $mask == 128) ) {
         $obj->check_value($check_opts,undef,$element,0,
                           "in_network must be a valid network IP",undef,
                           $err,$warn,$info);
         return ($element,$err,$warn,$info);
      }

      my $flag  = $net_obj->contains($ip_obj);
      $obj->check_value($check_opts,'in_network',$element,$flag,
                        "IP not in network",
                        "IP contained in network",
                        $err,$warn,$info);

      return ($element,$err,$warn,$info)  if (@$err);
   }

   #
   # network_ip, broadcast_ip
   #

   my $chk_net_ip   = ($obj->check_performed($check_opts,'network_ip') ? 1 : 0);
   my $chk_broad_ip = ($obj->check_performed($check_opts,'broadcast_ip') ? 1 : 0);
   if ( ($chk_net_ip  ||  $chk_broad_ip)  &&  ! $net_obj) {
      my $mask = $ip_obj->masklen();

      if ( ($vers == 4  &&  $mask == 32) ||
           ($vers == 6  &&  $mask == 128) ) {
         $obj->check_value($check_opts,undef,$element,0,
                           "IP must include network information for " .
                           "network/broadcast check",undef,
                           $err,$warn,$info);
         return ($element,$err,$warn,$info);
      }

      $net_obj = $ip_obj;
   }

   if ($chk_net_ip) {
      my $net_ip  = $net_obj->network->addr();
      my $ip      = $ip_obj->addr();
      $valid      = ($ip eq $net_ip);
      $obj->check_value($check_opts,'network_ip',$element,$valid,
                        "Network IP required",
                        "Non-network IP required",
                        $err,$warn,$info);
      return ($element,$err,$warn,$info)  if (@$err);
   }

   if ($chk_broad_ip) {
      my $broad_ip  = $net_obj->broadcast->addr();
      my $ip        = $ip_obj->addr();
      $valid        = ($ip eq $broad_ip);
      $obj->check_value($check_opts,'broadcast_ip',$element,$valid,
                        "Broadcast IP required",
                        "Non-broadcast IP required",
                        $err,$warn,$info);
      return ($element,$err,$warn,$info)  if (@$err);
   }

   return ($element,$err,$warn,$info);
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 3
# cperl-continued-statement-offset: 2
# cperl-continued-brace-offset: 0
# cperl-brace-offset: 0
# cperl-brace-imaginary-offset: 0
# cperl-label-offset: 0
# End:
