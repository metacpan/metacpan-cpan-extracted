use ExtUtils::MakeMaker;


our $WITH_OPENSSL         = 1;
our $WITH_WIN32_CRYPTOAPI = 0;
our $WITH_PERL            = 0;

my %option = (
    NAME => 'Crypt::Keyczar',
    VERSION_FROM => 'lib/Crypt/Keyczar.pm',
    PREREQ_PM => {
        'JSON' => 0.0, # 1.xx or 2.xx
        'MIME::Base64' => 0.0,
        'Test::Simple' => 0.0,
    },
    LIBS => [], # -lcrypto or other
    EXE_FILES => [ 'bin/keyczar' ],
    ($] >= 5.005 ?
        (ABSTRACT_FROM => 'lib/Crypt/Keyczar.pm',
         AUTHOR => '小山浩之 <oyama@module.jp>') : ()),
);

if ($WITH_OPENSSL) {
    $option{LIBS} = [ "-lcrypto -L$ENV{OPENSSL_PREFIX}/lib" ];
    $option{INC}  = "-I$ENV{OPENSSL_PREFIX}/include";
    $option{depend} = { 'Keyczar.c' => "Keyczar.xs xs/openssl.h xs/openssl/*.xst" };
#    has_openssl_sha2();
    WriteMakefile(%option);
}
elsif ($WITH_WIN32_CRYPTOAPI) {
    # PATCH WELLCOME :-)
}
elsif ($WITH_PERL) {
    # use Pure Perl implementation
    # PATCH WELLCOME :-)
}
else {
    die "ERROR: $option{NAME} require libcrypto(OpenSSL) or CryptoAPI(Win32)\n";
}


sub has_openssl_sha2 {
    my $v = `openssl version -v`;
    chomp $v;
    if ($v =~ /^[^\s]+\s+(\d+\.\d+)\.(\d+)([a-z]|[a-z]?-[^\s]+)?\s+.+$/) {
        if ($1 >= 1.0 || ($1 == 0.9 && $2 >= 8)) {
            return 1;
        }
        else {
            warn "WARN: disable SHA-224/256/384/512, please update to OpenSSL 0.9.8 or later.";
            return 0;
        }
    }
    else {
        die "not found 'openssl version' command or unknown version string: $v";
    }
}
