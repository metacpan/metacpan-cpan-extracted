#!/usr/bin/perl -I. -w

#
# The configuration file in this test is buggy.  It's a Cisco
# bug so we'll try to work around it.
#

use Cisco::Reconfig;
use Test::More qw(no_plan);
use Carp qw(verbose);
use Scalar::Util qw(weaken);

my $debugdump = 0;

my $config = readconfig(\*DATA);

my $finished;

END { ok($finished, "finished") }

if ($debugdump) {
	no warnings;
	require FindBin;
	require YAML;
	require Data::Dumper;
	require File::Slurp;
	require "$FindBin::Bin/lib/Local/NoWeak.pm";
	local($Data::Dumper::Indent) = 1;
	my $strong_only = Local::NoWeak::strong_clone($config);
	File::Slurp::write_file("output.yaml", YAML::Dump($strong_only));
	File::Slurp::write_file("output.dd", Data::Dumper::Dumper($strong_only));
	exit(0);
}

ok(defined $config);

BAIL_OUT("parse failed") unless defined $config;

is($config->get('set-dscp-transmit 63')->alltext, <<END, 'get set-dscp-transmit 63');
set-dscp-transmit 63
  bandwidth 8
  random-detect
  random-detect exponential-weighting-constant 3
  random-detect precedence 6   20    32    10   
 class ce_ef_output
   police 40000 2000 2000 conform-action set-dscp-transmit ef exceed-action
END

is($config->get('exceed-action set-dscp-transmit af31')->alltext, <<END, 'get exceed-action set-dscp-transmit af31');
exceed-action set-dscp-transmit af31 violate-action set-dscp-transmit af32
  bandwidth 180
  random-detect dscp-based
  random-detect exponential-weighting-constant 3
  random-detect dscp 26   20    32    10   
  random-detect dscp 28   6     16    5    
 class class-default
  bandwidth 26
  random-detect
  random-detect exponential-weighting-constant 3
  random-detect precedence 0   12    32    5    
  random-detect precedence 1   12    32    5    
  random-detect precedence 2   12    32    5    
  random-detect precedence 3   12    32    5    
  random-detect precedence 4   12    32    5    
  random-detect precedence 5   12    32    5    
  random-detect precedence 6   40    64    10   
  random-detect precedence 7   12    32    5    
END

ok(! $config->get('exceed-action set-xyzds-transmit af31'), 'get line not in the file');
is($config->get('exceed-action set-xyzds-transmit af31')->text, '', 'get line not in the file text');
is($config->get('exceed-action set-xyzds-transmit af31')->alltext, '', 'get line not in the file alltext');

$finished = 1;

# -----------------------------------------------------------------


__DATA__

! From doug@scuttle.org.uk  Tue Mar 20 07:54:09 2007
! Return-Path: <doug@scuttle.org.uk>
! X-Original-To: muir@idiom.com
! Delivered-To: muir@idiom.com
! From: "Douglas Crabbe" <doug@scuttle.org.uk>
! To: <muir@idiom.com>
! Subject: Cisco Reconfig Issues...
! Date: Tue, 20 Mar 2007 14:53:31 -0000
! Message-ID: <000301c76aff$98fada90$0600a8c0@SCUTTLE>
! 
! David - firstly, thanks for putting together the Cisco Reconfig module -
! it's been really usefyul in terms of templating and automatically ensuring
! routers are deplyed to a standard.
! 
!  
! 
! I've come up with an issue around how it handles blocks - I'm using a 12.4
! IOS with class maps - these change the indenting without a corresponding "!"
! - Reconfig.pm croaks on line 103 at this.
! 
!  
! 
! Just wondered if you'd noticed this and/or had a work-around.
! 
!  
! 
! Many thanks.
! 
!  
! 
! Doug.
! 
!  
! 
! Example config below:
! 
!
policy-map Outbound
 class ce_mgmt_bundled_output
   police 8000 8000 8000 conform-action set-dscp-transmit 63 exceed-action
set-dscp-transmit 63
  bandwidth 8
  random-detect
  random-detect exponential-weighting-constant 3
  random-detect precedence 6   20    32    10   
 class ce_ef_output
   police 40000 2000 2000 conform-action set-dscp-transmit ef exceed-action
set-dscp-transmit ef violate-action drop 
  priority 40
 class ce_af3_output
   police 24000 13000 26000 conform-action set-dscp-transmit af31
exceed-action set-dscp-transmit af31 violate-action set-dscp-transmit af32
  bandwidth 180
  random-detect dscp-based
  random-detect exponential-weighting-constant 3
  random-detect dscp 26   20    32    10   
  random-detect dscp 28   6     16    5    
 class class-default
  bandwidth 26
  random-detect
  random-detect exponential-weighting-constant 3
  random-detect precedence 0   12    32    5    
  random-detect precedence 1   12    32    5    
  random-detect precedence 2   12    32    5    
  random-detect precedence 3   12    32    5    
  random-detect precedence 4   12    32    5    
  random-detect precedence 5   12    32    5    
  random-detect precedence 6   40    64    10   
  random-detect precedence 7   12    32    5    
policy-map Inbound
 class ce_ef_input
   police 40000 2000 2000 conform-action set-dscp-transmit ef exceed-action
set-dscp-transmit ef
 class ce_af3_input
   police 24000 13000 26000 conform-action set-dscp-transmit af31
exceed-action set-dscp-transmit af32

!
