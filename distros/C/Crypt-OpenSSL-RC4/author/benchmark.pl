use strict;
use warnings;
use Benchmark qw/timethese/;
use Crypt::RC4 ();
use Crypt::RC4::XS ();
use Crypt::OpenSSL::RC4 ();

my $pass = 'hoge' x 100;
my $text = 'fuga' x 100;

timethese(
    10000 => {
        'pp' => sub {
            Crypt::RC4::RC4($pass, $text);
        },
        'xs' => sub {
            Crypt::RC4::XS::RC4($pass, $text);
        },
        'openssl' => sub {
            Crypt::OpenSSL::RC4::RC4($pass, $text);
        }
    }
);

timethese(
    300000 => {
        'xs' => sub {
            Crypt::RC4::XS::RC4($pass, $text);
        },
        'openssl' => sub {
            Crypt::OpenSSL::RC4::RC4($pass, $text);
        }
    }
);
