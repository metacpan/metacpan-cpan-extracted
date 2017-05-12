use strict;
use warnings;
use Test::More tests => 5;
use Archive::Ar::Libarchive;

my $ar = Archive::Ar::Libarchive->new;

ok !$ar->error, 'no error yet';

sub roger {
  $ar->_error("foo");
}

roger();

is $ar->error,    'foo', 'error = foo';
is $ar->error(0), 'foo', 'error(0) = foo';

like $ar->error(1), qr{foo}, 'longmess containst foo';
like $ar->error(1), qr{roger}, 'longmess contains roger';

