#$Id: SSH1.pm,v 1.5 2002/02/16 18:24:16 btrott Exp $

package Crypt::Keys::Private::RSA::SSH1;
use strict;

use constant PRIVKEY_ID => "SSH PRIVATE KEY FILE FORMAT 1.1\n";

use vars qw( %CIPHERS );
BEGIN {
    %CIPHERS = (
        1 => undef,    ## IDEA: requires CFB
        2 => sub {     ## DES
                 require Crypt::DES;
                 Crypt::CBC->new(
                            Cipher => Crypt::DES->new(substr $_[0], 0, 8),
                            IV     => chr(0)x8,
                       );
             },
        3 => sub {     ## 3DES
                 Crypt::Keys::Private::RSA::SSH1::DES3->new($_[0]);
             },
    );
}

use Crypt::CBC;
use Digest::MD5 qw( md5 );
use Crypt::Keys::Util qw( bitsize mod_inverse );
use Crypt::Keys::Buffer;

use Crypt::Keys::ErrorHandler;
use base qw( Crypt::Keys::ErrorHandler );

sub deserialize {
    my $class = shift;
    my %param = @_;
    my $blob = $param{Content};
    my $passphrase = $param{Passphrase} || '';

    my $buffer = Crypt::Keys::Buffer->new(MP => 'SSH1');
    $buffer->append($blob);

    my $id = $buffer->bytes(0, length(PRIVKEY_ID), '');
    return $class->error("Bad key file format")
        unless $id eq PRIVKEY_ID;
    $buffer->bytes(0, 1, '');

    my $data = {};

    my $cipher_type = $buffer->get_int8;
    $buffer->get_int32;   ## Reserved data.

    $buffer->get_int32;   ## Private key bits.
    $data->{n} = $buffer->get_mp_int;
    $data->{e} = $buffer->get_mp_int;

    $data->{comment} = $buffer->get_str;

    if ($cipher_type != 0) {     ## No encryption.
        my $code = $CIPHERS{$cipher_type} or
            return $class->error("Unknown cipher '$cipher_type' in key file");
        my $cipher;
        eval { $cipher = $code->(md5($passphrase)) };
        if ($@ || !$cipher) {
            return $class->error("Unsupported cipher '$cipher_type': $@");
        }
        my $decrypted = $cipher->decrypt($buffer->bytes($buffer->offset));
        $buffer->empty;
        $buffer->append($decrypted);
    }

    my $check1 = $buffer->get_int8;
    my $check2 = $buffer->get_int8;
    unless ($check1 == $buffer->get_int8 &&
            $check2 == $buffer->get_int8) {
        return $class->error("Bad passphrase supplied for key file");
    }

    $data->{d} = $buffer->get_mp_int;
    $buffer->get_mp_int;  ## u: don't need it
    $data->{p} = $buffer->get_mp_int;
    $data->{q} = $buffer->get_mp_int;

    $data->{dp} = $data->{d} % ($data->{p}-1);
    $data->{dq} = $data->{d} % ($data->{q}-1);

    $data->{iqmp} = mod_inverse($data->{q}, $data->{p});

    $data;
}

sub serialize {
    my $class = shift;
    my %param = @_;
    my $passphrase = $param{Passphrase} || '';
    my $cipher_type = $passphrase eq '' ? 0 :
        $param{Cipher} || 3;
 
    my $buffer = Crypt::Keys::Buffer->new(MP => 'SSH1');
    my($check1, $check2);
    $buffer->put_int8($check1 = int rand 255);
    $buffer->put_int8($check2 = int rand 255);
    $buffer->put_int8($check1);
    $buffer->put_int8($check2);

    my $data = $param{Data};
    $data->{u} = mod_inverse($data->{p}, $data->{q});

    $buffer->put_mp_int($data->{d});
    $buffer->put_mp_int($data->{u});
    $buffer->put_mp_int($data->{p});
    $buffer->put_mp_int($data->{q});

    $buffer->put_int8(0)
        while $buffer->length % 8;

    my $encrypted = Crypt::Keys::Buffer->new(MP => 'SSH1');
    $encrypted->put_chars(PRIVKEY_ID);
    $encrypted->put_int8(0);
    $encrypted->put_int8($cipher_type);
    $encrypted->put_int32(0);

    $encrypted->put_int32(bitsize($data->{n}));
    $encrypted->put_mp_int($data->{n});
    $encrypted->put_mp_int($data->{e});
    $encrypted->put_str($param{Comment} || '');

    if ($cipher_type) {
## xxx this is currently hard-coded to only use 3DES
        my $cipher =
            Crypt::Keys::Private::RSA::SSH1::DES3->new(md5($passphrase));
        $encrypted->append( $cipher->encrypt($buffer->bytes) );
    }
    else {
        $encrypted->append($buffer->bytes);
    }
    
    $encrypted->bytes;
}

package Crypt::Keys::Private::RSA::SSH1::DES3;
use strict;

use Crypt::CBC;
use Crypt::DES;

sub new {
    my $class = shift;
    my $cipher = bless {}, $class;
    $cipher->init(@_) if @_;
    $cipher;
}

sub init {
    my $cipher = shift;
    my($key) = @_;
    for my $i (1..3) {
        my $this_key = $i == 3 && length($key) <= 16 ?
            substr $key, 0, 8 :
            substr $key, 8*($i-1), 8;
        $cipher->{"cbc$i"} = Crypt::CBC->new({
                  key => $this_key,
                  cipher => 'Crypt::DES',
                  regenerate_key => 0,
                  iv => chr(0)x8,
                  prepend_iv => 0,
             });
    }
}

sub encrypt {
    my($cipher, $text) = @_;
    $cipher->{cbc3}->encrypt(
        $cipher->{cbc2}->decrypt(
            $cipher->{cbc1}->encrypt($text)
        )
    );
}

sub decrypt {
    my($cipher, $text) = @_;
    $cipher->{cbc1}->decrypt(
        $cipher->{cbc2}->encrypt(
            $cipher->{cbc3}->decrypt($text)
        )
    );
}

sub keysize { 8 }
sub blocksize { 8 }

1;
