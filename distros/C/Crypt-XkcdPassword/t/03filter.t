use Test::More tests => 3;
use Crypt::XkcdPassword;

my $i;
my $rng = sub { ++$i };
my $gen = Crypt::XkcdPassword->new(rng => $rng);

$i = 0;
is
	$gen->make_password(6),
	'i to the a and that',
	'no filter';

$i = 0;
is
	$gen->make_password(6, sub { length $_ > 1 }),
	'to the and that it of',
	'filter sub';

$i = 0;
is
	$gen->make_password(6, sub { !/e/ }),
	'i to a and that it',
	'filter regexp';

