#! perl
 
use strict;
use warnings;

use Test::More;

use Crypt::Bear::PEM ':all';
use Crypt::Bear::X509::Certificate;
use Crypt::Bear::PEM::Decoder;

for my $file (glob 't/vTrus*.pem') {
	subtest "Processing $file synchronously", sub {
		plan tests => 4;

		open my $fh, '<', $file or die $!;
		my $content = do { local $/; <$fh> };
		my ($name, $payload) = pem_decode($content);

		is $name, 'CERTIFICATE', 'First is certificate banner';
		my $cert = eval { Crypt::Bear::X509::Certificate->new($payload) };
		ok $cert, 'Can decode certificate'; 
		like $cert->dn, qr/vTrus/, 'dn contains the right word';
		ok $cert->public_key, 'Has a public key';
	};
}

for my $file (glob 't/vTrus*.pem') {
	subtest "Processing $file asynchronously", sub {
		plan tests => 5;

		my @entries;
		my $decoder = Crypt::Bear::PEM::Decoder->new(sub { push @entries, @_ });
		open my $fh, '<', $file or die $!;
		my @lines = <$fh>;
		$decoder->push($_) for @lines;

		is @entries, 2, 'Got two entries';
		is $entries[0], 'CERTIFICATE', 'First is certificate banner';
		my $cert = eval { Crypt::Bear::X509::Certificate->new($entries[1]) };
		ok $cert, 'Can decode certificate'; 
		like $cert->dn, qr/vTrus/, 'dn contains the right word';
		ok $cert->public_key, 'Has a public key';
	};
}

done_testing;
