package Carrot::Diversity::Include_Block
# /type class
# /attribute_type ::Many_Declared::Ordered
# /capability "Implements INCLUDE{} blocks."
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Diversity/Include_Block./manual_modularity.pl');
	} #BEGIN

	Carrot::Meta::Greenhouse::Package_Loader::provide(
		my $file_name_class = '::Personality::Valued::File::Name::Type::Regular::Content::UTF8_wBOM');

	my $expressiveness = Carrot::individuality;
	$expressiveness->declare_provider;

# =--------------------------------------------------------------------------= #

sub managed_diversity
# /type method
# /effect ""
# //parameters
#	meta_monad  ::Meta::Monad::Phase::Prepare
#	source_code
# //returns
{
	my ($this, $meta_monad, $source_code) = @ARGUMENTS;

	$$source_code =~ s{
		(?:\012|\015\012?)(\h+)PREPARE\h+\{(?:\012|\015\012?)
		((?:\h+[^\012\015]+(?:\012|\015\012?))+)
		\g{1}\}
	}{
		${$this->translate_code($meta_monad, $2)}
	}sxe;

	return;
}

sub translate_code
# /type method
# /effect ""
# //parameters
#	meta_monad  ::Meta::Monad::Phase::Prepare
#	block_code
# //returns
{
        my ($this, $meta_monad, $block_code) = @ARGUMENTS;

	$this = IS_UNDEFINED;
	my $candidate = eval $block_code;
	die($@) if ($@);

	return('') unless (defined($candidate));

	my $file_name = $file_name_class->constructor($candidate);
	$file_name->read_into(my $include_code);
        return(\$include_code);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.158
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
