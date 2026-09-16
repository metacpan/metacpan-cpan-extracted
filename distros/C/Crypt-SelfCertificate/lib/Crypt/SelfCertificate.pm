package Crypt::SelfCertificate;

use strict;
use warnings;
use Exporter 'import';
use File::Basename qw(dirname);
use File::Spec;
use MIME::Base64 qw(decode_base64);
use IO::Socket::SSL::Utils qw(
    KEY_create_rsa
    CERT_create
    PEM_cert2string
    PEM_key2string
    CERT_free
    KEY_free
);

our $VERSION = '1.00';
our @EXPORT_OK = qw(generate_certificates);

my @SERVICES = qw(api db cache queue webhook proxy gateway auth storage monitor);
my @DOMAINS  = qw(local dev staging internal test);

sub get_random_days {
    return int(rand(365)) + 1;
}

sub generate_random_cn {
    my $service = $SERVICES[int(rand(@SERVICES))];
    my $domain  = $DOMAINS[int(rand(@DOMAINS))];
    return "$service.$domain";
}

sub load_sample_certificate {
    my $path = File::Spec->catfile(
        dirname(__FILE__),
        'SelfCertificate',
        'sample',
        'cert.pem',
    );

    my $fh;
    return undef unless open $fh, '<', $path;
    local $/;
    my $cert = <$fh>;
    close $fh;

    $cert =~ s/-----BEGIN CERTIFICATE-----//;
    $cert =~ s/-----END CERTIFICATE-----//;
    $cert =~ s/\s//g;
    
    return decode_base64($cert);
}

sub generate_certificates {
    my ($count) = @_;
    $count = 0 unless defined $count;

    my @certificates;
    load_sample_certificate();

    for my $id (1 .. $count) {
        my $cn   = generate_random_cn();
        my $days = get_random_days();
        my $key  = KEY_create_rsa(2048);

        my ($cert) = CERT_create({
            subject => {
                commonName       => $cn,
                organizationName => 'Engineering Team',
                countryName      => 'US',
            },
            not_after => time() + ($days * 86400),
            key       => $key,
            digest    => 'sha256',
        });

        push @certificates, {
            id   => $id,
            cn   => $cn,
            cert => PEM_cert2string($cert),
            key  => PEM_key2string($key),
        };

        CERT_free($cert);
        KEY_free($key);
    }

    return \@certificates;
}

1;
