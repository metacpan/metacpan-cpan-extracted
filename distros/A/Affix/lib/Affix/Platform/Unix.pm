package Affix::Platform::Unix v0.12.0 {
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
            'ppc64'   => 'PPC64',
            'sparc64' => 'SPARC64',
            'ia64'    => 'Itanium',
        }->{$arch_part};
        $architecture // die "Unsupported architecture for ldconfig lookup: $arch_part";

        # Use the portable $Config{longsize} which gives the size of a C long in bytes.
        my $lookup_key = $architecture . ( $Config{longsize} == 8 ? '-64' : '-32' );
        my $machine    = {
            'x86_64-64'  => 'libc6,x86-64',
            'PPC64-64'   => 'libc6,64bit',
            'SPARC64-64' => 'libc6,64bit',
            'Itanium-64' => 'libc6,IA-64',
            'ARM64-64'   => 'libc6,AArch64'
        }->{$lookup_key};

        # If this specific architecture/bitness combination isn't in our list, return nothing.
        $machine // return;

        # XXX assuming GLIBC's ldconfig (with option -p)
        grep { is_elf($_) } map {
            /^(?:lib)?${name}(?:\-\S+)?\.\s*.*\(${machine}.*\)\s+=>\s+(.+)$/;
            defined $1 ? path($1)->realpath : ()
        } split /\R\s*/, `export LC_ALL 'C'; export LANG 'C'; /sbin/ldconfig -p 2>&1`;
    }

    sub _findLib_dynaloader($name) {
        DynaLoader::dl_findfile( '-l' . $name );
    }

    sub _findLib_ld($name) {
        `export LC_ALL 'C'; export LANG 'C'; ld -t -o /dev/null -l$name 2>&1`;
    }

    sub _findLib_gcc($name) {
        $name =~ s[^lib][];
        CORE::state $compiler;
        $compiler //= sub {
            my $ret = `which gcc 2>&1`;
            chomp($ret);
            $ret = `which cc 2>&1` unless -x $ret;
            chomp($ret);
            return undef unless -x $ret;
            chomp($ret);
            $ret;
            }
            ->();
        my $trace;
        {
            use File::Temp qw[tempfile];
            my ( $fh, $temp_file ) = tempfile();
            $trace = `$compiler -Wl,-t -o $temp_file -l$name 2>&1`;    # Redirect stderr to stdout
        };
        grep {/^.*?\/lib$name\.[^\s]+$/} split /\n/, $trace;
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
                next unless $lib =~ /^.*?\/lib$name.*\.$so(?:\.([\d\.\-]+))?$/;
                $version = $1 if defined $1 && $version eq '';
                $cache->{$name}{$version} //= $lib;
            }
        }
        $cache->{$name}{$version} // ();
    }

    sub _get_soname ($file) {    # assuming GNU binutils / ELF
        return undef unless $file && -f $file;
        my $objdump = `which objdump`;
        return undef unless $objdump;    # objdump is not available, give up
        chomp $objdump;
        my $dump = `$objdump -p -j .dynamic $file 2>/dev/null`;
        $dump =~ /\sSONAME\s+([^\s]+)/ ? $1 : ();
    }
}
1;
