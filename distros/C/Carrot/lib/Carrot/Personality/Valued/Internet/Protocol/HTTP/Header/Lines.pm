package Carrot::Personality::Valued::Internet::Protocol::HTTP::Header::Lines
# /type class
# /attribute_type ::Many_Declared::Ordered
# /autoload *
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->package_resolver->provide_instance(
		my $header_names = '[=parent_pkg=]::Names');

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_TYPE] = IS_UNDEFINED;
	$this->[ATR_LINES] = {};

	return;
}

sub set_type_request
# /type method
# /effect ""
# //parameters
# //returns
{
	$_[THIS][ATR_TYPE] = 'q';
}

sub set_type_response
# /type method
# /effect ""
# //parameters
# //returns
{
	$_[THIS][ATR_TYPE] = 'p';
}

sub append_to
# /type method
# /effect ""
# //parameters
#	string
# //returns
{
	my ($this) = @ARGUMENTS;

	my $lines = $this->[ATR_LINES];
	my $names = $header_names->grouped_names(
		[keys($lines)],
		$this->[ATR_TYPE]);
	foreach my $name (@$names)
	{
		next unless ($lines->{$name}->has_data);
		$_[SPX_STRING] .=
			$name
			. ': '
			. $lines->{$name}->value
			. TXT_CRLF;
	}
	return;
}

sub by_name
# /type method
# /effect ""
# //parameters
#	name
# //returns
#	?
{
	my ($this, $name) = @ARGUMENTS;

	my $lines = $this->[ATR_LINES];
	unless (exists($lines->{$name}))
	{
		$lines->{$name} = $header_names
			->create($name, $this->[ATR_TYPE]);
	}
	return($lines->{$name});
}

sub remove
# /type method
# /effect ""
# //parameters
#	name
# //returns
#	?
{
	delete($_[THIS][ATR_LINES]{$_[SPX_NAME]});
}

sub clear
# /type method
# /effect ""
# //parameters
#	name
# //returns
#	?
{
	splice($_[THIS][ATR_LINES]);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.139
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2010-2014 Winfried Trümper <pub+perl@wt.tuxomania.net>"
