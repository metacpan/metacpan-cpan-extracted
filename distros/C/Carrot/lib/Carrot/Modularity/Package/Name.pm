package Carrot::Modularity::Package::Name
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Modularity/Package/Name./manual_modularity.pl');
	} #BEGIN

	Carrot::Meta::Greenhouse::Package_Loader::provide_instance(
		my $loader = '::Modularity::Package::Loader',
		my $pkg_patterns = '::Modularity::Package::Patterns',
		my $translated_errors = '::Meta::Greenhouse::Translated_Errors');

	Carrot::Meta::Greenhouse::Package_Loader::provide(
		my $directory_class = '::Personality::Valued::File::Name::Type::Directory',
		my $file_name_class = '::Modularity::Package::File_Name',
		my $name_space_class = '::Modularity::Package::Name::Space');

# =--------------------------------------------------------------------------= #

sub constructor
# /type class_method
# /effect "Intercepts the actual constructor to check usage."
# /parameters *
# /returns *
{
	if (Scalar::Util::blessed($_[THIS]))
	{
#NOTE: one could avoid indirect_constructor, but what about the rest?!
#		my $function = ${$_[THIS]};
#		$_[THIS] = $function;
#		$function .= '::constructor';
#		goto(&$function);
		my $caller = [caller(0)];
		die("Use ->indirect_constructor\n at "
			.$caller->[RDX_CALLER_FILE]
			.' line '
			.$caller->[RDX_CALLER_LINE]
			."\n");
	}
	goto(&Carrot::Diversity::Attribute_Type::One_Anonymous::Scalar::constructor);
}

sub _file_name_actual
# /type method
# /effect ""
# //parameters
# //returns
{
	my $pkg_file = $_[THIS]->file_name_logical;
	if (exists($MODULES_LOADED{$pkg_file}))
	{
		unless (defined($MODULES_LOADED{$pkg_file}))
		{
			die("File '$pkg_file' not fully loaded, yet.");
		}
		return($MODULES_LOADED{$pkg_file});
	}
#	if (exists($CNI{$pkg_file}))
#	{
#		return($pkg_file);
#	}
	$translated_errors->advocate(
		'package_not_loaded',
		[$pkg_file]);
	return;
}

sub as_file_name
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Instance
{
	return($file_name_class->constructor(
		       $_[THIS]->_file_name_actual));
}

sub dot_directory_actual
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Instance
{
	return($directory_class->constructor(
	       $pkg_patterns->dot_directory_from_file(
		       $_[THIS]->_file_name_actual)));
}

sub name_space
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Instance
{
	return($name_space_class->constructor(${$_[THIS]}));
}

sub is_anchor
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(substr(${$_[THIS]}, -2) eq '::');
}

sub is_supportive
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(${$_[THIS]} =~ m{::_}s); # ::_Type::, ::_Corporate::
}

sub is_loaded
# /type method
# /effect ""
# /parameters *
# //returns
{
	return(exists($MODULES_LOADED{$_[THIS]->file_name_logical}));
}

sub load
# /type method
# /effect ""
# /parameters *
# /returns *
{
	my $this = shift(\@ARGUMENTS);

	unless ($this->is_valid)
	{
#FIXME: generate a backtrace
		$translated_errors->advocate(
			'invalid_package_name',
			[$$this]);
	}

	return($loader->load($$this, @ARGUMENTS));
}

sub adopt
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
{
	bless($_[SPX_THAT], ${$_[THIS]});
	return;
}

sub indirect
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return(${$_[THIS]});
}

sub indirect_constructor
# /type method
# /effect ""
# /parameters *
# //returns
#	?
{
	return(Carrot::Meta::Greenhouse::Package_Loader::create_instance(
		       ${shift(\@ARGUMENTS)}, @ARGUMENTS));
}

sub indirect_can
# /type method
# /effect ""
# //parameters
#	name
# //returns
#	::Personality::Abstract::Subroutine
{
	my ($this, $name) = @ARGUMENTS;
	my $class = $$this;
	return($class->can($name));
}

sub indirect_isa
# /type method
# /effect ""
# //parameters
#	pkg_name        ::Personality::Abstract::Text
# //returns
#	::Personality::Abstract::Boolean
{
	my ($this, $pkg_name) = @ARGUMENTS;
	my $class = $$this;
	return($class->isa($pkg_name));
}

sub indirect_method
# /type method
# /effect ""
# //parameters
#	method
#	*
# /returns *
{
	my ($this, $method) = splice(\@ARGUMENTS, 0, 2);
	my $class = $$this;
	return($class->$method(@ARGUMENTS));
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.421
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
