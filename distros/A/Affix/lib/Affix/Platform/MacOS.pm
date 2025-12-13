package Affix::Platform::MacOS v0.12.0 {
    use v5.40;
    use DynaLoader;
    use parent 'Affix::Platform::Unix';
    use parent 'Exporter';
    our @EXPORT_OK   = qw[find_library];
    our %EXPORT_TAGS = ( all => \@EXPORT_OK );

    sub find_library ($) {
        my ($name) = @_;
        return $name if -f $name;
        for my $file ( "lib$name.dylib", "$name.dylib", "$name.framework/$name" ) {
            my $path = DynaLoader::dl_findfile($file);
            return $path if $path;
        }
    }
};
1;
