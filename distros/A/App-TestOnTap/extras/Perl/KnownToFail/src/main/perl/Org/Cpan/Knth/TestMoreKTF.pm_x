# Test primitives, passing to Test::More but with extra methods and
# 'knownfails' handling mechanism
#
use strict;
use warnings;

package Org::Cpan::Knth;

use Exporter qw(import);
use Test::More qw();

our @EXPORT;

# Test::More primitives
# 
@EXPORT = qw
	(
		plan
		pass
		fail
		ok
		is
		isnt
		cmp_ok
		is_deeply
		like
		unlike
		skip
		BAIL_OUT
		$TODO
		todo_start
		todo_end
		explain
		done_testing
	);
	
# knownfails mechanism
#
@EXPORT =
	(
		@EXPORT,
		qw
		(
			testKnownToFail
			testsKnownToFail
			nextTestKnownToFail
			nextNTestsKnownToFail
		)
	);
my $dontHandleKnownFailures = exists($ENV{DONT_HANDLE_KNOWN_FAILURES}) ? 1 : 0;
my %knownFails;
  
# trap Test::More primitives
#
sub plan
{
	return Test::More::plan(@_);
}

sub pass (;$)
{
	return __dispatchTest(\&Test::More::pass, $_[0], @_);
}

sub fail (;$)
{
	return __dispatchTest(\&Test::More::fail, $_[0], @_);
}

sub ok ($;$)
{
	return __dispatchTest(\&Test::More::ok, $_[1], @_);
}

sub is ($$;$)
{
	return __dispatchTest(\&Test::More::is, $_[2], @_);
}

sub isnt ($$;$)
{
	return __dispatchTest(\&Test::More::isnt, $_[2], @_);
}

sub cmp_ok ($$$;$)
{
	return __dispatchTest(\&Test::More::cmp_ok, $_[3], @_);
}

sub is_deeply
{
	return __dispatchTest(\&Test::More::is_deeply, $_[2], @_);
}

sub like ($$;$)
{
	return __dispatchTest(\&Test::More::like, $_[2], @_);
}

sub unlike ($$;$)
{
	return __dispatchTest(\&Test::More::unlike, $_[2], @_);
}

sub skip
{
	return __dispatch(\&Test::More::skip, @_);
}

sub BAIL_OUT
{
	return __dispatch(\&Test::More::BAIL_OUT, @_);
}

sub todo_start
{
	return Test::More->builder()->todo_start(@_);
}

sub todo_end
{
	return Test::More->builder()->todo_end(@_);
}

sub explain
{
	return __dispatch(\&Test::More::explain, @_);
}

sub done_testing
{
	my $ret = Test::More::done_testing(@_);
	
	return $ret;
}

# knownfails mechanism
#

sub testKnownToFail
{
	my $failMsg = shift;
	my $testNum = shift;
	
	if (!$dontHandleKnownFailures)
	{
		my $existingFailMsg = $knownFails{$testNum};
		$knownFails{$testNum} = defined($existingFailMsg) ? [$existingFailMsg, $failMsg] : $failMsg;
	}
}

sub testsKnownToFail
{
	my $failMsg = shift;
	my @testNums = @_;
	
	testKnownToFail($failMsg, $_) foreach (@testNums);
}

sub nextTestKnownToFail
{
	my $failMsg = shift;
	
	testKnownToFail($failMsg, Test::More->builder()->current_test() + 1);
}

sub nextNTestsKnownToFail
{
	my $failMsg = shift;
	my $count = shift;
	
	my $start = Test::More->builder()->current_test() + 1;
	testKnownToFail($failMsg, $_) for ($start .. ($start + $count - 1));
}

# INTERNAL
#

sub __dispatch
{
	my $method = shift;
	
	my $addLvl = 1;
	while ((caller($addLvl))[0] eq __PACKAGE__)
	{
		$addLvl++;
	}
	$addLvl++;
	
	my $currentLvl = Test::More->builder()->level();
	Test::More->builder()->level($currentLvl + $addLvl);

	my $result = $method->(@_);
		
	Test::More->builder()->level($currentLvl);

	return $result;
}

sub __dispatchTest
{
	my $method = shift;
	my $msg = shift || '<no test msg given>';
	
	my $addLvl = 1;
	while ((caller($addLvl))[0] eq __PACKAGE__)
	{
		$addLvl++;
	}
	$addLvl++;
	
	my $currentLvl = Test::More->builder()->level();
	Test::More->builder()->level($currentLvl + $addLvl);

	my $nextTestNum = Test::More->builder()->current_test() + 1;
	my $failMsg = $knownFails{$nextTestNum};
	$failMsg = '(' . scalar(@$failMsg) . ' CAUSES) ' . join(' (NEXT CAUSE) ', @$failMsg) if (ref($failMsg) eq 'ARRAY');

	my $whichTestAmI = whichTestAmI();

	my $testResult;
	if (!defined($failMsg))
	{
		$testResult = $method->(@_);
		makeNote(1, "NOTE: This test designated as KNOWN_FAIL! ($failMsg)") if ($failMsg && !$testResult);
	}
	elsif (!$dontHandleKnownFailures)
	{
		$testResult = $method->(@_);
		&Test::More::BAIL_OUT("Test $whichTestAmI:$nextTestNum ($msg) designated as KNOWN_FAIL unexpectedly succeeded! ($failMsg)") if ($testResult && $failMsg);
	}
	else
	{
		&Test::More::BAIL_OUT("Test $whichTestAmI:$nextTestNum not designated as KNOWN_FAIL!") unless defined($failMsg);
		if (!$dontHandleKnownFailures)
		{
			my ($outbuf, $errbuf) = ('', '');
			my $tb = Test::More->builder();
			$tb->output(\$outbuf);
			$tb->failure_output(\$errbuf);
			$testResult = $method->(@_);
			$tb->current_test($nextTestNum - 1);
			$tb->reset_outputs();
			&Test::More::pass("$msg (KNOWN_FAIL PASS: $failMsg)");
			&Test::More::BAIL_OUT("Test $whichTestAmI:$nextTestNum ($msg) designated as KNOWN_FAIL unexpectedly succeeded! ($failMsg)") if ($testResult && $failMsg);
		} 
	}
		
	Test::More->builder()->level($currentLvl);

	return $testResult;
}

1;
