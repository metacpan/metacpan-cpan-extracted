use v5.40;
use Exotic::Zlib;

# A static-library consumer: feed the alien's include/link flags straight into
# Inline::C (the cc_lib_flags pattern) and bind a real zlib function.
my $zlib = Exotic::Zlib->new;
die 'Could not resolve zlib' unless $zlib->package_info;
print 'zlib:  ' . $zlib->libpath . "\n";
print 'cflags: ' . $zlib->cflags . "\n";
print 'libs:   ' . $zlib->libs . "\n";
use Inline ();    # Requires Inline::C
Inline->bind(
    'C', <<~'C',
    #include <zlib.h>

    const char* zlib_version_str( ) {
        return zlibVersion();
    }
    C
    INC  => $zlib->cflags,
    LIBS => $zlib->libs
);
print 'zlibVersion: ' . zlib_version_str() . "\n";
