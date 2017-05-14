package Carrot::Individuality::Controlled::Customized_Settings::Monad
# /type class
# /attribute_type ::Many_Declared::Ordered
# //parameters
#	inheritance  ::Modularity::Object::Inheritance::ISA_Occupancy
# /capability ""
{
	my ($inheritance) = @ARGUMENTS;

	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->provide(
		'::Individuality::Controlled::',
			my $class_names = '::Class_Names',
			my $distinguished_exceptions = '::Distinguished_Exceptions');

	$class_names->provide(
		my $cursor_class = '::Personality::Reflective::Iterate::Array::Cursor',
		'[=project_pkg=]::',
			my $line_class = '::Dot_Cfg::Line',
			my $source_class = '::Source::Here::Plain',
			my $dot_cdf_class = '::Dot_Cdf');

	$class_names->provide_instance(
		my $writable_overlay = '::Meta::Greenhouse::Writable_Overlay',
		my $compilation_name = '::Meta::Greenhouse::Compilation_Name');

	$distinguished_exceptions->provide(
		my $unsupported_data_type = 'unsupported_data_type',
		my $hash_element_missing = 'hash_element_missing');

	Carrot::Meta::Greenhouse::Package_Loader::provide_instance(
		my $loader = '::Modularity::Package::Loader');

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	meta_monad  ::Meta::Monad
# //returns
{
	my ($this, $meta_monad) = @ARGUMENTS;

	my $package_file = $meta_monad->package_file;
	my $dot_directory = $package_file->dot_directory;
	my $default_settings = $dot_directory->entry('default_settings.cdf');
	$default_settings->consider_regular_content;

	my $compiled_settings = $dot_directory->entry(
		"default_settings-$$compilation_name.pl");
	$writable_overlay->redirect_read($compiled_settings);
	if ($default_settings->modification_timestamp_is_newer($compiled_settings))
	{
	# NOTE: manually setting @ARGUMENTS copies but doesn't alias them
		@ARGUMENTS = ($loader, \$this->[ATR_VALUES]);
		require($compiled_settings->value);
		$this->[ATR_ARE_MODIFIED] = IS_FALSE;
		return;
	}
	$this->[ATR_ARE_MODIFIED] = IS_TRUE;

	my $these_values = $this->[ATR_VALUES] = {};

	my $dot_cdf = $dot_cdf_class->indirect_constructor(
		$meta_monad->class_names,
		$default_settings);
##	$this->[ATR_DEFINER] = $dot_cdf;
	$dot_cdf->definition($these_values);

	my $independent = IS_TRUE;
	my $occupied = $inheritance->collect_occupied(
		$meta_monad->parent_classes->perl_isa);
	foreach my $that (reverse(@$occupied))
	{
		my $those_values = $that->[ATR_VALUES];
#FIXME: the behaviour should be documented - different from ->inherit
		foreach my $key (keys($those_values))
		{
			$independent = IS_FALSE;
			next if (exists($these_values->{$key}));
			$these_values->{$key} =
				$those_values->{$key}->clone_constructor;
		}
	}

	if ($independent) # just because it could be newer?
	{
		require Data::Dumper;
		my $dumper = Data::Dumper->new([$these_values]);
		$dumper->Indent(1);

		my $dumped = $dumper->Dump; #($these_values);
		my $pkg_names = [$dumped =~ m{(?:\n +\]|\)\}), '([^\n\']+)' \),?\n}sg];
		@$pkg_names = keys({map(($_ => 1), @$pkg_names)});

		my $datetime = scalar(gmtime(time()));
		my $pkg_name = $meta_monad->package_name->value;
		my $perl_code =
			"# Automatically created on $datetime GMT.\n"
			."# Manual changes will get lost.\n"
			."# package $pkg_name\n"
#			"use strict;\n"
#			. "use warnings;\n"
			. join("\n", map("\$_[0]->load('$_');", @$pkg_names))
			. "\n\${\$_[1]} = my "
			. $dumped
			. "\nreturn(1);";

		$writable_overlay->redirect_write($compiled_settings);
		$compiled_settings->consider_regular_content;
		$compiled_settings->overwrite_from($perl_code);
	}
	return;
}

sub are_modified
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][ATR_ARE_MODIFIED]);
}

sub clone_constructor
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my ($this) = @ARGUMENTS;

	my $cloned_values = {};
	keys($this->[ATR_VALUES]); # reset 'each' iterator
	while (my ($key, $value) = each($this->[ATR_VALUES]))
	{
		$cloned_values->{$key} = $value->clone_constructor;
	}
	my $clone = [
#		$this->[ATR_DEFINER],
		$cloned_values]	;
	bless($clone, $this->class_name);
	$clone->lock_attribute_structure;

	return($clone);
}

#FIXME: this ended up as a convenience method
sub further_customized
# /type method
# /effect ""
# //parameters
#	raw_settings
# //returns
#	?
{
	my $clone = $_[THIS]->clone_constructor;

	unless (defined($_[SPX_RAW_SETTINGS]))
	{
		return($clone);
	}
	my $type = ref($_[SPX_RAW_SETTINGS]);
	if ($type eq '')
	{
		$clone->customize_by_scalar($_[SPX_RAW_SETTINGS]);

	} elsif ($type eq 'SCALAR')
	{
		$clone->customize_by_scalar(${$_[SPX_RAW_SETTINGS]});

	} elsif ($type eq 'HASH')
	{
		$clone->customize_by_hashref($_[SPX_RAW_SETTINGS]);

	} else {
		$unsupported_data_type->raise_exception(
			{'type' => $type},
			ERROR_CATEGORY_IMPLEMENTATION);
	}

	return($clone);
}

#FIXME: this is odd, let's get rid of it
sub customized_partial
# /type method
# /effect ""
# //parameters
#	re
#	names
#	partial_settings
# //returns
#	?
{
	my ($this, $re, $names) = @ARGUMENTS;

	my $partial_settings;
	my $type = ref($_[SPX_PARTIAL_SETTINGS]);
	if ($type eq '')
	{
		$_[SPX_PARTIAL_SETTINGS] =~ s{$re}{}s;
		$partial_settings = $1;

	} elsif ($type eq 'SCALAR')
	{
		${$_[SPX_PARTIAL_SETTINGS]} =~ s{$re}{}s;
		$partial_settings = $1;

	} elsif ($type eq 'HASH')
	{
		$partial_settings = {};
		foreach my $name (@$names)
		{
			$partial_settings->{$name} =
				delete($_[SPX_PARTIAL_SETTINGS]{$name});
		}
	}

	return($this->further_customized($partial_settings));
}

#sub provide_values
#{
#	my $this = shift(\@ARGUMENTS);
#
#	map($_ = $_->value, $this->provide(@ARGUMENTS));
#	return;
#}

sub provide_value
# /type method
# /effect ""
# //parameters
#	named_value  +multiple
# //returns
{
	my $this = shift(\@ARGUMENTS);

	my $values = $this->[ATR_VALUES];
	foreach my $named_value (@ARGUMENTS)
	{
		unless (exists($values->{$named_value}))
		{
			$hash_element_missing->raise_exception(
				{'key' => $named_value},
				ERROR_CATEGORY_IMPLEMENTATION);
		}
		$named_value = $values->{$named_value};
	}
	return;
}

sub provide_plain_value
# /type method
# /effect ""
# //parameters
#	named_value  +multiple
# //returns
{
	my $this = shift(\@ARGUMENTS);

	$this->provide_value(@ARGUMENTS);
	foreach my $named_value (@ARGUMENTS)
	{
		$named_value = $named_value->plain_value;
	}
	return;
}

sub provide_plain_values
# /type method
# /effect ""
# //parameters
#	value_name  +multiple
# //returns
{
	my $this = shift(\@ARGUMENTS);

	$this->provide_value(@ARGUMENTS);
	foreach my $named_value (@ARGUMENTS)
	{
		$named_value = $named_value->plain_values;
	}
	return;
}

sub inherit
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
{
	my ($this, $that) = @ARGUMENTS;

	unless ($this->is_sibling($that))
	{
		die("'$this' not compatible with '$that' for inheritance.");
	}
	my $these_values = $this->[ATR_VALUES];
	my $those_values = $that->[ATR_VALUES];
	foreach my $key (keys(%$these_values))
	{
		$these_values->{$key}->inherit($those_values->{$key});
	}

	return;
}

sub clone_plus_file
# /type method
# /effect ""
# //parameters
#	file_name       ::Personality::Valued::File::Name
# //returns
#	?
{
	my $clone = $_[THIS]->clone_constructor;
	$clone->customize_by_file($_[SPX_FILE_NAME]);
	return($clone);
}

sub customize_by_file
# /type method
# /effect ""
# //parameters
#	file_name       ::Personality::Valued::File::Name
# //returns
{
#	return unless (defined($file_name));

	$_[SPX_FILE_NAME]->consider_regular_content;
	$_[SPX_FILE_NAME]->read_into(my $buffer);
	$_[THIS]->customize_by_scalar($buffer);
	return;
}

sub clone_plus_scalarref
# /type method
# /effect ""
# //parameters
#	buffer
# //returns
#	?
{
	my $clone = $_[THIS]->clone_constructor;
	$clone->customize_by_scalar(${$_[SPX_BUFFER]});
	return($clone);
}

sub customize_by_scalar
# /type method
# /effect ""
# //parameters
#	buffer
# //returns
{
	$_[SPX_BUFFER] =~ s{\s+$}{}s;
	my $lines = [split(
		qr{(?:\012|\015\012?)},
		$_[SPX_BUFFER],
		PKY_SPLIT_IGNORE_EMPTY_TRAIL)];
	$_[THIS]->customize_by_arrayref($lines);
	return;
}

sub clone_plus_arrayref
# /type method
# /effect ""
# //parameters
#	buffer
# //returns
#	?
{
	my $clone = $_[THIS]->clone_constructor;
	$clone->customize_by_arrayref($_[SPX_BUFFER]);
	return($clone);
}

sub customize_by_arrayref
# /type method
# /effect ""
# //parameters
#	lines
# //returns
{
	my ($this, $lines) = @ARGUMENTS;

	my $line = $line_class->indirect_constructor;
	my $cursor = $cursor_class->indirect_constructor($lines, $line);

	my $count = 0;
	my ($setting, $source);
	my $anchor1 = 'Carrot::Individuality::Controlled::Customized_Settings';
	while ($cursor->advance)
	{
		if ($line->is_comment_or_empty)
		{
			next;

		} elsif (my ($text) = $line->is_name)
		{
			if (defined($setting))
			{
				$setting->modify($source);
			}
			$source = IS_UNDEFINED;

			unless (exists($this->[ATR_VALUES]{$text}))
			{
				$hash_element_missing->raise_exception(
					{+HKY_DEX_BACKTRACK => $count,
					 'key' => $text},
					ERROR_CATEGORY_IMPLEMENTATION);
			}
			$setting = $this->[ATR_VALUES]{$text};

		} elsif (($text) = $line->is_source_class)
		{
#FIXME: at least consistently broken
			$text = "$anchor1$text";
			$source = $class_names->indirect_instance_from_text(
				$text);

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

		} elsif ($line->is_separator)
		{
			next;

		} else {
			die("Format of line '$line' not recognized."); #FIXME
		}
	}
	if (defined($setting))
	{
		$setting->modify($source);
	}

	return;
}

sub clone_plus_hashref
# /type method
# /effect ""
# //parameters
#	buffer
# //returns
#	?
{
	my $clone = $_[THIS]->clone_constructor;
	$clone->customize_by_hashref($_[SPX_BUFFER]);
	return($clone);
}

sub customize_by_hashref
# /type method
# /effect ""
# //parameters
#	settings
# //returns
{
	my ($this, $settings) = @ARGUMENTS;

	return unless (defined($settings));
	foreach my $key (keys(%$settings))
	{
		unless (exists($this->[ATR_VALUES]{$key}))
		{
			$hash_element_missing->raise_exception(
				{'key' => $key},
				ERROR_CATEGORY_IMPLEMENTATION);
		}
		$settings->{$key} =~ s{\h+$}{}s;
		my $lines = [split(
			qr{(?:\012|\015\012?)},
			$settings->{$key},
			PKY_SPLIT_IGNORE_EMPTY_TRAIL)];
		$this->[ATR_VALUES]{$key}->modify($lines);
	}

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.333
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
