use Test::More;

use strict;
use warnings;

use HTTP::Request::Common;
use JSON::XS;

use lib qw(t/lib);

use Test::WWW::Mechanize::Catalyst 'MyApp';

my $mech = Test::WWW::Mechanize::Catalyst->new( agent => 'Safari');
my $tid  = 1;

ok(
    my $api = MyApp->controller('API')->api,
    'get api directly from controller'
);

ok(
		$mech->request(
			POST $api->{url},
			Content_Type => 'application/json',
			Content      => encode_json(
				{
					action => 'JSON',
					method => 'index',
					tid    => $tid,
					data   => [],
					type   => 'rpc',
				}
			)
		),
		'get json response'
	);
    
like( $mech->content, qr/{"foo":"bar"}/, 'json works' );



done_testing;
