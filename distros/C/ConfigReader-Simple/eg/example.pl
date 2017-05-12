#!/usr/bin/perl -w
#
# Testing ConfigReader::Simple
#
# Last updated by gossamer on Tue Sep  1 22:43:42 EST 1998
#

use ConfigReader::Simple;


my $config = ConfigReader::Simple->new("./example.config", [qw(Test1 Test2)]);

$config->parse();
$config->_validate_keys();  # die if there are keys in example.config 
                            # that aren't declared.

print "The value for directive Test1 is: " . $config->get("Test1") . "\n";

