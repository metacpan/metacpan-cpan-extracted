use feature 'say';
use Crypt::XkcdPassword;
use Text::Aspell;

my $aspell = Text::Aspell->new;

say Crypt::XkcdPassword->make_password(10, sub {
	$aspell->check($_)
});
