package Carrot::Individuality::Controlled::Customized_Settings::Structure::Table::Format::Column_Types
# /type class
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->package_resolver->provide(
		'::Personality::Elemental::Array::',
			my $array_texts_class = '::Texts',
			my $array_objects_class = '::Objects');

	$expressiveness->package_resolver->provide_instance(
		my $named_re = '::Meta::Greenhouse::Named_RE');

	$expressiveness->provide(
		my $distinguished_exceptions =
			'::Individuality::Controlled::Distinguished_Exceptions');

	$distinguished_exceptions->provide(
		my $invalid_row_format = 'invalid_row_format',
		my $uneven_column_count = 'uneven_column_count',
		my $mismatched_column_name = 'mismatched_column_name',
		my $mismatched_column_class = 'mismatched_column_type',
		my $incomplete_column_definition = 'incomplete_column_definition',
		my $missing_column_definition = 'missing_column_definition');

	$named_re->provide(
		my $re_trim_horizonal_space = 'trim_horizonal_space');

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_CLASSES] = $array_objects_class->indirect_constructor;
	$this->[ATR_NAMES] = $array_texts_class->indirect_constructor;

	return;
}

sub index
# /type method
# /effect ""
# //parameters
#	name
# //returns
{
	return($_[THIS][ATR_NAMES]->index($_[SPX_NAME]));
}

sub set_classes
# /type method
# /effect ""
# //parameters
#	classes
# //returns
{
	$_[THIS][ATR_CLASSES]->append($_[SPX_CLASSES]);
	return;
}

sub class_default
# /type method
# /effect ""
# //parameters
#	position
# //returns
{
	#FIXME: or ->clone_constructor ?
	return($_[THIS][ATR_CLASSES][$_[SPX_POSITION]]->value->value);
}

sub process_clone
# /type method
# /effect ""
# //parameters
#	position
#	element
# //returns
#	?
{
	#FIXME: or ->clone_constructor ?
	return($_[THIS][ATR_CLASSES][$_[SPX_POSITION]]
		->process_clone($_[SPX_ELEMENT]));
}

sub check
# /type method
# /effect ""
# //parameters
#	cursor
#	line
# //returns
{
	my ($this, $cursor, $line) = @ARGUMENTS;

	my $column_names;
	while ($cursor->advance)
	{
		if ($line->is_end_head)
		{
			last;

		} elsif ($line->is_start_head)
		{
			next;
		}

		my ($type, $elements) = $line->must_be_data;
		unless (defined($type))
		{
			$invalid_row_format->raise_exception(
				{'line' => $column_names,
				 'line_re' => $line},
				ERROR_CATEGORY_SETUP);
		}
		#FIXME: $type must be data
		@$column_names = map(
			#FIXME: obscure
			s{$re_trim_horizonal_space}{}rgo,
			@$elements);
	}

	if ($#$column_names == ADX_NO_ELEMENTS)
	{
		$missing_column_definition->raise_exception(
			{},
			ERROR_CATEGORY_SETUP);
	}
	if ($this->[ATR_NAMES]->is_empty)
	{
		$this->[ATR_NAMES]->append($column_names);
		Internals::SvREADONLY(@{$this->[ATR_NAMES]}, 1);
		return;
	}
	else {
		$this->must_be_compatible_names($column_names);

	}
	if ($this->[ATR_CLASSES]->is_equal_value($column_names))
	{
		$incomplete_column_definition->raise_exception(
			{'column_count' => $#$column_names,
			 'types_count' => $#{$this->[ATR_CLASSES]}},
			ERROR_CATEGORY_SETUP);
	}

	return($column_names);
}

sub must_be_compatible_names
# /type method
# /effect ""
# //parameters
#	names
# //returns
{
	my ($this, $names) = @ARGUMENTS;

	my $difference = $this->[ATR_NAMES]->first_difference($names);

	return unless (defined($difference));
	my ($position, $name1, $name2) = @$difference;

	if ($position == ADX_NO_ELEMENTS)
	{
		$uneven_column_count->raise_exception(
			{'count_this' => $#{$this->[ATR_NAMES]},
			 'count_that' => $#$names},
			ERROR_CATEGORY_SETUP);
	} else {
		$mismatched_column_name->raise_exception(
			{'name_this' => $name1,
			 'name_that' => $name2},
			ERROR_CATEGORY_SETUP);
	}

	return;
}

sub must_be_compatible_classes
# /type method
# /effect ""
# //parameters
#	classes
# //returns
{
	my ($this, $classes) = @ARGUMENTS;

	my ($position, $class1, $class2) =
		$this->[ATR_CLASSES]->first_difference($classes);

	if (defined($position))
	{
		if ($position == ADX_NO_ELEMENTS)
		{
			$uneven_column_count->raise_exception(
				{'count_this' => $#{$this->[ATR_CLASSES]},
				 'count_that' => $#$classes},
				ERROR_CATEGORY_SETUP);
		} else {
			$mismatched_column_class->raise_exception(
				{'name' => $this->[ATR_NAMES][$position],
				 'class_this' => Scalar::Util::blessed($class1),
				 'class_that' => Scalar::Util::blessed($class2)},
				ERROR_CATEGORY_SETUP);
		}
	}

	return;
}

sub must_be_compatible
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
{
	my ($this, $that) = @ARGUMENTS;

	$this->must_be_compatible_names($that->[ATR_NAMES]);
	$this->must_be_compatible_classes($that->[ATR_CLASSES]);

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.147
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"