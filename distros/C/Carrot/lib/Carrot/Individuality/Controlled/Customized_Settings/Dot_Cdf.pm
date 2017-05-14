package Carrot::Individuality::Controlled::Customized_Settings::Dot_Cdf
# /type class
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->provide(
		my $class_names = '::Individuality::Controlled::Class_Names');

	$class_names->provide_instance(
		my $translated_errors = '::Meta::Greenhouse::Translated_Errors');

	$class_names->provide(
		'::Personality::',
			my $eval_error_class = '::Valued::Perl5::Eval_Error',
			my $cursor_class = '::Reflective::Iterate::Array::Cursor',

		my $line_class = '[=this_pkg=]::Line',
		my $source_class = '[=project_pkg=]::Source::Here::Plain',

		'[=project_pkg=]::Definition::',
			my $flat_definition_class = '::Flat',
			my $list_definition_class = '::List',
			my $table_definition_class = '::Table');

	#my $dot_cdf_magic = q{=customized_settings;standard;v1};

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	class_names
#	file_name       ::Personality::Valued::File::Name
# //returns
{
	my ($this, $class_names, $file_name) = @ARGUMENTS;

	$this->[ATR_CLASS_NAMES] = $class_names;
	$this->[ATR_FILE_NAME] = $file_name;

	return;
}

sub definition
# /type method
# /effect ""
# //parameters
#	values
# //returns
#	?
{
	my ($this, $values) = @ARGUMENTS;

	eval {
		$this->parse($values);
		Internals::hv_clear_placeholders(%$values);
		Internals::SvREADONLY(%$values, 1);
		return(IS_TRUE);
	} or do {
		my $eval_error = $eval_error_class
			->indirect_constructor($EVAL_ERROR);
#FIXME: looks weird
		$translated_errors->escalate(
			'failed_definition',
			[$eval_error],
			$EVAL_ERROR);
	};

	return($values);
}

sub parse
# /type method
# /effect ""
# //parameters
#	values
# //returns
{
	my ($this, $values) = @ARGUMENTS;

	$this->[ATR_FILE_NAME]->read_into(my $buffer);
	$this->parse_buffer($values, \$buffer);

	return;
}

sub parse_buffer
# /type method
# /effect ""
# //parameters
#	values
#	buffer
# //returns
{
	my ($this, $values, $buffer) = @ARGUMENTS;

	my $line = $line_class->indirect_constructor;
	my $cursor = $cursor_class->indirect_constructor(
		[split(qr{(?:\012|\015\012?)}, $$buffer, PKY_SPLIT_IGNORE_EMPTY_TRAIL)],
		$line);

	my $anchor1 = '::Individuality::Controlled::Customized_Settings';
	my $anchor2 = '::Personality';
	my ($name, $definition, $source);
	my ($keyword, $text);
	while ($cursor->advance)
	{
		if ($line->is_comment_or_empty)
		{
			next;

		} elsif (($text) = $line->is_name)
		{
			if (defined($definition))
			{
				$values->{$name} = $definition->implement;
			}
			$definition = IS_UNDEFINED;
			$source = IS_UNDEFINED;
			$name = $text;

		} elsif (($keyword, $text) = $line->is_some_class)
		{
			if ($text =~ m{^::(Structure|Source)::})
			{
				$text = "$anchor1$text";
			} else {
				$text = "$anchor2$text";
			}
			my $candidate = $this->[ATR_CLASS_NAMES]
				->indirect_instance_from_text($text);

			if ($keyword eq 'source')
			{
				$source = $candidate;
				$definition->start_default($candidate);

			} elsif ($keyword eq 'flat')
			{
				$definition = $flat_definition_class
					->indirect_constructor($candidate);

			} elsif ($keyword eq 'list')
			{
				$definition = $list_definition_class
					->indirect_constructor($candidate);

			} elsif ($keyword eq 'element')
			{
				$definition->set_element($candidate);

			} elsif ($keyword eq 'table')
			{
				$definition = $table_definition_class
					->indirect_constructor($candidate);

			} elsif ($keyword eq 'rows')
			{
				$definition->set_row($candidate);

			} elsif ($keyword eq 'column')
			{
				$definition->add_column($candidate);

			}

		} elsif ($line->is_separator)
		{
			next;

		} elsif (($text) = $line->is_data)
		{
			next unless (length($text));
			unless (defined($source))
			{
				$source = $source_class->indirect_constructor;
			}
			$source->append_element($text);

		} elsif (($text) = $line->is_quoted_data)
		{
			unless (defined($source))
			{
				$source = $source_class->indirect_constructor;
			}
			$source->append_element($text);

		} elsif (($text) = $line->is_anchor)
		{
			$anchor1 = $text;
			$anchor2 = $text;

		} else {
#FIXME: outdated
			$translated_errors->advocate(
				'invalid_definition_format',
				[$this->[ATR_FILE_NAME],
				$cursor->current_index,
				$$line]);

		}
	}

	if (defined($definition))
	{
		$values->{$name} = $definition->implement;
	}
#FIXME: add inheritance of default values if only default is given

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.222
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"