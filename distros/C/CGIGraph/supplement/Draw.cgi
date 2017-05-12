#!/usr/bin/perl

use CGI;
use GD;
use CGI::Graph;

$q = new CGI;

%hash = $q->Vars;
my $type = new CGI::Graph(\%hash);

if ($q->param('grid')) {
	$gd = $type->drawGrid();
}

else {
	$gd = $type->drawGraph();
}

print $q->header('image/png');
binmode STDOUT;
print STDOUT $gd->png;
