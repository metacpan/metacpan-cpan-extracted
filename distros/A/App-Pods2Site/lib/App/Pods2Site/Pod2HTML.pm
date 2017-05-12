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
	my $podCopier = shift;

	my $self = bless( { generated => 0, uptodate => 0 }, $class);
	$self->__updateHTML($args, $podCopier);

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

sub getS2N2H
{
	my $self = shift;
	
	return $self->{s2n2h}; 	
}

# PRIVATE
#

sub __updateHTML
{
	my $self = shift;
	my $args = shift;
	my $podCopier = shift;
	
	my $t2i = $podCopier->getT2I();
	
	# get the sections - numbered, to ensure we get them in a
	# defined order
	#
	my @sections = sort(keys(%$t2i));

	# get the work tree pod root, and create a podpath
	#
	my $podroot = $podCopier->getPodRoot();
	my $podpath = join(':', @sections);

	my $spinner = createSpinner($args);

	# keep track of section (short, not numbered) => name => html file
	#
	my %s2n2h;
	foreach my $section (@sections)
	{
		foreach my $podinfo (@{$t2i->{$section}})
		{
			foreach my $podfile (@{$podinfo->{podfiles}})
			{
				my $outfile = $podfile;
				$outfile =~ s/^\Q$podroot\E.//;
				$outfile =~ s/\.[^.]+$//;
				$outfile = slashify($outfile, '/');
				
				my $htmlroot = ('..' x ($outfile =~ tr#/##)) || '.';
				$htmlroot =~ s#\.\.(?=\.)#../#g;
				
				# place all pod2html generated files in the pod2html dir
				#
				my $relOutFile = "pod2html/$outfile.html";
				$outfile = slashify($args->getSiteDir() . "/$relOutFile");
				
				my $shortSec = $section;
				$shortSec =~ s/^\d-(.+)/$1/;
				$s2n2h{$shortSec}->{$podinfo->{names}->[0]} = $outfile;
				
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
							"--podroot=$podroot",
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
						: $spinner->();
				}
				else
				{
					$self->{uptodate}++;

					$args->isVerboseLevel(1)
						? print "Skipping uptodate '$outfile'\n"
						: $spinner->();
				}
			}
		}
	}
	
	$self->{s2n2h} = \%s2n2h;
}

1;
