package Affix::Platform::Cygwin v1.4.0 {
    use v5.40;
    use DynaLoader;
    use parent 'Affix::Platform::Unix';
    use parent 'Exporter';
    our @EXPORT_OK   = qw[find_library];
    our %EXPORT_TAGS = ( all => \@EXPORT_OK );

    sub find_library ( $name, $version //= () ) {
        return $name if -f $name;
        my $base = $name;
        $base =~ s[^lib][];
        return 'cygwin1.dll' if $base eq 'c' || $base eq 'm';
        for my $file ( "cyg$base.dll", "lib$base.dll", "$base.dll" ) {
            my $path = DynaLoader::dl_findfile($file);
            return $path if $path;
            for my $dir (qw[/usr/bin /usr/lib /bin]) {
                my $cand = "$dir/$file";
                return $cand if -f $cand;
            }
        }
        my $path = DynaLoader::dl_findfile("-l$base");
        return $path if $path;
        return Affix::Platform::Unix::find_library( $name, $version );
    }
};
1;
