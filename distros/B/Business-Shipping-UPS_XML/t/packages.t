#!/usr/bin/perl -w       
################################################################################
#
#  Script Name : ScriptName
#  Version     : 1
#  Company     : Down Home Web Design, Inc
#  Author      : Duane Hinkley ( duane@dhwd.com )
#  Website     : www.DownHomeWebDesign.com
#
#  Copyright (c) 2004 Down Home Web Design, Inc.  All rights reserved.
#
#  This is free software; you can redistribute it and/or modify it
#  under the same terms as Perl itself.
#
#  Description:
#
#
#  $Header: /home/cvs/interchange_upsxml/t/packages.t,v 1.4 2004/06/27 14:25:28 dlhinkley Exp $
#
#  $Log: packages.t,v $
#  Revision 1.4  2004/06/27 14:25:28  dlhinkley
#  Cleaning up for realease
#
#  Revision 1.2  2004/06/27 14:07:25  dlhinkley
#  Getting ready for release
#
#  Revision 1.1  2004/06/15 14:56:34  dlhinkley
#  Added sending dimensions for multiple packages
#
#  Revision 1.4  2004/06/15 00:05:55  dlhinkley
#  Changes
#
#  Revision 1.2  2004/06/10 00:18:33  cvs
#  Clean up and document code
#
#  Revision 1.1  2004/06/06 21:38:39  cvs
#  Created as a Perl Module.  Moved the files over from unlimited_interchange and created new ones
#
#
################################################################################

use strict;
use lib qw( ./lib ../lib );
use Business::Shipping::UPS_XML;

use Test::More tests => 4;



use Data::Dumper;


my $config_file = "t/log/config.cfg";
my $userid;
my $userid_pass;
my $access_key;
my $origin_country	= 'CA';
my $origin_zip		= 'L4J8J2';
my $ups;
my $maxcost;
my $zone;
my $error;

if ( -f $config_file ) {


	open( CFG, "< $config_file");

	$userid = <CFG>;
	chomp($userid);

	$userid_pass = <CFG>;
	chomp($userid_pass);

	$access_key = <CFG>;
	chomp($access_key);

	close(CFG);


    $ups = new Business::Shipping::UPS_XML($userid,$userid_pass,$access_key,$origin_country);




    ($maxcost, $zone, $error) = $ups->getUPS( '11',$origin_zip, 'V5T3E2', 'CA','40');
	ok( $error eq '', "No Dimensions Service Test $maxcost\n") or diag($error);


    $ups->set_dimensions( '10', '10', '30', 'IN', '40');
    ($maxcost, $zone, $error) = $ups->getUPS( '11',$origin_zip, 'V5T3E2', 'CA','');
	ok( $error eq '', "Single Dimensions With Weight Service Test $maxcost\n") or diag($error);


    $ups->set_dimensions( '10', '10', '30', 'IN', '40');
    $ups->set_dimensions( '11', '11', '31', 'IN', '41');
    ($maxcost, $zone, $error) = $ups->getUPS( '11',$origin_zip, 'V5T3E2', 'CA','');
	ok( $error eq '', "Double Package Dimensions With Weight Service Test $maxcost\n") or diag($error);


    $ups->set_dimensions( '10', '10', '30', 'IN', '40');
    $ups->set_dimensions( '11', '11', '31', 'IN', '41');
    $ups->set_dimensions( '12', '12', '32', 'IN', '42');
    ($maxcost, $zone, $error) = $ups->getUPS( '11',$origin_zip, 'V5T3E2', 'CA','');
	ok( $error eq '', "Triple Package Dimensions With Weight Service Test $maxcost\n") or diag($error);

}

