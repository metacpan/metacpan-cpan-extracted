#!/usr/bin/env perl -w

use ExtUtils::Packlist;
use ExtUtils::Installed;

$ARGV[0] or die "Usage: $0 Module::Name\n";

my $module = $ARGV[0]; 

my $installed = ExtUtils::Installed->new();

foreach my $item ( sort( $installed->files($module) ) ) {
  print "removing $item\n";
  unlink $item;
}

my $packfile = $installed->packlist($module)->packlist_file();
print "removing $packfile\n";
unlink $packfile;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

