package main
# /type library
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->package_resolver->provide(
		my $status_code_class = '::Personality::Valued::Internet::Protocol::HTTP::Status_Code');

	my $status_code = $status_code_class->indirect_constructor;
	$status_code->set_100_continue;

	require Data::Dumper;
	print(STDERR Data::Dumper::Dumper($status_code));

	return(PERL_FILE_LOADED);
}
