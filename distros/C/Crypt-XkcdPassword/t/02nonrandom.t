use Test::More tests => 5;
use Crypt::XkcdPassword;

my $rng = sub { 666 };
my $gen = Crypt::XkcdPassword->new(rng => $rng);

is
	$gen->make_password,
	'choice choice choice choice';

is
	$gen->make_password(6),
	'choice choice choice choice choice choice';

is
	$gen->make_password(0),
	'choice choice choice choice';

is
	$gen->make_password(-1),
	'choice choice choice choice';

$gen = Crypt::XkcdPassword->new(rng => $rng, words => 'IT');

is
	$gen->make_password(0),
	'matrimonio matrimonio matrimonio matrimonio';
