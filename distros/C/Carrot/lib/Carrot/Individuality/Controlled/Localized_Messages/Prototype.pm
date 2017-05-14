package Carrot::Individuality::Controlled::Localized_Messages::Prototype
# /type class
# /attribute_type ::Many_Declared::Ordered
# //parameters
#	operator_languages
# /capability ""
{
	my ($operator_languages) = @ARGUMENTS;

	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->package_resolver->provide(
		my $template_class = '[=project_pkg=]::Template');

	$expressiveness->package_resolver->provide_instance(
		my $translated_errors = '::Meta::Greenhouse::Translated_Errors',
		my $empty_context = '::Personality::Reflective::Information_Barb');

	#use overload
	#	'""' => sub { return($_[THIS]->realize_text_flat) };

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	resolver
#	name
# //returns
{
	my ($this, $resolver, $name) = @ARGUMENTS;

	my $check = $resolver->find_message_file(undef, $name, []);
	unless (defined($check))
	{
		$translated_errors->advocate(
			'message_not_found',
			[$resolver->class_name, $name]);
	}
	$this->[ATR_RESOLVER] = $resolver;
	$this->[ATR_NAME] = $name;
	$this->[ATR_GENERAL_CONTEXT] = IS_UNDEFINED;
	$this->[ATR_SPECIFIC_CONTEXT] = IS_UNDEFINED;
	$this->[ATR_TEMPLATES] = {};

	return;
}

sub set_contexts
# /type method
# /effect ""
# //parameters
#	information_barb
#	specific_context
# //returns
{
	my ($this, $information_barb, $specific_context) = @ARGUMENTS;

	$this->[ATR_GENERAL_CONTEXT] = $information_barb;
	$this->[ATR_SPECIFIC_CONTEXT] = $specific_context;

	return;
}

sub set_information_barb
# /type method
# /effect ""
# //parameters
#	information_barb
# //returns
{
	my ($this, $information_barb) = @ARGUMENTS;

	die unless (defined($information_barb)); #FIXME
	die if (ref($information_barb) eq 'HASH'); #FIXME

	$this->[ATR_GENERAL_CONTEXT] = $information_barb;

	return;
}

# sub set_specific_context
# # method (<this>, <details>) public
# {
# 	my ($this, $details) = @ARGUMENTS;
#
# 	die unless (defined($details));
# 	$this->[ATR_SPECIFIC_CONTEXT] = $details;
#
# 	return;
# }
#

#FIXME: remove
#sub get_languages
## method (<this>) public
#{
##FIXME: should not happen by design
#	return(['en_US']) unless (defined($_[THIS][ATR_LANGUAGES]));
##FIXME: maybe a copy is too much
#	return([@{$_[THIS][ATR_LANGUAGES]}]);
#}

sub get_name
# /type method
# /effect ""
# //parameters
# //returns
#	?
{
	return($_[THIS][ATR_NAME]);
}

sub realize_text
# /type method
# /effect ""
# //parameters
#	specific_context
#	information_barb
#	languages
# //returns
#	?
{
	my ($this, $specific_context, $information_barb, $languages) = @ARGUMENTS;

	$specific_context //= $this->[ATR_SPECIFIC_CONTEXT];
	$information_barb //= $this->[ATR_GENERAL_CONTEXT] // $empty_context;
	$languages //= $operator_languages;

	my $rv = $this->[ATR_RESOLVER]->find_message_file(
		undef,
		$this->[ATR_NAME],
		$languages);
	unless (defined($rv))
	{
		$translated_errors->advocate(
			'message_not_found',
			[$this->[ATR_NAME],
				join(', ', @$languages)]);
	}
	my ($language, $file_name) = @$rv;

	unless (exists($this->[ATR_TEMPLATES]{$language}))
	{
		$this->[ATR_TEMPLATES]{$language} =
			$template_class->indirect_constructor(
				$this->[ATR_NAME],
				$file_name);
	}

	my $complete_context = $information_barb
		->extend(
			'void',
			$specific_context);

	my $msg = $this->[ATR_TEMPLATES]{$language}->filled_with(
		$complete_context);

	return($msg);
}

sub realize_text_flat
# /type method
# /effect ""
# /parameters *
# //returns
#	::Personality::Abstract::Text
{
	return(${shift(\@ARGUMENTS)->realize_text(@ARGUMENTS)});
}

sub realize_text_projected
# /type method
# /effect ""
# //parameters
#	specific_context
#	projection      Mica::Projection
# //returns
#	::Personality::Abstract::Text
{
	my ($this, $specific_context, $projection) = @ARGUMENTS;

	return($this->realize_text_projection(
		$specific_context,
		$projection->information_barb,
		$projection->languages));
}

sub localized_text
# /type method
# /effect ""
# /parameters *
# //returns
#	::Personality::Abstract::Text
{
	return(${shift(\@ARGUMENTS)->realize_text(undef, undef, @ARGUMENTS)});
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.100
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
