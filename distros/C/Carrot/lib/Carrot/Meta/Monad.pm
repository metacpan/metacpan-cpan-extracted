package Carrot::Meta::Monad
# /type class
# /attribute_type ::Many_Declared::Ordered
# //parameters
#	meta_provider  ::Meta::Provider
# /capability "Common capabilities of the $meta_monad across all phases."
{
	my ($meta_provider) = @ARGUMENTS;

	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Meta/Monad./manual_modularity.pl');
	} #BEGIN

	Carrot::Meta::Greenhouse::Package_Loader::provide(
		my $package_file_class = '::Modularity::Package::File_Name',
		my $package_name_class = '::Modularity::Package::Name',
		my $source_code_class = '::Modularity::Package::Source_Code');

	Carrot::Meta::Greenhouse::Package_Loader::provide_instance(
		my $pkg_patterns = '::Modularity::Package::Patterns',
		my $prefixed_list = '::Modularity::Package::Prefixed_List',
		my $loader = '::Modularity::Package::Loader',
		my $package_resolver = '::Modularity::Package::Resolver',
		my $translated_errors = '::Meta::Greenhouse::Translated_Errors');

	my $shortcuts_class = 'Carrot::Meta::Monad::Shortcuts';
	$loader->load(
		$shortcuts_class,
		$meta_provider);

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method  /access private
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	pkg_name
#	pkg_file
# //returns
{
	my ($this, $pkg_name, $pkg_file) = @ARGUMENTS;

	$this->[ATR_PACKAGE_NAME] = $package_name_class->constructor($pkg_name);
	$this->[ATR_PACKAGE_FILE] = $package_file_class->constructor($pkg_file);

	my $dot_directory = $this->[ATR_PACKAGE_FILE]->dot_directory;
	unless ($dot_directory->exists)
	{
		if (DEVELOPMENT_FLAG)
		{
			$dot_directory->create_fatally;
		} else {
			$translated_errors->advocate(
				'package_dot_missing',
				[$dot_directory->value]);
		}
	}
	$this->[ATR_DOT_DIRECTORY] = $dot_directory;

	$this->[ATR_SOURCE_CODE] = $source_code_class->constructor;
#	$this->[ATR_SOURCE_CODE] = IS_UNDEFINED;
	$this->[ATR_PARENT_CLASSES] = IS_UNDEFINED;
	$this->[ATR_PRINCIPLE] = 'unknown';

	return;
}

sub package_name
# /type method
# /effect ""
# //parameters
# //returns
#	::Modularity::Package::Name
{
	return($_[THIS][ATR_PACKAGE_NAME]);
}

sub package_file
# /type method
# /effect ""
# //parameters
# //returns
#	::Modularity::Package::Name
{
	return($_[THIS][ATR_PACKAGE_FILE]);
}

# sub verify_pkg_file
# # /type method
# # /effect ""
# # //parameters
# #	pkg_file
# # //returns
# {
# 	my ($this, $pkg_file) = @ARGUMENTS;
#
# 	unless ($this->[ATR_PACKAGE_FILE]->is_equal_value($pkg_file))
# 	{
# 		$translated_errors->advocate(
# 			'package_file_mismatch',
# 			[$this->[ATR_PACKAGE_FILE]
# 				$pkg_file]);
# 	}
# 	return,
# }

sub dot_directory
# /type method
# /effect ""
# //parameters
# //returns
#	::Modularity::Package::Name
{
	return($_[THIS][ATR_DOT_DIRECTORY]);
}

sub parent_classes
# /type method
# /effect ""
# //parameters
# //returns
#	::Modularity::Object::Parent_Classes
{
	my ($this) = @ARGUMENTS;

	unless (defined($this->[ATR_PARENT_CLASSES]))
	{
		$this->provide(
			my $parent_classes = '::Modularity::Object::Parent_Classes');
		$this->[ATR_PARENT_CLASSES] = $parent_classes;
	}
	return($this->[ATR_PARENT_CLASSES]);
}

sub declare_provider
# /type method
# /effect ""
# //parameters
# //returns
{
	$meta_provider->add_provider($_[THIS]);
	return;
}

sub source_code
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_SOURCE_CODE]->load($this->[ATR_PACKAGE_FILE]);

	return($this->[ATR_SOURCE_CODE]);
}

sub provide
# /type method
# /effect "Returns an individual monad for a package."
# //parameters
#	pkg_name  +multiple  ::Personality::Abstract::Text
# //returns
{
	my $this = shift(\@ARGUMENTS);

	my $calling_pkg = $this->package_name->value;
	my $anchor = 'Carrot';
	my $method = 'manual_'.$this->[ATR_PRINCIPLE];
	foreach my $pkg_name (@ARGUMENTS)
	{
		next if ($prefixed_list->is_anchor_prefix(
			$pkg_name,
			$anchor,
			$calling_pkg));

		my $provider = $meta_provider->monad_provider($pkg_name);
		if ($provider->can($method)) # manual_<principle>
		{
			$pkg_name = $provider->$method($this);

		} elsif ($provider->can('manual_principle'))
		{
			$pkg_name = $provider->manual_principle($this);

		} else {
			$pkg_name = $provider;

		}
	}

	return;
}

sub class_names
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	$_[THIS]->provide(
		my $class_names = '::Individuality::Controlled::Class_Names');
	return($class_names);
}

sub package_resolver
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($package_resolver);
}

our $AUTOLOAD;
sub AUTOLOAD
# /type function
# /effect "Creates a monad from a shortcut method"
# /parameters *
# /returns *
{
	my ($this) = @ARGUMENTS;

	if (TRACE_FLAG)
	{
		print(STDERR "Autoload caller: ", join("\n", caller), "\n");
	}
	my $sub_on_demand = $AUTOLOAD; # danger of a changing global variable

	my ($pkg_name, $sub_name) = $pkg_patterns->pkg_n_sub($sub_on_demand);
	unless (defined($pkg_name))
	{
		$translated_errors->advocate(
			'subroutine_name_not_qualified',
			[$AUTOLOAD]);
	}
	return if ($sub_name eq 'DESTROY');

	my $class = $shortcuts_class->monad_class_by_method($sub_name);
	unless (defined($class))
	{
		$translated_errors->advocate(
			'autoload_rule_missing',
			["\$expressiveness->$sub_name"]);
	}
	$this->provide($class);
	return($class);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.612
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
