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

	$test_plans->set_total(5);

	my $uri = $uri_class->indirect_constructor;
	$test_plans->check_method_transparency(
		$uri, 'assign_value', 'path', [
			['slash', '/'],
			['index', '/index.html'],
			['directory', '/news/']]);

	$test_plans->check_method_scalar_effect(
		$uri, 'assign_value', 'query', [
			['slash', ['/index.html?a=b&c=d'], 'a=b&c=d']]);

	$uri->assign_value('/index.html');
	$test_plans->report('path',
		($uri->path eq '/index.html'));

	$uri->assign_value('/index.html?a=b&c=d');
	$test_plans->report('path with query',
		($uri->path eq '/index.html'));

	$test_plans->report('fail',
		($uri->path eq '0'));

	require Data::Dumper;
	print(STDERR Data::Dumper::Dumper($uri));

	$test_plans->summary;

	return(PERL_FILE_LOADED);
}
