# $Id: OpenSSH.pm,v 1.1 2001/07/11 03:28:48 btrott Exp $

package Crypt::Keys::Public::RSA::OpenSSH;
use strict;

use Crypt::Keys::Buffer;
use MIME::Base64 qw( encode_base64 decode_base64 );

use constant KEY_TYPE => 'ssh-rsa';

sub deserialize {
    my $class = shift;
    my %param = @_;
    my($key_type, $blob, $comment) = split /\s+/, $param{Content};
    return $class->error("Incorrect key type")
        unless $key_type eq KEY_TYPE;
    my $b = Crypt::Keys::Buffer->new( MP => 'OpenSSH' );
    $b->append(decode_base64($blob));
    my $ktype = $b->get_str;
    return $class->error("Key types do not match") unless $ktype eq $key_type;
    { e => $b->get_mp_int, n => $b->get_mp_int };
}

sub serialize {
    my $class = shift;
    my %param = @_;
    my $data = $param{Data};
    my $b = Crypt::Keys::Buffer->new( MP => 'OpenSSH' );
    $b->put_str(KEY_TYPE);
    $b->put_mp_int($data->{e});
    $b->put_mp_int($data->{n});
    join(' ', KEY_TYPE, encode_base64($b->bytes, '')) . "\n";
}

1;
