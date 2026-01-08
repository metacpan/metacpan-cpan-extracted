package Affix::Build v1.0.3 {
    use v5.40;
    use experimental qw[class try];
    use Config;
    use Path::Tiny;
    use File::Spec;
    use Carp          qw[croak];
    use Capture::Tiny qw[capture];
    use ExtUtils::MakeMaker;
    use Text::ParseWords;

    class Affix::Build {

        # Public Parameters
        field $os        : param : reader //= $^O;
        field $clean     : param : reader //= 0;
        field $build_dir : param : reader //= Path::Tiny->tempdir( CLEANUP => $clean );
        field $name      : param : reader //= 'affix_lib';
        field $debug     : param : reader //= 0;
        field $version   : param : reader //= ();

        # Global flags applied to all compilations of that type
        # cflags, cxxflags, ldflags, rustflags, etc.
        field $flags : param : reader //= {};

        # Internal State
        field @sources;
        field $libname : reader;
        field $linker  : reader;

        # Cached Flag Arrays
        field @cflags;
        field @cxxflags;
        field @ldflags;
        field $_lib;
        #
        ADJUST {
            my $so_ext = $Config{so} // 'so';

            # Standard convention: Windows DLLs don't need 'lib' prefix, Unix SOs do.
            my $prefix = ( $os eq 'MSWin32' || $name =~ /^lib/ ) ? ''          : 'lib';
            my $suffix = defined $version                        ? ".$version" : '';
            $libname = $build_dir->child("$prefix$name.$so_ext$suffix")->absolute;

            # We prefer C++ drivers (g++, clang++) to handle standard libraries for mixed code (C+Rust, C+C++)
            $linker = $self->_can_run(qw[g++ clang++ c++ icpx]) || $self->_can_run(qw[cc gcc clang icx cl]) || 'c++';

            # Parse global flags...
            @cflags   = map { chomp; $_ } grep { defined && length } Text::ParseWords::parse_line( q/ /, 1, $flags->{cflags}   // '' );
            @cxxflags = map { chomp; $_ } grep { defined && length } Text::ParseWords::parse_line( q/ /, 1, $flags->{cxxflags} // '' );
            @ldflags  = map { chomp; $_ } grep { defined && length } Text::ParseWords::parse_line( q/ /, 1, $flags->{ldflags}  // '' );
        }

        method add ( $input, %args ) {
            $_lib = ();                        # Reset cached library handle
            my ( $path, $lang );
            if ( ref $input eq 'SCALAR' ) {    # Inline source code
                $args{lang} // croak q[Parameter 'lang' (extension) is required for inline source];
                $lang = lc $args{lang};

                # Generate a unique filename in the build dir
                state $counter = 0;
                my $fname = sprintf( "source_%03d.%s", ++$counter, $lang );
                $path = $build_dir->child($fname);
                $path->spew_utf8($$input);
            }
            else {                             #  File path
                $path = Path::Tiny::path($input)->absolute;
                croak "File not found: $path" unless $path->exists;
                ($lang) = $path =~ /\.([^.]+)$/;
                $lang = lc( $lang // '' );
            }

            # Handle local flags
            my $local_flags = $args{flags} // [];
            $local_flags = [ split ' ', $local_flags ] unless builtin::reftype $local_flags eq 'ARRAY';
            push @sources, { path => $path, lang => $lang, flags => $local_flags };
        }

        method compile_and_link () {
            croak "No sources added" unless @sources;

            # Check if we are mixing languages
            my %langs = map { $_->{lang} => 1 } @sources;
            if ( ( scalar keys %langs ) > 1 ) {
                return $self->_strategy_polyglot();
            }
            return $_lib = $self->_strategy_native();
        }
        method link { $_lib //= $self->compile_and_link(); $_lib }

        # Used when only one language is present. We delegate the entire build process
        # to that language's compiler to produce the final shared library.
        method _strategy_native () {
            my $src     = $sources[0];
            my $l       = $src->{lang};
            my $handler = $self->_resolve_handler($l);
            return $self->$handler( $src, $libname, 'dynamic' );
        }

        # Used when mixing languages (e.g. C + Rust). We compile everything to
        # static artifacts (.o or .a) and then use the system linker to combine them.
        method _strategy_polyglot () {
            my ( @files, @libs );
            foreach my $src (@sources) {
                my $handler = $self->_resolve_handler( $src->{lang} );

                # Request 'static' output from the handler
                my $res = $self->$handler( $src, undef, 'static' );
                push @files, $res->{file};
                push @libs,  @{ $res->{libs} } if $res->{libs};
            }

            # Link step
            my @cmd = ($linker);
            push @cmd, $os eq 'MSWin32' ? ('-shared') : ( '-shared', '-fPIC' );
            push @cmd, '-Wl,--export-all-symbols' if $os eq 'MSWin32' && $linker =~ /gcc|g\+\+|clang/;
            push @cmd, '-o', $libname->stringify;

            # MinGW Static Lib Fix: --whole-archive ensures unused symbols (like language runtimes) are kept
            my $is_gcc = ( $linker =~ /gcc|g\+\+|clang/ || $Config{cc} =~ /gcc/ );
            foreach my $f (@files) {
                my $p = "$f";
                if ( $is_gcc && $p =~ /\Q$Config{_a}\E$/ ) {
                    push @cmd, '-Wl,--whole-archive', $p, '-Wl,--no-whole-archive';
                }
                else {
                    push @cmd, $p;
                }
            }
            my %seen;
            for my $l (@libs) {
                next if $seen{$l}++;
                push @cmd, "-l$l";
            }
            push @cmd, @ldflags;
            $self->_run(@cmd);
            return $libname;
        }

        # Helper to map extensions to method names
        method _resolve_handler ($l) {

            # Normalize
            if    ( $l =~ /^(cpp|cxx|cc|c\+\+)$/ )      { return '_build_cpp'; }
            elsif ( $l =~ /^(f|f90|f95|for|fortran)$/ ) { return '_build_fortran'; }
            elsif ( $l =~ /^(ru?st?)$/ )                { return '_build_rust'; }
            elsif ( $l =~ /^(cs|csharp|c#)$/ )          { return '_build_csharp'; }
            elsif ( $l =~ /^(fs|fsharp|f#)$/ )          { return '_build_fsharp'; }
            elsif ( $l =~ /^(s|asm|assembly)$/ )        { return '_build_asm'; }
            elsif ( $l =~ /^(adb|ads|ada)$/ )           { return '_build_ada'; }
            elsif ( $l =~ /^(hs|lhs|haskell)$/ )        { return '_build_haskell'; }
            elsif ( $l =~ /^(cr|crystal)$/ )            { return '_build_crystal'; }
            elsif ( $l =~ /^(fut|futhark)$/ )           { return '_build_futhark'; }
            elsif ( $l =~ /^(pas|pp|pascal)$/ )         { return '_build_pascal'; }
            elsif ( $l =~ /^(cbl|cob|cobol)$/ )         { return '_build_cobol'; }
            elsif ( $l =~ /^(ml|ocaml)$/ )              { return '_build_ocaml'; }
            elsif ( $l =~ /^(e|eiffel)$/ )              { return '_build_eiffel'; }
            elsif ( $l =~ /^(go)$/ )                    { return '_build_go'; }
            elsif ( $l =~ /^(zig)$/ )                   { return '_build_zig'; }
            elsif ( $l =~ /^(odin)$/ )                  { return '_build_odin'; }
            elsif ( $l =~ /^(nim)$/ )                   { return '_build_nim'; }
            elsif ( $l =~ /^(d|dlang)$/ )               { return '_build_d'; }
            elsif ( $l =~ /^(swift)$/ )                 { return '_build_swift'; }
            elsif ( $l =~ /^(v|vlang)$/ )               { return '_build_v'; }

            # Fallback to C
            return '_build_c';
        }

        method _run (@cmd) {
            print STDERR "[Affix] Exec: @cmd\n" if $debug;

            # use Data::Dump;
            # ddx \@cmd;
            my ( $stdout, $stderr, $exit ) = capture {
                system @cmd;
            };
            if ( !!$exit ) {
                warn $stdout if $stdout;
                warn $stderr if $stderr;
                my $rc = $exit >> 8;
                croak "Command failed (Exit $rc): @cmd";
            }
        }

        method _can_run (@cmd) {
            for my $c (@cmd) {
                return $c if MM->maybe_command($c);
                for my $dir ( File::Spec->path ) {
                    my $abs = File::Spec->catfile( $dir, $c );
                    return $abs if MM->maybe_command($abs);
                }
            }
            return undef;
        }
        method _base ($file) { return $file->basename(qr/\.[^.]+$/); }
        #
        method _build_c ( $src, $out, $mode ) {
            my $file  = $src->{path};
            my @local = @{ $src->{flags} };
            my $cc    = $Config{cc} // 'cc';
            if ( $mode eq 'dynamic' ) {

                # Combine Global CFLAGS + Local Flags + Global LDFLAGS
                my @cmd = ( $cc, '-shared', @cflags, @local, "$file", '-o', "$out", @ldflags );
                push @cmd, '-fPIC' unless $os eq 'MSWin32';
                $self->_run(@cmd);
                return $out;
            }
            else {
                my $obj = $build_dir->child( $self->_base($file) . $Config{_o} );

                # Combine Global CFLAGS + Local Flags
                my @cmd = ( $cc, '-c', @cflags, @local, "$file", '-o', "$obj" );
                push @cmd, '-fPIC' unless $os eq 'MSWin32';
                $self->_run(@cmd);
                return { file => $obj };
            }
        }

        method _build_cpp ( $src, $out, $mode ) {
            my $file  = $src->{path};
            my @local = @{ $src->{flags} };
            my $cxx   = ( $Config{cc} =~ /gcc/ ) ? 'g++' : ( ( $Config{cc} =~ /clang/ ) ? 'clang++' : 'c++' );
            if ( $mode eq 'dynamic' ) {
                my @cmd = ( $cxx, '-shared', @cxxflags, @local, "$file", '-o', "$out", @ldflags );
                push @cmd, '-fPIC' unless $os eq 'MSWin32';
                $self->_run(@cmd);
                return $out;
            }
            else {
                my $obj = $build_dir->child( $self->_base($file) . $Config{_o} );
                my @cmd = ( $cxx, '-c', @cxxflags, @local, "$file", '-o', "$obj" );
                push @cmd, '-fPIC' unless $os eq 'MSWin32';
                $self->_run(@cmd);
                return { file => $obj };
            }
        }

        #~ https://fasterthanli.me/series/making-our-own-executable-packer/part-5
        #~ https://stackoverflow.com/questions/71704813/writing-and-linking-shared-libraries-in-assembly-32-bit
        #~ https://github.com/therealdreg/nasm_linux_x86_64_pure_sharedlib
        method _build_asm ( $src, $out, $mode ) {
            my $file  = $src->{path};
            my @local = @{ $src->{flags} };
            my $obj   = $build_dir->child( $self->_base($file) . $Config{_o} );

            # Detect Assembler Type: .asm (Intel/NASM) vs .s (AT&T/CC)
            my $is_nasm  = ( $file =~ /\.asm$/i );
            my $compiled = 0;
            if ($is_nasm) {    # .asm = Intel syntax = NASM
                my $nasm = $self->_can_run('nasm') // croak "NASM not found";
                my $fmt  = $os eq 'MSWin32' ? 'win64' : ( $os eq 'darwin' ? 'macho64' : 'elf64' );
                $self->_run( $nasm, '-f', $fmt, @local, "$file", '-o', "$obj" );
                $compiled = 1;
            }
            else {             # .s = AT&T/GNU syntax = System CC
                my $cc = $Config{cc};
                if ( $cc && $self->_can_run($cc) ) {
                    my @cmd = ( $cc, '-c', @local, "$file", '-o', "$obj" );
                    push @cmd, '-fPIC' unless $os eq 'MSWin32';
                    $self->_run(@cmd);
                    $compiled = 1;
                }
            }
            croak 'Assembly failed' unless $compiled && -e "$obj";
            if ( $mode eq 'dynamic' ) {
                my @cmd = ( $linker, '-shared', "$obj", '-o', "$out", @ldflags );
                push @cmd, '-fPIC' unless $os eq 'MSWin32';
                if ( $os eq 'MSWin32' && $linker =~ /gcc|g\+\+/ ) {
                    push @cmd, '-Wl,--export-all-symbols';
                }
                $self->_run(@cmd);
                return $out;
            }
            return { file => $obj };
        }

        #~ https://blog.asleson.org/2021/02/23/how-to-writing-a-c-shared-library-in-rust/
        method _build_rust ( $src, $out, $mode ) {
            my $file  = $src->{path};
            my @local = @{ $src->{flags} };
            my $rc    = $self->_can_run('rustc') // croak "Rustc not found";
            if ( $mode eq 'dynamic' ) {
                $self->_run( $rc, '--crate-type', 'cdylib', @local, '-o', "$out", "$file" );
                return $out;
            }
            else {
                my $lib = $build_dir->child( $self->_base($file) . $Config{_a} );
                my @cmd = ( $rc, '--crate-type=staticlib', '--emit=link', '-C', 'panic=abort', @local, "$file", '-o', "$lib" );

                # Force GNU target on MinGW to ensure compatibility with Perl's linker
                if ( $os eq 'MSWin32' && $Config{cc} =~ /gcc/ ) {
                    push @cmd, '--target', 'x86_64-pc-windows-gnu';
                }
                elsif ( $os ne 'MSWin32' ) {
                    push @cmd, '-C', 'relocation-model=pic';
                }
                $self->_run(@cmd);
                my @deps = $os eq 'MSWin32' ? qw(ws2_32 userenv bcrypt advapi32 ntdll) : qw(dl pthread m);
                return { file => $lib, libs => \@deps };
            }
        }

        #~ https://medium.com/@walkert/fun-building-shared-libraries-in-go-639500a6a669
        #~ https://github.com/vladimirvivien/go-cshared-examples
        method _build_go ( $src, $out, $mode ) {
            my $file  = $src->{path};
            my @local = @{ $src->{flags} };    # passed to go build args

            # MinGW GCC 8.3.0 had known issues guaranteeing the 16-byte stack alignment required by the
            # Go runtime (and SSE/AVX instructions) on Windows x64. If Perl calls your library with a
            # 8-byte aligned stack (which was common in older GCC optimization flags), Go will segfault
            # immediately when it tries to access the stack.
            push @local, q[-ldflags "-extldflags '-static -static-libgcc -static-libstdc++'"] if $^O eq 'MSWin32';
            if ( $mode eq 'dynamic' ) {
                $self->_run( 'go', 'build', '-buildmode=c-shared', @local, '-o', "$out", "$file" );
                return $out;
            }
            else {
                my $lib = $build_dir->child( $self->_base($file) . $Config{_a} );
                $self->_run( 'go', 'build', '-buildmode=c-archive', @local, '-o', "$lib", "$file" );
                return { file => $lib, libs => ['pthread'] };
            }
        }

        #~ https://odin-lang.org/news/calling-odin-from-python/
        #~ https://odin-lang.org/docs/install/#release-requirements--notes
        method _build_odin ( $src, $out, $mode ) {
            my $file  = $src->{path};
            my @local = @{ $src->{flags} };
            my $odin  = $self->_can_run('odin') // croak "Odin not found";
            if ( $mode eq 'dynamic' ) {
                $self->_run( $odin, 'build', "$file", '-file', '-build-mode:dll', @local, "-out:$out" );
                return $out;
            }
            else {
                my $obj = $build_dir->child( $self->_base($file) . $Config{_o} );
                my @cmd = ( $odin, 'build', "$file", '-file', '-build-mode:obj', @local, "-out:$obj" );
                push @cmd, '-reloc-mode:pic' unless $os eq 'MSWin32';
                $self->_run(@cmd);
                unless ( $obj->exists ) {    # Attempt to find it if Odin misnamed it (e.g. .obj vs .o)
                    my $cwd_obj = Path::Tiny::path( $self->_base($file) . $Config{_o} );
                    $cwd_obj->move($obj) if $cwd_obj->exists;
                }
                return { file => $obj };
            }
        }

        #~ https://dlang.org/articles/dll-linux.html#dso9
        #~ dmd -c dll.d -fPIC
        #~ dmd -oflibdll.so dll.o -shared -defaultlib=libphobos2.so -L-rpath=/path/to/where/shared/library/is
        method _build_d ( $src, $out, $mode ) {
            my $file = $src->{path};
            my $dmd  = $self->_can_run(qw[dmd ldc2 gdc]) // croak "D compiler not found";
            if ( $mode eq 'dynamic' ) {
                my @cmd = ( $dmd, '-shared', "$file", "-of=$out" );
                push @cmd, '-fPIC' unless $os eq 'MSWin32';
                $self->_run(@cmd);
                return $out;
            }
            else {
                my $lib = $build_dir->child( $self->_base($file) . $Config{_a} );
                my @cmd = ( $dmd, '-lib', "$file", "-of=$lib" );
                push @cmd, '-fPIC' unless $os eq 'MSWin32';
                $self->_run(@cmd);
                return { file => $lib };
            }
        }
        method _build_csharp ( $file, $out, $mode ) { $self->_build_dotnet( $file, $out, $mode, 'cs' ); }

        #~ https://github.com/secana/Native-FSharp-Library
        #~ https://secanablog.wordpress.com/2020/02/01/writing-a-native-library-in-f-which-can-be-called-from-c/
        method _build_fsharp ( $file, $out, $mode ) { $self->_build_dotnet( $file, $out, $mode, 'fs' ); }

        method _build_dotnet ( $src, $out, $mode, $lang ) {
            my $file     = $src->{path};
            my $dotnet   = $self->_can_run('dotnet') // croak "Dotnet not found";
            my $proj_dir = $build_dir->child( "dotnet_${lang}_" . $self->_base($file) );
            $proj_dir->mkpath;
            $file->copy( $proj_dir->child( $file->basename ) );
            my $ext      = $lang eq 'fs' ? 'fsproj' : 'csproj';
            my $proj     = $proj_dir->child("Build.$ext");
            my $lib_type = ( $mode eq 'dynamic' ) ? 'Shared'                                               : 'Static';
            my $items    = $lang eq 'fs'          ? '<ItemGroup><Compile Include="**/*.fs" /></ItemGroup>' : '';
            $proj->spew_utf8(<<"XML");
<Project Sdk="Microsoft.NET.Sdk">
<PropertyGroup>
<TargetFramework>net8.0</TargetFramework>
<PublishAot>true</PublishAot>
<NativeLib>$lib_type</NativeLib>
<SelfContained>true</SelfContained>
</PropertyGroup>
$items
</Project>
XML
            my $out_dir = $proj_dir->child('out');
            my $rid     = $os eq 'MSWin32' ? 'win-x64' : 'linux-x64';

            # Local flags? Dotnet CLI args are tricky, assuming they aremsbuild props?
            # Ignoring for now to keep it safe, or pass as raw args if user knows what they do.
            my @local = @{ $src->{flags} };
            $self->_run( "$dotnet", 'publish', "$proj", '-r', $rid, '-o', "$out_dir", @local );
            if ( $mode eq 'dynamic' ) {
                my $dll_ext = $Config{so};
                $dll_ext = ".$dll_ext" unless $dll_ext =~ /^\./;
                my ($artifact) = grep {/\Q$dll_ext\E$/} $out_dir->children;
                croak "Dotnet build failed" unless $artifact;
                Path::Tiny::path($artifact)->move($out);
                return $out;
            }
            else {
                my $lib_ext = $Config{_a};
                my ($artifact) = grep {/\Q$lib_ext\E$/} $out_dir->children;
                croak "Dotnet build failed" unless $artifact;
                return { file => Path::Tiny::path($artifact) };
            }
        }

        #~ https://ziglang.org/documentation/0.13.0/#Exporting-a-C-Library
        #~ zig build-lib mathtest.zig -dynamic
        method _build_zig ( $src, $out, $mode ) {
            my $file  = $src->{path};
            my @local = @{ $src->{flags} };
            my $zig   = $self->_can_run('zig') // croak "Zig not found";
            if ( $mode eq 'dynamic' ) {
                $self->_run( $zig, 'build-lib', '-dynamic', @local, "$file", "-femit-bin=$out" );
                return $out;
            }
            else {
                my $lib = $build_dir->child( $self->_base($file) . $Config{_a} );
                $self->_run( $zig, 'build-lib', '-static', @local, "$file", "-femit-bin=$lib" );
                return { file => $lib, libs => ( $os eq 'MSWin32' ? ['ntdll'] : [] ) };
            }
        }

        method _build_fortran ( $src, $out, $mode ) {
            my $file  = $src->{path};
            my @local = @{ $src->{flags} };
            my $fc    = $self->_can_run(qw[gfortran ifx ifort]) // croak "No Fortran compiler";
            if ( $mode eq 'dynamic' ) {
                my @cmd = ( $fc, '-shared', @local, "$file", '-o', "$out", @ldflags );
                push @cmd, '-fPIC' unless $os eq 'MSWin32';
                $self->_run(@cmd);
                return $out;
            }
            else {
                my $obj = $build_dir->child( $self->_base($file) . $Config{_o} );
                my @cmd = ( $fc, '-c', @local, "$file", '-o', "$obj" );
                push @cmd, '-fPIC' unless $os eq 'MSWin32';
                $self->_run(@cmd);
                return { file => $obj, libs => ( $os eq 'MSWin32' ? [] : ['gfortran'] ) };
            }
        }

        #~ https://peterme.net/dynamic-libraries-in-nim.html
        method _build_nim ( $src, $out, $mode ) {
            my $file = $src->{path};
            my $nim  = $self->_can_run('nim') // croak "Nim not found";
            if ( $mode eq 'dynamic' ) {
                $self->_run( $nim, 'c', '--app:lib', '--noMain', '--cc:c', "--out:$out", "$file" );
                return $out;
            }
            else {
                my $lib = $build_dir->child( $self->_base($file) . $Config{_a} );
                $self->_run( $nim, 'c', '--app:staticlib', '--noMain', '--cc:c', '--nimcache:' . $build_dir, "--out:$lib", "$file" );
                return { file => $lib };
            }
        }

        #~ https://www.rangakrish.com/index.php/2023/04/02/building-v-language-dll/
        #~ https://dev.to/piterweb/how-to-create-and-use-dlls-on-vlang-1p13
        method _build_v ( $src, $out, $mode ) {
            my $file = $src->{path};
            my $v    = $self->_can_run('v') // croak "V not found";
            if ( $mode eq 'dynamic' ) {
                $self->_run( $v, '-shared', '-o', "$out", "$file" );
                return $out;
            }
            else {
                my $c_file = $build_dir->child( $self->_base($file) . '.c' );
                $self->_run( $v, '-o', "$c_file", "$file" );
                return $self->_build_c( { path => $c_file }, undef, 'static' );
            }
        }

        #~ swiftc point.swift -emit-module -emit-library
        #~ https://forums.swift.org/t/creating-a-c-accessible-shared-library-in-swift/45329/5
        #~ https://theswiftdev.com/building-static-and-dynamic-swift-libraries-using-the-swift-compiler/#should-i-choose-dynamic-or-static-linking
        method _build_swift ( $src, $out, $mode ) {
            my $file = $src->{path};
            my $sc   = $self->_can_run('swiftc') // croak "Swiftc not found";

            # Swiftc uses -emit-library for both, just differs on output filename usually
            # But for static we usually want -static if available or just .a
            if ( $mode eq 'dynamic' ) {
                $self->_run( $sc, '-emit-library', "$file", '-o', "$out" );
                return $out;
            }
            else {
                my $lib = $build_dir->child( $self->_base($file) . $Config{_a} );

                # Note: Swift static linking is complex on Linux, but -emit-library -static usually works
                $self->_run( $sc, '-emit-library', '-static', '-parse-as-library', "$file", '-o', "$lib" );
                return { file => $lib };
            }
        }

        #~ https://gcc.gnu.org/onlinedocs/gcc-3.4.0/gnat_ug_unx/Creating-an-Ada-Library.html
        method _build_ada ( $src, $out, $mode ) {
            my $file = $src->{path};
            my $gnat = $self->_can_run('gnatmake') // croak "GNAT not found";

            # Ada compilation is usually to Object first
            my $obj = $build_dir->child( $self->_base($file) . $Config{_o} );
            my @cmd = ( $gnat, '-c', '-u', "$file" );
            push @cmd, '-fPIC' unless $os eq 'MSWin32';

            # GNAT often outputs to CWD
            $self->_run(@cmd);
            my $cwd_obj = Path::Tiny::path( $self->_base($file) . $Config{_o} );
            $cwd_obj->move($obj) if $cwd_obj->exists && $cwd_obj->absolute ne $obj->absolute;
            if ( $mode eq 'dynamic' ) {

                # Link the object to shared
                # We use the generic linker logic for this single file
                my $linker = $Config{cc} // 'cc';
                $self->_run( $linker, '-shared', '-o', "$out", "$obj" );
                return $out;
            }
            return { file => $obj, libs => ['gnat'] };
        }

        #~ https://github.com/bennoleslie/haskell-shared-example
        #~ https://www.hobson.space/posts/haskell-foreign-library/
        method _build_haskell ( $src, $out, $mode ) {
            my $file = $src->{path};
            my $ghc  = $self->_can_run('ghc') // croak "GHC not found";
            if ( $mode eq 'dynamic' ) {
                my @cmd = ( $ghc, '-shared', '-dynamic', "$file", '-o', "$out" );
                push @cmd, '-fPIC' unless $os eq 'MSWin32';
                $self->_run(@cmd);
                return $out;
            }
            else {
                my $obj = $build_dir->child( $self->_base($file) . $Config{_o} );
                my @cmd = ( $ghc, '-c', "$file", '-o', "$obj", '-no-hs-main' );
                push @cmd, '-fPIC' unless $os eq 'MSWin32';
                $self->_run(@cmd);
                return { file => $obj };
            }
        }

        #~ https://github.com/crystal-lang/crystal/issues/921#issuecomment-2413541412
        method _build_crystal ( $src, $out, $mode ) {
            my $file = $src->{path};
            my $cr   = $self->_can_run('crystal') // croak "Crystal not found";
            if ( $mode eq 'dynamic' ) {

                # Experimental: Attempt to pass linker flags
                # Crystal doesn't have a native 'build shared' flag easily exposed
                # It prefers static binaries.
                $self->_run( $cr, 'build', "$file", '--link-flags', '-shared', '-o', "$out" );
                return $out;
            }
            else {
                my $obj = $build_dir->child( $self->_base($file) . $Config{_o} );
                my @cmd = ( $cr, 'build', '--emit', 'obj', "$file", '-o', "$obj" );
                push @cmd, '--link-flags', '-fPIC' unless $os eq 'MSWin32';
                $self->_run(@cmd);
                return { file => $obj, libs => [ 'pcre', 'gc' ] };
            }
        }

        #~ https://futhark.readthedocs.io/en/stable/usage.html
        method _build_futhark ( $src, $out, $mode ) {
            my $file = $src->{path};
            my $fut  = $self->_can_run('futhark') // croak "Futhark not found";

            # Futhark -> C
            my $c_file = $build_dir->child( $self->_base($file) . '.c' );
            my $prefix = $build_dir->child( $self->_base($file) );
            $self->_run( $fut, 'c', '--library', "$file", '-o', "$prefix" );

            # Reuse C builder
            return $self->_build_c( { path => $c_file }, $out, $mode );
        }

        method _build_pascal ( $src, $out, $mode ) {
            my $file = $src->{path};
            my $fpc  = $self->_can_run('fpc') // croak "FPC not found";
            if ( $mode eq 'dynamic' ) {

                # Free Pascal needs 'library' keyword in source for shared libs usually
                # -CD creates dynamic lib
                $self->_run( $fpc, '-CD', "$file", "-o$out" );
                return $out;
            }
            else {
                my $obj = $build_dir->child( $self->_base($file) . $Config{_o} );
                my @cmd = ( $fpc, '-Cn', "$file", "-o$obj" );
                push @cmd, '-Cg' unless $os eq 'MSWin32';
                $self->_run(@cmd);
                return { file => $obj };
            }
        }

        method _build_cobol ( $file, $out, $mode ) {
            my $cobc = $self->_can_run('cobc') // croak "GnuCOBOL not found";
            if ( $mode eq 'dynamic' ) {

                # -b = build dynamic module
                $self->_run( $cobc, '-b', "$file", '-o', "$out" );
                return $out;
            }
            else {
                my $obj = $build_dir->child( $self->_base($file) . $Config{_o} );
                my @cmd = ( $cobc, '-c', "$file", '-o', "$obj" );
                push @cmd, '-fPIC' unless $os eq 'MSWin32';
                $self->_run(@cmd);
                return { file => $obj, libs => ['cob'] };
            }
        }

        method _build_ocaml ( $file, $out, $mode ) {
            my $ml = $self->_can_run('ocamlopt') // croak "OCaml not found";
            if ( $mode eq 'dynamic' ) {

                # ocamlopt -shared -o lib.so file.ml
                $self->_run( $ml, '-shared', "$file", '-o', "$out" );
                return $out;
            }
            my $obj = $build_dir->child( $self->_base($file) . $Config{_o} );
            $self->_run( $ml, '-output-obj', "$file", '-o', "$obj" );
            return { file => $obj };
        }

        #~ https://wiki.liberty-eiffel.org/index.php/Compile
        #~ https://svn.eiffel.com/eiffelstudio-public/branches/Eiffel_54/Delivery/docs/papers/dll.html
        method _build_eiffel ( $file, $out, $mode ) {
            my $se = $self->_can_run('se') // croak "SmartEiffel not found";

            # Transpile to C
            my $c_file = $build_dir->child( $self->_base($file) . '.c' );
            $self->_run( $se, 'c', '-o', "$c_file", "$file" );

            # Reuse C builder
            return $self->_build_c( $c_file, $out, $mode );
        }
    }
}
1;
__END__
Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.
