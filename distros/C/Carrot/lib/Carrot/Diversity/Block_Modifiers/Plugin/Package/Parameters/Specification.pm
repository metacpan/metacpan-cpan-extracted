package Carrot::Diversity::Block_Modifiers::Plugin::Package::Parameters::Specification
# /type class
# /attribute_type ::One_Anonymous::Array
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Diversity/Block_Modifiers/Plugin/Package/Parameters/Specification./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub constructor
# /type class_method
# /effect "Fills an newly constructed instance with life."
# //parameters
#	value
# //returns
{
	my ($class, $value) = @ARGUMENTS;

# my (...) = Carrot::Diversity::Block_Modifiers::Plugin::Package::Parameters::Validate( __PACKAGE__, \@ARGUMENTS, [qw(types)]);
# fixed count
# always require, no +optional, no +multiple, no method, only isa check
	my $this = [];
	foreach my $line (@$value)
	{
		push($this, [split(qr{\h+}, $line, 2)]);
	}

	bless($this, $class);
	return($this);
}

sub count
# /type method
# /effect ""
# //parameters
# //returns
#	name    ::Personality::Abstract::Number
{
	return($#{$_[THIS]}+1);
}

sub names
# /type method
# /effect ""
# //parameters
# //returns
#	name    ::Personality::Abstract::Text
{
	return([map($_->[0], @{$_[THIS]})]);
}

sub types
# /type method
# /effect ""
# //parameters
# //returns
#	name    ::Personality::Abstract::Text
{
	return([map($_->[1], @{$_[THIS]})]);
}


# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.172
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
