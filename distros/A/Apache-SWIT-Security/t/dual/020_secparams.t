use strict;
use warnings FATAL => 'all';

use Test::More tests => 9;
use Apache::SWIT::Test::Utils;

BEGIN { use_ok('T::Test'); }

my $t = T::Test->new;
$t->with_or_without_mech_do(8, sub {
	my $s1 = HTML::Tested::Seal->instance->encrypt("C");
	$t->ok_get("/test/basic_handler?c=$s1");
	like($t->mech->content, qr/hhhh/) or ASTU_Wait();
	like($t->mech->content, qr/c=C/) or ASTU_Wait();
	like($t->mech->content, qr/a=NONE/) or ASTU_Wait();
	like($t->mech->content, qr/no params denied/) or ASTU_Wait;
	like($t->mech->content, qr/random params denied/) or ASTU_Wait;
	like($t->mech->content, qr/params allowed/) or ASTU_Wait;

	$t->ok_get("/test/basic_handler?c=$s1&deny=1", 403);
});
