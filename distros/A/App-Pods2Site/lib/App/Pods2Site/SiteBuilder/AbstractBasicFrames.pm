package App::Pods2Site::SiteBuilder::AbstractBasicFrames;

use strict;
use warnings;

our $VERSION = '1.003';
my $version = $VERSION;
$VERSION = eval $VERSION;

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
	my $mainpage = shift;

	$self->__updateHeader($args, $mainpage);
	$self->__updateAbout($args, $partCounts);
	$self->__updateTOC($args, $workGroups);
	$self->__updateIndex($args, $mainpage);
}

# PRIVATE
#

sub __updateHeader
{
	my $self = shift;
	my $args = shift;
	my $mainpage = shift;

	my $title = encode_entities($args->getTitle());
	my $sysCssName = $self->getSystemCssName();

	my ($mainspan, $aboutspan);
	if ($mainpage eq ':std')
	{
		$mainspan = qq(<span style="float:left"><a href="about.html" target="main_frame" style="font-size:250%;font-weight:bold">$title</a></span>);
		$aboutspan = '';
	}
	else
	{
		$mainspan = qq(<span style="float:left"><a href="$mainpage" target="main_frame" style="font-size:250%;font-weight:bold">$title</a></span>);
		$aboutspan = qq(<span style="float:right"><a href="about.html" target="main_frame" style="font-size:125%;font-weight:bold">about</a></span>);
	}

	my $headerContent = <<HDR;
<!DOCTYPE html>
<html>

	<head>
		<title>Pods2Site header</title>
		<meta http-equiv="Content-Type" content="text/html;charset=UTF-8"/>
		<link href="$sysCssName.css" rel="stylesheet"/>
	</head>

	<body>
		$mainspan
		$aboutspan
	</body>

</html>
HDR

	my $sitedir = $args->getSiteDir();
	my $headerFile = slashify("$sitedir/header.html");
	writeUTF8File($headerFile, $headerContent);

	print "Wrote header as '$headerFile'\n" if $args->isVerboseLevel(2);
}

sub __updateAbout
{
	my $self = shift;
	my $args = shift;
	my $partCounts = shift;

	my $scannedLocations = '';
	foreach my $loc ($args->getBinDirs(), $args->getLibDirs())
	{
		$loc = encode_entities($loc);
		$scannedLocations .= "&emsp;$loc<br/>"
	}
	$scannedLocations = "<p>\n\t\t\t<strong>Scanned locations:</strong><br/>$scannedLocations\n\t\t</p>\n";

	my $style = "<p>\n\t\t\t<strong>Style:</strong><br/>";
	$style .= "&emsp;" . encode_entities($self->getStyleName()) . "<br/>";
	$style .= "\n\t\t</p>\n";
	
	my $actualCSS = encode_entities($args->getCSS() || '(default)');
	$actualCSS = "<p>\n\t\t\t<strong>CSS:</strong><br/>&emsp;$actualCSS<br/>\n\t\t</p>\n";
	
	my $groupDefs = '';
	foreach my $groupDef (@{$args->getGroupDefs()})
	{
		$groupDefs .= "\n\t\t\t<br/>" if $groupDefs;
		my $name = encode_entities($groupDef->{name});
		$groupDefs .= "&emsp;<strong>$name</strong> ($partCounts->{$groupDef->{name}} pods)<br/>";
		my $query = encode_entities($groupDef->{query}->getQuery());
		if ($query =~ s#\n#<br/>#g)
		{
			$query =~ s#\t#&emsp;#g;
		}
		$groupDefs .= "&emsp;&emsp;<em>$query</em><br/>";
	}	
	$groupDefs = "<p>\n\t\t\t<strong>Groups:</strong>\n\t\t\t<br/>$groupDefs\n\t\t</p>\n";
	
	my $sitedir = $args->getSiteDir();
	my $savedTS = readData($sitedir, 'timestamps') || [];
	push(@$savedTS, time());
	writeData($sitedir, 'timestamps', $savedTS);
	
	my $z = encode_entities(slashify($0));
	my $zv = encode_entities($App::Pods2Site::VERSION);
	my $x = encode_entities($^X);
	my $xv = encode_entities($]);
	my $builtBy = "<p>\n\t\t\t<strong>This site built using:</strong><br/>";
	$builtBy .= "&emsp;$z ($zv)<br/>";
	$builtBy .= "&emsp;$x ($xv)<br/>\n";
	$builtBy .= "\t\t</p>\n";

	my $createdUpdated = '';
	$createdUpdated .= ('&emsp;' . encode_entities(scalar(localtime($_))) . "<br/>") foreach (@$savedTS);
	$createdUpdated = "<p>\n\t\t\t<strong>Created/Updated:</strong><br/>$createdUpdated\n\t\t</p>\n";
	
	my $sysCssName = $self->getSystemCssName();
	
	my $aboutContent = <<ABOUT;
<!DOCTYPE html>
<html>

	<head>
		<title>Pods2Site main</title>
		<meta http-equiv="Content-Type" content="text/html;charset=UTF-8"/>
		<link href="$sysCssName.css" rel="stylesheet"/>
	</head>
		
	<body>
		$scannedLocations
		$style
		$actualCSS
		$groupDefs
		$createdUpdated
		$builtBy
	</body>
	
</html>
ABOUT

	my $aboutFile = slashify("$sitedir/about.html");
	writeUTF8File($aboutFile, $aboutContent);
	
	print "Wrote about as '$aboutFile'\n" if $args->isVerboseLevel(2);
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
	my $mainpage = shift;

	$mainpage = 'about.html' if $mainpage eq ':std';

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
		
	<frameset rows="8%,*">
		<frame src="header.html" name="header_frame" />
		<frameset cols="15%,*">
			<frame src="toc.html" name="toc_frame" />
			<frame src="$mainpage" name="main_frame" />
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
