#! perl

use strict;
use warnings;

use Test::More;

use Crypt::OpenSSL3::SSL;

my $context = Crypt::OpenSSL3::SSL::Context->new;
ok $context->load_verify_file('t/server.crt');

my $client = Crypt::OpenSSL3::SSL->new($context);
$client->set_verify(Crypt::OpenSSL3::SSL::VERIFY_PEER);
ok $client->set_tlsext_host_name('server');
ok $client->set_host('server');

my $server = Crypt::OpenSSL3::SSL->new($context);
ok $server->use_PrivateKey_file('t/server.key', Crypt::OpenSSL3::SSL::FILETYPE_PEM);
ok $server->use_certificate_chain_file('t/server.crt');

my ($left, $right) = Crypt::OpenSSL3::BIO->new_bio_pair(4096, 4096);
ok $left;
ok $right;
$client->set_rbio($left);
$client->set_wbio($left);
$server->set_rbio($right);
$server->set_wbio($right);

my $r1 = $client->connect;
is $r1, -1;
is $client->get_error($r1), Crypt::OpenSSL3::SSL::ERROR_WANT_READ;
is $left->pending, 0;
cmp_ok $right->pending, '>', 0;

my $r2 = $server->accept;
is $r2, -1;
cmp_ok $left->pending, '>', 0;
is $right->pending, 0;
is $server->get_error($r2), Crypt::OpenSSL3::SSL::ERROR_WANT_READ;

is $client->connect, 1;
my $verify = $client->get_verify_result;
ok $verify->ok or diag $verify->error_string;

is $server->accept, 1;

cmp_ok $client->write("Hello, World!"), '>', 0;

is $server->read(my $res1, 15), 13;

is $res1, 'Hello, World!';

done_testing;
