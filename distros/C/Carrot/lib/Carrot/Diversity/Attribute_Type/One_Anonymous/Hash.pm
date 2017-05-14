package Carrot::Diversity::Attribute_Type::One_Anonymous::Hash
# /type class
# //parent_classes
#	::Diversity::Attribute_Type::One_Anonymous
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Diversity/Attribute_Type/One_Anonymous/Hash./manual_modularity.pl');
	} #BEGIN

	Carrot::Meta::Greenhouse::Package_Loader::provide_instance(
	        my $translated_errors = '::Meta::Greenhouse::Translated_Errors');

# =--------------------------------------------------------------------------= #

sub constructor
# /type class_method
# /effect "Constructs a new instance."
# /parameters
#	value  +optional  ::Personality::Abstract::Hash
# //returns
#	::Personality::Abstract::Instance
{
	return(bless($_[SPX_VALUE] // {}, $_[THIS]));
}

sub retrieve_fatally
# /type method
# /effect "Checks whether a key exists."
# //parameters
#	key
# //returns
{
	unless (exists($_[THIS]{$_[SPX_KEY]}))
	{
		$translated_errors->oppose(
			'hash_key_missing',
			[$_[SPX_KEY], "$_[THIS]"]);
	}
	return($_[THIS]{$_[SPX_KEY]});
}

sub exists
# /type method
# /effect "Checks whether a key exists."
# //parameters
#	key
# //returns
#	::Personality::Abstract::Boolean
{
	return(CORE::exists($_[THIS]{$_[SPX_KEY]}));
}

sub clear
# /type method
# /effect ""
# //parameters
# //returns
{
	%{$_[THIS]} = ();
	return;
}

sub complement
# /type method
# /effect ""
# //parameters
#	that
# //returns
{
	my ($this, $that) = @ARGUMENTS;

	keys(%$that); # reset 'each' iterator
	while (my ($key, $value) = each(%$that))
	{
		next if (exists($this->{$key}));
		$this->{$key} = $value;
	}
	return;
}

sub complement_defined
# /type method
# /effect ""
# //parameters
#	that
# //returns
{
	my ($this, $that) = @ARGUMENTS;

	keys(%$that); # reset 'each' iterator
	while (my ($key, $value) = each(%$that))
	{
		next if (exists($this->{$key}) and defined($this->{$key}));
		$this->{$key} = $value;
	}
	return;
}

sub intersect
# /type method
# /effect "Deletes all keys not in both sets."
# //parameters
#	that
# //returns
{
	my ($this, $that) = @ARGUMENTS;

	foreach my $key (keys(%$this))
	{
		next if (exists($that->{$key}));
		delete($this->{$key});
	}
	return;
}

sub difference
# /type method
# /effect "Deletes all keys contained in both sets."
# //parameters
#	that
# //returns
{
	my ($this, $that) = @ARGUMENTS;

	foreach my $key (keys(%$this))
	{
		next unless (exists($that->{$key}));
		delete($this->{$key});
	}
	return;
}

sub copied_data
# /type method
# /effect "Returns a non-blessed copy of the hash."
# //parameters
# //returns
#	::Personality::Abstract::Hash
{
	return({%{$_[THIS]}});
}

sub remove_prefix_matches
# /type method
# /effect "Removes all keys matching the prefix."
# //parameters
#	value
# //returns
{
	my $l = length($_[SPX_VALUE]);
	my $remove = [grep(
			(substr($_, 0, $l) eq $_[SPX_VALUE]),
			keys(%{$_[THIS]}))];
	foreach (@$remove)
	{
		delete($_[THIS]{$_});
	}
	return;
}

sub lock_attribute_structure
# /type method
# /effect "Locks the structure of the instance (set of existing keys)."
# //parameters
# //returns
{
	Internals::hv_clear_placeholders(%{$_[THIS]});
	Internals::SvREADONLY(%{$_[THIS]}, 1);
	return;
}

sub unlock_attribute_structure
# /type method
# /effect "Unlocks the structure of the instance."
# //parameters
# //returns
{
	Internals::SvREADONLY(%{$_[THIS]}, 0);
	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.135
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
