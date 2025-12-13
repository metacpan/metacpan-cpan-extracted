package Affix::Platform::BSD v0.12.0 {
    use v5.40;
    use parent 'Affix::Platform::Unix';
    use parent 'Exporter';
    our @EXPORT_OK   = qw[find_library];
    our %EXPORT_TAGS = ( all => \@EXPORT_OK );

    sub find_library ( $name, $version //= '' ) {    # TODO: actually feed version to diff methods
        if ( -f $name ) {
            $name = readlink $name if -l $name;      # Handle symbolic links
            return $name                             # if is_elf($name);
        }
        CORE::state $cache;
        my $regex = qr[-l$name\.[^\s]+.+\s*=>\s*(.+)$];
        ( $cache->{$name}{$version} ) = map { -l $_ ? readlink($_) : $_ } map { $_ =~ $regex; defined $1 ? $1 : () } split /\n\s*/,
            `export LC_ALL 'C'; export LANG 'C'; /sbin/ldconfig -r`;
        $cache->{$name}{$version} // ();
    }
};
1;
