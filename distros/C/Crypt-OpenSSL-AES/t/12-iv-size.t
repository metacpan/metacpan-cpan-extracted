use strict;
use warnings;
use Test::More tests => 5;
BEGIN { use_ok('Crypt::OpenSSL::AES') };

my $key    = "e4e9ac6aa161179889f0e3804d187112f59f3325950a27d943be398074968afc";

my $iv     = "4b2e6d920c60f1212c07c2e4d7ce6776";
my $iv_len = length(pack("H*", $iv));
my $c;
eval {
    $c = Crypt::OpenSSL::AES->new(pack("H*", $key),
        {
            cipher   => 'AES-256-CBC',
            iv          => pack("H*", $iv),
            padding     => 1,
        });
};
ok(!$@, "Valid IV Length $iv_len as expected");
isa_ok($c, 'Crypt::OpenSSL::AES');

$iv     = "4b2e6d920c60f1212c07c2e4d7ce6776c";
eval {
    $c = Crypt::OpenSSL::AES->new(pack("H*", $key),
            {
                cipher   => 'AES-256-CBC',
                iv          => pack("H*", $iv),
                padding     => 1,
            });
};
like($@, qr/Invalid IV length/, "Invalid IV Length $iv_len as expected");

$iv     = "4b2e6d920c60f1212c07c2e4d7ce";
$iv_len = length(pack("H*", $iv));

eval {
    $c = Crypt::OpenSSL::AES->new(pack("H*", $key),
            {
                cipher   => 'AES-256-CBC',
                iv          => pack("H*", $iv),
                padding     => 1,
            });
};
like($@, qr/Invalid IV length/, "Invalid IV Length $iv_len as expected");
