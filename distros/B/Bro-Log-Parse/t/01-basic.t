use 5.10.1;
use strict;
use warnings;

use Test::More tests=>27;

BEGIN { use_ok( 'Bro::Log::Parse' ); }

my $parse = Bro::Log::Parse->new('logs/ssl.log');
my $line = $parse->getLine();
is(scalar keys %$line, 20, "Number of entries");
is($line->{ts}, '1394747126.855035', "ts");
is($line->{uid}, 'CXWv6p3arKYeMETxOg', "uid");
is($line->{'id.orig_h'}, '192.168.4.149', "id.orig_h");
is($line->{'id.orig_p'}, 60623, "id.orig_p");
is($line->{'id.resp_h'}, '74.125.239.129', "id.resp_h");
is($line->{'id.resp_p'}, 443, "id.resp_p");
ok(!defined($line->{server_name}), "undef server_name");
ok(exists($line->{server_name}), "existing server_name");
is($line->{version}, 'TLSv12', "version");
is($line->{cipher}, 'TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256', "cipher");
is($line->{curve}, 'secp256r1', "curve");
is($line->{server_name}, undef, "server_name");
is($line->{resumed}, 'F', "resumed");
is($line->{last_alert}, undef, "last_alert");
is($line->{next_protocol}, undef, "next_protocol");
is($line->{established}, 'T', "established");
is($line->{cert_chain_fuids}, 'FlaIzV19yTmBYwWwc6,F0BeiV3cMsGkNML0P2,F6PfYi2WUoPdIJrhpg', "cert_chain_fuids");
is(scalar @{$line->{client_cert_chain_fuids}}, 0, "client_cert_chain_fuids");
is($line->{subject}, 'CN=*.google.com,O=Google Inc,L=Mountain View,ST=California,C=US', "subject");
is($line->{issuer}, 'CN=Google Internet Authority G2,O=Google Inc,C=US', "issuer");
is($line->{client_subject}, undef, "client_subject");
is($line->{client_issuer}, undef, "client_issuer");

$line = $parse->getLine();
is(scalar keys %$line, 20, "Number of entries");
is($line->{uid}, 'CjhGID4nQcgTWjvg4c', "uid");

$line = $parse->getLine();
is($line, undef, 'EOF');
