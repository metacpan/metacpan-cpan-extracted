use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More;

plan tests => 35 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Crypt/Bear.pm',
    'Crypt/Bear/AEAD.pm',
    'Crypt/Bear/AES_CBC/Dec.pm',
    'Crypt/Bear/AES_CBC/Enc.pm',
    'Crypt/Bear/AES_CTR.pm',
    'Crypt/Bear/AES_CTR/DRBG.pm',
    'Crypt/Bear/AES_CTRCBC.pm',
    'Crypt/Bear/CBC/Dec.pm',
    'Crypt/Bear/CBC/Enc.pm',
    'Crypt/Bear/CCM.pm',
    'Crypt/Bear/CTR.pm',
    'Crypt/Bear/CTRCBC.pm',
    'Crypt/Bear/EAX.pm',
    'Crypt/Bear/EC/PrivateKey.pm',
    'Crypt/Bear/EC/PublicKey.pm',
    'Crypt/Bear/GCM.pm',
    'Crypt/Bear/HKDF.pm',
    'Crypt/Bear/HMAC.pm',
    'Crypt/Bear/HMAC/DRBG.pm',
    'Crypt/Bear/HMAC/Key.pm',
    'Crypt/Bear/Hash.pm',
    'Crypt/Bear/PEM.pm',
    'Crypt/Bear/PEM/Decoder.pm',
    'Crypt/Bear/PRNG.pm',
    'Crypt/Bear/RSA.pm',
    'Crypt/Bear/RSA/PrivateKey.pm',
    'Crypt/Bear/RSA/PublicKey.pm',
    'Crypt/Bear/SSL/Client.pm',
    'Crypt/Bear/SSL/Engine.pm',
    'Crypt/Bear/SSL/PrivateCertificate.pm',
    'Crypt/Bear/SSL/Server.pm',
    'Crypt/Bear/X509/Certificate.pm',
    'Crypt/Bear/X509/Certificate/Chain.pm',
    'Crypt/Bear/X509/PrivateKey.pm',
    'Crypt/Bear/X509/TrustAnchors.pm'
);



# no fake home requested

my @switches = (
    -d 'blib' ? '-Mblib' : '-Ilib',
);

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    diag('Running: ', join(', ', map { my $str = $_; $str =~ s/'/\\'/g; q{'} . $str . q{'} }
            $^X, @switches, '-e', "require q[$lib]"))
        if $ENV{PERL_COMPILE_TEST_DEBUG};

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, @switches, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { +require blib; blib->VERSION('1.01') };

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) ) if $ENV{AUTHOR_TESTING};


