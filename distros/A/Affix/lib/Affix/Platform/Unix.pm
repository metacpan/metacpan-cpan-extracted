package Affix::Platform::Unix v1.2.4 {
    use v5.40;
    use Path::Tiny qw[path];
    use Config     qw[%Config];
    use DynaLoader;
    use parent 'Exporter';
    our @EXPORT_OK   = qw[find_library];
    our %EXPORT_TAGS = ( all => \@EXPORT_OK );
    my $so = $Config{so};

    sub is_elf ($filename) {
        my $elf_header = "\x7fELF";                        # ELF header in binary format
        open( my $fh, '<:raw', $filename ) or return 0;    # Open in binary mode
        sysread( $fh, my $header, 4 ) || return;
        close($fh);
        return $header eq $elf_header;
    }

    sub _findLib_ldconfig ($name) {

        # Get the first part of the architecture name (e.g., "x86_64" from "x86_64-linux-gnu")
        my ($arch_part)  = split /-/, $Config{archname};
        my $architecture = {
            'x86_64'  => 'x86_64',
            'amd64'   => 'x86_64',    # A common alias
            'aarch64' => 'ARM64',
            'arm64'   => 'ARM64',
            'ppc64'   => 'PPC64',
            'sparc64' => 'SPARC64',
            'ia64'    => 'Itanium',
            'riscv64' => 'RISCV',
            'riscv'   => 'RISCV',
        }->{$arch_part};
        $architecture // die "Unsupported architecture for ldconfig lookup: $arch_part";

        # Use the portable $Config{longsize} which gives the size of a C long in bytes.
        my $lookup_key = $architecture . ( $Config{longsize} == 8 ? '-64' : '-32' );
        my $machine    = {
            'x86_64-64'  => 'libc6,x86-64',
            'PPC64-64'   => 'libc6,64bit',
            'SPARC64-64' => 'libc6,64bit',
            'Itanium-64' => 'libc6,IA-64',
            'ARM64-64'   => 'libc6,AArch64',
            'RISCV-64'   => 'libc6,rv64gc'
        }->{$lookup_key};

        # If this specific architecture/bitness combination isn't in our list, return nothing.
        $machine // return;

        # XXX assuming GLIBC's ldconfig (with option -p)
        grep { is_elf($_) } map {
            /^(?:lib)?\Q$name\E(?:\-\S+)?\.\s*.*\(\Q$machine\E.*\)\s+=>\s+(.+)$/;
            defined $1 ? path($1)->realpath : ()
        } split /\R\s*/, `export LC_ALL 'C'; export LANG 'C'; /sbin/ldconfig -p 2>&1`;
    }

    sub _findLib_dynaloader($name) {
        DynaLoader::dl_findfile( '-l' . $name );
    }

    sub _findLib_ld($name) {
        local $ENV{LC_ALL} = 'C';
        local $ENV{LANG}   = 'C';
        open( my $fh, '-|', 'ld', '-t', '-o', '/dev/null', "-l$name" ) or return;
        my $output = do { local $/; <$fh> };
        close $fh;
        return $output;
    }

    sub _findLib_gcc($name) {
        $name =~ s[^lib][];
        CORE::state $compiler;
        $compiler //= sub {
            for my $cc (qw[gcc cc]) {
                if ( open( my $fh, '-|', $cc, '--version' ) ) {
                    my $line = <$fh>;
                    close $fh;
                    return $cc if defined $line;
                }
            }
            return 'gcc';
            }
            ->();
        my $trace;
        {
            use File::Temp qw[tempfile];
            my ( undef, $temp_file ) = tempfile();
            if ( open( my $fh, '-|', $compiler, '-shared', '-Wl,-t', '-o', $temp_file, "-l$name" ) ) {
                $trace = do { local $/; <$fh> };
                close $fh;
            }
            if ( !defined $trace || !length $trace ) {
                if ( open( my $fh2, '-|', $compiler, '--print-file-name', "lib$name.$so" ) ) {
                    $trace = do { local $/; <$fh2> };
                    close $fh2;
                }
            }
        };
        grep {/^.*?\/lib\Q$name\E\.[^\s]+$/} split /\n/, $trace;
    }

    sub find_library ( $name, $version //= '' ) {    # TODO: actually feed version to diff methods
        if ( -f $name ) {
            $name = readlink $name if -l $name;        # Handle symbolic links
            return $name           if is_elf($name);
        }
        CORE::state $cache;
        unless ( defined $cache->{$name}{$version} ) {
            my @ret = grep { is_elf($_) } _findLib_dynaloader($name);
            @ret = grep { is_elf($_) } _findLib_ldconfig($name) unless @ret;
            @ret = grep { is_elf($_) } _findLib_gcc($name)      unless @ret;
            @ret = grep { is_elf($_) } _findLib_ld($name)       unless @ret;
            return unless @ret;
            for my $lib ( map { path($_)->realpath } @ret ) {
                next unless $lib =~ /^.*?\/lib\Q$name\E.*\.\Q$so\E(?:\.([\d\.\-]+))?$/;
                $version = $1 if defined $1 && $version eq '';
                $cache->{$name}{$version} //= $lib;
            }
        }
        $cache->{$name}{$version} // ();
    }

    sub _get_soname ($file) {    # assuming GNU binutils / ELF
        return undef unless $file && -f $file;
        open( my $fh, '-|', 'objdump', '-p', '-j', '.dynamic', $file ) or return;
        my $dump = do { local $/; <$fh> };
        close $fh;
        return unless defined $dump;
        $dump =~ /\sSONAME\s+([^\s]+)/ ? $1 : ();
    }
}
1;
