package Carrot::Individuality::Controlled::Customized_Settings::Structure::List::Autodetect_Type
# /type class
# /attribute_type ::Many_Declared::Ordered
# //parent_classes
#	::Individuality::Controlled::Customized_Settings::Structure
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->provide(
		'::Individuality::Controlled::',
			my $distinguished_exceptions = '::Distinguished_Exceptions',
			my $class_names = '::Class_Names');

	$distinguished_exceptions->provide(
		my $failed_autodetection = 'failed_autodetection');

	$class_names->provide(
		my $list_container_class = '::Individuality::Controlled::Customized_Settings::Structure::List');

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
# //returns
{
	my ($this) = @ARGUMENTS;

	$this->[ATR_CANDIDATES] = [];

	return;
}

sub initialize
# /type method
# /effect ""
# //parameters
#	lines
# //returns
{
	my ($this, $lines) = @ARGUMENTS;

	my $candidates = $this->[ATR_CANDIDATES];
	foreach my $line (@$lines)
	{
		$line =~ s{^\h+}{}s;
		push($candidates,
			$class_names->indirect_instance(
				split(qr{\h+}, $line,
					PKY_SPLIT_IGNORE_EMPTY_TRAIL)));
	}
	return;
}

sub customized_setting_resolve
# /type method
# /effect ""
# //parameters
#	elements
# //returns
{
	my ($this, $elements) = @ARGUMENTS;

	my $element0 = $elements->[0];
	my $found = IS_UNDEFINED;
	foreach my $candidate (@{$this->[ATR_CANDIDATES]})
	{
		next unless ($candidate->import_textual_value($element0));
		$found = $candidate->clone_constructor;
		last;
	}
	unless (defined($found))
	{
		$failed_autodetection->raise_exception(
			{'value' => $element0,
			 'rules' => join(TXT_LINE_BREAK, map($_->syntax_representation,
				 @{$this->[ATR_CANDIDATES]}))},
			ERROR_CATEGORY_SETUP);
	}

	my $list_container = $list_container_class->indirect_constructor;
	$list_container->set_element_class([$found]);
	$list_container->initialize($elements);
	$_[SPX_ELEMENTS] = $list_container;

	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.73
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"