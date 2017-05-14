package main
# /type library
# /capability "Proof of concept for ::HTTP::Request"
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->package_resolver->provide(
		my $request_class = '::Personality::Structured::Internet::Protocol::HTTP::Request');

	my $request = $request_class->indirect_constructor;
	$request->header_lines->header_host->assign_value('localhost');
	$request->line->method->assign_value('GET');

	require Data::Dumper;
	print(STDERR Data::Dumper::Dumper($request));

	return(PERL_FILE_LOADED);
}
