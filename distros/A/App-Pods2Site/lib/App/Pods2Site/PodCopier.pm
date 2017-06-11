package App::Pods2Site::PodCopier;

use strict;
use warnings;

use App::Pods2Site::Util qw(slashify createSpinner);

use Cwd;
use File::Copy;
use File::Basename;
use File::Path qw(make_path);

# CTOR
#
sub new
{
	my $class = shift;
	my $args = shift;
	my $podFinder = shift;

	my $cwd = getcwd();

	my $self = bless( { podroot => slashify("$cwd/podroot"), count => 0 }, $class);
	$self->__copyPods($args, $podFinder);

	return $self;
}

sub getCount
{
	my $self = shift;
	
	return $self->{count};
}

sub getPodRoot
{
	my $self = shift;
	
	return $self->{podroot};
}

sub getWorkGroups
{
	my $self = shift;
	
	return $self->{workgroups};
}

# copy all found pods into a work tree, so the HTML generation
# has a good base to work from
#
sub __copyPods
{
	my $self = shift;
	my $args = shift;
	my $podFinder = shift;

	# keep running tally of groups and associated pods
	#
	my @workGroups;

	# set up some progress feedback
	#
	my $spinner = createSpinner($args);

	# copy pods from each group
	#
	my $count = 0;
	my $groups = $podFinder->getGroups();
	foreach my $group (@$groups)
	{
		my $groupName = $group->{name};
		my $pods = $group->{pods};
		my %podInfo;
		foreach my $pod (@$pods)
		{
			my $podName = $pod->{name};
			my $inFile = $pod->{path};
			my $copyToNames = [ $podName ];
			
			# if we see a pod in namespace 'pods::', we also copy to an alias as it seems many links
			# go to 'perlxxx' rather than 'pods::perlxxx'
			# 
			push(@$copyToNames, $1) if ($podName =~ /^pods::(.*)/);
			
			my @podFiles = $self->__copy($inFile, $copyToNames, $groupName, $args);
			
			$podInfo{$podName} = { podfile => $podFiles[0], htmlfile => undef };
			
			$spinner->(++$count); 
		}
		
		push(@workGroups, { group => $groupName, podinfo => \%podInfo });
	}
	
	$self->{workgroups} = \@workGroups;
}

sub __copy
{
	my $self = shift;
	my $infile = shift;
	my $names = shift;
	my $group = shift;
	my $args = shift;

	# copy every 'name' infile to possibly multiple outfiles
	# for simplicity, always use the '.pod' extension
	#
	my @podfiles;
	foreach my $name (@$names)
	{
		my $podname = $name;
		$podname =~ s#::#/#g;
		my $outfile = slashify("$self->{podroot}/$group/$podname.pod");
		push(@podfiles, $outfile);
	
		# we're copying in a specific order, and it's possible
		# a pod with the same name might come from two different categories
		# if so, only copy the first, but make sure the copy retains the mtime
		# from the infile, so the HTML gen can avoid regenerating
		#
		my $mtimeInfile = (stat($infile))[9];
		if (!-e $outfile)
		{
			my $outfileDir = dirname($outfile);
			(!-d $outfileDir ? make_path($outfileDir) : 1) || die ("Failed to create directory '$outfileDir': $!\n");
			copy($infile, $outfile) || die("Failed to copy $infile => $outfile: $!\n");
			utime($mtimeInfile, $mtimeInfile, $outfile);
		}
		
		$self->{count}++;
		
		print "Copied '$infile' => '$outfile'\n" if $args->isVerboseLevel(3);
	}
	
	return @podfiles;
}

1;
