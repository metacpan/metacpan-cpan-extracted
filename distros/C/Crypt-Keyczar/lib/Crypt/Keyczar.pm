package Crypt::Keyczar;
use base 'Exporter';
use strict;
use warnings;
use Carp;
use Crypt::Keyczar::FileReader;
use Crypt::Keyczar::KeyMetadata;
use Crypt::Keyczar::Key;


our $VERSION = 0.09;

use constant FORMAT_VERSION => 0;
use constant FORMAT_BYTES   => pack 'C', 0;
use constant KEY_HASH_SIZE  => 4;
use constant HEADER_SIZE    => 1 + 4;

our @EXPORT_OK = qw(FORMAT_VERSION FORMAT_BYTES KEY_HASH_SIZE HEADER_SIZE);


sub new {
    my $class = shift;
    my $reader = shift;

    if (UNIVERSAL::isa($reader, 'Crypt::Keyczar::Reader')) {
        return $class->_new($reader);
    }
    else {
        return $class->_new(Crypt::Keyczar::FileReader->new($reader));
    }
}


sub _new {
    my $class = shift;
    my $reader = shift;

    my $self = bless {
        metadata => undef,
        primary_version => undef,
        version_map => {},
        hash_map    => {},
    }, $class;

    $self->metadata(Crypt::Keyczar::KeyMetadata->read($reader->get_metadata()));
    for my $v ($self->metadata->get_versions) {
        next if !$v;
        if ($v->status eq 'PRIMARY') {
            if ($self->primary) {
                croak "duplicate primary key";
            }
            $self->primary($v);
        }
        my $key = Crypt::Keyczar::Key->read_key(
            $self->metadata->get_type(), $reader->get_key($v->get_number()));
        my $key_hash = Crypt::Keyczar::_KeyHash->new($key->hash());
        $self->{hash_map}->{$key_hash->hash_code()} = $key;
        $self->{version_map}->{$v->get_number()} = $key;
    }
    return $self;
}


sub metadata {
    my $self = shift;
    $self->{metadata} = shift if @_;
    return $self->{metadata};
}


sub primary  {
    my $self = shift;
    $self->{primary_version} = shift if  @_;
    return $self->{primary_version};
}


sub get_key_by_number {
    my $self = shift;
    my $num = shift;
    return $self->{version_map}->{$num};
}


sub get_key {
    my $self = shift;
    my $id = shift;
    if (ref $id && $id->isa('Crypt::Keyczar::KeyVersion')) {
        # find by KeyVersion
        return $self->{version_map}->{$id->get_number};
    }
    elsif (ref $id && $id->isa('Crypt::Keyczar::Key')) {
        return $self->{hash_map}->{$id->hash};
    }
    else {
        # find by hash code
        my $hash = Crypt::Keyczar::_KeyHash->new($id);
        return $self->{hash_map}->{$hash->hash_code};
    }
}


sub add_key {
    my $self = shift;
    my ($version, $key) = @_;

    my $hash = Crypt::Keyczar::_KeyHash->new($key->hash);
    $self->{hash_map}->{$hash->hash_code} = $key;
    $self->{version_map}->{$version->get_number} = $key;

    $self->metadata->add_version($version);
}


1;


package Crypt::Keyczar::_KeyHash;
use strict;
use warnings;
use Carp;


sub new {
    my $class = shift;
    my $data = shift;
    if (length $data != Crypt::Keyczar::KEY_HASH_SIZE()) {
        confess "is not keyczar hash";
    }
    my $self = bless \$data, $class;
    return $self;
}


sub equals {
    my $self = shift;
    my $obj = shift;
    return $obj->isa('Crypt::Keyczar::_KeyHash') && $obj->hash_code() == $self->hash_code();
}


sub hash_code {
    my $self = shift;
    return unpack 'N', $$self;
}

1;
__END__

=head1 NAME

Crypt::Keyczar - Keyczar is an open source cryptographic toolkit 

=head1 SYNOPSIS

  use Crypt::Keyczar::Crypter;
  
  my $crypter = Crypt::Keyczar::Crypter->new('/path/to/your/crypt/keys');
  my $cipher_text = $crypter->encrypt("Secret message);
  my $plain_text = $crypter->decrypt($cipher_text);


  use Crypt::Keyczar::Signer;
  
  my $signer = Crypt::Keyczar::Signer->new('/pat/to/your/sign/keys');
  my $sign = $signer->sign("Public message");
  $signer->verify('Public message', $sign) ? 'OK' : 'NG';

=head1 DESCRIPTION

Keyczar is an open source cryptographic toolkit designed to make it easier and
safer for devlopers to use cryptography in their applications. Keyczar supports
authentication and encryption with both symmetric and asymmetric keys. Some
features of Keyczar include:

=over 4

* A simple API

* Key rotation and versioning

* Safe default algorithms, modes, and key lengths

* Automated generation of initialization vectors and ciphertext signatures

* Perl, Java, Python, and C++ implementations

=back 4

=head1 SEE ALSO

L<bin/keyczar>,
L<Crypt::Keyczar::Crypter>,
L<Crypt::Keyczar::Signer>,
L<Crypt::Keyczar::FileReader>,
L<http://www.keyczar.org/>

=head1 AUTHOR

Hiroyuki OYAMA <oyama@mixi.co.jp>

=head1 LICENSE

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut
