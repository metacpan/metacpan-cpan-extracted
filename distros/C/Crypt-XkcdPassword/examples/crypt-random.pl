use feature 'say';
use Crypt::Random;
use Crypt::XkcdPassword;

my $rng = sub { Crypt::Random::makerandom(Size => 12, Strength => 1) };

say Crypt::XkcdPassword
	-> new(rng => $rng)
	-> make_password(4, qr{...});
