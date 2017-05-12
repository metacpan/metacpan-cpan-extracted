#!/usr/bin/env perl

######################################################
# Author: Chengzhi Liang, Weigang Qiu, Peter Yang, Thomas Hladish, Brendan
# $Id: assumptionsblock_options.t,v 1.10 2010/09/22 19:59:00 astoltzfus Exp $
# $Revision: 1.10 $



# Written by Mikhail Bezruchko, Vivek Gopalan, Arlin Stoltzfus
# Refernce: http://www.perl.com/pub/a/2004/05/07/testing.html?page=2
# Date: 31 Jan 2007

use strict;
use warnings;
use Test::More 'no_plan';

use Bio::NEXUS;
use Data::Dumper;

################################
#	Testing 'Options' command
#	of Assumptions block.
################################

print "\n";

# methods/basic functions:
# - read options:
#	a. read a nexus file
#	b. get the assump_block
#	c. assump_block->get_def_type() eq 'expected'
#	d. assump_block->...() eq 'expected' ...
my $nex_obj;
eval {
    $nex_obj = new Bio::NEXUS("t/data/compliant/02_assumptions-block_options_02.nex");
};

my $assump_block = $nex_obj->get_block("assumptions");
#print Dumper $assump_block;

is ($@, '', "File parsed w/o errors");


print "--- get_option() ---\n";
is ($assump_block->get_option('deftype'), "unord", "deftype=unord");
is ($assump_block->get_option('gapmode'), "missing", "gapmode=missing");
is ($assump_block->get_option('polytcount'), undef, "polytcount is undefined");
is ($assump_block->get_option('unsupported_option'), undef, "no such option: unsupported_option: return undef");


print "--- set_option() ---\n";
$assump_block->set_option('deftype', 'Dollo');
$assump_block->set_option('gapmode', 'NewState');
$assump_block->set_option('random_opt', 'random_val');

is ($assump_block->get_option('deftype'), 'dollo', "deftype=dollo");
is ($assump_block->get_option('gapmode'), 'newstate', "gapmode=newstate");
is ($assump_block->get_option('polytcount'), undef, "polytcount is undefined");
is ($assump_block->get_option('random_opt'), 'random_val', "random_opt=random_val");


print "--- get_all_options() ---\n";
my $options = $assump_block->get_all_options();
print Dumper $options;
my $options_expected = {'deftype' => 'dollo',
			'gapmode' => 'newstate',
			'random_opt' => 'random_val'};
is_deeply ($options, $options_expected, "structures are equal");


print "--- set_all_options() ---\n";
# note: is_deeply is case sensitive, so: make sure that
#  the expected values match observed AND the case matches too
my $new_options = {'deftype' => 'unord',
			'gapmode' => 'missing',
			'random_opt' => ''};
$assump_block->set_all_options($new_options);
my $options_got = $assump_block->get_all_options();
is_deeply($new_options, $options_got, "structures are equal");

#print Dumper $assump_block->get_all_options();
#print Dumper $options_got;

print "Printing the assumption block\n";
$assump_block->_write();
$assump_block->{'options'} = {'deftype' => undef,
			      'gapmode' => 'missing'};

print "Deleting the options\n";
print Dumper $assump_block;

print "Printing the assumption block\n";
$assump_block->_write();


# - write options should be tested ... somehow.
# ...

print "--- _validate_options() ---\n";
print "> set_option()\n";
$assump_block->set_option('DefType', 'spam');

print "> set_all_options()\n";
$assump_block->set_all_options({'deftype' => 'spam_spam', 'gapmode' => 'eggs', 'new_option' => 'some_val'});
print Dumper $assump_block->get_all_options();

print "--- testing another file ---\n";
$nex_obj = undef;
eval {
    $nex_obj = new Bio::NEXUS("t/data/compliant/02_assumptions-block_options_01.nex");
};


$assump_block = $nex_obj->get_block("assumptions");
print Dumper $assump_block;

is ($@, '', "File parsed w/o errors");

print "--- get_option() ---\n";
is ($assump_block->get_option('deftype'), "unord", "deftype=unord");
