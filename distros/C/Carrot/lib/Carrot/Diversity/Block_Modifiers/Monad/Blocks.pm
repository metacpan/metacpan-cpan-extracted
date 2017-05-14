package Carrot::Diversity::Block_Modifiers::Monad::Blocks
# /type class
# /attribute_type ::One_Anonymous::Hash
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Diversity/Block_Modifiers/Monad/Blocks./manual_modularity.pl');
	} #BEGIN

# =--------------------------------------------------------------------------= #

sub get
# /type method
# /effect ""
# //parameters
#	key
# //returns
{
	return($_[THIS]{$_[SPX_KEY]});
}

sub add
# /type method
# /effect ""
# //parameters
#	path
#	keyword_trigger
# //returns
{
	my ($this, $path, $keyword_trigger) = @ARGUMENTS;

	my $generic = $this->{$path->[MLX_BLOCK_TYPE]};
	if ($path->[MLX_BLOCK_TYPE] eq 'package')
	{
		$generic->{$path->[MLX_BLOCK_KEYWORD]} = $keyword_trigger;
		unless (exists($generic->{''}))
		{
			$generic->{''} = $path->[MLX_BLOCK_NAME];
		}
	} elsif ($path->[MLX_BLOCK_TYPE] eq 'sub')
	{
		$generic->{$path->[MLX_BLOCK_NAME]}{$path->[MLX_BLOCK_KEYWORD]}
		= $keyword_trigger;
#	} else {
	}

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.24
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
