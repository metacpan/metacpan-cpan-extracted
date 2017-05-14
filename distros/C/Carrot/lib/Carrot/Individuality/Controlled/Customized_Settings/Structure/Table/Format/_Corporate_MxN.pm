package Carrot::Individuality::Controlled::Customized_Settings::Structure::Table::Format::_Corporate_MxN
# /type class
# //parent_classes
#	[=component_pkg=]::_Corporate
#	[=project_pkg=]
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';
	use bytes;

	my $expressiveness = Carrot::individuality;
	$expressiveness->provide(
		my $code_evaluation = '::Individuality::Singular::Execution::Code_Evaluation');

# =--------------------------------------------------------------------------= #

sub data_copy_for_clone
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return([map([map($_->clone_constructor, @$_)], @{$_[THIS][ATR_ROWS]})])
}

sub inherit
# /type method
# /effect ""
# //parameters
#	that            ::Personality::Abstract::Instance
# //returns
{
	my ($this, $that) = @ARGUMENTS;

	$this->enforce_compatible_structure($that);
	push($this->[ATR_ROWS],
		map(map($_->clone_constructor, @$_), @{$that->[ATR_ROWS]}));
	return;
}

sub add_row
# /type method
# /effect ""
# //parameters
#	row
# //returns
{
	my ($this, $row) = @ARGUMENTS;

	my $columns = $this->[ATR_COLUMNS];
	my $i = ADX_NO_ELEMENTS;

	foreach my $element (@$row)
	{
		$i++;
		next if (Scalar::Util::blessed($element));
		$element = $columns->process_clone($i, $element);
	}

	$this->store_row($row);

	return;
}

my $delete_template = q{package %s {
	my $sub = sub {
		my ($row1, $row2) = @ARGUMENTS;
		return(%s);
	};
	return($sub);
}};
sub delete_row
# /type method
# /effect ""
# //parameters
#	row1
# //returns
{
	my ($this, $row1) = @ARGUMENTS;

	my $checks = [];

	# how nice would a two-alias foreach be...
	for (my $i = ADX_FIRST_ELEMENT; $i <= $#$row1; $i++)
	{
		next if (length(ref($row1->[$i])) > 0); #\undef
		push($checks, "(\$row1->[$i] eq \$row2->[$i]->value)");
	}
	my $check_code = sprintf($delete_template,
		__PACKAGE__,
		join(' and ', @$checks));
	$code_evaluation->provide_fatally($check_code);

	my $delete = [];
	for (my $i = ADX_FIRST_ELEMENT; $i <= $#{$this->[ATR_ROWS]}; $i++)
	{
		next unless ($check_code->($row1, $this->[ATR_ROWS][$i]));
		push($delete, $i);
	}

	foreach my $i (@$delete)
	{
		splice($this->[ATR_ROWS], $i, 1);
	}

	return;
}

sub plain_values
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return([map([map($_->value, @$_)], @{$_[THIS][ATR_ROWS]})]);
}

sub values_1i1xN
# /type method
# /effect ""
# //parameters
#	position
# //returns
#	?
{
	my ($this, $position) = @ARGUMENTS;

	die("FIXME") unless (defined($position));
	my $values = {};
	foreach my $row (@{$this->[ATR_ROWS]})
	{
		$values->{$row->[0]->value // ''} = $row->[$position];
	}
	return($values);
}

sub plain_values_1i1xN
# /type method
# /effect ""
# //parameters
#	position
# //returns
#	?
{
	my ($this, $position) = @ARGUMENTS;

	die("FIXME") unless (defined($position));
	my $values = {};
	foreach my $row (@{$this->[ATR_ROWS]})
	{
		$values->{$row->[0]->value // ''} = $row->[$position]->value;
	}
	return($values);
}

sub values_1iMxN
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my ($this) = @ARGUMENTS;

	my $values = {};
	foreach my $row (@{$this->[ATR_ROWS]})
	{
		my $copy = [@$row];
		my $key = shift($copy);
		$values->{$key->value // ''} = $copy;
	}
	return($values);
}

sub plain_values_1iMxN
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	my ($this) = @ARGUMENTS;

	my $values = {};
	foreach my $row (@{$this->[ATR_ROWS]})
	{
		my $copy = [map($_->value, @$row)];
		my $key = shift($copy) // '';
		$values->{$key} = $copy;
	}
	return($values);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.328
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
