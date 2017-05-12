#!/usr/bin/perl

# Migratation scripts from Apache::PageKit 0.05 to 0.89
# usage: ./migrate_pagekit_0.05_to_0.89.pl /home/tjmather/anidea/page.xml /home/tjmather/anidea/

# note that this script is not perfect and will not 
# work in all cases

# in addition, you must take the server conf directives from httpd.conf
# and put them between <SERVER> </SERVER> tags in Config.xml manually
# and the constructor arguments from MyPageKit.pm (or where your 
# mod_perl Handler is defined) and put them between <GLOBAL> </GLOBAL>
# tags in Config.xml

use XML::Parser;

use vars qw($in_content);

use strict;

# This script takes the following inputs:
# 1. page.xml (page cnf and data)
# and outputs:
# 1. Config/Config.xml (global/server/page config)
# 2. Content/XML/ (page data)

# STEP 1 Load XML Data From page.xml
  my $p = XML::Parser->new(Style => 'Stream',
			   ParseParamEnt => 1,
			   NoLWP => 1);

  my $root_dir = $ARGV[1];

  mkdir "$root_dir/Content", 0755;
  mkdir "$root_dir/Content/xml", 0755;
  mkdir "$root_dir/Content/cache", 0755;
  mkdir "$root_dir/Config", 0755;

  open CONFIG, ">$root_dir/Config/Config.xml.deleteme";

  print CONFIG "<CONFIG>\n";
  print CONFIG "<GLOBAL/>\n";
  print CONFIG "<SERVERS>\n";
  print CONFIG "</SERVERS>\n";
  print CONFIG "<PAGES>\n";
  $p->parsefile($ARGV[0]);
  print CONFIG "</PAGES>\n";
  print CONFIG "</CONFIG>\n";

sub StartTag {
  my ($p, $element) = @_;
  if($element eq 'PAGE'){
    open CONTENT, ">$root_dir/Content/xml/$_{page_id}.xml";
    print CONTENT qq{<?xml version="1.0" ?>\n};
    print CONTENT qq{<!DOCTYPE pagekit SYSTEM "../Content.dtd">\n};
    print CONTENT "<PAGE>\n";
  }
  if($element eq 'TMPL_VAR'){
    $in_content++;
    print CONTENT "$_<![CDATA[";    
  } elsif($element =~ /^TMPL_/){
    $in_content++;
    print CONTENT $_;
  } elsif ($element eq 'SITE'){
    return;
  } else {
    print CONFIG $_;
  }
}

sub EndTag {
  my ($p, $element) = @_;
  if($element eq 'PAGE'){
    print CONTENT "</PAGE>\n";
    close CONTENT;
  }
  if($element eq 'TMPL_VAR'){
    $in_content--;
    print CONTENT "]]>$_\n";
  } elsif($element =~ /^TMPL_/){
    $in_content--;
    print CONTENT "$_\n";
  } elsif ($element eq 'SITE'){
    return;
  } else {
    print CONFIG $_;
  }
}

sub Text {
  if ($in_content > 0){
    print CONTENT $_;
  } else {
    print CONFIG $_;
  }
}
