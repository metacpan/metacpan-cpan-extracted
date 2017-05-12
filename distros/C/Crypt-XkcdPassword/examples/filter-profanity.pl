use feature 'say';
use Crypt::XkcdPassword;
use Regexp::Common;

say Crypt::XkcdPassword->make_password(4, sub {
	not /$RE{profanity}/
});
