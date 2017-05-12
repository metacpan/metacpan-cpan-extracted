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
#  $Header: /home/cvs/interchange_upsxml/t/01-core.t,v 1.7 2004/06/27 14:25:28 dlhinkley Exp $
#
#  $Log: 01-core.t,v $
#  Revision 1.7  2004/06/27 14:25:28  dlhinkley
#  Cleaning up for realease
#
#  Revision 1.5  2004/06/27 14:07:25  dlhinkley
#  Getting ready for release
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

use ExtUtils::MakeMaker qw(prompt);

use Test::More tests => 17;

my $config_file = "t/log/config.cfg";
my $userid;
my $userid_pass;
my $access_key;
my $origin_country	= 'CA';
my $origin_zip		= 'L4J8J2';
my $ups;

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


	test_query('11',$origin_zip,'V5T3E2', '40', 'CA','', '', '', '',1);
	test_query('11',$origin_zip,'48060', '40', 'US','', '', '', '',1);
	test_query('11',$origin_zip,'48060', '75', 'US','', '', '', '',1);
	test_query('11',$origin_zip,'48060', '150', 'US','', '', '', '',1);
	test_query('11',$origin_zip,'48060', '151', 'US','', '', '', '',0);
        test_query('01','L4J8J2', '83711', '3', 'US','10', '10', '30', 'IN',1);
        test_query('02','L4J8J2', '83711', '3', 'US','10', '10', '30', 'IN',0);
        test_query('03','L4J8J2', '83711', '3', 'US','10', '10', '30', 'IN',1);
        test_query('07','L4J8J2', '83711', '3', 'US','10', '10', '30', 'IN',1);
        test_query('08','L4J8J2', '83711', '3', 'US','10', '10', '30', 'IN',1);
        test_query('11','L4J8J2', '83711', '3', 'US','10', '10', '30', 'IN',1);
        #test_query('12','L4J8J2', '83711', '3', 'US','10', '10', '30', 'IN',1);
        test_query('13','L4J8J2', '83711', '3', 'US','10', '10', '30', 'IN',0);
        test_query('14','L4J8J2', '83711', '3', 'US','10', '10', '30', 'IN',1);
        test_query('54','L4J8J2', '83711', '3', 'US','10', '10', '30', 'IN',1);
        test_query('59','L4J8J2', '83711', '3', 'US','10', '10', '30', 'IN',0);
        test_query('64','L4J8J2', '83711', '3', 'US','10', '10', '30', 'IN',0);
        test_query('65','L4J8J2', '83711', '3', 'US','10', '10', '30', 'IN',0);
}

sub test_query {

	my ($s,$origin_zip,$zip,$weight,$country,$length,$width,$height,$units,$pass) = @_;

   $ups->set_dimensions( $length,$width,$height, $units, $weight);
   my ($maxcost, $zone, $error) = $ups->getUPS( $s,$origin_zip, $zip,$country,$weight);

 #print Dumper($ups);
   if ( $pass == 1 ) {

	ok( $error eq '', "Service $s from $origin_zip to $zip, $weight lbs: $maxcost\n") or diag($error);
   }
   else {

	ok( $error ne '', "Service $s from $origin_zip to $zip, $weight lbs: $maxcost\n") or diag($error);
   }
}