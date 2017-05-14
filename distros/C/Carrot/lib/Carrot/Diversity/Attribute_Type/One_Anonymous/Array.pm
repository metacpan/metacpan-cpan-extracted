package Carrot::Diversity::Attribute_Type::One_Anonymous::Array
# /type class
# //parent_classes
#	::Diversity::Attribute_Type::One_Anonymous
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Diversity/Attribute_Type/One_Anonymous/Array./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub constructor
# /type class_method
# /effect "Constructs a new instance."
# /parameters
#	value  +optional  ::Personality::Abstract::Array
# //returns
#	::Personality::Abstract::Instance
{
	return(bless($_[SPX_VALUE] // [], $_[THIS]));
}

sub clear
# /type method
# /effect ""
# //parameters
# //returns
{
	@{$_[THIS]} = ();
	return;
}

sub set_size
# /type method
# /effect ""
# //parameters
#	value
# //returns
{
	$#{$_[THIS]} = $_[SPX_VALUE]-1;
	return;
}

sub copy_data_into
# /type method
# /effect "Copies all elements into the argument."
# //parameters
# //returns
{
	push(@{$_[THAT]}, @{$_[THIS]});
	return;
}

sub copied_data
# /type method
# /effect "Returns a non-blessed copy of the array."
# //parameters
# //returns
#	::Personality::Abstract::Array
{
	return([@{$_[THIS]}]);
}

sub at_position
# /type method
# /effect "Returns the element at the position."
# //parameters
#	position
# //returns
#	::Personality::Abstract::Text
{
	exists($_[THIS][$_[SPX_POSITION]])
		? $_[THIS][$_[SPX_POSITION]]
		: IS_UNDEFINED;
}

sub set_at_position
# /type method
# /effect "Sets the element at the position to the value."
# //parameters
#	position
#	element
# //returns
{
	$_[THIS][$_[SPX_POSITION]] = $_[SPX_ELEMENT];
	return;
}

#questionable
sub at_positions
# /type method
# /effect ""
# //parameters
#	position  +multiple
# //returns
#	::Personality::Abstract::Array
{
	my $r = [];
	push($r, $_[THIS][$_]) for @ARGUMENTS;
	return($r);
}

sub count
# /type method
# /effect "Returns the element count."
# //parameters
# //returns
#	::Personality::Abstract::Number
{
	return($#{$_[THIS]} +1);
}

sub first
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Text
{
	exists($_[THIS][ADX_FIRST_ELEMENT])
		? $_[THIS][ADX_FIRST_ELEMENT]
		: IS_UNDEFINED;
}

sub last
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Text
{
	exists($_[THIS][ADX_LAST_ELEMENT])
		? $_[THIS][ADX_LAST_ELEMENT]
		: IS_UNDEFINED;
}

sub insert_at_position
# /type method
# /effect ""
# //parameters
#	position
# //returns
{
	my ($this, $position) = splice(\@ARGUMENTS, 0, 2);

	splice(@$this, $position, 0, @ARGUMENTS);
	return;
}

sub append_value
# /type method
# /effect ""
# //parameters
#	value  +multiple
# //returns
{
	push(@{shift(\@ARGUMENTS)}, @ARGUMENTS);
	return;
}

sub append
# /type method
# /effect ""
# //parameters
#	value  +multiple
# //returns
{
	push(@{$_[THIS]}, @{$_[SPX_VALUES]});
	return;
}

sub propend_value
# /type method
# /effect ""
# //parameters
#	value  +multiple
# //returns
{
	unshift(@{shift(\@ARGUMENTS)}, @ARGUMENTS);
	return;
}

sub propend
# /type method
# /effect ""
# //parameters
#	values
# //returns
{
	unshift(@{$_[THIS]}, @{$_[SPX_VALUES]});
	return;
}

sub removed_from_end
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Text
{
	return(pop(@{$_[THIS]}));
}

sub removed_from_beginning
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Text
{
	return(shift(@{$_[THIS]}));
}

sub highest_index
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Instance
{
	return($#{$_[THIS]});
}

sub is_greater_value
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return($#{$_[THIS]} > $_[SPX_VALUE]);
}

sub is_greater
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return($#{$_[THIS]} > $#{$_[THAT]});
}

sub is_lesser_value
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Instance
{
	return($#{$_[THIS]} < $_[SPX_VALUE]);
}

sub is_lesser
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Instance
{
	return($#{$_[THIS]} < $#{$_[THAT]});
}

sub is_equal_value
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return($#{$_[THIS]} == $_[SPX_VALUE]);
}

sub is_equal
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return($#{$_[THIS]} == $#{$_[THAT]});
}

sub is_empty
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return($#{$_[THIS]} == ADX_NO_ELEMENTS);
}

sub is_non_empty
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return($#{$_[THIS]} > ADX_NO_ELEMENTS);
}

sub first_defined
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Text
{
	foreach (@{$_[THIS]})
	{
		return($_) if (defined($_));
	}
	return(IS_UNDEFINED);
}

sub last_defined
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Text
{
	foreach (reverse(@{$_[THIS]}))
	{
		return($_) if (defined($_));
	}
	return(IS_UNDEFINED);
}

sub all_defined
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Array
{
	return([grep(defined($_), @{$_[THIS]})]);
}

#sub remove_undefined_at_end {
#        my $this = shift();
#
#        while (($#$this > ADX_NO_ELEMENTS) and
#            not defined($this->[ADX_LAST_ELEMENT])) {
#                pop(@$this);
#        }
#        return;
#}

sub rotate_left
# /type method
# /effect ""
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	return if ($#$this < 1);
	push(@$this, shift(@$this));
	return;
}

sub rotate_right
# /type method
# /effect ""
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	return if ($#$this < 1);
	unshift(@$this, pop(@$this));
	return;
}

sub removed_all
# /type method
# /effect ""
# //parameters
# //returns
{
	return([splice(@{$_[THIS]})]);
}

sub remove_undefined
# /type method
# /effect ""
# //parameters
# //returns
{
	@{$_[THIS]} = (grep(defined($_), @{$_[THIS]}));
	return;
}

sub remove_duplicates
# /type method
# /effect ""
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	my $seen = {};
	foreach my $element (splice(@$this))
	{
		next if (exists($seen->{$element}));
		$seen->{$element} = IS_EXISTENT;
		push(@$this, $element);
	}
	return;
}

sub has_duplicates
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	my $elements = {};
	foreach my $element (@{$_[THIS]})
	{
		return(IS_TRUE) if (exists($elements->{$element}));
		$elements->{$element} = IS_EXISTENT;
	}
	return(IS_FALSE);
}

sub reduce
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
#	method
#	*
# //returns
{
	my ($this, $that, $method) = splice(\@ARGUMENTS, 0, 3);

	my $rv = IS_UNDEFINED;
	foreach my $element (@{$_[THIS]})
	{
		$rv = $that->$method($element, $rv, @ARGUMENTS);
	}
	return;
}

sub run_on_all
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
#	method
#	*
# //returns
{
	my ($this, $that, $method) = splice(\@ARGUMENTS, 0, 3);

	foreach my $element (@$this)
	{
		$that->$method($element, @ARGUMENTS);
	}
	return;
}

sub run_until_success
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
#	method
#	*
# //returns
{
	my ($this, $that, $method) = splice(\@ARGUMENTS, 0, 3);

	foreach my $element (@$this)
	{
		last if ($that->$method($element, @ARGUMENTS));
	}
	return;
}

sub run_and_collect
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
#	method
#	*
# //returns
#	::Personality::Abstract::Array
{
	my ($this, $that, $method) = splice(\@ARGUMENTS, 0, 3);

	my $rv = [];
	foreach my $element (@$this)
	{
		push($rv, $that->$method($element, @ARGUMENTS));
	}
	return($rv);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.202
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
