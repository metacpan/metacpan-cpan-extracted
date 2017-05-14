package main
# /type library
# /capability ""
{
	use strict;
	use warnings 'FATAL' => 'all';

	my $expressiveness = Carrot::individuality;
	$expressiveness->package_resolver->provide(
		my $protocol_version_class = '::Personality::Valued::Internet::Protocol::HTTP::Protocol_Version');

	my $protocol_version = $protocol_version_class->indirect_constructor;
	$protocol_version->set_numerical_version('1.0');

	require Data::Dumper;
	print(STDERR Data::Dumper::Dumper($protocol_version));

	return(PERL_FILE_LOADED);
}
