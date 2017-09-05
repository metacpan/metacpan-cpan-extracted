package App::Pods2Site::SiteBuilder::AbstractBasicFrames;

use strict;
use warnings;

use base qw(App::Pods2Site::AbstractSiteBuilder);

use App::Pods2Site::Util qw(slashify readData writeData writeUTF8File);

use HTML::Entities;

sub _getCssContent
{
	return <<MYCSS;
\@charset "UTF-8";

html
{
	font-family: sans-serif;
	font-size: small;
}

MYCSS
}

sub makeSite
{
	my $self = shift;
	my $args = shift;
	my $workGroups = shift;
	my $partCounts = shift;

	$self->__updateMain($args, $partCounts);
	$self->__updateHeader($args);
	$self->__updateTOC($args, $workGroups);
	$self->__updateIndex($args);
}

# PRIVATE
#

sub __updateMain
{
	my $self = shift;
	my $args = shift;
	my $partCounts = shift;

	my $z = encode_entities(slashify($0));
	my $zv = encode_entities($App::Pods2Site::VERSION);
	my $x = encode_entities($^X);
	my $xv = encode_entities($]);
	my $builtBy = "<p><strong>This site built using:</strong><br/>";
	$builtBy .= "&emsp;$z ($zv)<br/>";
	$builtBy .= "&emsp;$x ($xv)<br/>\n";
	$builtBy .= "</p>\n";
	
	my $scannedLocations = '';
	foreach my $loc ($args->getBinDirs(), $args->getLibDirs())
	{
		$loc = encode_entities($loc);
		$scannedLocations .= "&emsp;$loc<br/>"
	}
	$scannedLocations = "<p><strong>Scanned locations:</strong><br/>$scannedLocations</p>\n";

	my $style = "<p><strong>Style:</strong><br/>";
	$style .= "&emsp;" . encode_entities($self->getStyleName()) . "<br/>";
	$style .= "</p>\n";
	
	my $actualCSS = encode_entities($args->getCSS() || '(default css)');
	$actualCSS = "<p><strong>CSS:</strong><br/>&emsp;$actualCSS<br/></p>";
	
	my $groupDefs = '';
	foreach my $groupDef (@{$args->getGroupDefs()})
	{
		$groupDefs .= '<br/>' if $groupDefs;
		my $name = encode_entities($groupDef->{name});
		$groupDefs .= "&emsp;<strong>$name</strong> ($partCounts->{$groupDef->{name}} pods)<br/>";
		my $query = encode_entities($groupDef->{query}->getQuery());
		if ($query =~ s#\n#<br/>#g)
		{
			$query =~ s#\t#&emsp;#g;
		}
		$groupDefs .= "&emsp;&emsp;<em>$query</em><br/>";
	}	
	$groupDefs = "<p><strong>Groups:</strong><br/>$groupDefs</p>\n";
	
	my $sitedir = $args->getSiteDir();
	my $savedTS = readData($sitedir, 'timestamps') || [];
	push(@$savedTS, time());
	writeData($sitedir, 'timestamps', $savedTS);
	
	my $createdUpdated = '';
	$createdUpdated .= ('&emsp;' . encode_entities(scalar(localtime($_))) . "<br/>\n") foreach (@$savedTS);
	$createdUpdated = "<p><strong>Created/Updated:</strong><br/>$createdUpdated</p>\n";
	
	my $sysCssName = $self->getSystemCssName();
	
	my $mainContent = <<MAIN;
<!DOCTYPE html>
<html>

	<head>
		<title>Pods2Site main</title>
		<meta http-equiv="Content-Type" content="text/html;charset=UTF-8"/>
		<link href="$sysCssName.css" rel="stylesheet"/>
	</head>
		
	<body>
$builtBy
$scannedLocations
$style
$actualCSS
$groupDefs
$createdUpdated
	</body>
	
</html>
MAIN

	my $mainFile = slashify("$sitedir/main.html");
	writeUTF8File($mainFile, $mainContent);
	
	print "Wrote main as '$mainFile'\n" if $args->isVerboseLevel(2);
}

sub __updateHeader
{
	my $self = shift;
	my $args = shift;

	my $sysCssName = $self->getSystemCssName();

	my $headerContent = <<MAIN;
<!DOCTYPE html>
<html>

	<head>
		<title>Pods2Site header</title>
		<meta http-equiv="Content-Type" content="text/html;charset=UTF-8"/>
		<link href="$sysCssName.css" rel="stylesheet"/>
	</head>
		
	<body>
		<h2><a href="main.html" target="main_frame">Pods2Site - Perl documentation from pods to html</a></h2>
	</body>
	
</html>
MAIN

	my $sitedir = $args->getSiteDir();
	my $headerFile = slashify("$sitedir/header.html");
	writeUTF8File($headerFile, $headerContent);
	
	print "Wrote header as '$headerFile'\n" if $args->isVerboseLevel(2);
}

sub __updateTOC
{
	my $self = shift;
	my $args = shift;
	my $workGroups = shift;

	my $sitedir = $args->getSiteDir();

	my $sections = '';
	foreach my $workGroup (@$workGroups)
	{
		$sections .= $self->_getCategoryTOC($workGroup->{group}, $workGroup->{podinfo}, $sitedir);
	}
	
	$self->_rewriteCss($args);
	
	my $sysCssName = $self->getSystemCssName();

	my $tocContent = <<TOC;
<!DOCTYPE html>
<html>

	<head>
		<title>Pods2Site toc</title>
		<meta http-equiv="Content-Type" content="text/html;charset=UTF-8"/>
		<link href="$sysCssName.css" rel="stylesheet"/>
	</head>
		
	<body>
$sections
	</body>
	
</html>
TOC

	my $tocFile = slashify("$sitedir/toc.html");
	writeUTF8File($tocFile, $tocContent);
	
	print "Wrote TOC as '$tocFile'\n" if $args->isVerboseLevel(2);
}

sub __updateIndex
{
	my $self = shift;
	my $args = shift;

	my $sysCssName = $self->getSystemCssName();
	my $title = encode_entities($args->getTitle());
	
	my $indexContent = <<INDEX;
<!DOCTYPE html>
<html>

	<head>
		<title>$title</title>
		<meta http-equiv="Content-Type" content="text/html;charset=UTF-8"/>
		<link href="$sysCssName.css" rel="stylesheet"/>
	</head>
		
	<frameset rows="10%,*">
		<frame src="header.html" name="header_frame" />
		<frameset cols="15%,*">
			<frame src="toc.html" name="toc_frame" />
			<frame src="main.html" name="main_frame" />
		</frameset>
	</frameset>

</html>
INDEX

	my $sitedir = $args->getSiteDir();
	my $indexFile = slashify("$sitedir/index.html");
	writeUTF8File($indexFile, $indexContent);
	
	print "Wrote index as '$indexFile'\n" if $args->isVerboseLevel(2);
}

sub _getCategoryTOC
{
	die("Missing override: _getCategoryTOC()");
}

sub _rewriteCss
{
	# noop
}

1;
