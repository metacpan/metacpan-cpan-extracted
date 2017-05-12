#!/usr/bin/perl

use lib '/dj/tools/perl-dbr/lib';
use DBR::Util::Logger;
use DBR;
use strict;
use Data::Dumper;

chdir '../';

my $logger = new DBR::Util::Logger(-logpath => '/tmp/dbr_example.log', -logLevel => 'debug3');
my $dbr    = new DBR(
		     -logger => $logger,
		     -conf   => 'support/example_dbr.conf',
		    );






my $dbrh = $dbr->connect('example') || die "failed to connect";

my $ret = $dbrh->select(
			-table => 'album',
			-fields => 'album_id artist_id name'
		       ) or die 'failed to select from album';


print Dumper($ret);
