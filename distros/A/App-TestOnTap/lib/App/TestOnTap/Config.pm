package App::TestOnTap::Config;

use strict;
use warnings;

use App::TestOnTap::Util qw(slashify ensureArray);
use App::TestOnTap::OrderStrategy;
use App::TestOnTap::ExecMap;
use App::TestOnTap::ParallelGroupManager;

use Config::Std;
use File::Spec;
use Grep::Query;
use UUID::Tiny qw(:std);

# CTOR
#
sub new
{
	my $class = shift;
	my $suiteRoot = shift;
	my $userCfgFile = shift;
	my $ignoreDeps = shift;

	my $configFile = slashify(File::Spec->rel2abs($userCfgFile || "$suiteRoot/" . getName()));
	die("Missing configuration file '$configFile'\n") unless -f $configFile;

	my $self = bless({}, $class);
	$self->__readCfgFile($configFile, $ignoreDeps);

	return $self;
}

# read the raw Config::Std file and fill in
# data fields
#
sub __readCfgFile
{
	my $self = shift;
	my $configFile = shift;
	my $ignoreDeps = shift;
	
	read_config($configFile, my $cfg);
	
	# this looks weird, I know - see https://rt.cpan.org/Public/Bug/Display.html?id=56862
	#
	# I seem to hit the problem with "Warning: Name "Config::Std::Hash::DEMOLISH" used only once..."
	# when running a Par::Packer binary but not when as a 'normal' script.
	#
	# The below incantation seem to get rid of that, at least for now. Let's see if it reappears... 
	#
	my $dummy = *Config::Std::Hash::DEMOLISH;
	$dummy = *Config::Std::Hash::DEMOLISH;
	
	# pick the necessities from the blank section
	#
	my $blankSection = $cfg->{''} || {};

	# a valid uuid is required
	#
	my $id = $blankSection->{id} || '';
	if (!$id)
	{
		$id = create_uuid_as_string();
		warn("WARNING: No id found, using generated '$id'!\n");
		$blankSection->{id} = $id; 
	}
	die("Invalid/missing suite id: '$id'") unless $id =~ /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/;
	$self->{id} = $id;
	
	# an optional filter to skip parts while scanning suite root
	#
	# ensure it's in text form - an array is simply joined using newlines
	#
	my $skip = $blankSection->{skip};
	if (defined($skip))
	{
		$skip = join("\n", @$skip) if ref($skip) eq 'ARRAY';
		$skip = Grep::Query->new($skip);
	}
	$self->{skip} = $skip;

	# an optional filter to check if a test can run in parallel (with any other test) 
	#
	# ensure it's in text form - an array is simply joined using newlines
	#
	my $parallelizable = $blankSection->{parallelizable};
	if (defined($parallelizable))
	{
		$parallelizable = join("\n", @$parallelizable) if ref($parallelizable) eq 'ARRAY';
		$parallelizable = Grep::Query->new($parallelizable);
	}
	$self->{parallelizable} = $parallelizable;

	# read the optional order strategy
	#
	$self->{orderstrategy} = App::TestOnTap::OrderStrategy->new($blankSection->{order}) if $blankSection->{order};	
	
	# read the preprocess (optional) command
	#
	$self->{preprocesscmd} = ensureArray($blankSection->{preprocess});
	
	# read the postprocess (optional) command
	#
	$self->{postprocesscmd} = ensureArray($blankSection->{postprocess});

	# set up optional ParallelGroup's 
	#
	$self->{parallelgroupmanager} = App::TestOnTap::ParallelGroupManager->new($cfg);

	# set up the execmap, possibly as a delegate from a user defined one 
	#
	$self->{execmap} = App::TestOnTap::ExecMap->new($cfg);

	my %depRules;
	if (!$ignoreDeps)
	{
		# find all dependency sections
		#
		my $depRx = qr(^\s*DEPENDENCY\s+(.+?)\s*$);
		foreach my $depRuleSectionName (grep(/$depRx/, keys(%$cfg)))
		{
			$depRuleSectionName =~ /$depRx/;
			my $depRuleName = $1;
			
			# all dep sections requires match/dependson Grep::Query queries
			# in case they're written as arrays, just join using newlines
			#
			foreach my $key (qw( match dependson ))
			{
				my $value = $cfg->{$depRuleSectionName}->{$key}; 
				die("Missing key '$key' in dependency rule section '$depRuleName'\n") unless defined($value);
				$value = join("\n", @$value) if ref($value) eq 'ARRAY';
				$depRules{$depRuleName}->{$key} = Grep::Query->new($value);
			}
			
			# check for unknown keys...
			#
			my %validSectionKeys = map { $_ => 1 } qw(match dependson);
			foreach my $key (keys(%{$cfg->{$depRuleSectionName}}))
			{
				warn("WARNING: Unknown key '$key' in section '[$depRuleSectionName]'\n") unless exists($validSectionKeys{$key});
			}
		}
	}
	$self->{deprules} = \%depRules;
	
	# finally check the config for unknown sections/keys...
	#
	my @validSections = (qr/^$/, qr/^DEPENDENCY\s/, qr/^EXECMAP\s+[^\s]+\s*$/, qr/^PARALLELGROUP\s+[^\s]+\s*$/);
	foreach my $section (sort(keys(%$cfg)))
	{
		my $knownSection = 0;
		foreach my $secToMatch (@validSections)
		{
			if ($section =~ /$secToMatch/)
			{
				$knownSection = 1;
				last;
			}
		}
		warn("WARNING: Unknown section: '[$section]'\n") unless $knownSection;
	}

	my %validBlankSectionKeys = map { $_ => 1 } qw(id skip preprocess postprocess parallelizable order execmap);
	foreach my $key (sort(keys(%$blankSection)))
	{
		warn("WARNING: Unknown key '$key' in default section\n") unless exists($validBlankSectionKeys{$key});
	}
	
	$self->{rawcfg} = { %$cfg };
}

sub getId
{
	my $self = shift;
	
	return $self->{id};
}

sub skip
{
	my $self = shift;
	my $test = shift;
	
	return
		$self->{skip}
			? $self->{skip}->qgrep($test)
			: 0;
}

sub getName
{
       # works as both class/instance/sub...
       #
       return 'config.testontap';
}

sub getOrderStrategy
{
	my $self = shift;
	
	return $self->{orderstrategy};
}

sub getPreprocessCmd
{
	my $self = shift;
	
	return $self->{preprocesscmd};
}

sub getPostprocessCmd
{
	my $self = shift;
	
	return $self->{postprocesscmd};
}

sub hasParallelizableRule
{
	my $self = shift;
	
	return $self->{parallelizable} ? 1 : 0
}

sub parallelizable
{
	my $self = shift;
	my $test = shift;
	
	return
		$self->{parallelizable}
			? $self->{parallelizable}->qgrep($test)
			: 0;
}

sub hasExecMapping
{
	my $self = shift;
	my $testName = shift;

	return $self->{execmap}->hasMapping($testName);	
}

sub getExecMapping
{
	my $self = shift;
	my $testName = shift;

	return $self->{execmap}->getMapping($testName);	
}

sub getRawCfg
{
	my $self = shift;

	return $self->{rawcfg};	
}

sub getDependencyRuleNames
{
	my $self = shift;
	
	return keys(%{$self->{deprules}});
}

sub getMatchesAndDependenciesForRule
{
	my $self = shift;
	my $depRuleName = shift;
	my $tests = shift;
	
	my @matches = $self->{deprules}->{$depRuleName}->{match}->qgrep(@$tests);
	my @dependencies = $self->{deprules}->{$depRuleName}->{dependson}->qgrep(@$tests);
	 
	return (\@matches, \@dependencies);
}

sub getParallelGroupManager
{
	my $self = shift;
	my $testName = shift;

	return $self->{parallelgroupmanager};	
}

1;
