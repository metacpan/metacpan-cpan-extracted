package Carrot::Modularity::Object::Universal
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Object/Universal./manual_modularity.pl');
	} #BEGIN

	require Scalar::Util; # for distinguishing blessed from non-blessed references

	Carrot::Meta::Greenhouse::Shared_Subroutines::announce;

	require Carrot::Modularity::Package::Patterns;
	my $pkg_patterns = Carrot::Modularity::Package::Patterns->constructor;

# =--------------------------------------------------------------------------= #

sub indirect_constructor
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my ($pkg_name, $pkg_file, $line) = caller;
	die("Change to ->constructor on line $line in file '$pkg_file'.");
}

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
}

sub class_name
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return(Scalar::Util::blessed($_[THIS]));
}

sub reference_type
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return("$_[THIS]" =~ m{\A[\w:]+=(\w+)\(0x\w+\)\z}sg);
}

sub attribute_type
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	no strict 'refs';
	#FIXME: this is more like a reminder; unused so far; ugly hack
	return(grep(m{::Attribute_Type::},
		@{Scalar::Util::blessed($_[THIS]).'::ISA'}));
}

sub _internal_memory_address
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
#NOTE: consistent with default (non-overloaded) stringification
	return('0x'.sprintf('%08X', Scalar::Util::refaddr($_[THIS])));
#	return(Scalar::Util::refaddr($_[THIS]));
}

sub is_itself
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
#	::Personality::Abstract::Boolean
{
	# scalar($_[THIS]) might be subject to overloading
	return(Scalar::Util::refaddr($_[THIS]) == Scalar::Util::refaddr($_[THAT]));
}

sub parent_class_names
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Array
{
	no strict 'refs';
	return(\@{Scalar::Util::blessed($_[THIS]).'::ISA'});
}

sub sibling_constructor
# /type class_method
# /effect ""
# /parameters *
# //returns
#	::Personality::Abstract::Instance
{
	my $class = Scalar::Util::blessed(shift(\@ARGUMENTS));
	return($class->constructor(@ARGUMENTS));
}

sub is_sibling
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
#	::Personality::Abstract::Boolean
{
	return(Scalar::Util::blessed($_[THIS]) eq Scalar::Util::blessed($_[THAT]));
}

sub class_change
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
{
	my ($this, $class) = @ARGUMENTS;

	my $target_type = Scalar::Util::blessed($class);
	if (defined($target_type))
	{
		if ($target_type eq 'Carrot::Modularity::Package::Name')
		{
			$class = $class->value;
		} else {
			$class = $target_type;
		}
	} elsif ($pkg_patterns->is_relative_package_name($class))
	{
		$class = Scalar::Util::blessed($this).$class;
	}
	bless($this, $class);

	return;
}

sub cloned_re_constructor
# /type method
# /effect ""
# //parameters
#	class
#	*
# //returns
{
	my $this = shift(\@ARGUMENTS);

	my $cloned = $this->clone_constructor;
	$cloned->re_constructor(@ARGUMENTS);
	return($cloned);
}

sub class_transfer
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
{
	bless($_[THAT], Scalar::Util::blessed($_[THIS]));
	return;
}

sub value_representation_debug
# /type method
# /effect "Returns the scalar value of the instance."
# //parameters
# //returns
#	::Personality::Abstract::Text
{
	return(qq{$_[THIS]});
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.150
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
