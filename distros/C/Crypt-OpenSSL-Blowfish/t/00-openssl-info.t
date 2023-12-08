use Test2::V0;
my $openssl = `openssl version`;
$openssl =~ /.*(openssl|LibreSSL).*/i;
like ($openssl, qr/openssl|LibreSSL/i, "$1 found", $openssl);
diag($openssl);

done_testing;
