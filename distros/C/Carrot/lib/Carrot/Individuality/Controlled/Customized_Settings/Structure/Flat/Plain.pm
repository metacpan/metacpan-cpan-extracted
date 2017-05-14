package Carrot::Individuality::Controlled::Customized_Settings::Structure::Flat::Plain
# /type class
# /attribute_type ::Many_Declared::Ordered
# //parent_classes
#	::Individuality::Controlled::Customized_Settings::Structure
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->provide(
		my $distinguished_exceptions = '::Individuality::Controlled::Distinguished_Exceptions');

#	$distinguished_exceptions->provide(
#		my $invalid_value = 'invalid_value');

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	value
# //returns
{
	my ($this, $value) = @ARGUMENTS;

	$this->[ATR_VALUE] = $value;

	return;
}

sub value
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][ATR_VALUE]);
}

sub plain_value
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][ATR_VALUE]->value);
}

sub process
# /type method
# /effect ""
# //parameters
#	source
# //returns
{
	my ($this, $source) = @ARGUMENTS;

	my $raw_data = $source->as_text;
	my $value = $this->[ATR_VALUE];
	unless ($value->import_textual_value($raw_data))
	{
		die("FIXME: invalid data '$raw_data'\n");
#		$invalid_value->raise_exception(
#			{'class' => $value->class_name,
#			 'value' => $raw_data},
#			ERROR_CATEGORY_SETUP);
	}
	$value->assign_value($raw_data);

	return;
}

sub process_clone
# /type method
# /effect ""
# //parameters
#	raw_data
# //returns
#	?
{
	my ($this, $raw_data) = @ARGUMENTS;

	my $value = $this->[ATR_VALUE];
	if (ref($raw_data) eq 'ARRAY')
	{
		$raw_data = join('', @$raw_data);
	}
	unless ($value->import_textual_value($raw_data))
	{
		die("FIXME: this message is missing for '$raw_data'.");
#		$invalid_value->raise_exception(
#			{'class' => $value->class_name,
#			 'value' => $raw_data},
#			ERROR_CATEGORY_SETUP);
	}
	my $clone = $value->clone_constructor;
	$clone->assign_value($raw_data);

	return($clone);
}

sub initialize
# /type method
# /effect ""
# //parameters
#	source
# //returns
#	?
{
	return($_[THIS]->process($_[SPX_SOURCE]));
}

sub modify
# /type method
# /effect ""
# //parameters
#	source
# //returns
#	?
{
	return($_[THIS]->process($_[SPX_SOURCE]));
}

sub inherit
# /type method
# /effect ""
# //parameters
#	raw_data
# //returns
{
	die; #FIXME: usage counter ;)
	$_[THIS][ATR_VALUE]->inherit($_[THAT][ATR_VALUE]);
	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.105
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
