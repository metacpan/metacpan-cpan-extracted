package Carrot::Personality::Valued::File::Name::Type::Directory::Content
# /type class
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Personality/Valued/File/Name/Type/Directory/Content./manual_modularity.pl');
	} #BEGIN

	Carrot::Meta::Greenhouse::Package_Loader::provide_instance(
		my $fatal_syscalls = '::Meta::Greenhouse::Fatal_Syscalls',
		my $translated_errors = '::Meta::Greenhouse::Translated_Errors');

# =--------------------------------------------------------------------------= #

sub list
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my $names;
	eval {
		$fatal_syscalls->opendir(my $directory, ${$_[THIS]});
		$names = $fatal_syscalls->readdir($directory);
		$fatal_syscalls->closedir($directory);
		return(IS_TRUE);

	} or $translated_errors->escalate(
		'named_file_operation',
		[${$_[THIS]}],
		$EVAL_ERROR);

	return($names);
}

sub list_by_extension
# /type method
# /effect ""
# //parameters
#	extension
# //returns
#	?
{
	my ($this, $extension) = @ARGUMENTS;

	my $names = [];
	my $l = length($extension);
	foreach my $name (@{$this->list})
	{
		next if (substr($name, -$l) ne $extension);
		push($names, $name);
	}
	return($names);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.109
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
