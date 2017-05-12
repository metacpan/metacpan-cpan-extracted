#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Captcha::noCAPTCHA');

my $cap = Captcha::noCAPTCHA->new({
	site_key   => 'fake site key',
	secret_key => 'fake secret key',
});

ok(not defined $cap->_parse_response);
is_deeply($cap->errors,['http-tiny-no-response']);

ok(not defined $cap->_parse_response(''));
is_deeply($cap->errors,['http-tiny-no-response']);

ok(not defined $cap->_parse_response('not a hash'));
is_deeply($cap->errors,['http-tiny-no-response']);

ok(not defined $cap->_parse_response({}));
is_deeply($cap->errors,['status-code-0']);

ok(not defined $cap->_parse_response({success => 0,status => 500}));
is_deeply($cap->errors,['status-code-500']);

ok(not defined $cap->_parse_response({success => 1}));
is_deeply($cap->errors,['no-content-returned']);

ok(not defined $cap->_parse_response({success => 1,content => ''}));
is_deeply($cap->errors,['no-content-returned']);

ok(not $cap->_parse_response({success => 1,content => '{"success": false}'}));
ok(not defined $cap->errors);

ok($cap->_parse_response({success => 1,content => '{"success": true}'}));
ok(not defined $cap->errors);

ok(defined $cap->response);
ok(ref $cap->response eq 'HASH');
# note: can't use is_deeply to compare the response to a hashref because
# booleans might be blessed JSON::PP::Boolean objects and is_deeply() doesn't
# like that.
ok(keys %{ $cap->response } == 1);
ok($cap->response->{success} == 1);

done_testing();
