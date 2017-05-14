package Carrot::Meta::Greenhouse::Test_Plans
# /type class
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Meta/Greenhouse/Test_Plans./manual_modularity.pl');
	} #BEGIN

	our $VERBOSE_FLAG //= 1;
	our $RECORD_FLAG //= 1;

# =--------------------------------------------------------------------------= #

sub constructor
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returned
{
        my $class = $_[THIS];

	my $file_name = $PROGRAM_NAME;
	my $out_file;
	if ($RECORD_FLAG and $file_name =~ s{\.pl\z}{.tpo}saa)
	{
		open($out_file, '>', $file_name);
	}

	my $this = [];
        $this->[ATR_SECTIONS] = 1000;
        $this->[ATR_SECTION] = [0];
        $this->[ATR_SUCCESS] = 0;
        $this->[ATR_FAILURE] = 0;
        $this->[ATR_OUT_FILE] = $out_file;
	bless($this, $class);

	my $datetime = scalar(localtime(time()));
	$this->announce(
		"Creating a test plan at $datetime.\n");

        return($this);
}

sub announce
# /type method
# /effect ""
# //parameters
#       msg
# //returned
{
        my ($this, $msg) = @ARGUMENTS;

	print STDERR $msg if($VERBOSE_FLAG);
	print {$this->[ATR_OUT_FILE]} $msg if(defined($this->[ATR_OUT_FILE]));

        return;
}

sub set_sections
# /type method
# /effect ""
# //parameters
#       value
# //returned
{
        my $this = $_[THIS];

	$this->announce(
		"Scheduling a total of $_[SPX_VALUE] plan sections.\n");
	$this->[ATR_SECTIONS] = $_[SPX_VALUE];

        return;
}

sub report
# /type method
# /effect ""
# //parameters
#       text
#       result
# //returned
{
        my ($this, $text, $result) = @ARGUMENTS;

        my $rc = ' ';
        if ($result)
        {
                $this->[ATR_SUCCESS] += 1;
                $rc = 'X';

        } elsif (! defined($result))
        {
                $this->[ATR_FAILURE] += 1;
                $rc = '!';
        }
        $this->[ATR_SECTION][ADX_LAST_ELEMENT] += 1;

	my $msg = sprintf('  Reported result #%s [%s] %s.',
		join('.', @{$this->[ATR_SECTION]}),
			$rc,
			$text). "\n";
	$this->announce($msg);

        return;
}

sub check_method_transparency
# /type method
# /effect ""
# //parameters
#       instance
#       method1
#       method2
#	tests
# //returned
{
        my ($this, $instance, $method1, $method2, $tests) = @ARGUMENTS;

	$this->announce(
		"Plan section for method transparency.\n");
        $this->[ATR_SECTION][ADX_LAST_ELEMENT] += 1;
	push($this->[ATR_SECTION], 0);
	foreach my $test (@$tests)
	{
		my ($name, $value) = @$test;
		$instance->$method1($value);
		my $rv = $instance->$method2;
		my $success = ($rv eq $value);
		unless ($success)
		{
			print STDERR "Expected '$value' but got '$rv'.\n";
		}
		$this->report($name, $success);
	}
	pop($this->[ATR_SECTION]);

        return;
}

sub check_method_scalar_returns
# /type method
# /effect ""
# //parameters
#       instance
#       method
#	tests
# //returned
{
        my ($this, $instance, $method, $tests) = @ARGUMENTS;

	$this->announce(
		"Plan section for method return values (scalar).\n");
        $this->[ATR_SECTION][ADX_LAST_ELEMENT] += 1;
	push($this->[ATR_SECTION], 0);
	foreach my $test (@$tests)
	{
		my ($name, $arguments, $result) = @$test;
		my $rv = $instance->$method(@$arguments);
		my $success = ($rv eq $result);
		unless ($success)
		{
			print STDERR "Expected '$result' but got '$rv'.\n";
		}
		$this->report($name, $success);
	}
	pop($this->[ATR_SECTION]);

        return;
}

sub check_method_scalar_effect
# /type method
# /effect ""
# //parameters
#       instance
#       method1
#       method2
#	tests
# //returned
{
        my ($this, $instance, $method1, $method2, $tests) = @ARGUMENTS;

	$this->announce(
		"Plan section for method effects (scalar).\n");
        $this->[ATR_SECTION][ADX_LAST_ELEMENT] += 1;
	push($this->[ATR_SECTION], 0);
	foreach my $test (@$tests)
	{
		my ($name, $arguments, $result) = @$test;
		$instance->$method1(@$arguments);
		my $rv = $instance->$method2;
		my $success = ($rv eq $result);
		unless ($success)
		{
			print STDERR "Expected '$result' but got '$rv'.\n";
		}
		$this->report($name, $success);
	}
	pop($this->[ATR_SECTION]);

        return;
}

sub has_methods
# /type method
# /effect ""
# //parameters
#       instance
#       method1
#       method2
#	tests
# //returned
{
        my ($this, $instance, $methods) = @ARGUMENTS;

	$this->announce(
		"Plan section for methods.\n");
        $this->[ATR_SECTION][ADX_LAST_ELEMENT] += 1;
	push($this->[ATR_SECTION], 0);
	foreach my $method (@$methods)
	{
		my $success = defined($instance->can($method));
#		unless ($success)
#		{
#			print STDERR "No method '$method' in instance $instance.\n";
#		}
		$this->report("->$method(...", $success);
	}
	pop($this->[ATR_SECTION]);

        return;
}

sub summary
# /method /public
# /effect ""
# /parameters 0
# /returned 0
{
        my $this = $_[THIS];

	my $error_code = 0;
	if ($this->[ATR_SECTION][ADX_FIRST_ELEMENT] != $this->[ATR_SECTIONS])
        {
                $error_code = 2;

        } elsif ($this->[ATR_FAILURE] > 0)
        {
                $error_code = 1;
        }

	my $datetime = scalar(localtime(time()));
	my $msg = join("\n",
		"Summary of test results at $datetime",
		'*-------+---------+---------+---------*',
		'| Total | Success | Failure | Missing |',
		'+-------+---------+---------+---------+',
		sprintf('| % 4d  | % 6d  | % 5d   | % 5d   |',
			($this->[ATR_FAILURE]+$this->[ATR_SUCCESS]),
			$this->[ATR_SUCCESS] ,
			$this->[ATR_FAILURE],
			($this->[ATR_SECTIONS]-$this->[ATR_SECTION][ADX_FIRST_ELEMENT])),
		'*-------+---------+---------+---------*',
		"Error code: $error_code");
	$this->announce($msg);

	exit($error_code) if ($error_code);

        return;
}

sub DESTROY
# /type method
# /effect ""
# /parameters 0
# /returned 0
{
        my $this = $_[THIS];

	return unless(defined($this->[ATR_OUT_FILE]));

        close($this->[ATR_OUT_FILE]);
	$this->[ATR_OUT_FILE] = IS_UNDEFINED;

        return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.102
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
