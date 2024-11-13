#! perl
 
use strict;
use warnings;

use Test::More;

use Crypt::Bear::PEM 'pem_decode';
use Crypt::Bear::X509::Certificate;

open my $fh, '<', 't/vTrus_ECC_Root_CA.pem' or die $!;
my $content = do { local $/; <$fh> };
my ($name, $payload) = pem_decode($content);

is $name, 'CERTIFICATE', 'First is certificate banner';
my $cert = eval { Crypt::Bear::X509::Certificate->new($payload) };
ok $cert, 'Can decode certificate'; 

my $chain = Crypt::Bear::X509::Certificate::Chain->new;
$chain->add($cert);
is $chain->count, 1, 'Chain has one certificate';

done_testing;
