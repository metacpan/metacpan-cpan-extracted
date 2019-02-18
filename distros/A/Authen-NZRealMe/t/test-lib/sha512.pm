package sha512;

use strict;
use warnings;

use Digest::SHA   qw(sha512);

our @ISA = Authen::NZRealMe->class_for('signer_algorithm');

use constant algorithm       => 'sha512';
use constant SignatureMethod => 'http://www.w3.org/2001/04/xmldsig-more#rsa-sha512';
use constant DigestMethod    => 'http://www.w3.org/2001/04/xmlenc#sha512';

sub encrypt { shift; sha512(@_); }

sub sign_options {
    my ($self, $rsa) = @_;

    $rsa->use_pkcs1_oaep_padding();
    $rsa->use_sha512_hash();

    return $rsa;
}

1;
