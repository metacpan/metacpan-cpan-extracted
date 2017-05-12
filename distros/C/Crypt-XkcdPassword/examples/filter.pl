use feature 'say';
use Crypt::XkcdPassword;
use Regexp::Common;
use Text::Aspell;

my $aspell = Text::Aspell->new;

say Crypt::XkcdPassword->make_password(4, sub {
	/.{3}/
	and $aspell->check($_)
	and not /$RE{profanity}/
});
