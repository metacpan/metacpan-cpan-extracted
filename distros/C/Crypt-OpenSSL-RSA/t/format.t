use strict;
use Test;

use Crypt::OpenSSL::RSA;

BEGIN { plan tests => 19 }

my $PRIVATE_KEY_STRING = <<EOF;
-----BEGIN RSA PRIVATE KEY-----
MBsCAQACAU0CAQcCASsCAQcCAQsCAQECAQMCAQI=
-----END RSA PRIVATE KEY-----
EOF

my $PUBLIC_KEY_PKCS1_STRING = <<EOF;
-----BEGIN RSA PUBLIC KEY-----
MAYCAU0CAQc=
-----END RSA PUBLIC KEY-----
EOF

my $PUBLIC_KEY_X509_STRING = <<EOF;
-----BEGIN PUBLIC KEY-----
MBowDQYJKoZIhvcNAQEBBQADCQAwBgIBTQIBBw==
-----END PUBLIC KEY-----
EOF

# openssl genrsa -des3 -passout pass:123456 1024
my $ENCRYPT_PRIVATE_KEY_STRING = <<EOF;
-----BEGIN RSA PRIVATE KEY-----
Proc-Type: 4,ENCRYPTED
DEK-Info: DES-EDE3-CBC,319C89EE262DB309

FPj3QbILNMiDvpoSkA38WZnjvjH+c2b5lKdge0mXJu2k3ZnbM+D51RL/iCTbItsU
Pgw1pjB7w2pkapSwdwzOwbsaiznLF9S8fj4XxDYWuWAlPGAwk6GA8YxAaCIbpSkr
QdJoDAsdaIBj1JA73C8HCtnw7h5dN3VLZfwmJVcFeSddz1S5MgN5tgD6YyIhdVwe
0tlQ3Jk4/j80MzgBoJlkKccVurnUVUKw6S5RkVd91tAj7WXlqepuGV4a1X4JtFpV
KUNlNt8Hrnf6zq5mNqHqLtXtDpVWj9zW7FIYFqXiq37VKr5qJ8s8RI/ACQK2q7E/
rJTXqoZFg2fpVW4CDO1Rpm3HF3k8hzCpVFYHHI6j0qmLl7YY5aSKUqFaVIv3O9so
w/dXO1jWLxiQH1rijl1GBdg86012CtT5hwQbetUjo2leaq5hxdHo0ynXM0Q8aYPU
I/QUGJvDW5gHE0n6aKQxfWq9OfhraqBKF/SA6S7aHdk7lrjsJPAxa0IGJfO0O471
SjXj6HHuL376r0KQmDAO4qXpckzfthztwRqDGpdStTVdD+iDOD7NbRW5OJZTvjvM
/866bpy5py65E6DtQJDAi2NHwQHbV4KEGlocavJybQ7Smaf2JSOMg4DKRwyIQucw
KdgWUX1Brg70pd8Zr/iGpvE1I7bBWzNbwGbO51srKD+0uZMBz3dwJ0iVrbBInSFW
UOviCyfFSHIyA5gWxi7ccQYfFj71FH5//4dJOLlh1FtNEYaNod57jE9yDtUPEunQ
Kg+us0d7vFPttZ5QfBq5yP1povSTgITcXLjjkBxJVvqH0exmSIA22w==
-----END RSA PRIVATE KEY-----
EOF

my $DECRYPT_PRIVATE_KEY_STRING = <<EOF;
-----BEGIN RSA PRIVATE KEY-----
MIICXQIBAAKBgQC9KazkIUqBOg6QBQJTItC5XBhQYyf+ohQZHsQ/f1URKOYtqsv9
VtKBSxc7ObSw9ctWEca8VWqqV2Xfmika5XCC/t91Sx8QLO9UAO2ycQeHSFjoYZ18
ch4Ostgmkbr1blbEDPCFCyIJFb3UzhX5raCIfIByWOvtkXKWuKDkPZD6VQIDAQAB
AoGBALxoFP7HtciOhdCmXJFnfNMSSllO2ZgB4NjATyEbdyP3Q4O6uSCkaFhE7Wec
6z7SIeuhGvuca/grwpj6l/RlEDCBYWk1JXJCAvnJkoBCwW70thOXFJ0gDfrJq3Co
GWntC/fdkv6HJx1axQF3xn9oDVHIn0fscS7D6FzN1jwSgRLhAkEA7kJt09/OlUnY
pV/9iVvswnnSsxEanoLchzA1bAaDNa9vkIU/BrFwQO9ctw+RQbHrvc/5KPbZoGsq
bfQ/wOXUnQJBAMs/ZGlziX19lOEGfziugMR33ybLxkBS7qcrpBebAED/8etijASp
LgMEOKeRz11WAVJJ5A4wi1yxD4fnBxp44xkCQG4RejNbPVByYQdlJPeD5Aijxta6
nBWGVuKNPuC80XjHpz6Yj9lDt5wH+EkJhA1ZaJKztWNbRoZ5e4x4PcubYXECQHA0
KubcVcblkU85Gvrbu1K7KoJsdKIGJqI7QXeWpmk74v4jhVD9ZN1dczlvEZ9hX5Fi
IXiD7Cvbw8svC4jdu+ECQQCw1ZlQPz2rGE+pFQiKOFPprH+pT+zkINh1d83jeMYd
GG7hKgfQB5J/B0u8/XzEtGnCq8m0xTADx2eplIoKhAFi
-----END RSA PRIVATE KEY-----
EOF

my ( $private_key, $public_key, $private_key2 );

ok( $private_key = Crypt::OpenSSL::RSA->new_private_key($PRIVATE_KEY_STRING) );
ok( $PRIVATE_KEY_STRING eq $private_key->get_private_key_string() );
ok( $PUBLIC_KEY_PKCS1_STRING eq $private_key->get_public_key_string() );
ok( $PUBLIC_KEY_X509_STRING eq $private_key->get_public_key_x509_string() );

ok( $public_key = Crypt::OpenSSL::RSA->new_public_key($PUBLIC_KEY_PKCS1_STRING) );
ok( $PUBLIC_KEY_PKCS1_STRING eq $public_key->get_public_key_string() );
ok( $PUBLIC_KEY_X509_STRING eq $public_key->get_public_key_x509_string() );

ok( $public_key = Crypt::OpenSSL::RSA->new_public_key($PUBLIC_KEY_X509_STRING) );
ok( $PUBLIC_KEY_PKCS1_STRING eq $public_key->get_public_key_string() );
ok( $PUBLIC_KEY_X509_STRING eq $public_key->get_public_key_x509_string() );

my $passphase = '123456';
ok( $private_key = Crypt::OpenSSL::RSA->new_private_key($ENCRYPT_PRIVATE_KEY_STRING, $passphase) );
ok( $DECRYPT_PRIVATE_KEY_STRING eq $private_key->get_private_key_string() );
ok( $private_key = Crypt::OpenSSL::RSA->new_private_key($DECRYPT_PRIVATE_KEY_STRING) );
ok( $private_key2 = Crypt::OpenSSL::RSA->new_private_key($private_key->get_private_key_string($passphase), $passphase) );
ok( $DECRYPT_PRIVATE_KEY_STRING eq $private_key2->get_private_key_string() );
ok( $private_key2 = Crypt::OpenSSL::RSA->new_private_key($private_key->get_private_key_string($passphase, 'des3'), $passphase) );
ok( $DECRYPT_PRIVATE_KEY_STRING eq $private_key2->get_private_key_string() );
ok( $private_key2 = Crypt::OpenSSL::RSA->new_private_key($private_key->get_private_key_string($passphase, 'aes-128-cbc'), $passphase) );
ok( $DECRYPT_PRIVATE_KEY_STRING eq $private_key2->get_private_key_string() );