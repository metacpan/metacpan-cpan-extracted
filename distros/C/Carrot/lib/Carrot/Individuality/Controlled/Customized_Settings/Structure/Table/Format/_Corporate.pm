package Carrot::Individuality::Controlled::Customized_Settings::Structure::Table::Format::_Corporate
# /type class
# /instances none
# /attribute_type ::Many_Declared::Ordered
# //parent_classes
#	[=project_pkg=]
#	[=project_pkg=]::Table::Constants
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';
	use bytes;

	my $expressiveness = Carrot::individuality;
	$expressiveness->package_resolver->provide_instance(
		my $re_english = '::Diversity::English::Regular_Expression');
	$expressiveness->package_resolver->provide(
		my $columns_class = '[=project_pkg=]::Table::Column_Types',
		'::Personality::',
			my $cursor_class = '::Reflective::Iterate::Array::Cursor',
			my $file_name_class = '::Valued::File::Name::Type::Regular::Content::UTF8_wBOM');

	# $expressiveness->provide(
	# 	my $distinguished_exceptions =
	# 		'::Individuality::Controlled::Distinguished_Exceptions');
	#
	# $distinguished_exceptions->provide(
	# 	my $table_already_initialized = 'table_already_initialized');

	my $first_char_re = $re_english->compile(
		'ON_START ( ANY_CHARACTER )',
			[RE_MOD_SAFER_UNICODE,  RE_MOD_SINGLE_LINE]);

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_ROWS] = [];
	$this->[ATR_COLUMNS] = $columns_class->indirect_constructor;

	return;
}

sub _clone_constructor
# /type method
# /effect ""
# //parameters
#	original
# //returns
{
	my ($this, $original) = @ARGUMENTS;

	$this->[ATR_ROWS] = $original->data_copy_for_clone;

	return;
}

sub drop_rows
# /type method
# /effect ""
# //parameters
# //returns
{
	$_[THIS][ATR_ROWS] = [];
	return;
}

sub rows
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Raw::Array
{
	return($_[THIS][ATR_ROWS]);
}

sub plain_value
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Raw::Array
{
	return([map([map($_->value, @$_)], @{$_[THIS][ATR_ROWS]})]);
}

# sub values
# # /type method
# # /effect ""
# # //parameters
# # //returns
# #	?
# {
# 	return($_[THIS][ATR_ROWS]);
# }

sub set_columns
# /type method
# /effect ""
# //parameters
#	column_classes
# //returns
{
	$_[THIS][ATR_COLUMNS]->set_classes($_[SPX_COLUMN_CLASSES]);
	return;
}

sub store_row
# /type method
# /effect ""
# //parameters
#	row
# //returns
{
	push($_[THIS][ATR_ROWS], $_[SPX_ROW]);
	return;
}

sub resolve_symbolic_element
# /type method
# /effect ""
# //parameters
#	position
#	flag
#	element
# //returns
{
	my ($this, $position, $flag, $element) = @ARGUMENTS;

	if ($flag eq '#')
	{
		$element = $this->[ATR_COLUMNS]->class_default($position);

	} elsif ($flag eq '?')
	{
		$element = undef;

	} elsif ($flag eq '<')
	{
		my $file_name = $file_name_class
			->indirect_constructor($element);
		$file_name->read_into($element);

	} elsif ($flag eq '*') # wildcard
	{
		$element = \(my $wildcard = '*');

	} else {
		return(IS_FALSE);
	}

	$_[SPX_ELEMENT] = $element;
	return(IS_TRUE);
}

sub row_action
# /type method
# /effect ""
# //parameters
#	context
#	row
# //returns
{
	my ($this, $context, $row) = @ARGUMENTS;

#	require Data::Dumper;
#	print STDERR Data::Dumper::Dumper($row);

	$this->unquote_row($row);
	if ($context eq RKY_LINE_TABLE_DATA)
	{
		$this->add_row($row);

	} elsif ($context eq RKY_LINE_TABLE_DELETE)
	{
		$this->delete_row($row);

	} elsif ($context eq RKY_LINE_TABLE_DEFAULTS)
	{
		$this->set_defaults($row);

	}
	return;
}

sub unquote_multiline_element
# /type method
# /effect ""
# //parameters
#	element
#	position
# //returns
{
	my ($this, $element, $position) = @ARGUMENTS;

	my $candidate = $element->[ADX_FIRST_ELEMENT];
	$candidate =~ s{$first_char_re}{}o;
	my $first_char = $1;

	if ($this->resolve_symbolic_element($position, $first_char, $candidate))
	{
		return($candidate);
	}

	# double quotes include empty lines
	if ($first_char eq q{"})
	{
		my $rv = join('',
			map(s{\h+\z}{}r,
				map(s{^.}{}r, @$element)));
		$rv =~ s{"\h*\z}{};
		return($rv);
	}

	foreach my $line (@$element)
	{
		$line =~ s{$first_char_re}{}o;
		my $first_char = $1;
		$line =~ s{\h+\z}{};

		if ($first_char eq ' ')
		{
			# exclude empty lines
			unless (length($line))
			{
				$line = IS_UNDEFINED;
			}

		} elsif ($first_char eq q{'})
		{
			# include on individual basis
			$line =~ s{'\z}{}s;

		} else {
			die("FIXME: unknown format '$line'.");
		}
	}
	return(join('', grep(defined($_), @$element)));
}

# sub detabify
# # /type method
# # /effect ""
# # //parameters
# #	<lines>
# # //returns
# {
# 	my ($this, $lines) = @ARGUMENTS;
#
# 	foreach my $line (@$lines)
# 	{
# 		next if (index($line, "\t") == ADX_NO_ELEMENTS);
# 		$line =~ s{(\t)(\t+)}{$1.('        ' x length($2))}sge;
# 		while ($line =~ s{^(.*)\t}{$1.' ' x (8-length($1)%8)}sge) {};
# 	}
#
# 	return;
# }

sub initialize
# /type method
# /effect ""
# /alias_name modify
# //parameters
#	source
# //returns
{
	my ($this, $source) = @ARGUMENTS;

#	$this->detabify($lines);
	my $line = $this->table_line_constructor($source->first_element);
	$source->re_constructor($cursor_class->value, $line);

	$this->[ATR_COLUMNS]->check($source, $line);
	$this->parse_lines($source, $line);

	return;
}
#*modify = \&initialize;

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.400
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
