use Test::More tests => 1;
use Crypt::XkcdPassword;

my $rng = sub { 281 };
my $gen = Crypt::XkcdPassword->new(rng => $rng, words => 'EN::Roget');

is
	$gen->make_password,
	'British British British British';
