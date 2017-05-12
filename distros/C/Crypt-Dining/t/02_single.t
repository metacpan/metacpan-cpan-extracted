use strict;
use warnings;
use Test::More tests => 7;

use_ok('Crypt::Dining');

eval {
	my $dc = new Crypt::Dining(
		Peers	=> [],
			);
};
ok(defined $@, "Construct failed with no peers.");

my $dc0 = new Crypt::Dining(
		LocalAddr	=> '127.0.0.2',
		LocalPort	=> 17356,
		Peers		=> [ '127.0.0.3:17357' ],
		# Debug		=> 1,
			);
ok(defined $dc0, 'Constructed something');
isa_ok($dc0, 'Crypt::Dining');

my $dc1 = new Crypt::Dining(
		LocalAddr	=> '127.0.0.3',
		LocalPort	=> 17357,
		Peers		=> [ '127.0.0.2:17356' ],
		# Debug		=> 1,
			);
ok(defined $dc1, 'Constructed something');
isa_ok($dc1, 'Crypt::Dining');

unless (fork) {
	$dc1->round("foo");
	exit;
}

my $answer = $dc0->round();
is(substr($answer, 0, 3), 'foo', 'Got the right message');

wait;
