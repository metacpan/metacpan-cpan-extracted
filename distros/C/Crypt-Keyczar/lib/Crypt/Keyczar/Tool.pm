package Crypt::Keyczar::Tool;

use strict;
use warnings;
use Crypt::Keyczar::Crypter;
use Crypt::Keyczar::FileReader;
use Crypt::Keyczar::KeyMetadata;
use Crypt::Keyczar::Manager;
use Crypt::Keyczar::Signer;
use Crypt::Keyczar::Util;
use Crypt::Keyczar::FileWriter;
use Carp;


sub new {
    my $class = shift;
    my $writer = shift;
    $writer ||= Crypt::Keyczar::FileWriter->new();
    return bless { writer => $writer }, $class;
}


sub writer { return $_[0]->{writer} }


sub create {
    my $self = shift;
    my ($location, $purpose, $opt) = @_;

    my $meta;
    if ($purpose eq 'sign') {
        if (!defined $opt->{asymmetric} && !defined $opt->{type}) {
            $meta = Crypt::Keyczar::KeyMetadata->new($opt->{name}, 'SIGN_AND_VERIFY', 'HMAC_SHA1');
        }
        elsif (!defined $opt->{asymmetric} && defined $opt->{type}) {
            $meta = Crypt::Keyczar::KeyMetadata->new($opt->{name}, 'SIGN_AND_VERIFY', $opt->{type});
        }
        elsif (uc $opt->{asymmetric} eq 'RSA') {
            $meta = Crypt::Keyczar::KeyMetadata->new($opt->{name}, 'SIGN_AND_VERIFY', 'RSA_PRIV');
        }
        else {
            $meta = Crypt::Keyczar::KeyMetadata->new($opt->{name}, 'SIGN_AND_VERIFY', 'DSA_PRIV');
        }
    }
    elsif ($purpose eq 'crypt') {
        if (defined $opt->{asymmetric}) {
            $meta = Crypt::Keyczar::KeyMetadata->new($opt->{name}, 'DECRYPT_AND_ENCRYPT', 'RSA_PRIV');
        }
        else {
            $meta = Crypt::Keyczar::KeyMetadata->new($opt->{name}, 'DECRYPT_AND_ENCRYPT', 'AES');
        }
    }
    else {
        croak 'unknonw purpose';
    }

    $self->writer->location($location);
    $self->writer->put_metadata($meta);
}


sub addkey {
    my $self = shift;
    my ($location, $status, $opt) = @_;

    my $kcz = Crypt::Keyczar::Manager->new($location);
    my $v = $kcz->add_version($status, $opt->{size});

    $self->writer->location($location);
    $self->writer->put_metadata($kcz->metadata);
    $self->writer->put_key($v->get_number, $kcz->get_key($v));
    return $v->get_number;
}


sub promote {
    my $self = shift;
    my ($location, $version) = @_;
    my $kcz = Crypt::Keyczar::Manager->new($location);
    $kcz->promote($version);
    $self->writer->location($location);
    $self->writer->put_metadata($kcz->metadata);
}


sub demote {
    my $self = shift;
    my ($location, $version) = @_;
    my $kcz = Crypt::Keyczar::Manager->new($location);
    $kcz->demote($version);
    $self->writer->location($location);
    $self->writer->put_metadata($kcz->metadata);
}


sub revoke {
    my $self = shift;
    my ($location, $version) = @_;
    my $kcz = Crypt::Keyczar::Manager->new($location);
    $kcz->revoke($version);
    $self->writer->location($location);
    $self->writer->put_metadata($kcz->metadata);
    if (!$self->writer->delete_key($version)) {
        croak "can't delete revoked key file: $location/$version: $!";
    }
}


sub pubkey {
    my $self = shift;
    my ($location, $destination) = @_;
    my $kcz = Crypt::Keyczar::Manager->new($location);
    my $private = $kcz->metadata;

    my $public;
    if ($private->get_type eq 'RSA_PRIV') {
        if ($private->get_purpose eq 'DECRYPT_AND_ENCRYPT') {
            $public = Crypt::Keyczar::KeyMetadata->new($private->get_name, 'ENCRYPT', 'RSA_PUB');
        }
        elsif ($private->get_purpose eq 'SIGN_AND_VERIFY') {
            $public = Crypt::Keyczar::KeyMetadata->new($private->get_name, 'VERIFY', 'RSA_PUB');
        }
        else {
            croak("unknown propose: ". $private->get_purpose);
        }
    }
    elsif ($private->get_type eq 'DSA_PRIV') {
        if ($private->get_purpose eq 'SIGN_AND_VERIFY') {
            $public = Crypt::Keyczar::KeyMetadata->new($private->get_name, 'VERIFY', 'DSA_PUB');
        }
        else {
            croak("unknown propose: ". $private->get_purpose);
        }
    }
    else {
        croak("not implement");
    }
    if (!$public) {
        croak("cannot export public key");
    }

    $self->writer->location($destination);
    for my $v ($private->get_versions) {
        if ($v) {
            my $p = $kcz->get_key($v)->get_public;
            $self->writer->put_key($v->get_number, $p);
        }
        $public->add_version($v);
    }
    $self->writer->put_metadata($public);
}


sub usekey {
    my $self = shift;
    my ($location, $message, $destination, $opt) = @_;

    my $reader = Crypt::Keyczar::FileReader->new($location);
    my $meta = Crypt::Keyczar::KeyMetadata->read($reader->get_metadata());
    my $result = '';
    if ($meta->get_purpose eq 'DECRYPT_AND_ENCRYPT') {
        my $crypter = Crypt::Keyczar::Crypter->new($reader);
        $result = $crypter->encrypt($message);
    }
    elsif ($meta->get_purpose eq 'SIGN_AND_VERIFY') {
        my $signer = Crypt::Keyczar::Signer->new($reader);
        $result = $signer->sign($message);
    }
    else {
        croak "unsupported purpose: ". $meta->get_purpose;
    }

    if ($destination) {
        open my $fh, '>', $destination
            or croak "cannot open destination file: $destination: $!";
        print $fh Crypt::Keyczar::Util::encode($result);
        close $fh;
    }
    else {
        print Crypt::Keyczar::Util::encode($result), "\n";
    }
}

1;
__END__
