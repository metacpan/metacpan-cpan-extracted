package Carrot::Diversity::Block_Modifiers::Plugin::Subroutine::Parameters::Specification
# /type class
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Diversity/Block_Modifiers/Plugin/Subroutine/Parameters/Specification./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	value
# //returns
{
	my ($this, $value) = @ARGUMENTS;

	$this->[ATR_MINIMUM] = IS_UNDEFINED;
	$this->[ATR_MAXIMUM] = IS_UNDEFINED;
	$this->[ATR_MULTIPLE] = IS_UNDEFINED;
	$this->[ATR_WILD] = IS_UNDEFINED;
	$this->[ATR_TYPES] = [];

# <name> +option (required|optional|undefined|) <class> | ->method(...) | ...
	if (ref($value) eq '')
	{
		if ($value eq '0')
		{
			$value = [];

		} elsif ($value eq '*')
		{
			$value = ['*'];
		}
	}

	my $i = ADX_NO_ELEMENTS;
	foreach my $line (@$value)
	{
		$i += 1;
		if ($line eq '*')
		{
			$this->[ATR_WILD] = $i;
			next;
		}

		unless ($line =~ s{^(\w+)(\h+|\z)}{}s)
		{
			die("Invalid parameter line '$line'.");
		}
		my $name = $1;

		my $option = '';
		if ($line =~ s{^\+(\w+)(\h+|\z)}{}s)
		{
			$option = $1;
		}
		if ($option eq 'multiple')
		{
			$this->[ATR_MULTIPLE] = $i;
#FIXME: fatal if defined($this->[ATR_OPTIONAL])

		} elsif ($option eq 'optional')
		{
#FIXME: fatal if defined($this->[ATR_MULTIPLE])
			$this->[ATR_MINIMUM] = $i-1;

#		} elsif ($option eq 'named')
#		{
# might even be thrown
		}

		my $switch = 'assert';
		if ($line =~ s{^(assert|require)(\h+|\z)}{}s)
		{
			$switch = $1;
		}

		#reminder of $line contains the checks
		push($this->[ATR_TYPES],
			[$name, $option, $switch, $line]);
	}

	return;
}

sub names
# /type method
# /effect ""
# //parameters
# //returns
#	name    ::Personality::Abstract::Text
{
	return([map($_->[0], @{$_[THIS][ATR_TYPES]})]);
}

sub enumerated_hash
# /type method
# /effect ""
# //parameters
#	offset
# //returns
#       ::Personality::Abstract::Hash
{
        my ($this, $offset) = @ARGUMENTS;

        my $i = ADX_NO_ELEMENTS +$offset;
        my $enumerated = {};
        foreach my $parameter (@{$this->[ATR_TYPES]})
        {
                my ($name, $type) = @$parameter;
                $enumerated->{$name} = ++$i;
        }

        return($enumerated);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.192
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"