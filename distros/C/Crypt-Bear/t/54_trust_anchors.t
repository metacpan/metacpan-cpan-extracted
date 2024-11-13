#! perl
 
use strict;
use warnings;

use Test::More;

use Crypt::Bear::PEM 'pem_decode';
use Crypt::Bear::X509::Certificate;
use Crypt::Bear::X509::TrustAnchors;

my $trusted = Crypt::Bear::X509::TrustAnchors->new;

for my $file (glob 't/*.pem') {
	open my $fh, '<', $file or die $!;
	my $content = do { local $/; <$fh> };
	my ($name, $payload) = pem_decode($content);

	is $name, 'CERTIFICATE', 'First is certificate banner';
	my $cert = eval { Crypt::Bear::X509::Certificate->new($payload) };
	ok $cert, 'Can decode certificate'; 

	$trusted->add($cert, 1)
}

is $trusted->count, 2;

my $second = Crypt::Bear::X509::TrustAnchors->new;
is $second->count, 0;
$second->merge($trusted);
is $second->count, 2;

if (eval { require Mozilla::CA }) {
	my $third = Crypt::Bear::X509::TrustAnchors->new;
	$third->load_file(Mozilla::CA::SSL_ca_file());
	ok $third->count;
	note 'Mozilla gives us ' . $third->count . ' entries';
}

done_testing;
