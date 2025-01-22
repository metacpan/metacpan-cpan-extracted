package Test::Crypt::OpenSSL::PKCS10::Util;
use warnings;
use strict;

# ABSTRACT: Utils for testsuite of Crypt::OpenSSL::PKCS10

use Test::More;

use File::Slurper qw/ write_text /;
use File::Temp qw/ tempfile /;
use File::Spec::Functions;
use Crypt::OpenSSL::Guess qw/find_openssl_prefix find_openssl_exec/;

use Crypt::OpenSSL::PKCS10;

require Exporter;

my $openssl_bin = find_openssl_exec(find_openssl_prefix());

my $config_loc = `$openssl_bin version -d`;

$config_loc =~ m/OPENSSLDIR: "(.*)"/;

my $configfile = catfile($1, 'openssl.cnf');

if (! -e "$configfile") {
	$configfile = ' -config t\\openssl.cnf';
	$ENV{'OPENSSL_CONF'} = 't\openssl.cnf';
} else {
    $configfile = '';
}

our @ISA    = qw(Exporter);
our @EXPORT = qw(
    get_openssl_output
 );

our @EXPORT_OK;

our %EXPORT_TAGS = (
    all => [@EXPORT, @EXPORT_OK],
);

sub get_openssl_output {
    my $csr = shift;

    my ($fh, $filename) = tempfile;
    write_text($filename, $csr);
    my $output = `$openssl_bin req $configfile -in $filename -text`;

    return $output;
}

