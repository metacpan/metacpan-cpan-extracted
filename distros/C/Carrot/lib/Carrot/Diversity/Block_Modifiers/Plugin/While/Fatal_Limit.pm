package Carrot::Diversity::Block_Modifiers::Plugin::While::Fatal_Limit
# /type class
# /implements [=component_pkg=]::_Prototype
# /capability "Limits the maximum number of iterations in while loops."
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Diversity/Block_Modifiers/Plugin/While/Fatal_Limit./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub address
# /type implementation
{
	return(['while', 'fatal_limit']);
}

sub trigger_modifier
# /type implementation
{
	my ($this, $meta_monad, $source_code, $all_blocks) = @ARGUMENTS;

	my $block_id = $this->[ATR_BLOCK_ID];
	my $counter = $block_id;
	my $modified = ($$source_code =~ s{
		((?:\012|\015\012?)\h+\#--8<--\ \w+-$block_id-head\ -->8--\#\K
		}{\n\{\nmy \$counter_$counter = ADX_NO_ELEMENTS;}sx);

	$modified += ($$source_code =~ s{
		\{\ \#--8<--\ \w+-$block_id-open\ -->8--\#\K
	}{
		\$counter_$counter += 1;
		if ($$counter > $this->[ATR_VALUE]) \
		\{
			die("Fatal while limit reached ($this->[ATR_VALUE]).");
		\}
	}sxg);

	unless ($modified == 2)
	{
		require Data::Dumper;
		print(STDERR Data::Dumper::Dumper($source_code));

		die("Could not fully match block_id '$block_id'.");
	}

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.36
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
