package App::TestOnTap::ExecMap;

use strict;
use warnings;

use App::TestOnTap::Util qw(trim $IS_WINDOWS);

use Config::Std;
use Grep::Query;
use Sort::Naturally qw(nsort);

# CTOR
#
sub new
{
	my $class = shift;
	my $cfg = shift || __defaultCfg();
	my $delegate = shift;

	my $self = bless( { delegate => $delegate }, $class);
	$self->__parseExecMap($cfg);
	
	return $self;
}

sub newFromFile
{
	my $class = shift;
	my $fn = shift;
	my $delegate = shift;
	
	# read in the file in Config::Std style
	#
	read_config($fn, my %cfg);

	# this looks weird, I know - see https://rt.cpan.org/Public/Bug/Display.html?id=56862
	#
	# I seem to hit the problem with "Warning: Name "Config::Std::Hash::DEMOLISH" used only once..."
	# when running a Par::Packer binary but not when as a 'normal' script.
	#
	# The below incantation seem to get rid of that, at least for now. Let's see if it reappears... 
	#
	my $dummy = *Config::Std::Hash::DEMOLISH;
	$dummy = *Config::Std::Hash::DEMOLISH;
	
	my $section = $cfg{EXECMAP};
	die("Missing EXECMAP section in '$fn'\n") unless $section;

	return $class->new($section, $delegate);
}

sub __parseExecMap
{
	my $self = shift;
	my $cfg = shift;

	my @matcherCmdlinePairs;
	
	# get all match<n> keys
	# ensure to sort them by 'natural sort', e.g. the number suffix
	# defines the order
	#
	foreach my $matchKey (nsort(grep(/^match\d+$/, keys(%$cfg))))
	{
		# find the corresponding cmd<n> key, complain if missing
		#
		$matchKey =~ /^match(\d+)$/;
		my $cmdKey = "cmd$1";
		die("The key '$matchKey' has no corresponding '$cmdKey'\n") unless exists($cfg->{$cmdKey});
		
		# compile the query
		#
		my $matcher = Grep::Query->new($cfg->{$matchKey});

		# we want to store the cmd as an array
		# Config::Std allows it to be in multiple forms:
		#   a single line (we split it on space)
		#   a ready-made array (take as is)
		#   a string with embedded \n (split on that)
		#
		my $cmdline = $cfg->{$cmdKey};
		$cmdline =
			(ref($cmdline) eq 'ARRAY')
				? $cmdline
				: ($cmdline =~ m#\n#)
					? [ split("\n", $cmdline) ]
					: [ split(' ', $cmdline) ];
					
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
	return
		{
			# well, a no-brainer...:-)
			#
			'match1' => 'regexp[\.(t|pl)$]',
			'cmd1' => 'perl',
			
			# if python is preferred...
			#
			'match2' => 'regexp[\.py$]',
			'cmd2' => 'python',

			# quite possible and important for java shops
			# (couple with some nice junit and other helpers)
			#
			'match3' => 'regexp[\.jar$]',
			'cmd3' => [qw(java -jar)],
			
			# common variants for groovy scripts, I understand...
			#
			'match4' => 'regexp[\.(groovy|gsh|gvy|gy)$]',
			'cmd4' => 'groovy',
			
			# basic platform specifics
			# 
			$IS_WINDOWS
				?
					(
						# possible, but perhaps not likely
						#
						'match5' => 'regexp[\.(bat|cmd)$]',
						'cmd5' => [qw(cmd.exe /c)],
					)
				:
					(
						# shell scripting is powerful, so why not
						#
						'match5' => 'regexp[\.sh$]',
						'cmd5' => '/bin/sh',
					),

			#######
			# add other conveniences here - ensure numbering is as desired
			#
			#######
		}
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
