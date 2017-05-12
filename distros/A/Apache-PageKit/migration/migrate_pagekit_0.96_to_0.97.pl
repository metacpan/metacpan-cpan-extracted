#!/usr/bin/perl

# Migratation of content from Apache::PageKit 0.96 to 0.97
# usage: ./migrate_pagekit_0.96_to_0.97.pl /path/to/pagekit/dir

use File::Find;
use File::Path;

use XML::LibXSLT;
use XML::LibXML;

$| = 1;

my $root_dir = $ARGV[0];

chomp(my $pwd = `pwd`);

File::Find::find(
		 sub {
		   return unless /\.xml$/;
		   migrate_content_file("$File::Find::dir/$_");
		 },
		 "$root_dir/Content/xml"
		);

sub migrate_content_file {
  my ($filename) = @_;

  print "parsing $filename\n";

  open FILE, "$filename";
  local($/) = undef;
  my $file = <FILE>;
  close FILE;

  # workaround for bug in LibXSLT 0.70
  $file =~ s/xml:lang/pkit_workaround_xml_lang/g;

  open FILE, ">$pwd/tmp";
  print FILE $file;
  close FILE;

  my $parser = XML::LibXML->new();
  my $xslt = XML::LibXSLT->new();
  my $source = $parser->parse_file("$pwd/tmp");
  my $style_doc = $parser->parse_file("$pwd/migrate_content_0.96_to_0.97.xsl");
  my $stylesheet = $xslt->parse_stylesheet($style_doc);
  my $results = $stylesheet->transform($source);
  my $output = $stylesheet->output_string($results);

  (my $new_filename = $filename) =~ s!^$root_dir/Content/xml!$root_dir/Content!;

  (my $dir = $new_filename) =~ s(/[^/]*?$)();
  File::Path::mkpath("$dir");

  open OUTPUT, ">$new_filename";
  print OUTPUT $output;
  close OUTPUT;
}
