package Carrot::Individuality::Singular::Execution::Fatal_Error::Details
# /type class
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';
	require Scalar::Util;

	BEGIN {
		my $expressiveness = Carrot::modularity;

		require overload;
		overload->import(
			'""' => 'overload_stringification');
	} #BEGIN

	my $expressiveness = Carrot::individuality;
	$expressiveness->provide(
		my $localized_messages = '::Individuality::Controlled::Localized_Messages');

	$localized_messages->provide_prototype(
		my $caller_info = 'caller_info');

	#use overload
	#	'""' => sub { return($_[THIS]->as_text) };

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	caller
#	msg
#	category
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_CALLER] = $_[SPX_CALLER];
	$this->[ATR_MSG] = $_[SPX_MSG];
	$this->[ATR_CATEGORY] = $_[SPX_CATEGORY];

#FIXME: remove
	die if ($this->[ATR_MSG]->class_name ne 'Carrot::Individuality::Controlled::Distinguished_Exceptions::Potential');

	return;
}

sub get_caller
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][ATR_CALLER]);
}

sub get_category
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][ATR_CATEGORY]);
}

sub caller_info
# /type method
# /effect ""
# //parameters
#	languages
# //returns
#	?
{
	my ($this, $languages) = @ARGUMENTS;

	my $caller = $this->[ATR_CALLER];
	my $text = $caller_info->realize_text(
		{
			'message_name' => $this->[ATR_MSG]->get_name,
			'caller_package' => $caller->[RDX_CALLER_PACKAGE],
			'caller_file' => $caller->[RDX_CALLER_FILE],
			'caller_line' => $caller->[RDX_CALLER_LINE],
			'error_category' => $this->[ATR_CATEGORY]
		},
		undef,
		$languages);

	return($text);
}

sub as_text
# /type method
# /effect ""
# //parameters
#	languages
# //returns
#	?
{
	my ($this, $languages) = @ARGUMENTS;

	my $text = ${$this->caller_info($languages)}
		. TXT_LINE_BREAK
		. $this->[ATR_MSG]->localized_text($languages);
	return($text);
}

sub overload_stringification
# /type method
# /effect "Overloads the double quotes operator."
# //parameters
#	that
#	is_swapped
# //returns
#	::Personality::Abstract::Text
{
#	my ($this, $that, $is_swapped) = @ARGUMENTS;

	return($_[THIS]->as_text);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.64
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"