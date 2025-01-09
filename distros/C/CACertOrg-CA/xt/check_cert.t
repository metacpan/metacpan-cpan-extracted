#!perl
use strict;
use warnings;

use File::Spec::Functions qw(catfile);
use File::Temp;
use HTTP::Tiny;
use Test::More;
use Data::Dumper;

=encoding utf8

=head1 NAME

xt/check_cert.t - discover when the root cert is out of date

=head1 SYNOPSIS

Run this on its own:

	% perl xt/check_cert.t

Or part of all the author checks:

	% prove xt

=head1 DESCRIPTION

This module distributes the root cert for CACert, and this test checks
what's current on their page and if the one in this repo matches.

Run as a scheduled GitHub Action (or some other means) lets us detect
when the root cert may have been updated.

=cut
SKIP:{
skip "Need v5.10 or later for Digest::SHA" unless $] >= '5.010';

require Digest::SHA;

my $version = `openssl version`;
diag $version;

skip "Need openssl for this test" unless $version =~ /OpenSSL/x;

my( $expected_sha1, $expected_sha256 );
subtest 'expected values' => sub {
	my $url = 'http://www.cacert.org/index.php?id=3';
	my $response = HTTP::Tiny->new->get($url);
	my $html = $response->{content};

	($expected_sha1  ) = map { uc } $html =~ m|<li>SHA1 fingerprint: (.*?)</li>|;
	($expected_sha256) = map { uc } $html =~ m|<li>SHA256 fingerprint: (.*?)</li>|;

	$expected_sha1   =~ s/\s+//g;
	$expected_sha256 =~ s/\s+//g;

	like $expected_sha1,   qr/[A-F0-9]{32}/, 'SHA1 looks like it should';
	like $expected_sha256, qr/[A-F0-9]{64}/, 'SHA256 looks like it should';

	diag "SHA1: $expected_sha1";
	diag "SHA256: $expected_sha256";
	};

my $der;
subtest 'remote DER' => sub {
	$der = get_remote_der();
	ok defined $der, 'DER is defined';

	my $der_sha1   = uc Digest::SHA::sha1_hex($der);
	my $der_sha256 = uc Digest::SHA::sha256_hex($der);

	is $der_sha1,   $expected_sha1,   'SHA1 for DER matches';
	is $der_sha256, $expected_sha256, 'SHA256 for DER matches';
	};

my( $pem_sha1, $pem_sha256 );
subtest 'PEM from DER' => sub {
	my $pem = convert_der_to_pem($der);
	like $pem, qr/\A-----BEGIN CERTIFICATE-----/, 'saw start sequence';
	like $pem, qr/-----END CERTIFICATE-----\n\z/, 'saw end sequence';

	$pem_sha1   = uc Digest::SHA::sha1_hex($pem);
	$pem_sha256 = uc Digest::SHA::sha256_hex($pem);
	};

subtest 'current and dist PEM' => sub {
	my $dist_pem    = get_local_pem();
	like $dist_pem, qr/\A-----BEGIN CERTIFICATE-----/, 'saw start sequence';
	like $dist_pem, qr/-----END CERTIFICATE-----\n\z/, 'saw end sequence';
	my $dist_sha1   = uc Digest::SHA::sha1_hex($dist_pem);
	my $dist_sha256 = uc Digest::SHA::sha256_hex($dist_pem);

	is $pem_sha1,   $dist_sha1,   'SHA1 for PEM matches';
	is $pem_sha256, $dist_sha256, 'SHA256 for PEM matches';
	};
}

done_testing();

sub get_remote_der {
	my $url = 'http://www.cacert.org/certs/root_X0F.der';
	my $response = HTTP::Tiny->new->get($url);
	is $response->{status}, '200', 'fetched DER' or do {
		done_testing();
		exit(1);
		};
	my $der = $response->{content};
	}

sub get_local_pem {
	my $file = catfile( qw( lib CACertOrg CA root.crt ) );
	open my $pem_fh, '<:raw', $file or die "Could not open $file: $!";
	my $dist_pem = do { local $/; <$pem_fh> };
	}

sub convert_der_to_pem {
	my( $der ) = @_;

	my @command = qw( openssl x509  -inform der -out - );

	use IPC::Open2;
	my $pid = open2(my $child_out, my $child_in, @command );
	print { $child_in } $der;
	close $child_in;

	my $pem = do { local $/; <$child_out> };
	$pem =~ s/\r\n/\n/g;

	return $pem;
	}

