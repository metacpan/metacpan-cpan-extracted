use Test::More;
use Crypt::OpenSSL::Verify;
use Crypt::OpenSSL::X509;
use File::Slurp qw(read_file);
use Test::Exception;

my $v = Crypt::OpenSSL::Verify->new('t/cacert.pem', { strict_certs => 0 });
ok($v);

my $text = read_file('t/cert-expired.pem');
like($text, qr/BhMCQ0ExFjAUBgNVBAgMDU5ldyBC/);

my $cert = Crypt::OpenSSL::X509->new_from_string($text);
ok($cert);

lives_ok(
    sub {
        $v->verify($cert);
    },
    'Default VerifyX509 function is that expired certs are trusted'
);

$v = Crypt::OpenSSL::Verify->new(
    't/cacert.pem',
    {
        CApath       => '/etc/ssl/certs',
        strict_certs => 0,
    }
);
ok($v);

lives_ok(
    sub {
        $v->verify($cert);
    },
    'Verify Expired is not an error without strict_certs',
);

$v = Crypt::OpenSSL::Verify->new(
    't/cacert.pem',
    {
        CApath       => '/etc/ssl/certs',
        strict_certs => 1
    }
);

throws_ok(
    sub {
        $v->verify($cert);
    },
    qr/(?:verify: certificate has expired)|(?:verify: unknown certificate verification error)/,
    'Verify Expired is an error with strict_certs',
);

done_testing;
