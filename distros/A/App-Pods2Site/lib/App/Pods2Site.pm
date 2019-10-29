package App::Pods2Site;

use 5.010_001;

use strict;
use warnings;

our $VERSION = '1.003';
my $version = $VERSION;
$VERSION = eval $VERSION;

use App::Pods2Site::Args;
use App::Pods2Site::PodFinder;
use App::Pods2Site::PodCopier;
use App::Pods2Site::Pod2HTML;
use App::Pods2Site::Util qw(slashify);

use Cwd;
use File::Basename;
use File::Copy;
use File::Path qw(make_path);

# main entry point
#
sub main
{
	my $args = App::Pods2Site::Args->new($version, @_);

	my $cwd = slashify(getcwd());
	
	my $workdir = $args->getWorkDir();
	chdir($workdir) || die("Failed to chdir to '$workdir': $!\n");
	
	if ($args->isVerboseLevel(0))
	{
		print "Scanning for pods in:\n";
		print "  $_\n" foreach ($args->getBinDirs(), $args->getLibDirs());
	}
	
	my $podFinder = App::Pods2Site::PodFinder->new($args);
	my ($sum, $partCounts) = $podFinder->getCounts(); 
	die("No pods found!\n") unless $sum;

	my $mainpagename = $args->getMainpage();
	my $mainpage;
	if ($mainpagename eq ':std')
	{
		$mainpage = $mainpagename;
	}
	else
	{
		foreach my $group (@{$podFinder->getGroups()})
		{
			foreach my $pod (@{$group->{pods}})
			{
				if ($pod->{name} eq $mainpagename)
				{
					$mainpage = $pod->{name};
					$mainpage =~ s{::}{/}g;
					$mainpage = "pod2html/$group->{name}/$mainpage.html";
					last;
				}
			}
		}
	}
	die("Failed to find the main page pod named '$mainpagename'\n") unless $mainpage;

	my $counts = '';
	foreach my $groupDef (@{$args->getGroupDefs()})
	{
		$counts .= ', ' if $counts;
		$counts .= "$groupDef->{name}=$partCounts->{$groupDef->{name}}";
	}
	print "Found $sum pods ($counts).\n" if $args->isVerboseLevel(0);

	print "Preparing pod work tree\n" if $args->isVerboseLevel(0);
	my $podCopier = App::Pods2Site::PodCopier->new($args, $podFinder);
	print "Prepared ", $podCopier->getCount(), " files\n" if $args->isVerboseLevel(0);

	my $siteDir = $args->getSiteDir();
	if (!-d $siteDir)
	{
		make_path($siteDir) || die("Failed to create sitedir '$siteDir': $!\n");
	}

	my $sitebuilder = $args->getSiteBuilder(); 

	$sitebuilder->prepareCss($args);

	print "Generating HTML from pods\n" if $args->isVerboseLevel(0);
	my $pod2html = App::Pods2Site::Pod2HTML->new($args, $podCopier->getPodRoot(), $podCopier->getWorkGroups());

	print "Generated ", $pod2html->getGenerated(), " documents (", $pod2html->getUptodate(), " up to date)\n" if $args->isVerboseLevel(0);

	$sitebuilder->makeSite($args, $podCopier->getWorkGroups(), $partCounts, $mainpage);

	$args->finish();
	
	my $style = $args->getStyle();
	my $updatedOrCreated = $args->getUpdating() ? 'updated' : 'created';
	print "Site $updatedOrCreated in '$siteDir' using style '$style'.\n" if $args->isVerboseLevel(0);

	chdir($cwd);
	
	return 0;
}

1;
