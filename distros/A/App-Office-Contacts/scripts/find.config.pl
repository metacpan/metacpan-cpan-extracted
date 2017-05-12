#!/usr/bin/env perl

use feature 'say';
use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8);    # Fatalize encoding glitches.
use open      qw(:std :utf8);    # Undeclared streams in UTF-8.
use charnames qw(:full :short);  # Unneeded in v5.16.

use File::ShareDir;

# --------------

my($app_name)    = 'App-Office-Contacts';
my($config_name) = '.htapp.office.contacts.conf';
my($path)        = File::ShareDir::dist_file($app_name, $config_name);

print "Using: File::ShareDir::dist_file('$app_name', '$config_name'): \n";
print "Found: $path\n";
