package Carrot::Individuality::Singular::Execution::Static_Flag
# /type class
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->class_names->provide(
		my $dot_ini_class = '::Meta::Greenhouse::Dot_Ini');

	$expressiveness->declare_provider;

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_FLAGS] = (my $flags = {});
	$this->[ATR_ALL_FLAGS_RE] = IS_UNDEFINED;

	my $dot_ini = $dot_ini_class->indirect_constructor($this);
	$dot_ini->find_configuration;

	my $flag_names = [keys($flags)];
	$this->[ATR_ALL_FLAGS_RE] = join('|', map(uc($_), @$flag_names));
	foreach my $flag_name (@$flag_names)
	{
		$flags->{$flag_name}[IDX_FLG_MATCHER] =
			$this->build_matcher($flags->{$flag_name}[IDX_FLG_MATCHER]);
	}

	return;
}

sub dot_ini_got_separated_values
# /type method
# /effect ""
# /parameters *
# //returns
{
	shift(\@ARGUMENTS)->add_flag(@ARGUMENTS);
	return;
}

sub add_flag
# /type method
# /effect ""
# //parameters
#	value
#	flag_name
#	pkg_name        ::Personality::Abstract::Text
# //returns
{
	my ($this, $value, $flag_name, $pkg_name) = @ARGUMENTS;

	$value =~ s{\W}{X}sg;

	my $flags = $this->[ATR_FLAGS];
	if ($pkg_name eq '*')
	{
		if (exists($flags->{$flag_name}))
		{
			$flags->{$flag_name}[IDX_FLG_DEFAULT] = $value;
		} else {
			$flags->{$flag_name} = [$value, {}, []];
		}
		return;
	}

	my $flag_names = [split(',', $flag_name, PKY_SPLIT_RETURN_FULL_TRAIL)];
	foreach my $flag_name (@$flag_names)
	{
		unless (exists($flags->{$flag_name}))
		{
			die("No default for flag '$flag_name' defined.");
		}
		my $selected_flag = $flags->{$flag_name};
		if ($pkg_name =~ s{::$}{}sg)
		{
			push($selected_flag->[IDX_FLG_MATCHER],
				[$pkg_name, $value]);
		} else {
			$selected_flag->[IDX_FLG_PACKAGES]{$pkg_name} =
				$value;
		}
	}

	return;
}

sub build_matcher
# /type method
# /effect ""
# //parameters
#	patterns
# //returns
#	?
{
	my ($this, $patterns) = @ARGUMENTS;

	my $definitions = ['sub {'];
	foreach my $pattern (@$patterns)
	{
		my ($name, $value) = @$pattern;
		my $definition = "return(q{$value}) if (\$_[0] =~ m{^$name}s);";
		push($definitions, $definition);
	}
	push($definitions, 'return(IS_UNDEFINED);', '}');

	my $definition = join(TXT_LINE_BREAK, @$definitions);
#	print STDERR "$definition\n";
	my $matcher = eval $definition;
	die($EVAL_ERROR) if ($EVAL_ERROR);

	return($matcher);
}

sub lookup_name
# /type method
# /effect ""
# //parameters
#	pkg_name        ::Personality::Abstract::Text
#	flag_name
# //returns
#	?
{
	my ($this, $pkg_name, $flag_name) = @ARGUMENTS;

	my $flags = $this->[ATR_FLAGS];
	unless (exists($flags->{$flag_name}))
	{
		die("Missing definition for flag '$flag_name' requested by package '$pkg_name'.");
	}
	my $flag = $flags->{$flag_name};

	my $value;
	if (exists($flag->[IDX_FLG_PACKAGES]{$pkg_name}))
	{
		$value = $flag->[IDX_FLG_PACKAGES]{$pkg_name};
	} else {
		$value = $flag->[IDX_FLG_MATCHER]->($flag_name);
		$value //= $flag->[IDX_FLG_DEFAULT];
	}
	return($value);
}

sub modularity_setup
# /type method
# /effect ""
# //parameters
#	meta_monad  ::Meta::Monad
# //returns
{
	my ($this, $meta_monad) = @ARGUMENTS;


	my $source_code = $meta_monad->source_code;

	return unless (defined($this->[ATR_ALL_FLAGS_RE]));
	my $flags = $source_code->unique_matches(
		qr{\W((?:$this->[ATR_ALL_FLAGS_RE])_FLAG)\W});
	return unless (@$flags);

	my $pkg_name = $meta_monad->package_name;

	my $name_space = $meta_monad->package_name->name_space;
	foreach my $flag (@$flags)
	{
		my $value = $this->lookup_name(
			$pkg_name,
			lc(substr($flag, 0, -5)));
		$name_space->add_inline_function($flag, $value);
	}

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.52
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"