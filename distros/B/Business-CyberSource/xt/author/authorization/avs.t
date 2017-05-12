use strict;
use warnings;
use Test::More;

use FindBin;
use Module::Runtime qw( use_module    );
use Test::Requires  qw( Path::FindDev );
use lib Path::FindDev::find_dev( $FindBin::Bin )->child('t', 'lib' )->stringify;

my $t = use_module('Test::Business::CyberSource')->new;

my $client = $t->resolve( service => '/client/object' );

my $ret0
	= $client->submit(
		$t->resolve(
			service    => '/request/authorization',
			parameters => {
				purchase_totals => $t->resolve(
					service    => '/helper/purchase_totals',
					parameters => {
						total => 5000.00,
					},
				),
			},
		)
	);

is( $ret0->decision,           'ACCEPT', 'check decision'       );
is( $ret0->reason_code,         100,     'check reason_code'    );
is( $ret0->auth->auth_code,    '831000', 'check auth code'      );
is( $ret0->auth->avs_code,     'X',      'check avs_code'       );
is( $ret0->auth->avs_code_raw, 'X',      'check avs_code_raw'   );


my $ret1
	= $client->submit(
		$t->resolve(
			service    => '/request/authorization',
			parameters => {
				purchase_totals => $t->resolve(
					service    => '/helper/purchase_totals',
					parameters => {
						total => 5005.00,
					},
				),
			},
		)
	);
isa_ok( $ret1, 'Business::CyberSource::Response' );

is( $ret1->decision,             'REJECT', 'check decision'       );
is( $ret1->reason_code,          '200',    'check reason_code'    );
is( $ret1->auth->avs_code,       'N',      'check avs_code'       );
is( $ret1->auth->avs_code_raw,   'N',      'check avs_code_raw'   );
is( $ret1->auth->processor_response, '00', 'check processor response' );

done_testing;
