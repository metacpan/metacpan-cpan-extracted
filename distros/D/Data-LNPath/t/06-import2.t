#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

{
	use Data::LNPath qw/all/, {
		errors => {
			invalid_path => sub { die 'INVALID PATH' },
			allow_meth_keys => undef
		}
	};
	my $blessed = bless {}, 'DUMMY';
	no strict 'refs';
	*{"DUMMY::okay"} = sub { return undef };
	my $data = {
		one => {
			a => [qw/10 2 3/],
			b => { a => 10, b => 1, c => 1 },
			c => 1,
			e => $blessed,
			i => sub { 'code breaks invalid path' },
		},
	};
	is(eval{lnpath($data, '/one/i/d')}, undef);
	is(eval{lnpath($data, '/one/a/10')}, undef);
	is(eval{lnpath($data, '/one/e/okay()')}, undef);
	ok(2);
}

done_testing();

