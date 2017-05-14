package Carrot::Meta::Monad::Phase::Begin
# /type class
# //parent_classes
#	::Meta::Monad
# //parameters
#	managed_modularity  ::Personality::Abstract::Array
# /capability "Capabilities of the $meta_monad during BEGIN."
{
	my ($managed_modularity) = @ARGUMENTS;

	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Meta/Monad/Phase/Begin./manual_modularity.pl');
	} #BEGIN

	Carrot::Meta::Greenhouse::Package_Loader::provide(
		my $managed_file_class = '::Meta::Monad::Managed_File',
		my $definitions_class = '::Meta::Monad::Phase::Begin::Definitions');

	Carrot::Meta::Greenhouse::Package_Loader::provide_instance(
		my $compilation_name = '::Meta::Greenhouse::Compilation_Name',
		my $writable_overlay = '::Meta::Greenhouse::Writable_Overlay',
		my $translated_errors = '::Meta::Greenhouse::Translated_Errors');

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	that  ::Meta::Monad
# //returns
{
	my ($this, $that) = @ARGUMENTS;

	@$this = @$that;
	$this->[ATR_PRINCIPLE] = 'modularity';

	return;
}

sub managed_hardcoded
# /type method
# /effect ""
# //parameters
# //returns
{
	$_[THIS][ATR_PRINCIPLE] = IS_UNDEFINED; #what a hack
	return;
}

sub _managed_modularity
# /type method
# /effect ""
# //parameters
#	managed_file       ::Meta::Monad::Managed_File
# //returns
{
	my ($this, $managed_file) = @ARGUMENTS;

	my $definitions = $definitions_class->constructor($this);
	foreach my $monad_provider (@$managed_modularity)
	{
		$monad_provider->managed_modularity(
			$this,
			$definitions);
	}
	$managed_file->update($definitions);
	return;
}

sub DESTROY
# /type method
# /effect ""
# //parameters
# //returns
{
	return if (${^GLOBAL_PHASE} eq 'DESTRUCT');
	my ($this) = @ARGUMENTS;

	return unless (defined($this->[ATR_PRINCIPLE]));
	my $manual_file = $this->[ATR_DOT_DIRECTORY]
		->entry('manual_modularity.pl');

	unless ($manual_file->exists)
	{
		my $managed_file = $managed_file_class->constructor($this);
		my $candidate = $this->[ATR_DOT_DIRECTORY]->entry(
			"managed_modularity-$$compilation_name.pl");
		$writable_overlay->redirect_write($candidate);

		$managed_file->set($candidate);
		eval {
			if ($managed_file->needs_update)
			{
				$this->_managed_modularity($managed_file);
			}
			$managed_file->require($this);
			return(IS_TRUE);

		} or $translated_errors->escalate(
			'modularity_failed',
			[$managed_file->name->value],
			$EVAL_ERROR);
	}

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.270
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
