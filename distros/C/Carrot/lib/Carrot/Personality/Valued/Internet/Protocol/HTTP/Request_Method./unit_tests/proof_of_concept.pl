package main
# /type library
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->package_resolver->provide(
		my $request_method_class = '::Personality::Valued::Internet::Protocol::HTTP::Request_Method');

	my $request_method = $request_method_class->indirect_constructor;
	$request_method->set_post;

	require Data::Dumper;
	print(STDERR Data::Dumper::Dumper($request_method));

	return(PERL_FILE_LOADED);
}
