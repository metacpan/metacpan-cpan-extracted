use v5.40;
use lib '../lib', 'lib';
use blib;
use Test2::Tools::Affix qw[:all];
use Affix               qw[:all];
use File::Temp          qw[tempfile];
$|++;
#
subtest simple => sub {
    my $lib = compile_ok(<<'END_C');
#include "std.h"
//ext: .c

#include <stdio.h>
#include <string.h>

// Write to a FILE* passed from Perl
DLLEXPORT int c_write_to_file(FILE* fp, const char* text) {
    if (!fp) return -1;
    return fprintf(fp, "%s", text);
}

// Read from a FILE* passed from Perl
DLLEXPORT int c_read_char(FILE* fp) {
    if (!fp) return -2;
    return fgetc(fp);
}

// Return a new FILE* created in C
DLLEXPORT FILE* c_create_tmpfile(void) {
    FILE* fp = tmpfile();
    if (fp) {
        fprintf(fp, "Content from C");
        fflush(fp);
        rewind(fp);
    }
    return fp;
}

// Identity function to test round-tripping a PerlIO pointer.
// Since we don't link against libperl here, we treat PerlIO* as void*.
DLLEXPORT void* c_perlio_identity(void* p) {
    return p;
}

// Check if FILE* is NULL (to verify failure cases)
DLLEXPORT int c_is_null_file(FILE* fp) {
    return fp == NULL;
}
END_C
    subtest 'Standard C FILE* (Affix::File)' => sub {

        # File represents the FILE struct, so Pointer[File] is FILE*
        affix $lib, 'c_write_to_file',  [ Pointer [File], String ] => Int;
        affix $lib, 'c_read_char',      [ Pointer [File] ]         => Int;
        affix $lib, 'c_create_tmpfile', []                         => Pointer [File];
        affix $lib, 'c_is_null_file',   [ Pointer [File] ]         => Int;
        #
        subtest 'Writing to a Perl filehandle from C' => sub {
            my ( $fh, $filename ) = tempfile();

            # Note: We use a real file because PerlIO_findFILE (used internally)
            # requires a valid C-level FILE* which scalar handles (\$) might not provide.
            # Turn off buffering to ensure C sees the file state immediately
            my $old_fh = select($fh);
            $| = 1;
            select($old_fh);
            my $bytes = c_write_to_file( $fh, 'Hello from C' );
            ok $bytes > 0, 'C function returned success count';
            close $fh;

            # Verify content
            open my $check, '<', $filename or die $!;
            my $content = <$check>;
            is $content, 'Hello from C', 'Data written by C appears in file';
            unlink $filename;
        };
        subtest 'Reading from a Perl filehandle in C' => sub {
            my ( $fh, $filename ) = tempfile();
            syswrite $fh, 'ABC';
            close $fh;
            open my $read_fh, '<', $filename or die $!;
            my $char_code = c_read_char($read_fh);
            is chr($char_code), 'A', 'C function read first character correctly';
            $char_code = c_read_char($read_fh);
            is chr($char_code), 'B', 'C function read second character correctly';
            close $read_fh;
            unlink $filename;
        };
        subtest 'Returning a FILE* from C to Perl' => sub {
            my $fh = c_create_tmpfile();
            ok $fh, 'Received a filehandle from C';

            # Affix returns a Glob reference for files
            is ref($fh), 'GLOB', 'Returned handle is a Glob reference';
            my $line = <$fh>;
            is $line, 'Content from C', 'Perl can read from the C-created FILE*';

            # C-created tmpfiles usually disappear on close, simply ensure no crash
            close $fh;
        };
        subtest 'Passing invalid handles' => sub {

            # Passing undef/closed handle should result in NULL on C side
            is c_is_null_file(undef), 1, 'Passing undef results in NULL FILE*';
        }
    };
    subtest 'PerlIO* Streams (Affix::PerlIO)' => sub {

        # Bind the identity function using PerlIO type
        affix $lib, 'c_perlio_identity', [ Pointer [PerlIO] ] => Pointer [PerlIO];

        # Test Roundtrip
        # Note: PerlIO* handles are generally strictly tied to the Perl layer.
        # When passed to C, we extract the PerlIO*, pass it, and wrap it in a new Glob on return.
        my ( $fh, $filename ) = tempfile();
        syswrite $fh, 'Test Data';
        seek( $fh, 0, 0 );
        my $new_fh = c_perlio_identity($fh);
        ok $new_fh, 'Received handle back from C';
        is ref($new_fh), 'GLOB', 'Returned handle is a Glob reference';

        # Since it's the same underlying stream, reading from one should advance the other
        # or at least access the same data source.
        my $line = <$new_fh>;
        is $line, 'Test Data', 'Round-tripped PerlIO handle is readable';
        close $fh;
        close $new_fh;    # Should be safe to close the wrapper
        unlink $filename;
    }
};
#
subtest complex => sub {
    my $lib = compile_ok(<<~'END_C');
        #include "std.h"
        //ext: .c

        #include <stdio.h>
        #include <string.h>

        // Define a struct that contains a file pointer
        typedef struct {
            FILE* log_file;
            int   counter;
        } Logger;

        // Initialize logger with a file
        DLLEXPORT void init_logger(Logger* logger, FILE* fp) {
            if (!fp) fprintf(stderr, "C-side Warning: fp is NULL\n");
            logger->log_file = fp;
            logger->counter = 0;
        }

        // Write to a file retrieved from the struct
        DLLEXPORT void log_message(Logger* logger, const char* msg) {
            if (logger->log_file) {
                fprintf(logger->log_file, "[%d] %s\n", ++logger->counter, msg);
                fflush(logger->log_file);
            }
        }

        // Return a struct containing a file pointer
        DLLEXPORT Logger create_logger(FILE* fp) {
            Logger l;
            l.log_file = fp;
            l.counter = 100;
            return l;
        }
        END_C

    # Define the struct type in Perl.
    # Use Pointer[File] because the C struct member is FILE*.
    typedef Logger => Struct [ log_file => Pointer [File], counter => Int ];

    # Bind functions
    affix $lib, 'init_logger',   [ Pointer [ Logger() ], Pointer [File] ] => Void;
    affix $lib, 'log_message',   [ Pointer [ Logger() ], String ]         => Void;
    affix $lib, 'create_logger', [ Pointer [File] ] => Logger();
    subtest 'File inside Struct (Pointer)' => sub {
        my ( $fh, $filename ) = tempfile();
        my $old_fh = select($fh);
        $| = 1;
        select($old_fh);

        # Allocate struct memory
        my $logger = malloc( sizeof( Logger() ) );

        # Pass filehandle to C to store in struct
        init_logger( $logger, $fh );

        # Verify via C function
        log_message( $logger, 'First message' );
        log_message( $logger, 'Second message' );

        # Verify Perl side struct access
        # Note: Pulling a File handle usually creates a new GLOB wrapper around the FILE*
        # Since we own $fh, let's verify checking against undef works
        my $logger_struct = cast( $logger, Logger() );    # View as struct
        my $retrieved_fh  = $logger_struct->{log_file};
        ok $retrieved_fh, 'Retrieved filehandle from struct';
        is ref($retrieved_fh), 'GLOB', 'It is a glob';

        # Write from Perl using retrieved handle
        # print {$retrieved_fh} "From Perl\n"; # Careful, might double-close if not careful
        # Check file content
        open my $check, '<', $filename;
        my @lines = <$check>;
        close $check;
        is scalar(@lines), 2, 'File has 2 lines';
        like $lines[0], qr/\[1\] First message/,  'Line 1 matches';
        like $lines[1], qr/\[2\] Second message/, 'Line 2 matches';
        free($logger);

        # Keep $fh alive until test end to avoid closing underneath C
        close $fh;
    };
    subtest 'File inside Struct (Value Return)' => sub {
        my ( $fh, $filename ) = tempfile();
        my $old_fh = select($fh);
        $| = 1;
        select($old_fh);

        # Call C function returning a struct by value
        my $logger_hash = create_logger($fh);
        is $logger_hash->{counter}, 100, 'Counter is correct';
        ok $logger_hash->{log_file}, 'Got filehandle back';
        is ref( $logger_hash->{log_file} ), 'GLOB', 'It is a glob';

        # Write using the returned handle to verify it works
        # Note: $logger_hash->{log_file} wraps the same FILE* as $fh.
        ok syswrite( $logger_hash->{log_file}, "Direct write from Perl\n" ), 'syswrite to the handle from Perl';

        # To avoid double-close warnings, we let Perl handle cleanup of the glob
        # but be careful about explicit closes.
        undef $logger_hash;

        # Check
        open my $check, '<', $filename;
        my $content = <$check>;
        close $check;
        is $content, "Direct write from Perl\n", 'Handle returned in struct is usable';
        close $fh;
    };
    subtest 'File in Array' => sub {
        my $lib2 = compile_ok(<<~'END_C2');
        #include "std.h"
        //ext: .c

        #include <stdio.h>

        DLLEXPORT void write_all(FILE* files[3], const char* msg) {
            for(int i=0; i<3; i++) {
                if(files[i]) fprintf(files[i], "%s", msg);
            }
        }
        END_C2

        # Array of Pointers to Files (FILE* files[3])
        affix $lib2, 'write_all', [ Array [ Pointer [File], 3 ], String ] => Void;
        my ( $fh1, $f1 ) = tempfile();
        my ( $fh2, $f2 ) = tempfile();
        my ( $fh3, $f3 ) = tempfile();

        # Flush buffers
        for my $h ( $fh1, $fh2, $fh3 ) { my $o = select($h); $| = 1; select($o); }

        # Pass array of handles
        write_all( [ $fh1, $fh2, $fh3 ], 'Broadcast' );
        close $_ for ( $fh1, $fh2, $fh3 );

        # Verify
        for my $f ( $f1, $f2, $f3 ) {
            open my $in, '<', $f;
            is <$in>, 'Broadcast', "File $f written to";
            close $in;
        }
    };
    subtest PerlIO => sub {

        # Define C code.
        # NOTE: We use void* and PerlIO types to avoid Windows CRT mismatch crashes.
        # This proves that we can store ANY pointer-sized handle in a struct and retrieve it.
        my $C_CODE = <<'END_C';
#include "std.h"
//ext: .c
// Define a struct that contains a handle (void* to allow PerlIO or FILE)
typedef struct {
    void* handle;
    int   counter;
} Logger;

// 1. Initialize logger with a handle
DLLEXPORT void init_logger2(Logger* logger, void* fp) {
    logger->handle = fp;
    logger->counter = 0;
}

// 2. Return a struct containing a handle
DLLEXPORT Logger create_logger2(void* fp) {
    Logger l;
    l.handle = fp;
    l.counter = 100;
    return l;
}

END_C
        my $lib = compile_ok($C_CODE);

        # Define the struct type in Perl using PerlIO for the handle
        # Struct member is PerlIO* so use Pointer[PerlIO]
        typedef Logger2 => Struct [ handle => Pointer [PerlIO], counter => Int ];

        # Bind functions using the defined struct
        affix $lib, 'init_logger2',   [ Pointer [ Logger2() ], Pointer [PerlIO] ] => Void;
        affix $lib, 'create_logger2', [ Pointer [PerlIO] ]                        => Logger2();
        subtest 'PerlIO inside Struct (Pointer)' => sub {
            my ( $fh, $filename ) = tempfile();
            syswrite $fh, "Original Content\n";

            # Allocate struct memory
            my $logger = malloc( sizeof( Logger2() ) );

            # Pass Perl filehandle to C. C stores the PerlIO* address.
            init_logger2( $logger, $fh );

            # Verify we can retrieve it back as a Glob
            my $logger_struct = cast( $logger, Logger2() );
            my $retrieved_fh  = $logger_struct->{handle};
            ok $retrieved_fh, 'Retrieved filehandle from struct';
            is ref($retrieved_fh), 'GLOB', 'It is a glob';

            # Verify it points to the same stream by writing to it
            syswrite $retrieved_fh, "Appended via Struct\n";
            close $fh;

            # Check file content
            open my $check, '<', $filename;
            my @lines = <$check>;
            close $check;
            is scalar(@lines), 2, 'File has 2 lines';
            like $lines[0], qr/Original Content/,    'Line 1 matches';
            like $lines[1], qr/Appended via Struct/, 'Line 2 matches';
            free($logger);
        };
        subtest 'PerlIO inside Struct (Value Return)' => sub {
            my ( $fh, $filename ) = tempfile();

            # Call C function returning a struct by value
            my $logger_hash = create_logger2($fh);
            is $logger_hash->{counter}, 100, 'Counter is correct';
            ok $logger_hash->{handle}, 'Got filehandle back';
            is ref( $logger_hash->{handle} ), 'GLOB', 'It is a glob';

            # Write using the returned handle
            syswrite $logger_hash->{handle}, "Write via Value Return\n";
            close $fh;

            # Verify content
            open my $check, '<', $filename;
            my $content = <$check>;
            close $check;
            is $content, "Write via Value Return\n", 'Handle returned in struct is usable';
        };
        subtest 'PerlIO in Array' => sub {

            # Quick dynamic test for array of handles
            my $C_CODE_ARRAY = <<'END_C2';
    #include "std.h"
    //ext: .c

    // Swap the first two handles in the array
    DLLEXPORT void swap_handles(void* handles[3]) {
        void* temp = handles[0];
        handles[0] = handles[1];
        handles[1] = temp;
    }
END_C2
            my $lib2 = compile_ok($C_CODE_ARRAY);

            # Array of PerlIO*
            affix $lib2, 'swap_handles', [ Array [ Pointer [PerlIO], 3 ] ] => Void;
            my ( $fh1, $f1 ) = tempfile();
            my ( $fh2, $f2 ) = tempfile();
            my ( $fh3, $f3 ) = tempfile();

            # Write distinct markers
            syswrite $fh1, 'File 1';
            syswrite $fh2, 'File 2';
            syswrite $fh3, 'File 3';

            # Pass array. C swaps 0 and 1.
            my $list = [ $fh1, $fh2, $fh3 ];
            swap_handles($list);

            # $list now reflects the C-side modification (Array Writeback)
            my $swapped_1 = $list->[0];
            my $swapped_2 = $list->[1];

            # Verify contents
            seek $swapped_1, 0, 0;
            seek $swapped_2, 0, 0;
            my $c1 = <$swapped_1>;
            my $c2 = <$swapped_2>;
            is $c1, 'File 2', 'Index 0 now contains File 2';
            is $c2, 'File 1', 'Index 1 now contains File 1';
            close $_ for ( $fh1, $fh2, $fh3 );
        }
    }
};
#
done_testing;
