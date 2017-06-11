package App::Pods2Site::Pod2HTML;

use strict;
use warnings;

use App::Pods2Site::Util qw(slashify createSpinner);

use File::Basename;
use File::Path qw(make_path);
use Pod::Html;

# CTOR
#
sub new
{
	my $class = shift;
	my $args = shift;
	my $podRoot = shift;
	my $workGroups = shift;

	my $self = bless( { generated => 0, uptodate => 0 }, $class);
	$self->__updateHTML($args, $podRoot, $workGroups);

	return $self;
}

sub getGenerated
{
	my $self = shift;
	
	return $self->{generated};
}

sub getUptodate
{
	my $self = shift;
	
	return $self->{uptodate};
}

# PRIVATE
#

sub __updateHTML
{
	my $self = shift;
	my $args = shift;
	my $podRoot = shift;
	my $workGroups = shift;
	
	# get the work tree pod root, and create a podpath
	#
	my @sections;
	push(@sections, $_->{group}) foreach (@$workGroups);
	my $podpath = join(':', @sections);

	my $spinner = createSpinner($args);

	my $count = 0;
	foreach my $workGroup (@$workGroups)
	{
		foreach my $podName (keys(%{$workGroup->{podinfo}}))
		{
			$count++;
			
			my $podfile = $workGroup->{podinfo}->{$podName}->{podfile};
			
			my $outfile = $podfile;
			$outfile =~ s/^\Q$podRoot\E.//;
			$outfile =~ s/\.[^.]+$//;
			$outfile = slashify($outfile, '/');
			
			my $htmlroot = ('..' x ($outfile =~ tr#/##)) || '.';
			$htmlroot =~ s#\.\.(?=\.)#../#g;
			
			# place all pod2html generated files in the pod2html dir
			#
			my $relOutFile = "pod2html/$outfile.html";
			$outfile = slashify($args->getSiteDir() . "/$relOutFile");

			$workGroup->{podinfo}->{$podName}->{htmlfile} = $outfile;

			my $mtimePodfile = (stat($podfile))[9];
			my $mtimeOutfile = (stat($outfile))[9] || 0;

			if (!-e $outfile || $mtimePodfile > $mtimeOutfile)
			{
				my $outfileDir = dirname($outfile);
				(!-d $outfileDir ? make_path($outfileDir) : 1) || die ("Failed to create directory '$outfileDir': $!\n");
				my @p2hargs =
					(
						"--infile=$podfile",
						"--outfile=$outfile",
						"--podroot=$podRoot",
						"--podpath=$podpath",
						"--htmlroot=$htmlroot",
						"--css=$htmlroot/../pods2site.css",
					);
				if (!$args->isVerboseLevel(2))
				{
					push(@p2hargs, '--quiet');
				}
				else
				{
					push(@p2hargs, '--verbose') if $args->isVerboseLevel(3);
				}
				pod2html(@p2hargs);

				$self->{generated}++;

				$args->isVerboseLevel(1)
					? print "Generating '$outfile'...\n"
					: $spinner->($count);
			}
			else
			{
				$self->{uptodate}++;

				$args->isVerboseLevel(1)
					? print "Skipping uptodate '$outfile'\n"
					: $spinner->($count);
			}
		}
	}
}

1;
