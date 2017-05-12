package App::Pods2Site;

use 5.010_001;

use strict;
use warnings;

our $VERSION = '0.010';
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

# main entry point
#
sub main
{
	my $args = App::Pods2Site::Args->new(@_);

	my $cwd = slashify(getcwd());
	
	my $workdir = $args->getWorkDir();
	chdir($workdir) || die("Failed to chdir to '$workdir': $!\n");
	
	if ($args->isVerboseLevel(0))
	{
		print "Scanning for pods in:\n";
		print "  $_\n" foreach ($args->getBinDirs(), $args->getLibDirs());
	}
	
	my $podFinder = App::Pods2Site::PodFinder->new($args);
	print "Found ", $podFinder->getCount(), " pods\n" if $args->isVerboseLevel(0);

	print "Preparing pod work tree\n" if $args->isVerboseLevel(0);
	my $podCopier = App::Pods2Site::PodCopier->new($args, $podFinder);
	print "Prepared ", $podCopier->getCount(), " files\n" if $args->isVerboseLevel(0);

	my $sitebuilder = $args->getSiteBuilder(); 

	$sitebuilder->prepareCss($args);

	print "Generating HTML from pods\n" if $args->isVerboseLevel(0);
	my $pod2html = App::Pods2Site::Pod2HTML->new($args, $podCopier);
	print "Generated ", $pod2html->getGenerated(), " documents (", $pod2html->getUptodate(), " up to date)\n" if $args->isVerboseLevel(0);

	$sitebuilder->makeSite($args, $pod2html);
	print "Completed site in ", $args->getSiteDir(), "\n" if $args->isVerboseLevel(0);

	chdir($cwd);
	
	return 0;
}

1;
