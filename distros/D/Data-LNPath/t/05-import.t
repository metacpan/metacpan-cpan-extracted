#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

{
	use Data::LNPath qw/all/, { return_undef => 1 };
	my $data = {
		one => {
			a => [qw/10 2 3/],
			b => { a => 10, b => 1, c => 1 },
			c => 1
		},
	};
	is(lnpath($data, '/one/d'), undef);
	ok(2);
}
{
	use Data::LNPath qw/one all/;
	ok(2);
}
{
	use Data::LNPath qw/nope/, { errors => { allow_meth_keys => 'High in the sky' }, as => { path => 'lnpath' } };
	ok(2);
}
done_testing();

