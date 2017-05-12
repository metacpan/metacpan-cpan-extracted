package Crypt::OpenSSL::Blowfish;

use strict;
use Carp;

use vars qw/$VERSION @ISA/;

require DynaLoader;
@ISA = qw/DynaLoader/;

$VERSION = '0.02';

bootstrap Crypt::OpenSSL::Blowfish $VERSION;

sub blocksize   {  8; }
sub keysize     {  0; }
sub min_keysize {  8; }
sub max_keysize { 56; }

sub new {
    my $self = {};
    bless $self, shift;
    $self->{ks} = Crypt::OpenSSL::Blowfish::init(shift);

    $self;
}

sub encrypt {
    my ($self, $data) = @_;

    Crypt::OpenSSL::Blowfish::crypt($data, $self->{ks}, 0);

    $data;
}

sub decrypt {
    my ($self, $data) = @_;

    Crypt::OpenSSL::Blowfish::crypt($data, $self->{ks}, 1);

    $data;
}

1;

__END__

=head1 NAME

Crypt::OpenSSL::Blowfish - Blowfish Algorithm using OpenSSL

=head1 SYNOPSIS

    use Crypt::OpenSSL::Blowfish;
    my $cipher = new Crypt::OpenSSL::Blowfish $key; 
    my $ciphertext = $cipher->encrypt($plaintext);
    $plaintext = $cipher->decrypt($ciphertext);

=head1 DESCRIPTION

Crypt::OpenSSL::Blowfish implements the Blowfish Algorithm using functions contained in the OpenSSL crypto library.
Crypt::OpenSSL::Blowfish has an interface similar to Crypt::Blowfish, but produces different result than Crypt::Blowfish.

=head1 SEE ALSO

L<Crypt::Blowfish>

http://www.openssl.org/

=head1 AUTHOR

Vitaly Kramskikh, E<lt>vkramskih@cpan.orgE<gt>

=cut
