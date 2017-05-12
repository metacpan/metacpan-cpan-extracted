#!/usr/bin/perl -w

# $Id: build_locale.pl,v 1.1 2001/12/04 13:57:49 borisz Exp $

use strict;

use File::Path;

use vars qw( $root_dir $template_dir @catalog_files $msgfmt_cmd );

chomp( $msgfmt_cmd = `which msgfmt` );
$msgfmt_cmd =~ /^which: no/ and die "msgfmt not found!";

$root_dir = shift || die "$0 /full/path/to/your/documentroot";

$template_dir = $root_dir . '/contrib/locale/templates/po';

chdir $template_dir and opendir DIR, '.' or die "$!";
@catalog_files = grep { /\.po$/ && -f } readdir DIR;
closedir DIR;

for (@catalog_files) {
  my ($lang) = /(.*)\.po$/;
  my $catalog_dir = "$root_dir/locale/$lang/LC_MESSAGES";
  mkpath($catalog_dir);
  print "Create catalog $catalog_dir/PageKit.mo\n";
  system( "$msgfmt_cmd", "-o", "$catalog_dir/PageKit.mo", "$_" ) == 0 or die "$msgfmt_cmd failed $?";
}
