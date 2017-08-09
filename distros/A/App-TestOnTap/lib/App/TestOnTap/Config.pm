package App::TestOnTap::Config;

use strict;
use warnings;

use App::TestOnTap::Util qw(slashify);
use App::TestOnTap::OrderStrategy;
use App::TestOnTap::_dbgvars;

use Config::Std;
use Grep::Query;
use UUID::Tiny qw(:std);

# CTOR
#
sub new
{
	my $class = shift;
	my $path = shift;
	my $userExecMapFile = shift;

	my $configFilePath = -f $path ? $path : slashify("$path/" . getName());
	
	my $self = bless({}, $class);
	$self->__readCfgFile($configFilePath, $userExecMapFile);

	return $self;
}

# read the raw Config::Std file and fill in
# data fields
#
sub __readCfgFile
{
	my $self = shift;
	my $configFilePath = $App::TestOnTap::_dbgvars::FORCED_CONFIG_FILE || shift;
	my $userExecMapFile = shift;
	
	my $cfg;
	if (-e $configFilePath && !$App::TestOnTap::_dbgvars::IGNORE_CONFIG_FILE)
	{
		read_config($configFilePath, $cfg);
		
		# this looks weird, I know - see https://rt.cpan.org/Public/Bug/Display.html?id=56862
		#
		# I seem to hit the problem with "Warning: Name "Config::Std::Hash::DEMOLISH" used only once..."
		# when running a Par::Packer binary but not when as a 'normal' script.
		#
		# The below incantation seem to get rid of that, at least for now. Let's see if it reappears... 
		#
		my $dummy = *Config::Std::Hash::DEMOLISH;
		$dummy = *Config::Std::Hash::DEMOLISH;
	}
	else
	{
		my $id = create_uuid_as_string();
		warn("WARNING: No configuration file found, using blank with generated id '$id'!\n");
		$cfg->{''}->{id} = $id; 
	}

	# pick the necessities from the blank section
	#
	my $blankSection = $cfg->{''} || {};

	# a valid uuid is required
	#
	my $id = $blankSection->{id} || '';
	die("Invalid suite id: '$id'") unless $id =~ /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/;
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
	my $preprocesscmd = $blankSection->{preprocess};
	if (defined($preprocesscmd))
	{
		$preprocesscmd =
			(ref($preprocesscmd) eq 'ARRAY')
				? $preprocesscmd
				: ($preprocesscmd =~ m#\n#)
					? [ split("\n", $preprocesscmd) ]
					: [ split(' ', $preprocesscmd) ];
	}
	$self->{preprocesscmd} = $preprocesscmd;
	
	# set up the execmap, possibly as a delegate from a user defined one 
	#
	# a non-existing section will cause a default execmap
	#
	my $execMap = App::TestOnTap::ExecMap->new($cfg->{EXECMAP});
	$execMap = App::TestOnTap::ExecMap->newFromFile($userExecMapFile, $execMap) if $userExecMapFile;
	$self->{execmap} = $execMap; 

	my %depRules;
	if (!$App::TestOnTap::_dbgvars::IGNORE_DEPENDENCIES)
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
		}
	}
	$self->{deprules} = \%depRules;
}

sub getName
{
	# works as both class/instance/sub...
	#
	return $App::TestOnTap::_dbgvars::CONFIG_FILE_NAME;
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
	die("No tests selected by 'match' in dependency rule '$depRuleName'\n") unless @matches;

	my @dependencies = $self->{deprules}->{$depRuleName}->{dependson}->qgrep(@$tests);
	die("No tests selected by 'dependson' in dependency rule '$depRuleName'\n") unless @dependencies;
	 
	return (\@matches, \@dependencies);
}

1;
