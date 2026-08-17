use 5.016000;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;
use Config;

# Crypt::JWS binds libcrypto (OpenSSL) for JWS signing and verification.
# Unlike Fetch, where TLS is optional, libcrypto is the whole point here:
# configure fails loudly when it is missing. Detection follows the house
# cascade - pkg-config, then a compile probe, then homebrew keg paths -
# and API differences between OpenSSL 1.1 and 3.x are FEATURE probed
# (never version sniffed): the 3.x provider API via EVP_PKEY_fromdata,
# the 1.1 struct API via RSA_set0_key.

my $DEFINE = '';
my $LIBS   = '';
my $INC    = '-Iinclude';

my ($ssl_cflags, $ssl_libs);
if (system('pkg-config --exists libcrypto >/dev/null 2>&1') == 0) {
    chomp($ssl_cflags = `pkg-config --cflags libcrypto 2>/dev/null`);
    chomp($ssl_libs   = `pkg-config --libs libcrypto 2>/dev/null`);
    $ssl_libs ||= '-lcrypto';
}
if (!$ssl_libs && probe_crypto('')) {
    ($ssl_cflags, $ssl_libs) = ('', '-lcrypto');
}
if (!$ssl_libs) {   # homebrew keg-only path (no pkg-config on macOS)
    for my $p ('/opt/homebrew/opt/openssl', '/opt/homebrew/opt/openssl@3',
               '/opt/homebrew/opt/openssl@1.1',
               '/usr/local/opt/openssl', '/usr/local/opt/openssl@3',
               '/usr/local/opt/openssl@1.1') {
        next unless -d "$p/include";
        if (probe_crypto("-I$p/include -L$p/lib")) {
            ($ssl_cflags, $ssl_libs) = ("-I$p/include", "-L$p/lib -lcrypto");
            last;
        }
    }
}
na("Crypt::JWS requires OpenSSL's libcrypto (install libssl-dev / "
 . "openssl-devel / brew install openssl)")
    unless $ssl_libs;
$INC  .= " $ssl_cflags" if $ssl_cflags;
$LIBS .= " $ssl_libs";
print "Found libcrypto: $ssl_libs\n";

# --- feature probes --------------------------------------------------------

if (probe('fromdata', $ssl_cflags,
    "#include <openssl/evp.h>\n#include <openssl/core_names.h>\n#include <openssl/param_build.h>",
    'OSSL_PARAM_BLD *b = OSSL_PARAM_BLD_new(); EVP_PKEY_CTX *c = EVP_PKEY_CTX_new_from_name(NULL, "RSA", NULL); (void)b; (void)c; return EVP_PKEY_fromdata_init(c);',
    $ssl_libs)) {
    $DEFINE .= ' -DCJWS_HAVE_FROMDATA';
    print "Found EVP_PKEY_fromdata: OpenSSL 3.x provider key import.\n";
}
elsif (probe('set0', $ssl_cflags,
    "#include <openssl/rsa.h>\n#include <openssl/ec.h>",
    'RSA *r = RSA_new(); (void)RSA_set0_key(r, 0, 0, 0); EC_KEY *k = EC_KEY_new_by_curve_name(415); (void)k; return 0;',
    $ssl_libs)) {
    $DEFINE .= ' -DCJWS_HAVE_SET0';
    print "Found RSA_set0_key: OpenSSL 1.1 struct key import.\n";
}
else {
    na("libcrypto found but neither EVP_PKEY_fromdata (3.x) nor "
     . "RSA_set0_key (1.1) compiled - OpenSSL 1.1.0 or newer (or "
     . "LibreSSL 2.7+) is required");
}

# --- ExtUtils::Depends: consume frj_abi.h, provide jws_abi.h --------------
# Crypt::JWS is BOTH a consumer (File::Raw::JSON's frj_abi decodes and
# encodes JWS header JSON in C) and a provider (jws_abi.h for C-level
# consumers like PDF::Make).

my $pkg;
eval { $pkg = ExtUtils::Depends->new('Crypt::JWS', 'File::Raw::JSON'); 1 };
if (!$pkg) {
    die "Cannot find the File::Raw::JSON dependency.\n"
      . "Install File::Raw::JSON 0.05+, or place it as a sibling directory.\n"
        unless -d '../File-Raw-JSON/include';
    $pkg = ExtUtils::Depends->new('Crypt::JWS');       # provider only
    $INC .= ' -I../File-Raw-JSON/include';             # frj_abi.h fallback
}
$pkg->install('include/jws_abi.h');
mkdir 'Install' unless -d 'Install';
$pkg->save_config('Install/Files.pm');
my %dep = $pkg->get_makefile_vars;
$INC = join ' ', grep { defined && length } $INC, delete $dep{INC};
# Merge (don't clobber) LIBS - EU::Depends returns an empty LIBS that
# would otherwise wipe -lcrypto from the link and silently break the
# load. LDFROM likewise defaults to $(OBJECT); drop EU::Depends' copy.
$LIBS = join ' ', grep { defined && length } $LIBS, delete $dep{LIBS};
delete $dep{LDFROM};

# EU::Depends' PM map (installing jws_abi.h + Files.pm) replaces
# MakeMaker's auto-detected PM, so re-add the module's own .pm files.
require File::Find;
File::Find::find(sub {
    return unless /\.pm\z/;
    (my $rel = $File::Find::name) =~ s{^lib/}{};
    $dep{PM}{$File::Find::name} = "\$(INST_LIB)/$rel";
}, 'lib');

# MakeMaker tracks neither include/*.h nor xs/*.xs pulled in by INCLUDE:,
# so edits there do not rebuild without this (house gotcha).
my @headers = glob 'include/cjws/*.h include/jws_abi.h';
my @xs      = glob 'xs/*.xs';
my $deps    = join ' ', @headers, @xs;

WriteMakefile(
    NAME             => 'Crypt::JWS',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Crypt/JWS.pm',
    ABSTRACT_FROM    => 'lib/Crypt/JWS.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.016000',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'ExtUtils::Depends'   => '0.404',
        'File::Raw::JSON'     => '0.05',   # frj_abi.h at build time
    },
    TEST_REQUIRES => {
        'Test::More' => '0.98',
    },
    PREREQ_PM => {
        'ExtUtils::Depends' => '0.404',
        'File::Raw::JSON'   => '0.05',   # JWS header JSON encode/decode
        'XSLoader'          => '0',
    },
    INC    => $INC,
    DEFINE => $DEFINE,
    LIBS   => [$LIBS],
    XS     => { 'JWS.xs' => 'JWS.c' },
    OBJECT => 'JWS$(OBJ_EXT)',
    depend => {
        'JWS.c'         => $deps,
        'JWS$(OBJ_EXT)' => $deps,
    },
    macro => { TARFLAGS   => "--format=ustar -c -v -f" },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean => { FILES => 'Crypt-JWS-* JWS.c JWS.o JWS.bs Install/Files.pm' },
    %dep,
);

# A missing/too-old libcrypto is not a bug in this distribution, so bail
# out the way CPAN::Reporter grades NA rather than UNKNOWN: the literal
# phrase "OS unsupported" on stdout and a clean exit with no Makefile.
sub na {
    my $why = shift;
    print "OS unsupported: $why - Crypt::JWS cannot be built here.\n";
    exit 0;
}

sub probe {
    my ($name, $flags, $includes, $body, $libs) = @_;
    $flags //= '';
    my $dir = "cjws_probe_${name}_$$";
    mkdir $dir or return 0;
    my ($src, $bin, $ok) = ("$dir/p.c", "$dir/p", 0);
    if (open my $fh, '>', $src) {
        print $fh "$includes\nint main(void){ $body }\n";
        close $fh;
        my $cc = $Config{cc} || 'cc';
        $ok = system("$cc $flags $src -o $bin $libs >/dev/null 2>&1") == 0;
    }
    unlink $src, $bin; rmdir $dir;
    return $ok;
}

sub probe_crypto {
    my $flags = shift;
    return probe('crypto', $flags, '#include <openssl/evp.h>',
        'EVP_MD_CTX *c = EVP_MD_CTX_new(); if (c) EVP_MD_CTX_free(c); return 0;',
        '-lcrypto');
}
