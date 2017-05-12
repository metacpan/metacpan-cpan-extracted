#!/usr/bin/perl
#
# This mod_perl script graphs the WHERE portion of a query passed in the sql URL argument
# To run it, The following items are required:
#
#	1. mod_perl including Apache2::Request;
#	2. Graphviz from http://www.graphviz.org
#	3. Ghostscript from http://www.ghostscript.com
#
# Best typographical results are obtained with the Verdana font from Microsoft
#
#	1. Download verdan32.exe from http://downloads.sourceforge.net/corefonts/verdan32.exe?
#	2. Extract verdan32.exe using cabextract (http://www.kyz.uklinux.net/cabextract.php) to obtain Verdana.TTF
#	3. Add the following line to /usr/share/ghostscript/7.07/lib/Fontmap.GS, replacing the correct path to Verdana.TTF
#
#	A live demo of the script is available at
#
#		http://69.61.72.18/mygraph/
#

use strict;
use DBIx::MyParse;
use GraphViz;
use Apache2::Request;

my $r = shift;
my $req = Apache2::Request->new($r);

$r->no_cache(1);

my $parser = DBIx::MyParse->new( datadir => "/tmp" );
$parser->setDatabase("test");

my $query = $parser->parse($req->param("sql"));

if ($query->getCommand() eq 'SQLCOM_ERROR') {
	$r->content_type("text/plain");
	$r->print($query->getErrstr());
	exit;
} else {
	$r->content_type("image/png");
}

our $graph = GraphViz->new();

foreach my $table (@{$query->getTables()}) {
	my $table_node = graph_item( $table );
} 

my $ps = $graph->as_ps();
my $ps_file = "/tmp/mygraph.ps.$$";
my $png_file = "/tmp/mygraph.png.$$";
open (PSFILE, ">$ps_file");
print PSFILE $ps;
close PSFILE;

system("/usr/bin/gs -sDEVICE=png16m -dNOPAUSE -dBATCH -sOutputFile=$png_file -dTextAlphaBits=4 -dGraphicsAlphaBits=4 $ps_file");

open (PNGFILE, $png_file );
read (PNGFILE, my $png, -s $png_file );
$r->print($png);

unlink($ps_file);
unlink($png_file);

sub graph_item {

	my $item = shift;
	my $type = $item->getType();

	my $node_name;

	if ($type eq 'FUNC_ITEM') {
		$node_name = $item->getFuncName();
	} elsif ($type eq 'JOIN_ITEM') {
		$node_name = $item->getJoinType();
		$node_name =~ s{JOIN_TYPE_}{}sgio;
		$node_name = 'INNER' if not defined $node_name;
		$node_name = lc($node_name);
	} elsif ($type eq 'TABLE_ITEM') {
		$node_name = $item->getAlias();
	} else {
		$node_name = $item->print();
	} 
	my $item_node = $graph->add_node($item, label => $node_name, fontname => 'Verdana', fillcolor => 'lightblue2', style => 'filled' );

	if (($type eq 'FUNC_ITEM') && ($item->getArguments())) {
		foreach my $arg_item (@{$item->getArguments()}) {
			my $arg_node = graph_item($arg_item);
			$graph->add_edge($item_node, $arg_node);
		}
	}

	if (($type eq 'JOIN_ITEM') && ($item->getJoinItems())) {
		my @join_items = @{$item->getJoinItems()};
		for (my $i = 0; $i <= $#join_items; $i++) {
			my $join_node = graph_item( $join_items[$i] );
			$graph->add_edge($item_node, $join_node );	
		}
	}

	return $item_node;
}

