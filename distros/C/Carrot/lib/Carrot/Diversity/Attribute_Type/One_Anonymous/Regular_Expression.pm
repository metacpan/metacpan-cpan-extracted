package Carrot::Diversity::Attribute_Type::One_Anonymous::Regular_Expression
# /type class
# //parent_classes
#	::Diversity::Attribute_Type::One_Anonymous
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Diversity/Attribute_Type/One_Anonymous/Regular_Expression./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub constructor
# /type class_method
# /effect "Constructs a new instance."
# //parameters
#	value
#	*
# //returns
#	::Personality::Abstract::Instance
{
	my ($class, $value) = splice(\@ARGUMENTS, 0, 2);

	my $this = bless(qr{$value}, $class);
	$this->attribute_construction(@ARGUMENTS) if ($this->can('attribute_construction'));
	return($this);
}

sub matches
# /type class_method
# /effect "Returns context-sensitive result of RE match."
# //parameters
#	value
# //returns
#	::Personality::Abstract::Raw::Text
{
	my ($this) = @ARGUMENTS; # $_[THIS] is taken as $_ + class [THIS]

#not really convincing
	scalar($_[SPX_VALUE] =~ m{$this});
	return(\@LAST_MATCH_START, \@LAST_MATCH_END);
}

sub matches_next
# /type class_method
# /effect ""
# //parameters
#	value
# //returns
#	::Personality::Abstract::Raw::Text
{
	my ($this) = @ARGUMENTS;

#ditto
	scalar($_[SPX_VALUE] =~ m{$this}g);
	return(\@LAST_MATCH_START, \@LAST_MATCH_END);
}

sub match_all
# /type class_method
# /effect ""
# //parameters
#	value
# //returns
#	::Personality::Abstract::Array
{
	my ($this) = @ARGUMENTS;
	return([$_[SPX_VALUE] =~ m{$this}g]);
}

sub substitute
# /type class_method
# /effect "Returns context-sensitive result of RE match."
# //parameters
#	value
# //returns
#	::Personality::Abstract::Raw::Text
{
	my ($this, $value, $replacement) = @ARGUMENTS;

	return($value =~ s{$this}{$replacement});
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.65
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
