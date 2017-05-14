package main
# /type library
# /capability "Proof of concept for ::Structured::Protocol::HTTP"
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->package_resolver->provide(
		'::Personality::Structured::Internet::Protocol::HTTP::',
                my $request_class = '::Request',
                my $response_class = '::Response');

	my $request = $request_class->indirect_constructor;
	my $response = $response_class->indirect_constructor;

	$request->header_lines->header_host->assign_value('localhost');
	$response->line->status_code->set_200_ok;
	$response->header_lines->header_accept->assign_value('text/html');

	require Data::Dumper;
	print STDERR Data::Dumper::Dumper($request, $response);

	return(PERL_FILE_LOADED);
}
