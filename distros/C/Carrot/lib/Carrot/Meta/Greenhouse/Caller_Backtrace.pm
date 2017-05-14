package Carrot::Meta::Greenhouse::Caller_Backtrace
# /type class
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Meta/Greenhouse/Caller_Backtrace./manual_modularity.pl');
	} #BEGIN

	#FIXME: this is misleading - there are no such official constants
	sub RDX_CALLER_LEVEL() { 11 }
	sub RDX_CALLER_SUB_ARGS() { 12 }

	my $max_trace_level = 1000;

# =--------------------------------------------------------------------------= #

sub raw
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my ($this) = @ARGUMENTS;

	my $caller = [CORE::caller(2)];

	my $level = 3;
	$caller->[RDX_CALLER_LEVEL] = $level-2;
	$caller->[RDX_CALLER_SUB_ARGS] = [];

	my $raw = [$caller];
	while ($level < $max_trace_level)
	{
		$level += 1;
		my $caller;
		package DB {
			my $args = [];
			$caller = [
				CORE::caller($level),
				$level-2,
				$args];
			push($args, @DB::args) if ($caller->[4]);
		}
		last if ($#$caller < 2);
		push($raw, $caller);
	}

	return($raw);
}

sub trigger
# /type method
# /effect ""
# /parameters *
# //returns
#	?
{
	return($_[THIS]->format($_[THIS]->raw));
}

sub trigger_fatal
# /type method
# /effect ""
# /parameters *
# //returns
#	?
{
	die($_[THIS]->format($_[THIS]->raw));
}

sub trigger_fatal_if
# /type method
# /effect ""
# //parameters
#	result
#	*
# //returns
#	?
{
	return unless ($_[SPX_RESULT]);
	die($_[THIS]->format($_[THIS]->raw));
}

sub arg_representation
# /type method
# /effect ""
# //parameters
#	caller
# //returns
#	?
{
	my ($this, $caller) = @ARGUMENTS;

	my $arguments = [];
	foreach my $sub_arg (@{$caller->[RDX_CALLER_SUB_ARGS]})
	{
		unless (defined($sub_arg))
		{
			push($arguments, 'IS_UNDEFINED');
			next;
		}

		my $class = Scalar::Util::blessed($sub_arg);
		if (defined($class))
		{
			unless ($sub_arg->can('value_representation_debug'))
			{
				push($arguments, "$sub_arg");
#					print(STDERR "$sub_arg<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");
				next;
			}
			push($arguments,
				$sub_arg->value_representation_debug);
			next;
		}

		my $type = ref($sub_arg);
		if ($type eq '')
		{
			if (length($sub_arg) > 256)
			{
				substr($sub_arg, 255) = '...';
			}
			push($arguments, qq{'$sub_arg'});

		} elsif ($type eq 'SCALAR')
		{
			if (length($$sub_arg) > 256)
			{
				substr($$sub_arg, 255) = '...';
			}
			push($arguments, qq{\\'$$sub_arg'});

		} else {
			$sub_arg = qq{$sub_arg};
		}
	}

	return('(' .join(",", map("\n\t\t$_", $arguments)) .')');
}

sub format
# /type method
# /effect ""
# //parameters
#	raw
# //returns
#	?
{
	my ($this, $raw) = @ARGUMENTS;

	my $trace = [];
	foreach my $caller (@$raw)
	{
		last unless (defined($caller));
		next if ($#$caller == ADX_NO_ELEMENTS);

		if (defined($caller->[RDX_CALLER_EVAL_TEXT]))
		{
			if ($caller->[RDX_CALLER_IS_REQUIRE])
			{
				$caller->[RDX_CALLER_SUB_NAME] =
					"require ('$caller->[RDX_CALLER_EVAL_TEXT]')";
			} else {
				$caller->[RDX_CALLER_SUB_NAME] =
					"eval '$caller->[RDX_CALLER_EVAL_TEXT]'";
			}
		} elsif (defined($caller->[RDX_CALLER_SUB_NAME]))
		{
			$caller->[RDX_CALLER_SUB_NAME] =~ s{^.*::}{}s;
			$caller->[RDX_CALLER_SUB_NAME] .=
				$this->arg_representation($caller);
		}

		push($trace, "\n#$caller->[RDX_CALLER_LEVEL]"
			." L$caller->[RDX_CALLER_LINE] "
			." $caller->[RDX_CALLER_FILE]\n"
			."\t$caller->[RDX_CALLER_SUB_NAME]");
	}

	return(join("\n", @$trace));
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.168
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
