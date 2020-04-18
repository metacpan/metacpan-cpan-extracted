use strict;
use warnings;
use Test::More;

require_ok( 'Bio::Phylo::CIPRES' );

my %args = (
	'infile'  => $0, 
	'tool'    => 'MAFFT_XSEDE',
	'param'   => { 'vparam.anysymbol_' => 1 },
	'outfile' => { 'output.mafft' => '/path/to/outfile' },
	'url'     => 'https://cipresrest.sdsc.edu/cipresrest/v1',
	'user'    => 'rvosa',
	'pass'    => 'fakePassword',
	'cipres_appkey' => 'Bio::Phylo::CIPRES',
);

my $obj = new_ok( 'Bio::Phylo::CIPRES' => [ %args ] );

while( my ( $property, $expected ) = each %args ) {
	my $observed = $obj->$property;
	is_deeply( $observed, $expected );
}

isa_ok( $obj->ua, 'LWP::UserAgent' );

isa_ok( $obj->payload, 'ARRAY' );

eval { $obj->run };
isa_ok( $@, 'Bio::Phylo::Util::Exceptions::NetworkError' );

eval { $obj->get_results };
isa_ok( $@, 'Bio::Phylo::Util::Exceptions::NetworkError' );

eval { $obj->launch_job };
isa_ok( $@, 'Bio::Phylo::Util::Exceptions::NetworkError' );

done_testing();
