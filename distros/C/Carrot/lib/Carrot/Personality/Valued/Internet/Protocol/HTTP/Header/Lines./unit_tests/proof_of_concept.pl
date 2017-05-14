package main
# /type library
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->package_resolver->provide(
		my $header_lines_class = '::Personality::Valued::Internet::Protocol::HTTP::Header::Lines');

	my $header_lines = $header_lines_class->indirect_constructor;
	$header_lines->by_name('Accept')->assign_value('Yes');
	$header_lines->append_to(my $buffer = '');

	require Data::Dumper;
	print(STDERR Data::Dumper::Dumper($header_lines, $buffer));


	return(PERL_FILE_LOADED);
}
