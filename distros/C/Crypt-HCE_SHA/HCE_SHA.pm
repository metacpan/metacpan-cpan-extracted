#
# Crypt::HCE_SHA
# implements one way hash chaining encryption using SHA
#
# $Id: HCE_SHA.pm,v 1.3 2000/02/19 03:47:11 eric Exp $
#

package Crypt::HCE_SHA;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

use Digest::SHA;
use MIME::Base64;
use Carp;

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(

);
$VERSION = '0.75';


sub new {
    my $class = shift;
    my $self = {};

    bless $self, $class;

    if ((@_ != 2) && (@_ != 3)) {
        croak "Error: must be invoked HCE_SHA->new(key, random_thing, [algorithm to use (1, 224, 256, 384, 512)])";
    }

    $self->{SKEY} = shift(@_);
    $self->{RKEY} = shift(@_);
    if (@_ > 0) {
        $self->{BITS} = shift(@_);
    } else {
        $self->{BITS} = 1;
   }

    return $self;
}

sub _new_key {
    my $self = shift;
    my ($rnd) = @_;

    my $context = new Digest::SHA->new($self->{BITS});
    $context->add($self->{SKEY}, $rnd);
    my $digest = $context->digest();
    my @e_block = unpack('C*', $digest);
    return @e_block;
}

sub hce_block_encrypt {
    my $self = shift;
    my ($data) = @_;
    my ($i, $key, $data_size, $ans, $mod, @e_block, @data, @key, @ans);

    @key = unpack ('C*', $self->{SKEY});
    @data = unpack ('C*', $data);

    undef @ans;
    @e_block = $self->_new_key($self->{RKEY});
    $data_size = scalar(@data);
    for($i=0; $i < $data_size; $i++) {
        $mod = $i % 20;
        if (($mod == 0) && ($i > 19)) {
            @e_block = $self->_new_key(pack 'C*', (@ans)[($i-20)..($i-1)]);
        }
        $ans[$i] = $e_block[$mod] ^ $data[$i];
    }
    $ans = pack 'C*', @ans;
    return $ans;
}

sub hce_block_decrypt {
    my $self = shift;
    my ($data) = @_;
    my ($i, $key, $data_size, $ans, $mod, @e_block, @data, @key, @ans);

    @key = unpack ('C*', $self->{SKEY});
    @data = unpack ('C*', $data);

    undef @ans;
    @e_block = $self->_new_key($self->{RKEY});
    $data_size = scalar(@data);
    for($i=0; $i < $data_size; $i++) {
        $mod = $i % 20;
        if (($mod == 0) && ($i > 19)) {
            @e_block = $self->_new_key(pack 'C*', (@data)[($i-20)..($i-1)]);
        }
        $ans[$i] = $e_block[$mod] ^ $data[$i];
    }
    $ans = pack 'C*', @ans;
    return $ans;
}

sub hce_block_encode_mime {
    my $self = shift;
    my ($data) = @_;

    my $new_data = $self->hce_block_encrypt($data);
    my $encode = encode_base64($new_data, "");
    return $encode;
}

sub hce_block_decode_mime {
    my $self = shift;
    my ($data) = @_;

    my $decode = decode_base64($data);
    my $new_data = $self->hce_block_decrypt($decode);
    return $new_data;
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__


=head1 NAME

Crypt::HCE_SHA - Perl extension implementing one way hash chaining encryption using SHA

=head1 SYNOPSIS

  use Crypt::HCE_SHA;

  $hce_sha = Crypt::HCE_SHA->new("SharedSecret", "Random01,39j309ad");

  $crypted = $hce_sha->hce_block_encrypt("Encrypt this information");
  $info = $hce_sha->hce_block_decrypt($crypted);

  $mime_crypted = $hce_sha->hce_block_encode_mime("Encrypt and Base64 this information");
  $info = $hce_sha->hce_block_decode_mime($mime_crypted);

  $hce_sha = Crypt::HCE_SHA->new("key", "random", 256);  # use SHA256 instead of SHA1

=head1 DESCRIPTION

This module implements a chaining block cipher using a one way hash.  This method of encryption is the same that is used by radius (RFC2138) and is also described in Applied Cryptography.

Two interfaces are provided in the module.  The first is straight block encryption/decryption the second does base64 mime encoding/decoding of the encrypted/decrypted blocks.

The idea is the the two sides have a shared secret that supplies one of the keys and a randomly generated block of bytes provides the second key.  The random key is passed in cleartext between the two sides.

An example client and server are packaged as modules with this module.  They are used in the tests. They can be found in the examples directory.

Thanks to Jake Angerman for the bug report on the bug in key generation for the chaining portion of the algorithm

=head1 AUTHOR

Eric Estabrooks, eric@urbanrage.com

=head1 SEE ALSO

perl(1).

=cut
