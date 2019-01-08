package App::TestOnTap::Harness;

use strict;
use warnings;

use base qw(TAP::Harness);

use App::TestOnTap::Scheduler;
use App::TestOnTap::Dispenser;
use App::TestOnTap::Util qw(slashify runprocess $IS_PACKED);

use TAP::Formatter::Console;
use TAP::Formatter::File;

use List::Util qw(max);

sub new
{
	my $class = shift;
	my $args = shift;

	my $self = $class->SUPER::new
								(
									{
										formatter => __getFormatter($args),
										jobs => $args->getJobs(),
										merge => $args->getMerge(),
										callbacks => { after_test => $args->getWorkDirManager()->getResultCollector() },
										'exec' => __getExecMapper($args),
										scheduler_class => 'App::TestOnTap::Scheduler'
									}
								);

	$self->{testontap} = { args => $args, pez => App::TestOnTap::Dispenser->new($args) };

	return $self;
}

sub make_scheduler
{
	my $self = shift;
	
	return $self->{scheduler_class}->new($self->{testontap}->{pez}, @_);
}

sub runtests
{
	my $self = shift;
	
	my $args = $self->{testontap}->{args}; 
	my $sr = $args->getSuiteRoot();
	
	my @pairs;
	push(@pairs, [ slashify("$sr/$_"), $_ ]) foreach ($self->{testontap}->{pez}->getAllTests());

	my $failed = 0;
	{
		my $wdmgr = $self->{testontap}->{args}->getWorkDirManager();

		local %ENV = %{$self->{testontap}->{args}->getPreprocess()->getEnv()};
		$ENV{TESTONTAP_SUITE_DIR} = $sr;
		$ENV{TESTONTAP_TMP_DIR} = $wdmgr->getTmp();
		$ENV{TESTONTAP_SAVE_DIR} = $wdmgr->getSaveSuite();
		
		if ($self->{testontap}->{args}->useHarness())
		{
			# the normal case is to run with a 'real' harness that parses
			# TAP, handles parallelization, formatters and all that
			#
			$wdmgr->beginTestRun();
			my $aggregator = $self->SUPER::runtests(@pairs); 
			$wdmgr->endTestRun($self->{testontap}->{args}, $aggregator);
			$failed = $aggregator->failed() || 0;
		}
		else
		{
			# if the user has requested 'no harness', just run the jobs serially
			# in the right context, but make no effort to parse their output
			# in any way - more convenient for debugging (esp. with an execmap
			# that can start a test in debug mode)
			#
			my $scheduler = $self->make_scheduler(@pairs);

			# figure out the longest test file name with some extra to produce some
			# nice delimiters...
			#
			my $longestTestFileName = 0;
			$longestTestFileName = max($longestTestFileName, length($_->[0])) foreach (@pairs);
			$longestTestFileName += 10;
			my $topDelimLine = '#' x $longestTestFileName;
			my $bottomDelimLine = '-' x $longestTestFileName;

			while (my $job = $scheduler->get_job())
			{
				my $desc = $job->description();
				my $filename = $job->filename;
				my $cmdline = $self->exec()->($self, $filename);
				my $dryrun = $self->{testontap}->{args}->doDryRun();
				my $parallelizable = ($self->{testontap}->{args}->getConfig()->parallelizable($desc) ? '' : 'not ') . 'parallelizable'; 
				print "$topDelimLine\n";
				print "Run test '$desc' ($parallelizable) using:\n";
				print "  $_\n" foreach (@$cmdline);
				print "$bottomDelimLine\n";
				if ($dryrun)
				{
					print "(dry run only, actual test not executed)\n";
				}
				else
				{	 
					$failed++ if system(@$cmdline) >> 8;
				}
				$job->finish();
			}	
		}
		
		# run postprocessing
		#
		my $postcmd = $self->{testontap}->{args}->getConfig()->getPostprocessCmd();
		if ($postcmd && @$postcmd)
		{
			my @postproc;
			my $xit = runprocess
						(
							sub
								{
									push(@postproc, $_[0]);
									print STDERR $_[0]
								},
							$sr,
							(
								@$postcmd,
								@{$self->{testontap}->{args}->getPreprocess()->getArgv()}
							)
						);
			if ($xit)
			{
				$failed++;
				warn("WARNING: exit code '$xit' when running postprocess command\n");
			}
			$failed++ if $xit;

			$args->getWorkDirManager()->recordPostprocess([ @postproc ]);
		}
		
		# drop the special workaround envvar...
		#
		delete $ENV{PERL5LIB} if $IS_PACKED;
	}
	
	return ($failed > 127) ? 127 : $failed;
}

sub _open_spool
{
	my $self = shift;
	my $testpath = shift;

	return $self->{testontap}->{args}->getWorkDirManager()->openTAPHandle($testpath);
}

sub _close_spool
{
    my $self = shift;
    my $parser = shift;

	$self->{testontap}->{args}->getWorkDirManager()->closeTAPHandle($parser);

	return; 
}

sub __getExecMapper
{
	my $args = shift;

	return sub
			{
				my $harness = shift;
				my $testfile = shift;
		
				# trim down the full file name to the test name
				#
				my $srfs = slashify($args->getSuiteRoot(), '/');
				my $testname = slashify($testfile, '/');
				$testname =~ s#^\Q$srfs\E/##;

				# get the commandline corresponding to the test name
				#
				my $cmdline = $args->getConfig()->getExecMapping($testname);
				
				# expand it with the full set
				#
				$cmdline = [ @$cmdline, $testfile, @{$args->getArgv()} ];
				
				# make a note of the result for the work area records
				#
				$args->getWorkDirManager()->recordCommandLine($testname, $cmdline);
				
				return $cmdline;
			};
}

sub __getFormatter
{
	my $args = shift;

	my $formatterArgs = 
						{
							jobs => $args->getJobs(),
							timer => $args->getTimer(),
							show_count => 1,
							verbosity => $args->getVerbose(),
						};
						
	return
		-t \*STDOUT
			?	TAP::Formatter::Console->new($formatterArgs)
			:	TAP::Formatter::File->new($formatterArgs);
}

1;
