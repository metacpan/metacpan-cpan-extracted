package Crypt::OpenSSL::EVP::MD::CTX;

use strict;
use warnings;
use Carp;

use Crypt::OpenSSL::EVP::MD;
use vars qw( @ISA );

require DynaLoader;
use base qw(DynaLoader);
bootstrap Crypt::OpenSSL::EVP::MD $Crypt::OpenSSL::MD::VERSION;

1;
__END__

=head1 NAME

Crypt::OpenSSL::EVP::MD::CTX -  OpenSSL EVP_MD_CTX

=head1 SYNOPSIS

  use Crypt::OpenSSL::EVP::MD::CTX;
  my $md_ctx = Crypt::OpenSSL::EVP::MD::CTX->new();

=head1 SEE ALSO

L<Crypt::OpenSSL::EVP::MD>

=cut
