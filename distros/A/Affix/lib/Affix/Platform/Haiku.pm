package Affix::Platform::Haiku v1.2.7 {
    use v5.40;
    use Path::Tiny qw[path];
    use Config     qw[%Config];
    use parent 'Affix::Platform::Unix';
    use parent 'Exporter';
    our @EXPORT_OK   = qw[find_library];
    our %EXPORT_TAGS = ( all => \@EXPORT_OK );
    my $so = $Config{so} // 'so';

    # Haiku has no separate libm/libc: the C library and the math functions are both provided by
    # libroot.so. Linker probes for `-lm`/`-lc` therefore fail, so resolve those names to libroot
    # instead.
    my %alias    = ( m => 'root', c => 'root' );
    my @lib_dirs = qw[
        /boot/system/lib
        /boot/system/develop/lib
        /boot/system/non-packaged/lib
        /boot/home/config/lib
    ];

    sub find_library ( $name, $version //= () ) {
        my $base = $name;
        $base =~ s[^lib][];
        if ( my $target = $alias{$base} ) {
            my $found = Affix::Platform::Unix::find_library( $target, $version );
            return $found if defined $found;
            for my $dir ( grep {-d} @lib_dirs ) {
                my @cand = grep {/\Alib\Q$target\E\.\Q$so\E/} map { path($_) } path($dir)->children;
                for my $cand (@cand) {
                    return $cand->realpath->stringify if -e $cand;
                }
            }
        }
        return Affix::Platform::Unix::find_library( $name, $version );
    }
};
#
1;
