use v5.40;
use Exotic::SQLite3;
use Inline ();    # Requires Inline::C

# A static-library consumer: feed the alien's include/link flags straight into Inline::C (the
# cc_lib_flags pattern) and bind a real sqlite3 function.
my $sqlite = Exotic::SQLite3->new;
die 'Could not resolve sqlite3' unless $sqlite->package_info;
say 'sqlite3: ' . $sqlite->libpath;
say 'cflags:  ' . $sqlite->cflags;
say 'libs:    ' . $sqlite->libs;
#
Inline->bind(
    'C', <<~'C',
    #include <sqlite3.h>

    const char* sqlite_libversion( ) {
        return sqlite3_libversion();
    }
    C
    INC  => $sqlite->cflags,
    LIBS => $sqlite->libs
);
say 'sqlite3_libversion: ' . sqlite_libversion();
