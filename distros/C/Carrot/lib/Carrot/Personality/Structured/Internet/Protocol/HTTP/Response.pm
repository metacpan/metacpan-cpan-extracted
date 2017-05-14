package Carrot::Personality::Structured::Internet::Protocol::HTTP::Response
# /type class
# //parent_classes
#	[=project_pkg=]::_Corporate
# //attribute_construction
#	line        [=this_pkg=]::Line +method
#	+
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

# =--------------------------------------------------------------------------= #

sub clone_constructor
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my ($this) = @ARGUMENTS;

	my $cloned = [
		$this->[ATR_LINE]->clone_constructor,
		$this->[ATR_HEADER_LINES]->clone_constructor,
		(defined($this->[ATR_BODY])
			? $this->[ATR_BODY]->clone_constructor
			: IS_UNDEFINED),
		$this->[ATR_PENDING],
		$this->[ATR_CACHABLE]
		];
	bless($cloned, $this->class_name);
	$cloned->lock_attribute_structure;

	return($cloned);
}

#sub evt_projection_start {
#	my ($this, $projection) = @ARGUMENTS;
#
#	return;
#}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.107
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2010-2014 Winfried Trümper <pub+perl@wt.tuxomania.net>"
