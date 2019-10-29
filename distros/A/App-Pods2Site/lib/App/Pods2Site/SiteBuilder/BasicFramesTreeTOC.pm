package App::Pods2Site::SiteBuilder::BasicFramesTreeTOC;

use strict;
use warnings;

our $VERSION = '1.003';
my $version = $VERSION;
$VERSION = eval $VERSION;

use base qw(App::Pods2Site::SiteBuilder::AbstractBasicFrames);

use App::Pods2Site::Util qw(slashify readUTF8File writeUTF8File);

sub new
{
	my $class = shift;

	my $self = $class->SUPER::new(@_);
	$self->{maxtocdepth} = -1;

	return $self;
}

sub _getCategoryTOC
{
	my $self = shift;
	my $groupName = shift;
	my $podInfo = shift;
	my $sitedir = shift;
	
	my $toc = '';
	my %tree;
	foreach my $podName (sort(keys(%$podInfo)))
	{
		my $treeloc = \%tree;
		for my $level (split(/::/, $podName))
		{
			$treeloc->{$level} = {} unless exists($treeloc->{$level});
			$treeloc = $treeloc->{$level};
		}
	}
	$self->_genRefs($sitedir, \$toc, $podInfo, \%tree, -1);
	chomp($toc);
	if ($toc)
	{
		if ($groupName)
		{
			$toc = qq(<details class="toc-top">\n\t\t\t<summary class="toc-top">$groupName</summary>\n\t\t\t\t$toc\n\t\t</details>\n);
		}
		else
		{
			my $newtoc = '';
			while ($toc =~ /class="toc-(top|\d+)"/g)
			{
				my $lvl = ($1 == 0) ? 'top' : $1 - 1;
				$newtoc .= substr( $toc, 0, $-[0] ) . qq(class="toc-$lvl");
				$toc = substr( $toc, $+[0] );
			}
			$toc = "$newtoc$toc"; 
		}
	}
	
	return $toc;
}

sub _genRefs
{
	my $self = shift;
	my $sitedir = shift;
	my $ref = shift;
	my $podInfo = shift;
	my $treeloc = shift;
	my $depth = shift;
	my $n = shift;
	my $np = shift;

	$self->{maxtocdepth} = $depth if $depth > $self->{maxtocdepth};
	
	my $hasSubNodes = keys(%$treeloc) ? 1 : 0;
	
	my $r = '';
	if ($n)
	{
		$r = "${n}::";

		$$ref .= qq(<details class="toc-$depth">\n) if $hasSubNodes;
		
		$$ref .= ($hasSubNodes ? qq(<summary class="toc-$depth">) : qq(<div class="toc-$depth">));
		my $p = $podInfo->{$n}->{htmlfile};
		if ($p)
		{
			$p =~ s#\Q$sitedir\E.##;
			$p = slashify($p, '/');
			$$ref .= qq(<a href="$p" target="main_frame">$np</a>);
		}
		else
		{
			$$ref .= qq($np);
		}
		$$ref .= ($hasSubNodes ? qq(</summary>) : qq(</div>));
		$$ref .= "\n";
	}
	
	foreach my $subnp (sort { lc($a) cmp lc($b) } (keys(%$treeloc)))
	{
		my $subn = "$r$subnp";
		
		$depth++;
		$self->_genRefs($sitedir, $ref, $podInfo, $treeloc->{$subnp}, $depth, $subn, $subnp);
		$depth--;
	}
	
	if ($n)
	{
		$$ref .= qq(</details>\n) if $hasSubNodes;
	}
}

sub _rewriteCss
{
	my $self = shift;
	my $args = shift;

	my $tocrules = <<TOCTOPRULES;
summary.toc-top
{
	font-weight: bolder;
}

TOCTOPRULES

	for my $num (0 .. $self->{maxtocdepth})
	{
		my $sumem = $num + 1;
		my $divem = $num + 2;
		$tocrules .= <<TOCNUMRULES;
summary.toc-$num
{
	font-size: small;
	margin-left: ${sumem}em;
}

div.toc-$num
{
	font-size: small;
	margin-left: ${divem}em;
}

TOCNUMRULES
	}

	my $sitedir = $args->getSiteDir();
	my $sbName = $self->getStyleName();
	my $sbCssFile = slashify("$sitedir/$sbName.css");
	my $cssContent = readUTF8File($sbCssFile);
	writeUTF8File($sbCssFile, "$cssContent\n$tocrules"); 	
}

1;
