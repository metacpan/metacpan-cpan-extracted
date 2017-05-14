package Carrot::Diversity::Block_Modifiers::Plugin::Subroutine::Returns
# /type class
# /implements [=component_pkg=]::_Prototype
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Diversity/Block_Modifiers/Plugin/Subroutine/Returns./manual_modularity.pl');
	} #BEGIN

	my $pkg_filter = {};
	my $previous_name = '';

# =--------------------------------------------------------------------------= #

sub dot_ini_got_association
# /type method
# /effect "Processes an association from an .ini file."
# //parameters
#	name
#	value
# //returns
{
        my ($this, $name, $value) = @ARGUMENTS;

	if ($name eq '-"-')
	{
		$name = $previous_name;
	} else {
		$previous_name = $name;
	}

# (require|assert) ::Some::Pkg(::sub_name\(\))

	unless (($name eq 'require') or ($name eq 'assert'))
        {
		die("Invalid keyword '$name'.");
        }

	my $sub_name;
	if ($value =~ s{::(\w+)\(\)\z}{}s)
	{
		$sub_name = $1;
	} else {
		$sub_name = '*';
	}

        return;
}

sub address
# /type implementation
{
	return(['sub', 'returns']);
}

sub trigger_modifier
# /type implementation
{
	my ($this, $meta_monad, $source_code, $all_blocks) = @ARGUMENTS;

	my $value = $this->[ATR_VALUE];
	if (ref($value) eq '')
	{
		if ($value eq '0')
		{
			$this->[ATR_VALUE] = $value = [];

		} elsif ($value eq '*')
		{
			return;
		}

	} elsif (ref($value) eq 'ARRAY')
	{
		if (@$value and ($value->[ADX_FIRST_ELEMENT] eq '*'))
		{
			return;
		}

	}

	my $block_body = $source_code->extract_modifier_block_body(
		$this->[ATR_BLOCK_ID]);

	my $count = $#$value+1;
	if ($block_body =~ m{\Wreturn\h*;}s)
	{
		if ($count > 0)
		{
			my $pkg_name = $all_blocks->{'package'}{''};
			die("A return; in '$this->[ATR_BLOCK_ID]' but returned==$count in package '$pkg_name'.");
		}
	} else {
		while ($block_body =~ m{\Wreturn\h*\((.*)\)}sg)
		{
#			print(STDERR "$1**************************************\n");
		}
	}

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.176
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
