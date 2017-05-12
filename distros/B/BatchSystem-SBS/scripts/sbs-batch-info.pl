#!/usr/bin/env perl
use strict;

use BatchSystem::SBS::ScriptsCommon;
BatchSystem::SBS::ScriptsCommon::init();


use Getopt::Long;
my($field);
if (!GetOptions(
		"field=s"=>\$field,
	       )
   ){
  die;
}
die "must pass a --field=INFO_FIELD[,OTHER FIELD] argument (e.g status)" unless $field;

my @fields=split /,/, $field;
foreach (@ARGV){
  if(/^all$/i){
    my @tmp=
  }
  my %h=$sbs->job_info(id=>$_);
  print $h{id};
  print "\t$h{$_}" foreach (@fields);
  print "\n";
}
