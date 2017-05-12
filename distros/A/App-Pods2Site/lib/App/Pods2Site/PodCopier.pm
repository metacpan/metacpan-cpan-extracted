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

sub getT2I
{
	my $self = shift;
	
	return $self->{t2i}; 	
}

sub getPodRoot
{
	my $self = shift;
	
	return $self->{podroot};
}

# copy all found pods into a work tree, so the HTML generation
# has a good base to work from
#
sub __copyPods
{
	my $self = shift;
	my $args = shift;
	my $podFinder = shift;

	# keep 'types' to 'info' for later use by the HTML generation
	# the types are prefixed by number to allow the gen to sort them
	#
	my %t2i;

	# set up some progress feedback
	#
	my $spinner = createSpinner($args);

	# copy pods from each category
	#
	my $coren2p = $podFinder->getCoreN2P();
	foreach my $name (sort { lc($a) cmp lc($b) } (keys(%$coren2p)))
	{
		my $type = '1-core';
		my $alias = $name;
		$alias =~ s/^pods:://;
		my $p = $coren2p->{$name};
		# for core, we copy to an alias too, as many links go to 'perlxxx' rather than 'pods::perlxxx'
		# 
		my $names = [ $alias, $name ];
		my $podfiles = $self->__copy($args, $names, $p, $type);
		my $ra = $t2i{$type} || [];
		push(@$ra, { names => $names, infile => $p, podfiles => $podfiles });
		$t2i{$type} = $ra; 
		$spinner->();
	}
	
	my $pragman2p = $podFinder->getPragmaN2P();
	foreach my $name (sort { lc($a) cmp lc($b) } (keys(%$pragman2p)))
	{
		my $type = '2-pragma';
		my $p = $pragman2p->{$name};
		my $names = [ $name ];
		my $podfiles = $self->__copy($args, $names, $p, $type);
		my $ra = $t2i{$type} || [];
		push(@$ra, { names => $names, infile => $p, podfiles => $podfiles });
		$t2i{$type} = $ra; 
		$spinner->();
	}
	
	my $modulen2p = $podFinder->getModuleN2P();
	foreach my $name (sort { lc($a) cmp lc($b) } (keys(%$modulen2p)))
	{
		my $type = '3-module';
		my $p = $modulen2p->{$name};
		my $names = [ $name ];
		my $podfiles = $self->__copy($args, $names, $p, $type);
		my $ra = $t2i{$type} || [];
		push(@$ra, { names => $names, infile => $p, podfiles => $podfiles });
		$t2i{$type} = $ra; 
		$spinner->();
	}

	my $scriptn2p = $podFinder->getScriptN2P();
	foreach my $name (sort { lc($a) cmp lc($b) } (keys(%$scriptn2p)))
	{
		my $type = '4-script';
		my $p = $scriptn2p->{$name};
		my $names = [ $name ];
		my $podfiles = $self->__copy($args, $names, $p, $type);
		my $ra = $t2i{$type} || [];
		push(@$ra, { names => $names, infile => $p, podfiles => $podfiles });
		$t2i{$type} = $ra; 
		$spinner->();
	}
	
	$self->{t2i} = \%t2i;
}

sub __copy
{
	my $self = shift;
	my $args = shift;
	my $names = shift;
	my $infile = shift;
	my $typeRoot = shift;

	# copy every 'name' infile to possibly multiple outfiles
	# for simplicity, always use the '.pod' extension
	#
	my @podfiles;
	foreach my $name (@$names)
	{
		my $podname = $name;
		$podname =~ s#::#/#g;
		my $outfile = slashify("$self->{podroot}/$typeRoot/$podname.pod");
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
	
	return \@podfiles;
}

1;
