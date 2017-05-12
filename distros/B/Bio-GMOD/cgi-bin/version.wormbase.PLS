#!perl
use Config;
use File::Basename qw(&basename &dirname);
use Cwd;

$origdir = cwd;
chdir dirname($0);
$file = basename($0, '.PL','.PLS');
#$file .= $^O eq 'VMS' ? '.com' : '.pl';

open OUT,">$file" or die "Can't create $file: $!";

print "Extracting $file (with variable substitutions)\n";

print OUT "$Config{startperl}\n";

print OUT <<'!NO!SUBS!';
#!/usr/bin/perl

# filename: version.wormbase.cgi
# Author: T. Harris
# A simple script to report the state of the current database

use lib '../lib';
use CGI 'param','header','path_info';
use Ace;
use Ace::Browser::AceSubs;
use ElegansSubs;
use strict;

use vars qw($DB);
$DB = OpenDatabase() || AceError("Couldn't open database.");

print header('text/xml');

my $to_display = { database => { title=>1,version  =>1,release=>1},
		   #		code     => { version=>1,build =>1},
		   #		resources=> { memory=>1,classes=>1},
		 };

my %status  = $DB->status;
my $version = $status{database}->{version};
my $title   = $status{database}->{title};

# Fetch the modtime of the current release.
my @temp = stat('/usr/local/acedb/' . "elegans_$version");
my $modtime = localtime($temp[9]);

# Fetch the modtime of the package release
my @package_temp = stat('/usr/local/ftp/pub/wormbase/database_tarballs/' . "$version");
my $package_modtime = localtime($package_temp[9]);


print qq{<?xml version="1.0" encoding="UTF-8"?>\n};
print qq{<!DOCTYPE mod_version SYSTEM "http://www.wormbase.org/dtd/gmod/version.dtd">};
print "<mod_version>\n";
print "<name>WormBase</name>\n";
print "<description>$title</description>\n";
print "<version>$version</version>\n";
print "<release_date>$modtime</release_date>\n";
print "</mod_version>";

exit 0;
!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;
