package main
# /type library
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->package_resolver->provide(
		my $uri_class = '::Personality::Valued::Internet::Protocol::HTTP::URI');
	$expressiveness->package_resolver->provide_instance(
		my $test_plans = '::Meta::Greenhouse::Test_Plans');

	$test_plans->set_sections(1);

	my $uri = $uri_class->indirect_constructor;
	$uri->assign_value('/index.html?a=b');
	$uri->path->assign_value('/news/index.html');
	$test_plans->check_method_transparency(
		$uri, 'assign_value', 'value', [
			['slash', '/'],
			['index', '/index.html'],
			['directory', '/news/?a=b&c=d']]);
#
#	$test_plans->check_method_scalar_effect(
#		$uri, 'assign_value', 'query', [
#			['slash', ['/index.html?a=b&c=d'], 'a=b&c=d']]);
#
#	$test_plans->has_methods(
#		$uri, ['assign_value', 'query', 'asdf']);
#
#	$test_plans->report('fail', 0);

	require Data::Dumper;
	print(STDERR Data::Dumper::Dumper($uri));

	$test_plans->summary;

	return(PERL_FILE_LOADED);
}
