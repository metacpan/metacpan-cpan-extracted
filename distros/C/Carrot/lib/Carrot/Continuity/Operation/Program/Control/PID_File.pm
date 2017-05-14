package Carrot::Continuity::Operation::Program::Control::PID_File
# /type class
# /implements [=project_pkg=]::_Plugin_Prototype
# /attribute_type ::Many_Declared::Ordered
# /capability "Records the process pid in a file."
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->class_names->provide(
		my $pid_file_class = '::Personality::Valued::File::Content::PID_File');

	$expressiveness->provide(
		my $customized_settings = '::Individuality::Controlled::Customized_Settings');

	$customized_settings->provide_plain_value(
		my $file_name = 'file_name');

# =--------------------------------------------------------------------------= #

sub attribute_construction
# /type method
# /effect "Constructs the attribute(s) of a newly created instance."
# //parameters
#	information_barb  ::Personality::Reflective::Information_Barb
# //returns
{
	my ($this, $information_barb) = @ARGUMENTS;

#	$$this = $file_name->value;
#	$information_barb->resolve_standard_placeholders($this);

	$this->[ATR_PID_FILE] = $pid_file_class->indirect_constructor('/tmp/carrot.pid');
	return;
}

sub activate
# /type implementation
{
	$_[THIS][ATR_PID_FILE]->store_current;
	return;
}

sub deactivate
# /type implementation
{
	$_[THIS][ATR_PID_FILE]->remove;
	return;
}

# =--------------------------------------------------------------------------= #

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.101
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"