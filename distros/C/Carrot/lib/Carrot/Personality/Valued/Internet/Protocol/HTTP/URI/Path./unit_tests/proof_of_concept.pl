package main
# /type library
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->package_resolver->provide(
		my $path_class = '::Personality::Valued::Internet::Protocol::HTTP::URI::Path');
	$expressiveness->package_resolver->provide_instance(
		my $test_plans = '::Meta::Greenhouse::Test_Plans');

	$test_plans->set_sections(3);

	my $path = $path_class->indirect_constructor;
	$test_plans->check_method_transparency(
		$path, 'assign_value', 'value', [
			['slash', '/'],
			['index', '/index.html'],
			['directory', '/news/']]);

#	$test_plans->check_method_scalar_effect(
#		$path, 'assign_value', 'query', [
#			['slash', ['/index.html?a=b&c=d'], 'a=b&c=d']]);

	$test_plans->has_methods(
		$path, ['assign_value', 'query', 'asdf']);

	$test_plans->report('fail', 0);

	require Data::Dumper;
	print(STDERR Data::Dumper::Dumper($path));

	$test_plans->summary;

	return(PERL_FILE_LOADED);
}
