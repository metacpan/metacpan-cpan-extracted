package Carrot::Individuality::Controlled::Localized_Messages::Template
# /type class
# /attribute_type ::Many_Declared::Ordered
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->package_resolver->provide(
		my $template_class = '::Productivity::Text::Placeholder::Template::File::Plain');

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	msg_name
#	file_name       ::Personality::Valued::File::Name
# //returns
{
	my ($this, $msg_name, $file_name) = @ARGUMENTS;

	$this->[ATR_MSG_NAME] = $msg_name;
	$this->[ATR_FILE_NAME] = \$file_name;
	$this->[ATR_TEMPLATE] = IS_UNDEFINED;
	$this->[ATR_MINIPLATE] = IS_UNDEFINED;

	return;
}

sub get_name
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][ATR_MSG_NAME]);
}

#sub get_file_name
## method (<this>) public
#{
#	return(${$_[THIS][ATR_FILE_NAME]});
#}

sub load_template
# /type method
# /effect ""
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	my $template = $template_class->indirect_constructor(
		my $miniplate = '::Productivity::Text::Placeholder::Miniplate::Information_Barb');
	$template->set_file(${$this->[ATR_FILE_NAME]});
	$template->compile;

	$this->[ATR_TEMPLATE] = $template;
	$this->[ATR_MINIPLATE] = $miniplate;

	return;
}

sub filled_with
# /type method
# /effect ""
# //parameters
#	subject
# //returns
#	::Personality::Abstract::Text
{
	my ($this, $subject) = @ARGUMENTS;

	$this->load_template unless (defined($this->[ATR_TEMPLATE]));
	$this->[ATR_MINIPLATE]->set_subject($subject);

	return($this->[ATR_TEMPLATE]->execute);
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.54
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"