package Carrot::Personality::Reflective::Information_Barb::Step
# /type class
# //parent_classes
#	::Productivity::Text::Placeholder::Miniplate::_Corporate
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	subject
# //returns
{
	my ($this, $subject) = @ARGUMENTS;

	$this->[ATR_SUBJECT] = $subject;
	$this->[ATR_COUNTER] = 0; # debugging, profiling - no format needed
	$this->[ATR_TIMESTAMP] = time;
	$this->[ATR_CACHE] = {};

	return;
}

sub used
# /type method
# /effect ""
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_COUNTER] += 1;
	$this->[ATR_TIMESTAMP] = time;

	return;
}

sub formatted_path_value
# /type method
# /effect ""
# //parameters
#	path
#	format
# //returns
#	?
{
	my ($this, $path, $format) = @ARGUMENTS;

	if ($path eq '_.counter')
	{
		return($this->[ATR_COUNTER]);
	} elsif ($path eq '_.timestamp')
	{
		return(scalar(localtime($this->[ATR_TIMESTAMP])));
	}

	my $subject = $this->[ATR_SUBJECT];
	if (ref($subject) eq 'HASH')
	{
		return('??') unless (exists($subject->{$path}));
#FIXME: how to evaluate $format?
		return($subject->{$path});
	}

	my $cache = $this->[ATR_CACHE];
	unless (exists($cache->{$path}))
	{
		my $last_method = IS_UNDEFINED;
		my $methods = [split('.', $path, PKY_SPLIT_RETURN_FULL_TRAIL)];
		foreach my $method (@$methods)
		{
			return('??') unless ($subject->can($method));
			my $rv = $subject->$method;
			if (Scalar::Util::blessed($rv))
			{
				$subject = $rv;
			} else {
				$last_method = $method;
				last;
			}
		}

		my $last_call = (defined($last_method)
			? $subject->can($last_method)
			: ($subject->can('value_formatted')
				// $subject->can('value')));
		$cache->{$path} = [$subject, $last_call];
	}

	my ($value, $last_call) = @{$cache->{$path}};
	return($last_call->($value, $format));
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.61
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"