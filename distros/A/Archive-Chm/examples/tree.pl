#!/usr/bin/perl -w
#   Example script of the Archive::Chm module. It shows how you can get information about the
# structure of a chm archive. Since extract_all dumps all the .html's to the output folder
# you'll need something like this in your script in order to properly reproduce the
# tree structure.
#
#   If you need to extract the archive in a folder-tree as the one it was compiled in you can
# modify this script to use extract_item and put every .html in it's designated folder.
#	If you only want to display the separate .html's in the structure from the TOC, you can
# dump all .html's in one folder and use this script to create a kind of virtual folder for
# navigating through the archive.
#
#   It's your choice, really. :)

use strict;

use HTML::TreeBuilder;
use Archive::Chm;

#get the table of contents from the .chm archive
my $chm = Archive::Chm->new("TestPrj.chm");
my $fout;
open($fout, ">", "TOC.hhc") ||
    die "Can't create file TOC.hhc";
my $item = $chm->extract_item("/Table of Contents.hhc");
# and
#	die "Can't extract the table of contents.\n";
print $fout, $item;
close $fout;

#parse the TOC file into a HTML tree
my $tree = HTML::TreeBuilder->new;
$tree->parse_file("TOC.hhc");


#move through the tree until we get to the start of the list
#as in the first <ul> tag in the body of the HTML file
my $el = $tree;
foreach ($el->content_list()) {
	if ($_->tag() eq "body") {
		$el = $_; last;
	}
}
foreach ($el->content_list()) {
	if ($_->tag() eq "ul") {
		$el = $_; last;
	}
}
#now do a DFS on the tree starting at root of the list
DFS($el, 0);
#finally delete the tree and the TOC
$tree = $tree->delete();
unlink("TOC.hhc") or
	die "Error deleting 'TOC.hhc' in test script: $!\n";




#Depth First Search function. It goes through all elements in the html
#tree starting at the root element.
sub DFS {
	my ($el, $nspaces) = @_;
	my $next;

	#if the tag is "object", we have a leaf node
	if ($el->tag() eq "object") {
		my ($name, $url, $spaces);
		for (my $i = 0; $i < $nspaces; $i++) {
			$spaces .= ' ';
		}
		#get the content of all the <param ...> tags
		foreach ($el->content_list()) {
			if ($_->attr("name") eq "Name") {
				$name = $_->attr("value");
			}
			elsif ($_->attr("name") eq "Local") {
				$url = $_->attr("value");
			}
		}
		#if we have a name and a url print them
		print $spaces . "Name = $name\n" if defined($name);
		print $spaces . "URL = $url\n" if defined($url);
	}
	#else just move through all descendents
	else {
		foreach $next ($el->content_list()) {
			DFS($next, $nspaces + 2);
		}
	}
}