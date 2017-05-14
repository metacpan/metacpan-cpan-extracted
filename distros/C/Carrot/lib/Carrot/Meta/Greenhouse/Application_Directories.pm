package Carrot::Meta::Greenhouse::Application_Directories
# /type class
# /instances singular
# /attribute_type ::One_Anonymous::Hash
# /capability "Initial management of named directories."
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Meta/Greenhouse/Application_Directories./manual_modularity.pl');
	} #BEGIN

	Carrot::Meta::Greenhouse::Package_Loader::provide(
		my $file_name_class = '::Personality::Valued::File::Name');

	Carrot::Meta::Greenhouse::Package_Loader::provide_instance(
		my $named_re = '::Meta::Greenhouse::Named_RE',
		my $translated_errors = '::Meta::Greenhouse::Translated_Errors');

	$named_re->provide(
		my $re_carrot_placeholder = 'carrot_placeholder');

	my $THIS = bless({}, __PACKAGE__);

# =--------------------------------------------------------------------------= #

sub constructor
# /type class_method
# /effect "Constructs a new instance."
# //parameters
# //returns
#	::Personality::Abstract::Instance
{
	my $this = $THIS; # simple singular monad

	unless (keys(%$this))
	{
#		$this->{'program_file_name_full'} = $name;
		$this->{'os_name'} = $OS_NAME;
		$this->{'pid'} = $PROCESS_ID;
		$this->{'perl_version'} = $PERL_VERSION;
	}

	return($this);
}

sub dot_ini_got_association
# /type class_method
# /effect "Processes an association from an .ini file."
# //parameters
#	name
#	value
# //returns
{
	my ($class, $name, $value) = @ARGUMENTS;

	$THIS->register($name, $value);

	return;
}

sub register
# /type method
# /effect "Registers a new named directory."
# //parameters
#	key
#	value
# //returns
{
	my ($this, $key, $value) = @ARGUMENTS;

	my $file_name = $file_name_class->constructor($value);
#	$file_name->canonify;
	$this->resolve_placeholders($file_name);
	$file_name->canonify;

	$this->{$key} = $file_name->value;
	return;
}

sub provide
# /type method
# /effect "Provides directories of given names."
# //parameters
#	placeholder_name  +multiple  ::Personality::Abstract::Text
# //returns
{
	my $this = shift(\@ARGUMENTS);

	foreach my $name (@ARGUMENTS)
	{
		if (exists($this->{$name}))
		{
			$name = $this->{$name};
		} else {
			$name = undef;
		}
	}
	return;
}

sub resolve_placeholders
# /type method
# /effect "Resolves placeholders with actual directories."
# //parameters
#	file_name       ::Personality::Valued::File::Name
# //returns
#	 ::Personality::Abstract::Number
{
	my ($this, $file_name) = @ARGUMENTS;

	my $placeholders = [$$file_name =~ m{$re_carrot_placeholder}go];
	foreach my $placeholder (@$placeholders)
	{
		next if (exists($this->{$placeholder}));
		$translated_errors->advocate(
			'hash_key_missing',
			[$placeholder, "$this"]);
	}

	my $modified = ($$file_name =~ s{$re_carrot_placeholder}{$this->{$1}}go);
	$file_name->canonify;

	return($modified);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.152
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
