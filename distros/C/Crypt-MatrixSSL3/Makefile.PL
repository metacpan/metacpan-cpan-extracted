use 5.00001;
use ExtUtils::MakeMaker 6.63_03;

use strict;
use warnings;

use Config;
use File::ShareDir::Install;
$File::ShareDir::Install::INCLUDE_DOTFILES = 1;
$File::ShareDir::Install::INCLUDE_DOTDIRS = 1;
install_share dist => 'share';

#
#  WARNING: Do not try to "make dist" under Windows; it destroys the Upper/lower CaSe of some files.
#
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
#
# Many thanks to Randy Kobes for helping me figure out how to make this work on Win32, which
# also laid the foundation for me getting it to work nicely on Linux and Macintosh
#

# Compile options
my @cOptions = (
    # ------
    # matrixSSL configuration
    # ------

    #-------
    # matrixSSL cipher suites selection
    #-------

    # matrixsslConfig.h Cipher Suites

    # ** WARNING **
    # If you enable DHE cipher suites you *must*:
    # - enable USE_DH in the options below (enabled by default)
    # - load DH params for the session keys by using $keys->load_DH_params( $DH_params_file )
    #
    # If you plan to support HTTP/2 you are required by specification to support the following cipher
    #   TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256

    #******************************************************************************
    #
    #   Recommended cipher suites:
    #
    #   Define the following to enable various cipher suites
    #   At least one of these must be defined.  If multiple are defined,
    #   the handshake will determine which is best for the connection.
    #

    'USE_TLS_RSA_WITH_AES_128_CBC_SHA',
    'USE_TLS_RSA_WITH_AES_256_CBC_SHA',
    'USE_TLS_RSA_WITH_AES_128_CBC_SHA256', # TLS 1.2
    'USE_TLS_RSA_WITH_AES_256_CBC_SHA256', # TLS 1.2
    'USE_TLS_RSA_WITH_AES_128_GCM_SHA256', # TLS 1.2
    'USE_TLS_RSA_WITH_AES_256_GCM_SHA384', # TLS 1.2

    # Pre-Shared Key Ciphers
    #'USE_TLS_PSK_WITH_AES_256_CBC_SHA',
    #'USE_TLS_PSK_WITH_AES_128_CBC_SHA',
    #'USE_TLS_PSK_WITH_AES_256_CBC_SHA384', # TLS 1.2
    #'USE_TLS_PSK_WITH_AES_128_CBC_SHA256', # TLS 1.2

    # Ephemeral ECC DH keys, ECC DSA certificates
    #'USE_TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA',
    #'USE_TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA',
    #'USE_TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256', # TLS 1.2
    #'USE_TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384', # TLS 1.2
    #'USE_TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256', # TLS 1.2 - HTTP/2 approved
    #'USE_TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384', # TLS 1.2 - HTTP/2 approved

    # Ephemeral ECC DH keys, RSA certificates
    'USE_TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA',
    'USE_TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA',
    'USE_TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384', # TLS 1.2
    'USE_TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256', # TLS 1.2
    'USE_TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384', # TLS 1.2 - HTTP/2 approved
    'USE_TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256', # TLS 1.2 - HTTP/2 approved and *required*

    # Non-Ephemeral ECC DH keys, ECC DSA certificates
    #'USE_TLS_ECDH_ECDSA_WITH_AES_128_CBC_SHA',
    #'USE_TLS_ECDH_ECDSA_WITH_AES_256_CBC_SHA',
    #'USE_TLS_ECDH_ECDSA_WITH_AES_128_CBC_SHA256', # TLS 1.2
    #'USE_TLS_ECDH_ECDSA_WITH_AES_256_CBC_SHA384', # TLS 1.2
    #'USE_TLS_ECDH_ECDSA_WITH_AES_128_GCM_SHA256', # TLS 1.2
    #'USE_TLS_ECDH_ECDSA_WITH_AES_256_GCM_SHA384', # TLS 1.2

    # Non-Ephemeral ECC DH keys, RSA certificates
    #'USE_TLS_ECDH_RSA_WITH_AES_256_CBC_SHA',
    #'USE_TLS_ECDH_RSA_WITH_AES_128_CBC_SHA',
    #'USE_TLS_ECDH_RSA_WITH_AES_256_CBC_SHA384', # TLS 1.2
    #'USE_TLS_ECDH_RSA_WITH_AES_128_CBC_SHA256', # TLS 1.2
    #'USE_TLS_ECDH_RSA_WITH_AES_256_GCM_SHA384', # TLS 1.2
    #'USE_TLS_ECDH_RSA_WITH_AES_128_GCM_SHA256', # TLS 1.2

    #******************************************************************************
    #
    #   These cipher suites are secure, but not in general use. Enable only if
    #   specifically required by application.
    #
    'USE_TLS_DHE_PSK_WITH_AES_256_CBC_SHA',
    'USE_TLS_DHE_PSK_WITH_AES_128_CBC_SHA',
    'USE_TLS_DHE_RSA_WITH_AES_256_CBC_SHA',
    'USE_TLS_DHE_RSA_WITH_AES_128_CBC_SHA',
    'USE_TLS_DHE_RSA_WITH_AES_128_CBC_SHA256', # TLS 1.2
    'USE_TLS_DHE_RSA_WITH_AES_256_CBC_SHA256', # TLS 1.2

    #******************************************************************************
    #
    #   These cipher suites are generally considered weak, not recommended for use.
    #
    #'USE_TLS_ECDHE_RSA_WITH_3DES_EDE_CBC_SHA', #x
    #'USE_SSL_DHE_RSA_WITH_3DES_EDE_CBC_SHA',
    #'USE_SSL_RSA_WITH_3DES_EDE_CBC_SHA',      #x
    #'USE_TLS_RSA_WITH_SEED_CBC_SHA',
    #'USE_SSL_RSA_WITH_RC4_128_SHA',
    #'USE_SSL_RSA_WITH_RC4_128_MD5',

    #******************************************************************************
    #
    #   These cipher suites do not combine authentication and encryption and
    #   are not recommended for use-cases that require strong security or
    #   Man-in-the-Middle protection.
    #
    #'USE_TLS_DH_anon_WITH_AES_256_CBC_SHA',
    #'USE_TLS_DH_anon_WITH_AES_128_CBC_SHA',
    #'USE_SSL_DH_anon_WITH_3DES_EDE_CBC_SHA',
    #'USE_SSL_DH_anon_WITH_RC4_128_MD5',
    #'USE_SSL_RSA_WITH_NULL_SHA',               # enabled just for test purposes
    #'USE_SSL_RSA_WITH_NULL_MD5',

    # include encryption algorithms
    'USE_AES',
    'USE_AES_GCM',
    'USE_3DES',
    'USE_DES',
    'USE_ARC4',
    'USE_RC2',

    # include digest algorithms
    'USE_SHA1',
    'USE_SHA256',
    'USE_SHA384',
    'USE_SHA512',
    'USE_MD5',
    'USE_HMAC',

    # certificates and keys
    'USE_ECC',
    'USE_DH',
    'USE_RSA',
    'USE_X509',
    'USE_BASE64_DECODE',

    # ------
    # matrixSSL compile options
    #-------

    # enable certificate and key parsing
    'USE_CERT_PARSE',
    'USE_FULL_CERT_PARSE',
    'USE_PRIVATE_KEY_PARSING',

    # Define in the build environment. Enables file access for parsing X.509
    # certificates and private keys.
    'MATRIX_USE_FILE_SYSTEM',

    # matrixsslConfig.h - Enables client side SSL support
    'USE_CLIENT_SIDE_SSL',

    # matrixsslConfig.h - Enables server side SSL support
    'USE_SERVER_SIDE_SSL',

    # matrixsslConfig.h - Enables TLS 1.0 protocol support and above (SSL version 3.1)
    'USE_TLS_1_0_AND_ABOVE',

    # matrixsslConfig.h - Disables SSL version 3.0
    # TODO: disable the definition in matrixSSL so users will be able to support it if they comment the next line
    'DISABLE_SSLV3',

    # matrixsslConfig.h - Disables TLS 1.0 if USE_TLS is enabled but only later versions of the protocol are desired
    #'DISABLE_TLS_1_0',

    # matrixsslConfig.h - Disables TLS 1.1 if USE_TLS_1_1 is enabled but
    # only later versions of the protocol are desired
    #'DISABLE_TLS_1_1',

    # matrixsslConfig.h - Applicable to servers only. The size of the
    # session resumption table for caching session identifiers. Old entries
    # will be overwritten when size is reached
    'SSL_SESSION_TABLE_SIZE=32',

    # matrixsslConfig.h - Applicable to servers only. The time in seconds
    # that a session identifier will be valid in the session table. A value of 0
    # will disable SSL resumption (in milliseconds)
    'SSL_SESSION_ENTRY_LIFE=86400000',

    # matrixsslConfig.h - Enable the stateless ticket resumption mechanism
    # defined by RFC 5077. Clients must then set the
    # ticketResumption member of the session options to 1 to
    # activate for a given session.
    'USE_STATELESS_SESSION_TICKETS',

    # matrixsslConfig.h - the max size of the server key list
    'SSL_SESSION_TICKET_LIST_LEN=32',

    # matrixsslConfig.h - Enable secure rehandshaking as defined in RFC 5746
    'ENABLE_SECURE_REHANDSHAKES',

    # matrixsslConfig.h - Enable protocol downgrade check
    'ENABLE_TLS_FALLBACK_SCSV',

    # matrixsslConfig.h - Halt communications with any SSL peer that has not implemented RFC 5746
    'REQUIRE_SECURE_REHANDSHAKES',

    # matrixsslConfig.h - Enable certificate status handling
    'USE_OCSP',

    # matrixSslConfig.h - Enable certificate transparency handling
    'USE_SCT',

    # matrixsslConfig.h - enable ALPN
    'USE_ALPN',

    'USE_DTLS',

    # matrixsslConfig.h - enable server preferrer ciphers
    'USE_SERVER_PREFERRED_CIPHERS',

    # matrixsslConfig.h - Enable legacy renegotiations. NOT RECOMMENDED
    #'ENABLE_INSECURE_REHANDSHAKES',

    # matrixsslConfig.h - See code comments in file
    'ENABLE_FALSE_START',

    # matrixsslConfig.h - See code comments in file.
    'USE_BEAST_WORKAROUND',

    # matrixsslConfig.h - Enables two-way(mutual) authentication
    'USE_CLIENT_AUTH',

    # matrixsslConfig.h - A client authentication feature. Allows the server
    # to send an empty CertificateRequest message if no CA files have
    # been loaded
    'SERVER_CAN_SEND_EMPTY_CERT_REQUEST',

    # matrixsslConfig.h - A client authentication feature. Allows the server
    # to -downgrade- a client authentication handshake to a standard
    # handshake if client does not provide a certificate
    'SERVER_WILL_ACCEPT_EMPTY_CLIENT_CERT_MSG',

    # matrixsslConfig.h - Enable the TLS compression extension negotiation
    #'USE_ZLIB_COMPRESSION',

    # enable key file password
    'USE_PBKDF1',

    # cryptoConfig.h - Enables the parsing of password protected private keys
    'USE_PKCS5',

    # cryptoConfig.h - Enables the parsing of PKCS#8 formatted private keys
    'USE_PKCS8',

    # cryptoConfig.h - Enables the parsing of PKCS#12 formatted certificate and key material
    'USE_PKCS12',

    # cryptoConfig.h - Enables fast math for 1024-bit public key operations
    #'USE_1024_KEY_SPEED_OPTIMIZATIONS',

    # cryptoConfig.h - RSA and Diffie-Hellman speed vs. runtime memory tradeoff. Default is to optimize for smaller RAM. Choose only one
    #'PS_PUBKEY_OPTIMIZE_FOR_SMALLER_RAM',
    # OSX defines __OPTIMIZE__ and __OPTIMIZE_SIZE__ which triggers matrixSSL to define
    # PS_PUBKEY_OPTIMIZE_FOR_SMALLER_RAM and having both triggers a compilation error
    ($^O !~ /darwin/ms ? 'PS_PUBKEY_OPTIMIZE_FOR_FASTER_SPEED' : ()),

    # cryptoConfig.h - Optionally enable for selected algorithms to improve
    # performance at the cost of increased binary code size.
    'PS_AES_IMPROVE_PERF_INCREASE_CODESIZE',
    'PS_3DES_IMPROVE_PERF_INCREASE_CODESIZE',
    'PS_MD5_IMPROVE_PERF_INCREASE_CODESIZE',
    'PS_SHA1_IMPROVE_PERF_INCREASE_CODESIZE',

    # cryptoConfig.h - use multi-threading
    #'USE_MULTITHREADING',

    # cryptoConfig.h - use shared memory session cache
    #'USE_SHARED_SESSION_CACHE',

    # ------
    # Debug configuration - ! Do not use on production envrironments !
    # ------

    # if the following define is enabled, log messages and debug symbols will be available
    #'MATRIX_DEBUG',

    # coreConfig.h - Enables the osdepBreak platform function whenever a
    # psError trace function is called. Helpful in debug environments.
    #'HALT_ON_PS_ERROR',

    # coreConfig.h - Enables the psTraceCore family of APIs that display
    # function-level messages in the core module
    #'USE_CORE_TRACE',

    # cryptoConfig.h - Enables the psTraceCrypto family of APIs that
    # display function-level messages in the crypto module
    #'USE_CRYPTO_TRACE',

    # matrixsslConfig.h - Enables SSL handshake level debug trace for
    # troubleshooting connection problems
    #'USE_SSL_HANDSHAKE_MSG_TRACE',

    # matrixsslConfig.h - Enables SSL function level debug trace for
    #'USE_SSL_INFORMATIONAL_TRACE',

    # ------
    # OS related and other stuff
    # ------

    ($^O =~ /linux/ms ? 'LINUX' : ()),
    ($^O !~ /Win32/ms ? 'POSIX' : ()),
    ($^O !~ /Win32|darwin/ms && $Config{myuname} =~ /x86_64|amd64|x64/ms ? 'PSTM_64BIT' : ()),

    # module compiles as a dynamic DLL
    ($^O =~ /Win32/ms ? '_USRDLL' : ()),

    # not used anywhere - fails to compile because missing includes
    'NO_ASN_FORMAT_OID',
);

# Compute the compiler definitions string
my $define = q{};
my $debug_build = 0;
foreach my $d (@cOptions) {
    if ($d =~ /\A!(.*)\z/ms) {
        $define .= "-U$1 " if $define !~ /-U\Q$1\E\s/ms;
    } else {
        $define .= "-D$d " if $define !~ /-D\Q$d\E\s/ms;
    }
    $debug_build = 1 if $d eq 'MATRIX_DEBUG';
}

# Prepare for matrixSSL compilation
my $os_src = ($^O =~ /Win32/ms) ? 'core/WIN32' : 'core/POSIX';
my $o = $Config{obj_ext};
my $c = '.c';
my $mxbase = 'inc/matrixssl-3-9-1-open';
my $mxfiles = "$mxbase.files";
my $mxmodfiles = 'modfiles';

# Extract the MatrixSSL original source if it's not already extracted.

use Archive::Tar;
if (!-d $mxbase) {
    my $tar = Archive::Tar->new;
    $tar->setcwd('inc');
    $tar->read("$mxbase.tar.gz");
    $tar->extract();
}

# Apply cumulative patch, if any
use File::Which;
if (-d 'inc/patches') {
    if (which('patch')) {
        use Cwd;
        my $wd = getcwd();
        chdir $mxbase or die "chdir($mxbase): $!";
        local $/;
        for my $file (glob '../../inc/patches/*.patch') {
            open my $f, '<', $file or die "open($file): $!";
            my $patch = <$f>;
            close $f or die "close($file): $!";
            open $f, '| patch -p1 -N' or die "run patch: $!";
            # print will change \n to \r\n on Win, without this patch.exe will crash
            print {$f} $patch;
            close $f;
        }
        chdir $wd or die "chdir($wd): $!";
    }
    else {
        my $pp = prompt "It looks like the patch tool is not installed on your system!\n" .
                        'Do you want to continue (the resulted build might be unstable)?', 'n';
        die 'Aborting...' if 'y' ne lc $pp;
    }
}

# NOTE: For future versions of MatrixSSL (this is v1.8.6) - if the below routine failes - you might need to do this;
#       1. cd matrixssl-x-y-z/src
#       2. make all; cd ..
#       3. find . -name '*.o' -print >/tmp/objs
#       4. vi ../Makefile.PL
#       5. include the file /tmp/objs - eg:   ":r /tmp/objs"
#       6. change all the ".o" endings to "$mxext"
#       7. change all the leading "./" to $mxbase/
#       8. join them all on to one line and assign them all to "$mxfiles"; be careful NOT to expand the "$mxext" or "$mxbase" (eg: use single quotes)
#       9. replace the os/linux/linux$mxext one with os/$os_src$mxext


# Autogenerate list with object files produced by MatrixSSL because it's
# different between MatrixSSL versions.
if (!-r $mxfiles) {
    if ($^O =~ /Win32/ms) {
        # TODO  I don't have windoze with installed perl and C compiler,
        #       so I can't realize this feature for Win32.
        die "$mxfiles autogeneration not supported under Win32 yet.\n";
    }
    else {
        system "
            cd \Q$mxbase\E/ &&
            make all OSDEP=POSIX &&
            cd ../../ &&
            find \Q$mxbase\E -name '*.o' | sed 's/\.o\$//' | sort > \Q$mxfiles\E
            " and die "system: $? $!";
    }
}

# Prepare list of object & C MatrixSSL files for usage in Makefile later.
open my $files, '<', $mxfiles or die "open: $!";
chomp(my @files = <$files>);
close $files or die "close: $!";
s{core/POSIX|core/WIN32}{$os_src}ms for @files;
# These are all the object files we need for our release
my $mxobjs  = join q{ }, map { $_.$o } @files;

# Some Linicies seem to require '-lpthread' - if you're having problems, try removing this:-
my $libs = ($^O =~ /Win32/ms) ? q{} : '-lpthread -lrt';

# Additional compiler/linker flags
my ($ccflags, $lddlflags) = (q{}, q{});
if ($^O =~ /Win32/ms) {
    if ($Config{cc} eq 'cl') {  # Microsoft Windows compiler
        $ccflags =  ' -Dinline=__inline /wd4005 /wd4996';  # disable warnings for macro redefinition and unsafe function usage
    }  else {                   # Other Windows compiler (assuming gcc)
        $ccflags = ' -Os -Wp,-w -m32 -fomit-frame-pointer -fPIC -I./ -I../';
        $lddlflags = ' -m32';
    }
} else {
    if ($debug_build) {
        $ccflags = ' -O0 -g -DDEBUG -Wall';
    } else {
        $ccflags = ' -Os -Wp,-w -fomit-frame-pointer -fPIC -I./ -I../';
    }
    $lddlflags = q{};
}

WriteMakefile(
    NAME                => 'Crypt::MatrixSSL3',
    VERSION_FROM        => 'lib/Crypt/MatrixSSL3.pm', # finds $VERSION
VERSION_FROM       => undef,
  'ABSTRACT' => 'Perl extension for SSL and TLS using MatrixSSL.org v3.7.2b',
  'AUTHOR' => 'C. N. Drake <christopher@pobox.com>',
  'LICENSE' => 'gpl',
  'VERSION' => 'v3.9.0',
  'CONFIGURE_REQUIRES' => {
    'Archive::Tar' => '0',
    'ExtUtils::Constant' => '0',
    'ExtUtils::MakeMaker' => '6.63_03',
    'File::ShareDir::Install' => '0.06',
    'File::Which' => '0'
  },
  'PREREQ_PM' => {
    'File::ShareDir' => '0',
    'Getopt::Long' => '0',
    'JSON' => '0',
    'LWP::UserAgent' => '0',
    'List::Util' => '0',
    'MIME::Base64' => '0',
    'Pod::Usage' => '0',
    'Scalar::Util' => '0',
    'Text::Wrap' => '0',
    'version' => '0.77'
  },
  'TEST_REQUIRES' => {
    'Socket' => '0',
    'Test::Exception' => '0',
    'Test::More' => '0'
  },
    CCFLAGS             => $Config{ccflags} . $ccflags,
    LDDLFLAGS           => $Config{lddlflags} . $lddlflags,
    LIBS                => [$libs], # e.g., '-lm'
    DEFINE              => $define, # e.g., '-DHAVE_SOMETHING'
    INC                 => "-I. -I$mxbase -I$mxbase/crypto", # e.g., '-I. -I/usr/include/other'
    OBJECT              => "$mxobjs \$(O_FILES)", # link all the C files too
    EXE_FILES           => [ grep {-f && -x} glob 'script/*' ],
);


if (eval {require ExtUtils::Constant; 1}) {
    open my $f, '<', 'lib/Crypt/MatrixSSL3.pm' or die "open: $!";
    my %names = map { my $s=$_; $s=~s/\A\s*//ms; $s=~s/\s*\z//ms; $s=>1 }
         grep {/\A\s+[A-Z][a-zA-Z0-9_]+\s*\z/ms} <$f>;
    close $f or die "close: $!";
    ExtUtils::Constant::WriteConstants(
        NAME         => 'Crypt::MatrixSSL3',
        DEFAULT_TYPE => 'IV',
        NAMES        => [
            (grep {!/\AMATRIXSSL_VERSION(?:_CODE)?\z/ms} keys %names),
#             (map {{name=>$_,type=>'PV'}} qw( MATRIXSSL_VERSION MATRIXSSL_VERSION_CODE )),
        ],
        C_FILE       => 'inc/const-c.inc',
        XS_FILE      => 'inc/const-xs.inc',
    );
}


=for comment currently contained in the patch we apply

# fix for MatrixSSL DLL compilation/linking warnings
if ($^O =~ /Win32/) {
    open my $f, '<', $mxbase.'/core/osdep.h' or die "open: $!";
    my $h = join q{}, <$f>;
    close $f or die "close: $!";
    $h =~ s{__declspec\(dll\w+\)}{}g;
    open $f, '>', $mxbase.'/core/osdep.h' or die "open: $!";
    print {$f} $h;
    close $f or die "close: $!";
}

=cut

package MY;

use Config;
use File::ShareDir::Install qw(postamble);

sub c_o {
    my $inherited = shift->SUPER::c_o(@_);

    if ($^O =~ /Win32/ms && $Config{cc} eq 'cl') {  # Microsoft deprecated -o in favor of /Fo
        $inherited =~ s{\$\*\.c\s*$}{/Fo\$\*.obj \$\*.c\n}msg;
    } else {
        $inherited =~ s{\$\*\.c\s*$}{\$\*.c -o \$\*.o\n}msg;
    }

    return $inherited;
}

sub clean_subdirs {
    return qq ~clean_subdirs :\n\t\$(RM_RF) "$mxbase"\n~;
}

=pod

my $message;
BEGIN {
    $message = <<'EOF';

  ********************************* ERROR ************************************

  This module uses Dist::Milla for development.
  This Makefile.PL should not be used for building dists.
  Building a dist should be done with 'milla build'.
  Releasing should be done with 'milla release'.

  ****************************************************************************

EOF
    $message =~ s/^([^\n]*)$/\t\$(NOECHO) echo "$1";/msg;
}

sub dist_core {
    return <<EOF
dist :
$message
EOF
}

=cut
