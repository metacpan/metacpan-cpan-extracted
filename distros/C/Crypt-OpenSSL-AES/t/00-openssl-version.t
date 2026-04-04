use strict;
use warnings;
use Crypt::OpenSSL::Guess qw(find_openssl_exec find_openssl_prefix);
use Test::More tests => 1;

my $openssl = find_openssl_exec(find_openssl_prefix());
ok($openssl, "Found OpenSSL full path");
if ($openssl) {
    my $version = `$openssl version`;
    diag($version);
} else {
    warn "Unable to find openssl";
}
