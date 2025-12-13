package Affix::Platform::Windows v0.12.0 {
    use v5.40;
    use DynaLoader;
    use Win32;    # Core on Windows
    use File::Spec;
    use parent 'Exporter';
    our @EXPORT_OK   = qw[find_library];
    our %EXPORT_TAGS = ( all => \@EXPORT_OK );

    sub find_msvcrt () {
        my $version = get_msvcrt_version();    # Assuming _get_build_version is defined elsewhere
        if ( !$version ) {
            my @possible_dlls = (
                'msvcrt.dll',

                #~ sprintf( 'msvcr%d.dll', $version * 10 )
            );

            # Search for the DLL in common system directories
            for my $dll (@possible_dlls) {
                for my $dir ( Win32::GetFolderPath( Win32::CSIDL_SYSTEM() ), qw[C:/Windows/System32 C:/Windows/SysWOW64] ) {
                    my $file = File::Spec->catfile( $dir, $dll );
                    return $file if -f $file;
                }
            }
        }
        my $clibname;
        if ( $version <= 6 ) {
            $clibname = 'msvcrt';
        }
        elsif ( $version <= 13 ) {
            $clibname = sprintf( 'msvcr%d', $version * 10 );
        }
        else {
            # CRT not directly loadable (see python/cpython#23606)
            return undef;
        }

        # Check for debug build
        my $debug_suffix = '_d';    # Assuming debug suffix is '_d'
        my $suffixes     = join '|', map quotemeta, @DynaLoader::dl_extensions;
        if ( $debug_suffix =~ /$suffixes/ ) {
            $clibname .= $debug_suffix;
        }
        return "$clibname.dll";
    }

    sub get_msvcrt_version() {
        open( my $pipe, '-|', 'dumpbin /headers msvcrt.dll', 'r' ) or return;
        my $dumpbin_output;
        $dumpbin_output .= $_ while <$pipe>;
        close $pipe;
        return $1 if $dumpbin_output && $dumpbin_output =~ /FileVersion\s+(\d+\.\d+\.\d+\.\d+)/;
    }

    sub find_library($name) {
        return $name         if -f $name;
        return find_msvcrt() if $name eq 'c' || $name eq 'm';
        for my $dir ( split ';', $ENV{PATH} ) {
            my $file = File::Spec->catfile( $dir, $name );
            $file .= '.dll' if $file !~ /\.dll$/i;    # Check for ".dll" extension (case-insensitive)
            return $file    if -f $file;
        }
    }
};
1;
