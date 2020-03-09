#! perl

use strict;
use warnings;

use Test::More 0.89;
use Crypt::Argon2 qw/argon2i_pass argon2i_raw argon2i_verify/;

sub hashtest {
	my ($t_cost, $m_cost, $parallelism, $password, $salt, $hexref, $mcfref) = @_;
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	my $encoded = argon2i_pass($password, $salt, $t_cost, $m_cost, $parallelism, 32);
	is($encoded, $mcfref, "$t_cost:$m_cost:$parallelism($password, $salt) encodes as expected");
	ok(argon2i_verify($encoded, $password), "$t_cost:$m_cost:$parallelism($password, $salt) matches as expected");
	my $hex = unpack "H*", argon2i_raw($password, $salt, $t_cost, $m_cost, $parallelism, 32);
	is($hex, $hexref, "$t_cost:$m_cost:$parallelism($password, $salt) verifies as expected");
}

hashtest(2, '64M', 1, 'password', 'somesalt',
	'c1628832147d9720c5bd1cfd61367078729f6dfb6f8fea9ff98158e0d7816ed0',
	'$argon2i$v=19$m=65536,t=2,p=1$c29tZXNhbHQ$wWKIMhR9lyDFvRz9YTZweHKfbftvj+qf+YFY4NeBbtA');
hashtest(2, '256k', 1, 'password', 'somesalt',
	'89e9029f4637b295beb027056a7336c414fadd43f6b208645281cb214a56452f',
	'$argon2i$v=19$m=256,t=2,p=1$c29tZXNhbHQ$iekCn0Y3spW+sCcFanM2xBT63UP2sghkUoHLIUpWRS8');
hashtest(2, '256k', 2, 'password', 'somesalt',
	'4ff5ce2769a1d7f4c8a491df09d41a9fbe90e5eb02155a13e4c01e20cd4eab61',
	'$argon2i$v=19$m=256,t=2,p=2$c29tZXNhbHQ$T/XOJ2mh1/TIpJHfCdQan76Q5esCFVoT5MAeIM1Oq2E');
hashtest(1, '64M', 1, 'password', 'somesalt',
	'd168075c4d985e13ebeae560cf8b94c3b5d8a16c51916b6f4ac2da3ac11bbecf',
	'$argon2i$v=19$m=65536,t=1,p=1$c29tZXNhbHQ$0WgHXE2YXhPr6uVgz4uUw7XYoWxRkWtvSsLaOsEbvs8');
hashtest(4, '64M', 1, 'password', 'somesalt',
	'aaa953d58af3706ce3df1aefd4a64a84e31d7f54175231f1285259f88174ce5b',
	'$argon2i$v=19$m=65536,t=4,p=1$c29tZXNhbHQ$qqlT1YrzcGzj3xrv1KZKhOMdf1QXUjHxKFJZ+IF0zls');
hashtest(2, '64M', 1, 'differentpassword', 'somesalt',
	'14ae8da01afea8700c2358dcef7c5358d9021282bd88663a4562f59fb74d22ee',
	'$argon2i$v=19$m=65536,t=2,p=1$c29tZXNhbHQ$FK6NoBr+qHAMI1jc73xTWNkCEoK9iGY6RWL1n7dNIu4');
hashtest(2, '64M', 1, 'password', 'diffsalt',
	'b0357cccfbef91f3860b0dba447b2348cbefecadaf990abfe9cc40726c521271',
	'$argon2i$v=19$m=65536,t=2,p=1$ZGlmZnNhbHQ$sDV8zPvvkfOGCw26RHsjSMvv7K2vmQq/6cxAcmxSEnE');
if ($ENV{EXTENDED_TESTING} || $ENV{AUTHOR_TESTING}) {
	hashtest(2, '256M', 1, 'password', 'somesalt',
		'296dbae80b807cdceaad44ae741b506f14db0959267b183b118f9b24229bc7cb',
		'$argon2i$v=19$m=262144,t=2,p=1$c29tZXNhbHQ$KW266AuAfNzqrUSudBtQbxTbCVkmexg7EY+bJCKbx8s');
	hashtest(2, '1G', 1, 'password', 'somesalt',
		'd1587aca0922c3b5d6a83edab31bee3c4ebaef342ed6127a55d19b2351ad1f41',
		'$argon2i$v=19$m=1048576,t=2,p=1$c29tZXNhbHQ$0Vh6ygkiw7XWqD7asxvuPE667zQu1hJ6VdGbI1GtH0E');
}

done_testing();
