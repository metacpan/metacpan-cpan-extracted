#! perl
 
use strict;
use warnings;

use Test::More;

use Crypt::Bear::PEM 'pem_decode';
use Crypt::Bear::X509::Certificate;

open my $fh, '<', 't/server.key' or die $!;
my $content = do { local $/; <$fh> };
my ($name, $payload) = pem_decode($content);

is $name, 'PRIVATE KEY', 'First is certificate banner';
my $cert = eval { Crypt::Bear::X509::PrivateKey->new($payload) };
ok $cert, 'Can decode privateKey'; 

done_testing;

