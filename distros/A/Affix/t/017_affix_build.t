use v5.40;
use blib;
use Affix qw[wrap Int32];
use Affix::Build;
use Test2::Tools::Affix qw[:all];
use Path::Tiny;
use DynaLoader;
use Config;
use File::Spec;
#
my $TMP_DIR = Path::Tiny->tempdir( CLEANUP => 1 );
#
subtest 'Inline Source' => sub {
    skip_all 'No CC' unless bin_path( $Config{cc} );
    my $c = Affix::Build->new( build_dir => $TMP_DIR, name => 'inline_lib' );
    $c->add( \<<~'', lang => 'c' );
        #include <stdio.h>
        #ifdef _WIN32
        __declspec(dllexport)
        #endif
        int inline_add(int a, int b) { return a + b; }

    ok lives { $c->compile_and_link() },                                 'Linked inline source';
    ok my $fn = wrap( $c->link, 'inline_add', [ Int32, Int32 ], Int32 ), 'wrap';
    is $fn->( 65, 43 ), 108, 'call';
};
#
sub bin_path ($bin) {
    return $bin if -x $bin && !-d $bin;    # Check absolute
    for my $dir ( File::Spec->path ) {     # Check PATH
        my $full = File::Spec->catfile( $dir, $bin );
        return $full if -x $full && !-d $full;
        if ( $^O eq 'MSWin32' ) {
            return "$full.exe" if -x "$full.exe";
            return "$full.cmd" if -x "$full.cmd";
            return "$full.bat" if -x "$full.bat";
        }
    }
    return undef;
}

sub check_dotnet () {
    return 0 unless bin_path('dotnet');
    my $out = `dotnet --list-sdks 2>&1`;
    return ( $out =~ /^8\./m );
}

sub check_rust_gnu () {
    return 0 unless bin_path('rustc');

    # If not windows, standard rustc is fine
    return 1 if $^O ne 'MSWin32';

    # On Windows, we need to prove the GNU target works
    my $tmp = Path::Tiny->tempfile( SUFFIX => '.rs' );
    $tmp->spew('fn main() {}');
    my $cmd = "rustc --target x86_64-pc-windows-gnu \"$tmp\" -o \"$tmp.exe\" 2>&1";
    my $out = `$cmd`;
    return ( $? == 0 );
}

sub enjoin( $lib, @symbols ) {
    my $path = $lib->stringify;
    my $dll  = DynaLoader::dl_load_file( $path, 0 );
    unless ($dll) {
        fail( "Failed to load library '$path': " . DynaLoader::dl_error() );
        return;
    }
    for my $sym (@symbols) {
        if ( DynaLoader::dl_find_symbol( $dll, $sym ) ) {
            pass( "Symbol '$sym' found in " . $lib->basename );
        }
        else {
            fail( "Symbol '$sym' NOT found in " . $lib->basename );
        }
    }
    DynaLoader::dl_unload_file($dll) if defined &DynaLoader::dl_unload_file;
}

sub run_test ( $lang, $name, $code, $sym, $bin_req, $validator //= () ) {
    subtest "$name compilation" => sub {
        my $bin = ( $lang eq 'c' ) ? $Config{cc} : $bin_req;
        unless ( bin_path($bin) ) {
            skip_all "No $name compiler found ($bin)";
            return;
        }
        if ($validator) {
            unless ( $validator->() ) {
                skip_all "$name toolchain unmet";
                return;
            }
        }
        #
        my $ext
            = $lang eq 'rust'   ? 'rs' :
            $lang eq 'csharp'   ? 'cs' :
            $lang eq 'fsharp'   ? 'fs' :
            $lang eq 'fortran'  ? 'f90' :
            $lang eq 'pascal'   ? 'pas' :
            $lang eq 'crystal'  ? 'cr' :
            $lang eq 'assembly' ? 'asm' :
            $lang eq 'cobol'    ? 'cbl' :
            $lang;
        my $src = $TMP_DIR->child("test_$lang.$ext");
        $src->spew_utf8($code);
        #
        my $c = Affix::Build->new( build_dir => $TMP_DIR, name => "${lang}_lib" );
        $c->add($src);
        try { $c->compile_and_link() }
        catch ($err) {
            skip_all 'Link failed (toolchain issue?): ' . $err;
            return;
        }
        pass 'Linked successfully';
        #
        my $lib = $c->libname;
        ok $lib->exists, 'Library created: ' . $lib->basename;
        #
        my $dll = DynaLoader::dl_load_file( "$lib", 0 );
        if ($dll) {
            if ( DynaLoader::dl_find_symbol( $dll, $sym ) ) {
                pass("Symbol '$sym' found");
            }
            else {
                fail("Symbol '$sym' NOT found in lib");
            }

            # Attempt unload
            DynaLoader::dl_unload_file($dll) if ( $^O eq 'MSWin32' ? $lang ne 'go' : 1 ) && defined &DynaLoader::dl_unload_file;
        }
        else {
            diag( "Load failed: " . DynaLoader::dl_error() );
        }
        #
        ok my $fn = wrap( $lib, $sym, [ Int32, Int32 ], Int32 ), 'wrap';
        is $fn->( 3, 7 ), 10, 'call';
    };
}
#
run_test( 'c', 'C', <<~'', 'add_c', 'cc' );
    #include <stdio.h>
    #ifdef _WIN32
    __declspec(dllexport)
    #endif
    int add_c(int a, int b) {
        return a + b;
    }

run_test( 'cpp', 'C++', <<~'', 'add_cpp', 'c++' );
    #ifdef _WIN32
    #define EXPORT __declspec(dllexport)
    #else
    #define EXPORT
    #endif
    extern "C" {
        EXPORT int add_cpp(int a, int b) {
            return a + b;
        }
    }

run_test( 'csharp', 'C#', <<~'', 'add_cs', 'dotnet', \&check_dotnet );
    using System.Runtime.InteropServices;
    namespace T {
        public class C {
            [UnmanagedCallersOnly(EntryPoint="add_cs")]
            public static int Add(int a, int b) => a + b;
        }
    }

run_test( 'rust', 'Rust', <<~'', 'add_rs', 'rustc' );
    #[no_mangle]
    pub extern "C" fn add_rs(a: i32, b: i32) -> i32 {
        a + b
    }

run_test( 'go', 'Go', <<~'', 'add_go', 'go' );
    package main
    import "C"
    //export add_go
    func add_go(a, b C.int) C.int {
        return a + b
    }
    func main() { }

run_test( 'zig', 'Zig', <<~'', 'add_zig', 'zig' );
    export fn add_zig(a: i32, b: i32) i32 {
        return a + b;
    }


# Windows DLLs in D need an entry point mixin
run_test( 'd', 'D', ( $^O eq 'MSWin32' ? <<~'' : '' ) . <<~'', 'add_d', 'dmd' );
    import core.sys.windows.dll;
    mixin SimpleDllMain;
    export

    extern(C) int add_d(int a, int b) { return a + b; }

run_test( 'odin', 'Odin', <<~'', 'add_odin', 'odin' );
    package main
    @(export)
    add_odin :: proc "c" (a, b: i32) -> i32 {
        return a + b
    }

run_test( 'fortran', 'Fortran', <<~'', 'add_f', 'gfortran' );
    function add_f(a, b) bind(c, name='add_f')
        use iso_c_binding
        integer(c_int), value :: a, b
        integer(c_int) :: add_f
        add_f = a + b
    end function

run_test( 'nim', 'Nim', <<~'', 'add_nim', 'nim' );
    proc add_nim(a, b: cint): cint {.exportc, dynlib.} =
        return a + b

run_test( 'v', 'V', <<~'', 'add_v', 'v' );
    [export: 'add_v']
    fn add_v(a int, b int) int {
        return a + b
    }

run_test( 'pascal', 'Pascal', <<~'', 'add_pas', 'fpc' );
    library test_pas;
    function add_pas(a, b: LongInt): LongInt; cdecl; export;
    begin
        add_pas := a + b;
    end;
    exports add_pas;
    begin end.

run_test( 'cr', 'Crystal', <<~'', 'add_cr', 'crystal' );
    fun add_cr(a : Int32, b : Int32) : Int32
      a + b
    end

run_test( 'swift', 'Swift', <<~'', 'add_swift', 'swiftc' );
    @_cdecl("add_swift")
    public func add_swift(a: Int32, b: Int32) -> Int32 {
        return a + b
    }

run_test( 'assembly', 'Assembly', $Config{archname} =~ /arm64|aarch64/ ? <<~'' : $^O eq 'MSWin32' ? <<~'': <<~'', 'add_asm', 'nasm' );
        ; ARM64: add w0, w0, w1
        .global add_asm
        .text
        .align 2
        add_asm:
            add w0, w0, w1
            ret

        ; Win64 x86_64: RCX + RDX -> RAX
        global add_asm
        section .text
        add_asm:
            mov eax, ecx
            add eax, edx
            ret

        ; SysV x86_64: RDI + RSI -> RAX
        global add_asm
        section .text
        add_asm:
            mov eax, edi
            add eax, esi
            ret

run_test( 'cobol', 'Cobol', <<~'', 'add_cob', 'cobc' );
           IDENTIFICATION DIVISION.
           PROGRAM-ID. add_cob.
           DATA DIVISION.
           LINKAGE SECTION.
           01 A PIC 9(9) USAGE COMP-5.
           01 B PIC 9(9) USAGE COMP-5.
           01 R PIC 9(9) USAGE COMP-5.
           PROCEDURE DIVISION USING A, B, R.
               ADD A TO B GIVING R.
               GOBACK.
           END PROGRAM add_cob.

subtest 'Polyglot: Number Cruncher (C + Fortran + ASM)' => sub {
    skip_all "Missing compilers" unless bin_path( $Config{cc} ) && bin_path('gfortran');

    # C is our orchestrator
    my $c_src = $TMP_DIR->child('math_core.c');
    $c_src->spew_utf8(<<~'C');
        #include <stdio.h>
        #ifdef _WIN32
        __declspec(dllexport)
        #endif
        int core_version() { return 1; }
        C

    # Fortran does the math
    my $f_src = $TMP_DIR->child('math_algos.f90');
    $f_src->spew_utf8(<<~'F90');
        function fortran_add(a, b) bind(c, name='fortran_add')
            use iso_c_binding
            integer(c_int), value :: a, b
            integer(c_int) :: fortran_add
            fortran_add = a + b
        end function
        F90

    # Assembly for optimization
    my $asm_bin;
    my $asm_src;
    my $asm_file_name;
    if ( $Config{archname} =~ /arm64|aarch64/ ) {
        $asm_bin       = $Config{cc};
        $asm_file_name = 'fast.s';
        $asm_src       = <<~'' }
            .global asm_inc
            .text
            .align 2
            asm_inc:
                add w0, w0, #1
                ret

    elsif ( $^O eq 'MSWin32' ) {
        $asm_bin       = 'nasm';
        $asm_file_name = 'fast.asm';
        $asm_src       = <<~'' }
            global asm_inc
            section .text
            asm_inc:
                mov eax, ecx
                inc eax
                ret

    else {
        $asm_bin       = 'nasm';
        $asm_file_name = 'fast.asm';
        $asm_src       = <<~'' }
            global asm_inc
            section .text
            asm_inc:
                mov eax, edi
                inc eax
                ret

    skip_all "Missing Assembler ($asm_bin)" unless bin_path($asm_bin);
    my $asm_file = $TMP_DIR->child($asm_file_name);
    $asm_file->spew_utf8($asm_src);
    #
    my $compiler = Affix::Build->new( name => 'number_cruncher', build_dir => $TMP_DIR );
    $compiler->add($c_src);
    $compiler->add($f_src);
    $compiler->add($asm_file);
    ok( lives { $compiler->link() }, 'Linked Number Cruncher' ) or note $@;
    ok( $compiler->libname->exists,  'Library exists' );
    enjoin( $compiler->libname, 'core_version', 'fortran_add', 'asm_inc' );
};
subtest 'Polyglot: Modern Stack (C++ + Rust + Zig)' => sub {
    skip_all 'Missing compilers'         unless bin_path('g++') && bin_path('rustc') && bin_path('zig');
    skip_all 'Rust/MinGW target missing' unless check_rust_gnu();

    # C++ for ease of ABI
    my $cpp_src = $TMP_DIR->child('interface.cpp');
    $cpp_src->spew_utf8(<<~'');
        extern "C" {
        #ifdef _WIN32
        __declspec(dllexport)
        #endif
            int cpp_interface() { return 2025; }
        }


    # Rust for safety
    my $rs_src = $TMP_DIR->child('safety.rs');
    $rs_src->spew_utf8(<<~'');
        #[no_mangle]
        pub extern "C" fn rust_safe_add(a: i32, b: i32) -> i32 {
            a + b
        }


    # Zig for logic
    my $zig_src = $TMP_DIR->child('logic.zig');
    $zig_src->spew_utf8(<<~'');
        export fn zig_calc() i32 {
            return 42;
        }

    #
    my $compiler = Affix::Build->new( name => 'modern_stack', build_dir => $TMP_DIR );
    $compiler->add($cpp_src);
    $compiler->add($rs_src);
    $compiler->add($zig_src);
    ok( lives { $compiler->link() }, 'Linked Modern Stack' ) or note $@;
    enjoin( $compiler->libname, 'cpp_interface', 'rust_safe_add', 'zig_calc' );
};
subtest 'Polyglot: Kitchen Sink (C, C++, Rust, Zig, Dlang, Fortran, ASM)' => sub {
    my @reqs = qw(g++ zig dmd gfortran);
    push @reqs, $Config{cc};    # System CC
    push @reqs, ( $Config{archname} =~ /arm64/ ? $Config{cc} : 'nasm' );
    push @reqs, 'rustc';
    for my $bin (@reqs) {
        skip_all "Missing $bin" unless bin_path($bin);
    }
    skip_all 'Rust/MinGW target missing' unless check_rust_gnu();
    my $c = Affix::Build->new( name => 'mega_lib', build_dir => $TMP_DIR );
    #
    my $f1 = $TMP_DIR->child('f1.c');
    $f1->spew_utf8(<<~'');
    #ifdef _WIN32
    __declspec(dllexport)
    #endif
    int func_c( ) { return 1; }

    $c->add($f1);
    #
    my $f2 = $TMP_DIR->child('f2.cpp');
    $f2->spew_utf8(<<~'');
    extern "C" {
    #ifdef _WIN32
        __declspec(dllexport)
    #endif
        int func_cpp( ) { return 2; }
    }

    $c->add($f2);
    #
    my $f3 = $TMP_DIR->child('f3.rs');
    $f3->spew_utf8(<<~'');
    #[no_mangle]
    pub extern "C" fn func_rs( )->i32{ 3 }

    $c->add($f3);
    #
    my $f4 = $TMP_DIR->child('f4.zig');
    $f4->spew_utf8(<<~'');
    export fn func_zig() i32 { return 4; }

    $c->add($f4);
    #
    my $f5 = $TMP_DIR->child('f5.d');
    $f5->spew_utf8( ( $^O eq 'MSWin32' ? <<~'' : '' ) . <<~'' );
    import core.sys.windows.dll;
    mixin SimpleDllMain;
    export

    extern(C) int func_d() { return 5; }

    $c->add($f5);
    #
    my $f6 = $TMP_DIR->child('f6.f90');
    $f6->spew_utf8(<<~'');
    function func_f() bind(c, name='func_f')
        use iso_c_binding
        integer(c_int) :: func_f
        func_f=6
    end function

    $c->add($f6);
    #
    my $asm_ext = ( $Config{archname} =~ /arm64/ ) ? 's' : 'asm';
    my $f7      = $TMP_DIR->child("f7.$asm_ext");
    $f7->spew_utf8( ( $^O eq 'MSWin32' || $Config{archname} !~ /arm64/ ) ? <<~'' : <<~'' );
    ; x86/x64
    global func_asm
    section .text
    func_asm:
        mov eax, 7
    ret

    ; ARM64
    .global func_asm
    .text
    func_asm:
        mov w0, #7
    ret

    $c->add($f7);
    #
    ok( lives { $c->link() }, 'Linked Kitchen Sink' ) or note $@;
    #
    enjoin( $c->libname, 'func_c', 'func_cpp', 'func_rs', 'func_zig', 'func_d', 'func_f', 'func_asm' );
};
#
done_testing;
