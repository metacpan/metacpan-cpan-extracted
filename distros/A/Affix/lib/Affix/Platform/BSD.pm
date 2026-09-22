package Affix::Platform::BSD v1.2.7 {
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
        return $cache->{$name}{$version} if defined $cache->{$name}{$version};
        my $regex = qr[-l\Q$name\E\.[^\s]+.+\s*=>\s*(.+)$];

        # ldconfig lives in different places per BSD (and NetBSD may not ship it
        # at all), so probe the common locations before giving up.
        my $ldconfig = '';
        for my $cmd (qw[/sbin/ldconfig /usr/sbin/ldconfig ldconfig]) {
            my $out = `export LC_ALL 'C'; export LANG 'C'; $cmd -r 2>/dev/null`;
            if ( defined $out && $out =~ /\S/ ) { $ldconfig = $out; last; }
        }
        my @found = grep {-e} map { -l $_ ? readlink($_) : $_ } map { $_ =~ $regex; defined $1 ? $1 : () } split /\n\s*/, $ldconfig;
        return $cache->{$name}{$version} = $found[0] if @found;

        # No ldconfig (or it doesn't know this library) -- fall back to the
        # portable Unix probes (DynaLoader, gcc, ld).
        $cache->{$name}{$version} = Affix::Platform::Unix::find_library( $name, $version );
    }
};
1;
