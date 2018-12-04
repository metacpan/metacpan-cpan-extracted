#!/usr/bin/perl
# Update ./ca-certificates.crt using current Firefox CA bundle.
use warnings;
use strict;
use Crypt::MatrixSSL3;

use version 0.77 (); our $VERSION = 'v3.9.2';

## no critic (Capitalization, RequireCarping)

(my $path = $0) =~ s{[^/]*\z}{}ms;
system "\Q$path\Emk-ca-bundle.pl -u -f -p ALL:TRUSTED_DELEGATOR" and die "mk-ca-bundle.pl failed\n";
open my $f, '<', 'ca-bundle.crt' or die "open: $!";
undef $/;
my $bundle = <$f>;
close $f or die "close: $!";
unlink 'ca-bundle.crt' or die "unlink: $!";

Crypt::MatrixSSL3::Open();

open $f, '>', 'ca-certificates.crt' or die "open: $!"; ## no critic (RequireBriefOpen)
while ($bundle =~ /^(\S[^\n]*)\n=+\n(-----BEGIN CERTIFICATE-----\n.*?\n-----END CERTIFICATE-----\n)/msg) { ## no critic (ProhibitComplexRegexes)
    my ($name, $cert) = ($1, $2);
    open my $tmp, '>', 'temp.crt' or die "open: $!";
    print {$tmp} $cert;
    close $tmp or die "close: $!";
    my $keys = Crypt::MatrixSSL3::Keys->new();
    my $rc = $keys->load_rsa(undef, undef, undef, 'temp.crt');
    undef $keys;
    unlink 'temp.crt';
    printf "%s %s\n", ($rc == PS_SUCCESS ? 'Adding' : 'Ignoring'), $name;
    if ($rc == PS_SUCCESS) {
        print {$f} $cert;
    }
}
close $f or die "close: $!";

Crypt::MatrixSSL3::Close();
