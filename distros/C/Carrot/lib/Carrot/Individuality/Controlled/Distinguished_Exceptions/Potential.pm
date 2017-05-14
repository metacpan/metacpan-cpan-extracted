package Carrot::Individuality::Controlled::Distinguished_Exceptions::Potential
# /type class
# //parent_classes
#	::Individuality::Controlled::Localized_Messages::Prototype
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->provide(
#		my $logging_channel = '::Individuality::Singular::Application::Logging_Channel',
		my $fatal_error = '::Individuality::Singular::Execution::Fatal_Error');

	$expressiveness->package_resolver->provide(
		my $policy_class = '[=project_pkg=]::Details_Policy');

#	$logging_channel->provide(
#		my $exception_log = 'exception_log');

	my $max_trace_level = 1_000;

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	resolver
#	msg_name
# //returns
{
	my ($this, $resolver, $msg_name) = @ARGUMENTS;

	$this->superseded($resolver, $msg_name);
	$this->[ATR_POLICY] = $policy_class->indirect_constructor;

	return;
}

sub raise_exception
# /type method
# /effect ""
# //parameters
#	details
#	category
# //returns
#	?
{
	my ($this, $details, $category) = @ARGUMENTS;
	my $caller = [caller];

	die unless (ref($details) eq 'HASH'); #	$details //= {};

#	$details->{'caller_package'} //= $caller->[RDX_CALLER_PACKAGE];
#	$details->{'caller_file'} //= $caller->[RDX_CALLER_FILE];
#	$details->{'caller_line'} //= $caller->[RDX_CALLER_LINE];
	if (exists($details->{+HKY_DEX_BACKTRACK}))
	{
#FIXME: format information
#FIXME: avoid recursive processing
		$this->backtrack_argument(
			delete($details->{+HKY_DEX_BACKTRACK}), $details);
	}

	$this->[ATR_SPECIFIC_CONTEXT] = $details;

	$fatal_error->trigger(
		$caller,
		$this,
		$category);
}

sub backtrack_argument
# /type method
# /effect ""
# //parameters
#	candidate
#	details
# //returns
{
	my ($this, $candidate, $details) = @ARGUMENTS;

	$details->{'traced_frame_argument'} = $candidate;

	my $depth = 1;
	while ($depth < $max_trace_level)
	{
		$depth += 1;
		my $caller;
		my $subroutine_args;
		package DB {
			our @args;
			$caller = [caller($depth)];
			$subroutine_args = [@args];
		}
		last if ($#$caller == ADX_NO_ELEMENTS);

		my $position = ADX_NO_ELEMENTS;
		my $found = IS_FALSE;
		foreach my $argument (@$subroutine_args)
		{
			$position++;
			if (defined($candidate))
			{
				next unless (defined($argument));
				next unless ("$argument" eq $candidate);
			} else {
				next if (defined($argument));
			}
			$found = IS_TRUE;
			last;
		}
		last unless ($found);
		my $key = (defined($subroutine_args->[ADX_FIRST_ELEMENT])
			? "$subroutine_args->[ADX_FIRST_ELEMENT]"
			: '');
		$details->{'traced_frame_level'} = $depth;
		$details->{'traced_frame_caller'} = $caller;
		$details->{'traced_frame_position'} = $position;
		$details->{'traced_frame_key'} = $key;
	}

	my $call_frame = {
		'traced_frame_level' => -1,
		'traced_frame_caller' => ['', '', -1, ''],,
		'traced_frame_position' => ADX_NO_ELEMENTS,
		'traced_frame_key' => undef};

	if ($#{$call_frame->{'traced_frame_caller'}} == ADX_NO_ELEMENTS)
	{
		$details->{'traced_frame_level'} = -1;
		$details->{'traced_frame_caller'} = ['', '', -1, ''];
		$details->{'traced_frame_position'} = ADX_NO_ELEMENTS;
		$details->{'traced_frame_key'} = IS_UNDEFINED;
	} else {
		$details->{'traced_frame_caller'}[RDX_CALLER_SUB_NAME] =~ s{^.*::}{}s;
	}

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}

__END__
disabled - something existing intentionally not available
unknown - not clear how to handle
missing - something known could not be found
invalid - not matching regarding a pattern or discrete value
illegal - regarding a policy
incomplete
# //revision_control
#	version 1.1.79
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
