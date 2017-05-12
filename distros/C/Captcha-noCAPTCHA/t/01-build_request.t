#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Captcha::noCAPTCHA');

my $cap = Captcha::noCAPTCHA->new({
	site_key   => 'fake site key',
	secret_key => 'fake secret key',
	api_url    => 'file:t/success_response.json',
});

my $req1 = $cap->_build_request('the response');

cmp_ok(keys %$req1,'==',2);
cmp_ok($req1->{response},'eq','the response');
cmp_ok($req1->{secret},'eq','fake secret key','eq',);

my $req2 = $cap->_build_request('the response','127.0.0.1');
cmp_ok($req2->{response},'eq','the response');
cmp_ok($req2->{remoteip},'eq','127.0.0.1');
cmp_ok(keys %$req2,'==',3);

done_testing();
