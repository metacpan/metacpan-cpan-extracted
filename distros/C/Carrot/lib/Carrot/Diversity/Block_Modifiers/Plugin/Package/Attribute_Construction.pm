package Carrot::Diversity::Block_Modifiers::Plugin::Package::Attribute_Construction
# /type class
# /implements [=component_pkg=]::_Prototype
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	BEGIN {
		require('Carrot/Diversity/Block_Modifiers/Plugin/Package/Attribute_Construction./manual_modularity.pl');
	} #BEGIN

#	require Carrot::Diversity::Attribute_Type::Many_Declared::Ordered;

	Carrot::Meta::Greenhouse::Package_Loader::provide(
		my $source_code_class = '::Modularity::Package::Source_Code');

	Carrot::Meta::Greenhouse::Package_Loader::provide_instance(
		my $pkg_patterns = '::Modularity::Package::Patterns');

# =--------------------------------------------------------------------------= #

sub address
# /type implementation
{
	return(['package', 'attribute_construction']);
}

sub trigger_modifier
# /type implementation
{
	my ($this, $meta_monad, $source_code, $all_blocks) = @ARGUMENTS;

# //attribute_construction
#       sample1     (#) means to take it from the constructor argument #
#       sample2     ""
#       sample3     123
#       sample4     PRE_* all caps no :
#       sample5     ::Diversity::Block_Modifiers::Monad::Blocks instance

	my $ready_made = [
		'',
		'sub attribute_construction',
		'# /type method',
		'# /effect "Constructs the attribute(s) of a newly created instance."',
		'# //parameters',
		'#	*',
		'# //returns',
		'{',
		'	my $this = $_[THIS];',
#		'print(STDERR join("\n", caller, __PACKAGE__), "\n========\n");',
		''];
	my $class_names = [];
	my $optional_methods = [];

	foreach my $mapping (@{$this->[ATR_VALUE]})
	{
		my $options = [];
		while ($mapping =~ s{\h+\+(\w+)}{}saa)
		{
			push($options, $1);
		}

		my ($name, $value) = split(qr{\h+}, $mapping, 2);

		if ($name eq '+')
		{
			push($ready_made, "\t\$this->superseded;");
			next;
		}
		$value //= '';

		my $atr_name = 'ATR_'.uc($name);
		if ($value =~ m{\((\d+)\)}saa)
		{
			push($ready_made, "\t\$this->[$atr_name] = \$_[$1];");

		} elsif ($value =~ m{\A('|")(.*)\g{1}\z}saa)
		{
			push($ready_made, "\t\$this->[$atr_name] = q{$2};");

		} elsif ($value =~ m{\A(\d+)\z}saa)
		{
			#FIXME: re_number would be better
			push($ready_made, "\t\$this->[$atr_name] = $1;");

		} elsif ($value =~ m{\A([A-Z]+_[A-Z_]+)\z}saa)
		{
			#FIXME: check wheter such a constant exists
			push($ready_made, "\t\$this->[$atr_name] = $1;");

		} elsif ($value =~ m{\A((?:\[=\w+=\])?[\w:]+)\z}saa)
		{
			$pkg_patterns->resolve_placeholders(
				my $pkg_name = $1,
				$meta_monad->package_name->value);
			my $class_class = $name.'_class';
			push ($class_names, [$class_class, $pkg_name]);
			push($ready_made, "\t\$this->[$atr_name] = \$$class_class->indirect_constructor;");

		} else {
			die("Don't know what to do with value '$value' for name '$name'.");
		}
		foreach my $option (@$options)
		{
			my $optional_method = '';
			if ($option eq 'predicate')
			{
				if ($value eq 'IS_UNDEFINED')
				{
					$optional_method =
						$this->optional_predicate_has(
							"has_$name", $atr_name, '');
				} else {
					$optional_method =
						$this->optional_method(
							"is_$name", $atr_name,
						'::Personality::Abstract::Boolean');
				}

			} elsif ($option eq 'method')
			{
				$optional_method = $this->optional_method(
					$name, $atr_name, '*');

			} elsif ($option eq 'set')
			{
				my $type = ($value =~ m{\AIS_(TRUE|FALSE)\z}saa)
					? '::Personality::Abstract::Boolean'
					: '*';

				$optional_method = $this->optional_set(
					"set_$name", $atr_name, $type);

			} elsif ($option eq 'ondemand')
			{
				# what a hack
				foreach my $line (@$ready_made)
				{
					last if ($line =~ s{this->\[$atr_name\] = \K\$\w+_class->indirect_constructor}{IS_UNDEFINED});
				}
				$optional_method =
					$this->optional_predicate_has(
						"has_$name", $atr_name);
				push ($optional_methods, $optional_method);
				$optional_method = $this->optional_ondemand(
					$name, $atr_name);

			} elsif ($option eq 'commented')
			{
				foreach my $line (@$ready_made)
				{
					next unless ($line =~ m{this->\[$atr_name\] = }saa);
					$line = "#$line";
					last;
				}

			} else {
				die("Don't know how to handle option '$option'.");
			}
			push ($optional_methods, $optional_method);
		}
	}
	push ($ready_made,
		'	return;',
		'}',
		'');
	my $code = join("\n", @$ready_made, @$optional_methods);
	my $generated = $source_code_class->constructor($code);

	return($generated) unless(@$class_names);
	$code = '$expressiveness->class_names->provide('
		. "\n"
		. join(",\n", map("\t\tmy \$$_->[0] = '$_->[1]'", @$class_names))
		. ');';
	$source_code->insert_after_individuality($code);

	return($generated);
}

sub optional_method
# /type method
# /effect ""
# //parameters
#	sub_name
#	atr_name
#	parameter_type
# //returns
#	::Personality::Abstract::Text
{
	my ($this, $sub_name, $atr_name, $parameter_type) = @ARGUMENTS;

	my $code = qq{
sub $sub_name
# /type method
# /effect ""
# //parameters
# //returns
#	$parameter_type
{
	return(\$_[THIS][$atr_name]);
}
};
	return($code);
}

sub optional_ondemand
# /type method
# /effect ""
# //parameters
#	sub_name
#	atr_name
# //returns
#	::Personality::Abstract::Text
{
	my ($this, $sub_name, $atr_name) = @ARGUMENTS;

	my $code = qq{
sub $sub_name
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Instance
{
	my \$this = \$_[THIS];

	unless (defined(\$this->[$atr_name]))
	{
		\$this->[$atr_name] = \$${sub_name}_class
			->indirect_constructor(\$this);
	}
	return(\$this->[$atr_name]);
}
};
	return($code);
}

sub optional_set
# /type method
# /effect ""
# //parameters
#	sub_name
#	atr_name
#	parameter_type
# //returns
#	::Personality::Abstract::Text
{
	my ($this, $sub_name, $atr_name, $parameter_type) = @ARGUMENTS;

	my $code = qq{
sub $sub_name
# /type method
# /effect ""
# //parameters
#	value $parameter_type
# //returns
{
	\$_[THIS][$atr_name] = \$_[SPX_VALUE];
	return;
}
};
	return($code);
}

sub optional_predicate_has
# /type method
# /effect ""
# //parameters
#	sub_name
#	atr_name
# //returns
#	::Personality::Abstract::Text
{
	my ($this, $sub_name, $atr_name) = @ARGUMENTS;

	my $code = qq{
sub $sub_name
# /type method
# /effect ""
# //parameters
# //returns
#	::Personality::Abstract::Boolean
{
	return(defined(\$_[THIS][$atr_name]));
}
};
	return($code);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.215
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
