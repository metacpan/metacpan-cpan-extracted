use v5.40;
use feature 'class';
no warnings 'experimental::class';
class Alien::Xrepo 0.08 {
    use Alien::Xmake;
    use JSON::PP;
    use Path::Tiny;
    use Config;
    use Capture::Tiny qw[capture];
    #
    field $verbose : param //= 0;
    field $xmake = Alien::Xmake->new;
    method blah ($msg) { return unless $verbose; say $msg; }
    #
    class Alien::Xrepo::PackageInfo {
        use Path::Tiny;
        field $includedirs : param : reader;
        field $libfiles    : param : reader;
        field $license     : param : reader;
        field $linkdirs    : param : reader;
        field $links       : param : reader;
        field $shared      : param : reader;
        field $static      : param : reader;
        field $version     : param : reader;
        field $libpath     : param : reader //= ();
        field $bindirs     : param : reader //= [];

        # Helper to find a specific header inside the includedirs
        method find_header ($filename) {
            for my $dir (@$includedirs) {
                my $p = path($dir)->child($filename);
                return $p->stringify if $p->exists;
            }

            # Fallback check: sometimes xrepo returns the generic include root,
            # and the file is in a subdir (e.g. GL/gl.h)
            warn "Header '$filename' not found in package include directories:\n" . join( "\n", @$includedirs ) . "\n";
            return;
        }
        method bin_dir {@$bindirs}

        method _data_printer ($ddp) {
            {   includedirs => $includedirs,
                libfiles    => $libfiles,
                license     => $license,
                linkdirs    => $linkdirs,
                links       => $links,
                shared      => $shared,
                static      => $static,
                version     => $version,
                libpath     => $libpath,
                bindirs     => $bindirs
            }
        }
    }
    #
    method install ( $pkg_spec, $version //= (), %opts ) {
        my $full_spec = defined $version && length $version ? "$pkg_spec $version" : $pkg_spec;

        # Build common arguments for both install and fetch
        my @args = $self->_build_args( \%opts );
        say "[*] xrepo: ensuring $full_spec is installed..." if $verbose;

        # Install
        my @install_cmd = ( $xmake->exe, qw[lua private.xrepo], 'install', '-y', @args, $full_spec );
        $self->blah("Running: @install_cmd");
        system(@install_cmd) == 0 or die "xrepo install failed for $full_spec";

        # Fetch (must use same args to get correct paths for arch/mode)
        warn "[*] xrepo: fetching paths...\n" if $verbose;
        my @fetch_cmd = ( $xmake->exe, qw[lua private.xrepo], 'fetch', '--json', @args, $full_spec );
        $self->blah("Running: @fetch_cmd");
        my ( $json_out, $json_err, $json_exit ) = capture { system @fetch_cmd };
        die "xrepo fetch failed:\nCommand: @fetch_cmd\nError:\n$json_err" if $json_exit != 0;
        my $data;
        try { $data = decode_json($json_out); } catch ($e) {
            die "Failed to decode xrepo JSON output: $e\nOutput was: $json_out"
        };

        # xrepo might return a single object or a list.
        $self->_process_info( ( ref $data eq 'ARRAY' ) ? $data->[0] : $data );
    }

    method uninstall ( $pkg_spec, %opts ) {
        my @args = $self->_build_args( \%opts );
        say "[*] xrepo: uninstalling $pkg_spec..." if $verbose;
        system $xmake->exe, qw[lua private.xrepo], 'remove', '-y', @args, $pkg_spec;
    }

    method search ($query) {
        say "[*] xrepo: searching for $query..." if $verbose;
        system $xmake->exe, qw[lua private.xrepo], 'search', $query;
    }

    method clean () {
        say '[*] xrepo: cleaning cache...' if $verbose;
        system $xmake->exe, qw[lua private.xrepo], 'clean', '-y';
    }
    #
    method add_repo ( $name, $url, $branch //= () ) {
        say "[*] xrepo: adding repo $name..." if $verbose;
        my @cmd = ( $xmake->exe, qw[lua private.xrepo], 'add-repo', '-y', $name, $url );
        push @cmd, $branch if defined $branch;
        my ( $out, $err, $exit ) = capture { system @cmd };
        die "xrepo add-repo failed:\n$err" if $exit != 0;
        return 1;
    }

    method remove_repo ($name) {
        say "[*] xrepo: removing repo $name..." if $verbose;
        system $xmake->exe, qw[lua private.xrepo], 'remove-repo', '-y', $name;
    }

    method update_repo ( $name //= () ) {
        say '[*] xrepo: updating repositories...' if $verbose;
        my @cmd = ( $xmake->exe, qw[lua private.xrepo], 'update-repo', '-y' );
        push @cmd, $name if defined $name;
        system @cmd;
    }
    #
    method _build_args ($opts) {
        my @args;

        # Standard xmake/xrepo flags
        push @args, '-p', $opts->{plat} if $opts->{plat};                        # platform (iphoneos, android, etc)
        push @args, '-a', $opts->{arch} if $opts->{arch};                        # architecture (arm64, x86_64)
        push @args, '-m', $opts->{mode} if $opts->{mode};                        # debug/release
        push @args, '-k', ( $opts->{kind} // 'shared' );                         # static/shared (Default to shared for FFI)
        push @args, '--toolchain=' . $opts->{toolchain} if $opts->{toolchain};

        # Complex configs (passed as --configs='key=val,key2=val2')
        if ( my $c = $opts->{configs} ) {
            if ( ref $c eq 'HASH' ) {
                my $str = join( ',', map {"$_=$c->{$_}"} sort keys %$c );
                push @args, "--configs=$str";
            }
            else {
                push @args, "--configs=$c";
            }
        }

        # Build Includes (deps)
        if ( my $i = $opts->{includes} ) {
            push @args, '--includes=' . ( ref $i eq 'ARRAY' ? join( ',', @$i ) : $i );
        }
        return @args;
    }

    method _process_info ($info) {
        return () unless defined $info;
        my $libfiles = $info->{libfiles}    // [];
        my $incdirs  = $info->{includedirs} // [];
        my $linkdirs = $info->{linkdirs}    // [];
        my $bindirs  = $info->{bindirs}     // [];

        # 1. Validate that we actually got files back
        unless (@$libfiles) {
            $self->blah('[!] xrepo returned no library files. Package might be header-only.');

            # Return a generic object (likely header-only)
            return Alien::Xrepo::PackageInfo->new(
                includedirs => $incdirs,
                libfiles    => [],
                libpath     => undef,
                linkdirs    => $linkdirs,
                links       => $info->{links}   // [],
                license     => $info->{license} // (),
                shared      => $info->{shared}  // 0,
                static      => $info->{static}  // 0,
                version     => $info->{version} // ()
            );
        }

        # 2. Heuristic to find the Runtime Library (DLL/SO/DyLib) for FFI
        my $runtime_lib;
        if ( $^O eq 'MSWin32' ) {

            # Check if the DLL is already in libfiles (MinGW often does this)
            ($runtime_lib) = grep {/\.dll$/i} @$libfiles;

            # If not, we must hunt for it in the 'bin' directory sibling to the 'lib' directory.
            unless ($runtime_lib) {
                my ($imp_lib) = grep {/\.lib$/i} @$libfiles;
                if ($imp_lib) {
                    my $lib_path = path($imp_lib);
                    my $basename = $lib_path->basename(qr/\.lib$/i);    # e.g., 'zlib' from 'zlib.lib'

                    # Construct list of potential directories to search
                    my @search_dirs = @$bindirs;

                    # Add standard relative paths: /path/to/lib/../bin
                    push @search_dirs, $lib_path->parent->parent->child('bin');
                    push @search_dirs, $lib_path->parent->sibling('bin');         # Some layouts differ

                    # Search for the DLL
                    for my $dir (@search_dirs) {
                        next unless -d $dir;
                        my $d = path($dir);

                        # Exact match: zlib.lib -> zlib.dll
                        my $try = $d->child("$basename.dll");
                        if ( $try->exists ) { $runtime_lib = $try->stringify; last; }

                        # MSVC vs MinGW naming: libpng.lib -> libpng16.dll or png.dll
                        # Scan directory for anything starting with the basename
                        my ($fuzzy) = grep { /^$basename/i && /\.dll$/i } map { $_->basename } $d->children;
                        if ($fuzzy) { $runtime_lib = $d->child($fuzzy)->stringify; last; }
                    }
                }
            }
        }
        elsif ( $^O eq 'darwin' ) {

            # macOS: Prefer .dylib, then .so
            ($runtime_lib) = grep {/\.dylib$/i} @$libfiles;
            ($runtime_lib) //= grep {/\.so$/i} @$libfiles;
        }
        else {
            # Linux/BSD: Prefer .so, .so.x.y, .so.x
            ($runtime_lib) = grep {/\.so(\.|-|\d|$)/} @$libfiles;
        }

        # Fallback and Logging
        unless ($runtime_lib) {

            # If we asked for shared but couldn't find a runtime binary, log a warning.
            # We fall back to the first file (likely a static .a/.lib) so that
            # XS builds might still work, even if Affix or FFI::Platypus will fail.
            if ( $info->{shared} // 0 ) {
                $self->blah('[!] Warning: Package is marked "shared" but no Runtime Binary (dll/so/dylib) was detected.');
                $self->blah( '[!] Libfiles returned: ' . join( ', ', @$libfiles ) );
            }
            $runtime_lib = $libfiles->[0];
        }
        $self->blah( '[*] Identified runtime library: ' . $runtime_lib ) if $runtime_lib;
        return Alien::Xrepo::PackageInfo->new(
            includedirs => $incdirs,
            libfiles    => $libfiles,
            libpath     => $runtime_lib,
            linkdirs    => $linkdirs,
            links       => $info->{links}   // [],
            license     => $info->{license} // (),
            shared      => $info->{shared}  // 0,
            static      => $info->{static}  // 0,
            version     => $info->{version} // ()
        );
    }
};
1;
