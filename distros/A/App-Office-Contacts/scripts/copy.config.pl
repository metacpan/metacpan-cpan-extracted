#!/usr/bin/env perl

use strict;
use warnings;

use File::Copy;
use File::ShareDir;

use Path::Tiny; # For path().

use Try::Tiny;

# --------------

my($app_name)    = 'App-Office-Contacts';
my($config_name) = '.htapp.office.contacts.conf';

my($dist_dir);

try
{
	$dist_dir = File::ShareDir::dist_dir($app_name);
}
catch
{
	die "File::ShareDir::dist_dir($app_name) cannot find the distro's installation directory\n";
};

my($source_file_name) = path("share/$config_name");

File::Copy::copy($source_file_name, $dist_dir);

try
{
	print "Copied $source_file_name to $dist_dir\n";
}
catch
{
	die "Unable to copy $source_file_name to $dist_dir\n";
};
