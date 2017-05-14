package main
# /type library
# /capability "Setup Carrot and delegate to a program class"
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	my $package_resolver = $expressiveness->package_resolver;
	$package_resolver->provide(
		my $program_class = '::Continuity::Operation::Program');
	$package_resolver->provide_instance(
		my $translated_errors = '::Meta::Greenhouse::Translated_Errors');

	my $program = $program_class->indirect_constructor;
	eval {
		$program->run;

	} or $translated_errors->escalate(
		'program_failed',
		[$program->class_name],
		$EVAL_ERROR);

	return(PERL_FILE_LOADED);
}
# //revision_control
#	version 1.1.85
#	branch main
#	maturity alpha
# /license MPL-2.0 (Mozilla Public License v2.0)
# /copyright "(C) 2009-2014 Winfried Trümper <win@carrot-programming.org>"
