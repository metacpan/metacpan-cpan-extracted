use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Test::Deep;
use Test::Method;
use Module::Runtime qw( use_module );

# this test uses a response from a sale

my $res
	= new_ok( use_module('Business::CyberSource::Response') => [{
		'ccAuthReply' => {
			'processorResponse' => '00',
			'authorizedDateTime' => '2012-10-30T00:25:38Z',
				'reasonCode' => '100',
				'authorizationCode' => '841000',
				'amount' => '3000.01',
				authRecord => my $auth_record = '0110322000000E10003840979308471'
					. '907091389487900270728165933335487401834987091873407037490'
					. '173409710734104400183498397490379470730947109740701734053'
					. '0373033383032303934734070970137490713904709',
				'avsCodeRaw' => 'Y',
				'avsCode' => 'Y',
				'reconciliationID' => 'Y37080808BUW'
		},
		'purchaseTotals' => {
			'currency' => 'USD'
		},
		'ccCaptureReply' => {
			'amount' => '3000.01',
			'requestDateTime' => '2012-10-30T00:25:38Z',
			'reconciliationID' => '51142857',
			'reasonCode' => '100'
		},
		'decision' => 'ACCEPT',
		'reasonCode' => '100',
		'requestID' => '3515567380160176056470',
		requestToken => my $token = 'Ahj/7omgletsmakesurethisissecurebychangi'
			. 'ngitsguts/Imnotgivingyouarealcode/Icanthearyouu2AAAA/QAO',
		merchantReferenceCode => 'test-1349678423',
	}]);

ok ! $res->can('serialize'), 'can not serialize';

can_ok $res, qw(
		auth
		purchase_totals
		capture
		decision
		reason_code
		request_id
		request_token
		reference_code
	);

method_ok $res, decision       => [], 'ACCEPT';
method_ok $res, reason_code    => [], '100';
method_ok $res, request_id     => [], '3515567380160176056470';
method_ok $res, request_token  => [], $token;
method_ok $res, reference_code => [], 'test-1349678423';
method_ok $res, is_accept      => [], bool(1);
method_ok $res, is_reject      => [], bool(0);
method_ok $res, is_error       => [], bool(0);

isa_ok my $auth = $res->auth, 'Business::CyberSource::ResponsePart::AuthReply';
isa_ok my $capt = $res->capture, 'Business::CyberSource::ResponsePart::Reply';

can_ok $auth, qw(
	processor_response
	datetime
	reason_code
	amount
	auth_record
	auth_code
	avs_code
	avs_code_raw
	cv_code
	cv_code_raw
	reconciliation_id
);

method_ok $auth, processor_response => [], '00';
method_ok $auth, reason_code        => [], 100;
method_ok $auth, amount             => [], 3000.01;
method_ok $auth, auth_record        => [], $auth_record;
method_ok $auth, auth_code          => [], 841000;
method_ok $auth, reason_code        => [], 100;
method_ok $capt, amount             => [], 3000.01;
method_ok $capt, reconciliation_id  => [], 51142857;

isa_ok $auth->datetime, 'DateTime';
isa_ok $capt->datetime, 'DateTime';

method_ok $auth->datetime, year => [], '2012', 'auth';
method_ok $capt->datetime, year => [], '2012', 'capt';

done_testing;
