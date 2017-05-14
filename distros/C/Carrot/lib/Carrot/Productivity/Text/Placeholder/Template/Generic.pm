package Carrot::Productivity::Text::Placeholder::Template::Generic
# /type class
# /attribute_type ::Many_Declared::Ordered
# /project_entry ::Productivity::Text::Placeholder
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->package_resolver->provide(
		my $placeholder_class = '::Productivity::Text::Placeholder');
	$expressiveness->provide(
		my $class_names = '::Individuality::Controlled::Class_Names');
	$class_names->provide(
		my $parser_class = '[=project_pkg=]::Parser::RE');

	my $default_parser = $parser_class->indirect_constructor;

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# /parameters *
# //returns
{
	my $this = shift(\@ARGUMENTS); # my $pkg_names = \@ARGUMENTS;

	$this->[ATR_PARSER] = IS_UNDEFINED;
	$this->[ATR_MINIPLATES] = [];
	$this->[ATR_TEXTS] = [];
	$this->[ATR_CALLS] = [];
	$this->[ATR_ALIASES] = [];

	$this->provide_miniplate(@ARGUMENTS);
#	$this->provide_miniplate($pkg_names);

	return;
}

sub provide_parser_class
# /type method
# /effect ""
# //parameters
#	parser_class
# //returns
{
	$class_names->provide($_[SPX_PARSER_CLASS]);
	return;
}

sub create_parser
# /type method
# /effect ""
# /parameters *
# //returns
{
	my $this = shift(\@ARGUMENTS);

	# NOTE: this can't easily become provide_parser() because of
	# the parser specific arguments - is that used at all?
	$this->[ATR_PARSER] = $parser_class->indirect_constructor(@ARGUMENTS);
	return($this->[ATR_PARSER]);
}

sub set_parser
# /type method
# /effect ""
# //parameters
#	parser
# //returns
{
	$_[THIS][ATR_PARSER] = $_[SPX_PARSER];
	return;
}

sub provide_miniplate
# /type method
# /effect ""
# //parameters
#	pkg_names  +multiple ::Personality::Abstract::Text
# //returns
{
	my $this = shift(\@ARGUMENTS);
#	my $pkg_names = \@ARGUMENTS;

	$class_names->provide(@ARGUMENTS);
	foreach my $pkg_name (@ARGUMENTS)
	{
		next if (Scalar::Util::readonly($pkg_name));
#		next unless (defined($pkg_name)); #FIXME: leftover?
		$pkg_name = $pkg_name->indirect_constructor;
		push($this->[ATR_MINIPLATES], $pkg_name);
	}
	return;
}

sub find_call
# /type method
# /effect ""
# //parameters
#	symbol
# //returns
#	?
{
	my ($this, $symbol) = @ARGUMENTS;

	my $call = IS_UNDEFINED;
	foreach my $miniplate (@{$this->[ATR_MINIPLATES]})
	{
		$call = $miniplate->find_call($symbol);
		last if (defined($call));
	}
	unless (defined($call))
	{
		die("No miniplate defines symbol '$symbol'.");
	}
	return($call);
}

sub compile
# /type method
# /effect ""
# //parameters
#	format
# //returns
{
	my ($this) = @ARGUMENTS;

	unless (defined($this->[ATR_PARSER]))
	{
		$this->[ATR_PARSER] = $default_parser;
	}

	my $parts = $this->[ATR_PARSER]->split_text($_[SPX_FORMAT]);

	my $texts = [];
	my $calls = [];
	my $aliases = [];
	my $placeholders = {};
	foreach my $part (@$parts)
	{
		my ($text, $placeholder) = @$part;

		push($texts, $text, '');
		last if ($placeholder eq '');

		if (exists($placeholders->{$placeholder}))
		{
			push($aliases, [$placeholders->{$placeholder}, $#$texts]);
			next;
		}

		$placeholders->{$placeholder} = $#$texts;
		my $call = $this->find_call($placeholder);
		next unless (defined($call));
		push($calls, [$call, $#$texts]);
	}

	$this->[ATR_TEXTS] = $texts;
	$this->[ATR_CALLS] = $calls;
	$this->[ATR_ALIASES] = $aliases;

	return;
}

sub execute
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my ($this) = @ARGUMENTS;

	my $texts = $this->[ATR_TEXTS];
	foreach my $call_position (@{$this->[ATR_CALLS]})
	{
		my ($call, $offset) = @$call_position;
		my ($method_ref, $arguments) = @$call;
		$texts->[$offset] = $method_ref->(@$arguments);
	}
	foreach my $alias (@{$this->[ATR_ALIASES]})
	{
		my ($master, $offset) = @$alias;
		$texts->[$offset] = $texts->[$master];

	}
	my $text = join('', @$texts);
#	foreach my $call (@{$this->[ATR_CALLS]}, @{$this->[ATR_ALIASES]})
#	{
#		my (undef, $offset) = @$call;
#		$texts->[$offset] = '';
#	}

	return(\$text);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.91
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"