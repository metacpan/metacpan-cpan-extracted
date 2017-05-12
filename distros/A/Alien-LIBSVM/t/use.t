use strict;
use warnings;
use Test::More;

use_ok('Alien::LIBSVM');

my $u = Alien::LIBSVM->new;

like( $u->libs, qr/svm/ );

done_testing;
