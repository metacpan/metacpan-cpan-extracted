package App::TestOnTap::ExecMap;

use strict;
use warnings;

our $VERSION = '1.001';
my $version = $VERSION;
$VERSION = eval $VERSION;

use App::TestOnTap::Util qw(trim $IS_WINDOWS ensureArray);

use Grep::Query;

# CTOR
#
sub new
{
	my $class = shift;
	my $cfg = shift;

	my $self = bless( {}, $class);
	$self->__parseExecMap($cfg);
	
	return $self;
}

sub __parseExecMap
{
	my $self = shift;
	my $cfg = shift;

	my @matcherCmdlinePairs;

	my $emOrder = $cfg->{''}->{execmap};
	if (!$emOrder)
	{
		warn("WARNING: No execmap found, using internal default!\n");
		$cfg = __defaultCfg();
		$emOrder = $cfg->{''}->{execmap};
	}
	$emOrder = ensureArray($emOrder);
	
	foreach my $em (@$emOrder)
	{
		my $emSec = $cfg->{"EXECMAP $em"};
		die("Missing execmap section for '$em'\n") unless $emSec;

		# trip any unknown keys
		#
		warn("WARNING: Unknown key '$_' in execmap section '$em'\n") foreach (grep(!/^(match|cmd)$/, keys(%$emSec)));
		
		# extract the ones we want
		#
		my $match = $emSec->{match};
		my $cmd = $emSec->{cmd} || '';
		die("The execmap section '$em' must have at least the 'match' key\n") unless $match;

		# compile the query
		#
		my $matcher = Grep::Query->new($match);

		# we want to store the cmd as an array
		# Config::Std allows it to be in multiple forms:
		#   a single line (we split it on space)
		#   a ready-made array (take as is)
		#   a string with embedded \n (split on that)
		#
		my $cmdline = ensureArray($cmd);
					
		# now store the matcher and cmdline in an array so we can evaluate them
		# in a defined order when we need to
		#
		push(@matcherCmdlinePairs, [ $matcher, $cmdline ]);
	}

	# not much meaning in continuing if there are no mappings at all...!
	#
	die("No entries in the execmap\n") unless @matcherCmdlinePairs;

	$self->{mcpairs} = \@matcherCmdlinePairs;
}

sub __defaultCfg
{
	# TODO: add more useful standard mappings here
	#
	my %cfg = 
		(
			'' =>
				{
					execmap => [qw(perl python java groovy shell autoit3 batch binary)] 
				},
			'EXECMAP perl' =>
				{
					# well, a no-brainer...:-)
					#
					'match' => 'regexp[\.(t|pl)$]',
					'cmd' => 'perl',
				},
			'EXECMAP python' =>
				{
					# if python is preferred...
					#
					'match' => 'regexp[\.py$]',
					'cmd' => 'python',
				},
			'EXECMAP java' =>
				{
					# quite possible and important for java shops
					# (couple with some nice junit and other helpers)
					#
					'match' => 'regexp[\.jar$]',
					'cmd' => [qw(java -jar)],
				},
			'EXECMAP groovy' =>
				{
					# common variants for groovy scripts, I understand...
					#
					'match' => 'regexp[\.(groovy|gsh|gvy|gy)$]',
					'cmd' => 'groovy',
				},
			'EXECMAP shell' =>
				{
					# shell scripting is powerful, so why not
					#
					'match' => 'regexp[\.sh$]',
					'cmd' => 'sh',
				},
			'EXECMAP autoit3' =>
				{
					# For using AutoIt scripts (https://www.autoitscript.com/site/autoit/)
					# (Windows only)
					#
					'match' => 'regexp[\.au3$]',
					'cmd' => 'autoit3',
				},
			'EXECMAP batch' =>
				{
					# possible, but perhaps not likely
					# (Windows only)
					#
					'match' => 'regexp[\.(bat|cmd)$]',
					'cmd' => [qw(cmd.exe /c)],
				},
			'EXECMAP binary' =>
				{
					# for directly executable binaries, no actual 'cmd' is needed
					# On Windows: rename 'xyz.exe' => 'xyz.tbin'
					# On Unix: rename 'xyz' => 'xyz.tbin'
					#
					'match' => 'regexp[\.tbin$]',
				},
		);
	
	return \%cfg;
}

# just check if the given test has a mapping
#
sub hasMapping
{
	my $self = shift;
	my $testName = shift;
	
	foreach my $matcherCmdlinePair (@{$self->{mcpairs}})
	{
		return 1 if $matcherCmdlinePair->[0]->qgrep($testName);
	}
	
	if (defined($self->{delegate}))
	{
		return 1 if $self->{delegate}->hasMapping($testName);
	}
	
	return 0;
}

# retrieve the cmdline map for the test
#
sub getMapping
{
	my $self = shift;
	my $testName = shift;
	
	foreach my $matcherCmdlinePair (@{$self->{mcpairs}})
	{
		return $matcherCmdlinePair->[1] if $matcherCmdlinePair->[0]->qgrep($testName);
	}
	
	if (defined($self->{delegate}))
	{
		return $self->{delegate}->getMapping($testName);
	}
	
	die("INTERNAL ERROR - should not reach this point!");
}

1;
