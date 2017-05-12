use 5.010;
use strict;
use Crypt::XkcdPassword;

my $words  = shift || 'EN';
my $size   = shift || 4;
my $number = shift || 1;

my $gen = Crypt::XkcdPassword->new(words => $words);
say $gen->make_password($size)
	for 1 .. $number;
