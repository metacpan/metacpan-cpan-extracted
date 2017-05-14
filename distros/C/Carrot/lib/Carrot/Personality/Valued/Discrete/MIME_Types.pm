package Carrot::Personality::Valued::Discrete::MIME_Types
# /type class
# /attribute_type ::One_Anonymous::Array
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->provide(
		my $customized_settings = '::Individuality::Controlled::Customized_Settings');

	$customized_settings->provide_plain_value(
		my $pre_defined = 'pre_defined');

	my $mime_types = {};
	my $extensions = {};
	foreach my $type (keys(%$pre_defined)) 
	{
		my $extensions = [split(qr{\h*,\h*}, $pre_defined->{$type},
			PKY_SPLIT_RETURN_FULL_TRAIL)];
		$mime_types->{$type} = $extensions;
		foreach my $extension (@$extensions)
		{
			$extensions->{$extension} = $type;
		}
	}

	$expressiveness->declare_provider;

# =--------------------------------------------------------------------------= #

sub lookup_extension_of_mime_type
# /type method
# /effect ""
# //parameters
#	mime_type
# //returns
#	?
{
	return(IS_UNDEFINED) unless (exists($mime_types->{$_[SPX_MIME_TYPE]}));
	return($mime_types->{$_[SPX_MIME_TYPE]});
}

sub lookup_mime_type_of_extension
# /type method
# /effect ""
# //parameters
#	extension
# //returns
#	?
{
	return(IS_UNDEFINED) unless (exists($extensions->{$_[SPX_EXTENSION]}));
	return($extensions->{$_[SPX_EXTENSION]});
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.51
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
