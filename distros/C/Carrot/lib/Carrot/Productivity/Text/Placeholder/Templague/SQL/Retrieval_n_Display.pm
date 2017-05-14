package Carrot::Productivity::Text::Placeholder::Templague::SQL::Retrieval_n_Display
# /type class
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->class_names->provide(
		my $template_class = '[=project_pkg=]::Template::Generic');

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# /parameters *
# //returns
{
	my $this = shift(\@ARGUMENTS);

	$this->[ATR_P1] = $template_class->indirect_constructor(
		my $result = '::Miniplate::SQL::Result', @ARGUMENTS);
	$this->[ATR_RESULT] = $result;
	$result->set_placeholder_re(qr{^fld_(\w+)$});

	$this->[ATR_P2] = $template_class->indirect_constructor(
		$this->[ATR_GENERIC] = '::Miniplate::Generic',
		$this->[ATR_STATEMENT] = '::Miniplate::SQL::Statement');
	$this->[ATR_STATEMENT]->set_placeholder_re(qr{^cond_(\w+)$});

	$this->[ATR_GENERIC]->add_placeholder('field_list',
		$result->field_list);

	$this->[ATR_VALUE_NAMES] = []
	$this->[ATR_VALUE_CLOSURES] = {};

# 2 ::Generic field_list 1 ::SQL::Result field_list

	return;
}

sub html_parameter
# /type method
# /effect ""
# //parameters
#	html
# //returns
{
	$_[THIS][ATR_P1]->compile($_[SPX_HTML]);
	return;
}

sub sql_parameter
# /type method
# /effect ""
# //parameters
#	sql
# //returns
#	::Personality::Abstract::Text
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_P2]->compile($_[SPX_SQL]);
	$this->[ATR_VALUE_NAMES] = $this->[ATR_STATEMENT]->fields;
	return($this->[ATR_P2]->execute);
}

sub provide_formatted
# /type method
# /effect ""
# //parameters
#	rows
# //returns
{
	my ($this, $rows) = @ARGUMENTS;

	foreach my $row (@$rows)
	{
		$this->[ATR_RESULT]->set_subject($row);
		$row = ${$this->[ATR_P1]->execute};
	}
	return;
}

sub add_named_value
# /type method
# /effect ""
# //parameters
#	name
#	closure
# //returns
{
	$_[THIS][ATR_VALUE_CLOSURES]{$_[SPX_NAME]} = $_[SPX_CLOSURE];
	return;
}

sub values
# /type method
# /effect ""
# /parameters *
# //returns
#	?
{
	my $this = shift(\@ARGUMENTS);

	my $value_closures = $this->[ATR_VALUE_CLOSURES];
	return([map($value_closures->{$_}->(@ARGUMENTS),
		@{$this->[ATR_VALUE_NAMES]}]);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.58
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"