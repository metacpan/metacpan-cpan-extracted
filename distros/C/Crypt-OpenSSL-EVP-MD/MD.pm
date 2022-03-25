package Crypt::OpenSSL::EVP::MD;

use strict;
use warnings;
use Carp;

use vars qw( $VERSION @ISA );

use base qw(DynaLoader);

$VERSION = '0.01';

bootstrap Crypt::OpenSSL::EVP::MD $VERSION;

1;
__END__

