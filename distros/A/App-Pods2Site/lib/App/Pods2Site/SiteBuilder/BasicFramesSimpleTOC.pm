package App::Pods2Site::SiteBuilder::BasicFramesSimpleTOC;

use strict;
use warnings;

use base qw(App::Pods2Site::SiteBuilder::AbstractBasicFrames);

use App::Pods2Site::Util qw(slashify);

sub _getCategoryTOC
{
	my $self = shift;
	my $category = shift;
	my $n2h = shift;
	my $sitedir = shift;
	
	my $toc = '';
	my %tree;
	foreach my $name (keys(%$n2h))
	{
		my $treeloc = \%tree;
		for my $level (split(/::/, $name))
		{
			$treeloc->{$level} = {} unless exists($treeloc->{$level});
			$treeloc = $treeloc->{$level};
		}
	}
	$self->_genRefs($sitedir, \$toc, $n2h, \%tree);
	chomp($toc);
	$toc = qq(<strong>$category</strong><br/><br/>\n$toc<br/><hr/>) if $toc;
}

sub _genRefs
{
	my $self = shift;
	my $sitedir = shift;
	my $ref = shift;
	my $n2h = shift;
	my $treeloc = shift;
	my $depth = shift || 0;
	my $n = shift;
	my $np = shift;

	my $r = '';
	if ($n)
	{
		$r = "${n}::";
		$$ref .= ('&emsp;' x ($depth - 1)) if $depth > 1;
		my $p = $n2h->{$n};
		if ($p)
		{
			$p =~ s#\Q$sitedir\E.##;
			$p = slashify($p, '/');
			$$ref .= qq(<a href="$p" target="main_frame"><small>$np</small></a><br/>\n);
		}
		else
		{
			$$ref .= qq(<small>$np</small><br/>\n);
		}
	}
	foreach my $subnp (sort { lc($a) cmp lc($b) } (keys(%$treeloc)))
	{
		my $subn = "$r$subnp";
		
		$depth++;
		$self->_genRefs($sitedir, $ref, $n2h, $treeloc->{$subnp}, $depth, $subn, $subnp);
		$depth--;
	}
}

1;
