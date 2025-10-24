use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More;

plan tests => 30 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Crypt/OpenSSL3.pm',
    'Crypt/OpenSSL3/BIO.pm',
    'Crypt/OpenSSL3/BIO/Address.pm',
    'Crypt/OpenSSL3/BIO/PollDescriptor.pm',
    'Crypt/OpenSSL3/BigNum.pm',
    'Crypt/OpenSSL3/BigNum/Context.pm',
    'Crypt/OpenSSL3/Cipher.pm',
    'Crypt/OpenSSL3/Cipher/Context.pm',
    'Crypt/OpenSSL3/Error.pm',
    'Crypt/OpenSSL3/KDF.pm',
    'Crypt/OpenSSL3/KDF/Context.pm',
    'Crypt/OpenSSL3/MAC.pm',
    'Crypt/OpenSSL3/MAC/Context.pm',
    'Crypt/OpenSSL3/MD.pm',
    'Crypt/OpenSSL3/MD/Context.pm',
    'Crypt/OpenSSL3/PKey.pm',
    'Crypt/OpenSSL3/PKey/Context.pm',
    'Crypt/OpenSSL3/Random.pm',
    'Crypt/OpenSSL3/Random/Context.pm',
    'Crypt/OpenSSL3/SSL.pm',
    'Crypt/OpenSSL3/SSL/Cipher.pm',
    'Crypt/OpenSSL3/SSL/Context.pm',
    'Crypt/OpenSSL3/SSL/Method.pm',
    'Crypt/OpenSSL3/SSL/Session.pm',
    'Crypt/OpenSSL3/Signature.pm',
    'Crypt/OpenSSL3/X509.pm',
    'Crypt/OpenSSL3/X509/Name.pm',
    'Crypt/OpenSSL3/X509/Name/Entry.pm',
    'Crypt/OpenSSL3/X509/Store.pm',
    'Crypt/OpenSSL3/X509/VerifyResult.pm'
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


