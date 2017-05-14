package Carrot::Diversity::Block_Modifiers::Plugin::Package::Instances
# /type class
# /implements [=component_pkg=]::_Prototype
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Diversity/Block_Modifiers/Plugin/Package/Instances./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub address
# /type implementation
{
	return(['package', 'instances', '*']);
}

sub trigger_modifier
# /type implementation
{
	my ($this, $meta_monad, $source_code, $all_blocks) = @ARGUMENTS;

	if ($this->[ATR_VALUE] eq 'singular')
	{
		my $modified = $source_code->insert_after_modularity(
			'Carrot::Meta::Greenhouse::Package_Loader::mark_singular;');
		unless ($modified)
		{
			my $pkg_file = $meta_monad->package_file->value;
			die("Could not add singular marker for package '$pkg_file'.\n");
		}

	} elsif ($this->[ATR_VALUE] eq 'none')
	{
		my $modified = $source_code->insert_after_modularity(
			'Carrot::Meta::Greenhouse::Package_Loader::mark_no;');
		unless ($modified)
		{
			my $pkg_file = $meta_monad->package_file->value;
			die("Could not add 'no' marker for package '$pkg_file'.\n");
		}

	} elsif ($this->[ATR_VALUE] eq 'regular')
	{
	} else {
		die("Got unknown instances value '$this->[ATR_VALUE]'.");
	}

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.75
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
