use v5.40;
use experimental 'class';
class Alien::Xmake 0.08 {
    use File::Spec;
    use File::Basename qw[dirname];
    use JSON::PP       qw[decode_json];
    #
    field $windows = $^O eq 'MSWin32';
    field $config : param //= sub {
        my $conf;
        try {
            require Alien::Xmake::ConfigData;    # Try to load the ConfigData module generated during install
            $conf = { map { $_ => Alien::Xmake::ConfigData->config($_) } Alien::Xmake::ConfigData->config_names };

            # The raw 'bin' value in config is a relative path string.
            # We must call the generated helper method to get the absolute path.
            if ( Alien::Xmake::ConfigData->can('bin') ) {
                $conf->{bin} = Alien::Xmake::ConfigData->bin;
            }
        }
        catch ($e) {    # Fallback / manual install detection
            $conf = { install_type => 'system' };
        }
        return $conf;
        }
        ->();

    # We don't really need $dir detection if ConfigData is working,
    # but we keep it for fallback scenarios (running from blib/lib, etc).
    field $dir;
    ADJUST {
        if ( !$config->{bin} || !-e $config->{bin} ) {
            my @parts = qw[auto share dist Alien-Xmake];
            push @parts, 'bin' unless $windows;

            # Look through @INC for the share directory
            foreach my $inc (@INC) {
                my $d = File::Spec->catdir( $inc, @parts );
                if ( -d $d ) {
                    $dir = $d;
                    last;
                }
            }
        }
    }

    # Pointless stubs required by some Alien::Base consumers
    method cflags ()       {''}
    method libs ()         {''}
    method dynamic_libs () { }

    # Valuable
    method install_type () { $config->{install_type} }

    method bin_dir () {

        # Return the directory of the raw path (unquoted)
        my $exe = $self->_resolve_path;
        return dirname($exe);
    }

    method exe () {

        # Return a potentially quoted path for execution
        my $path = $self->_resolve_path;
        return $self->_quote_path($path);
    }

    method xrepo () {

        # xrepo is usually in the same folder as Xmake
        my $exe_path   = $self->_resolve_path;
        my $parent     = dirname($exe_path);
        my $xrepo_name = 'xrepo' . ( $windows ? '.bat' : '' );

        # Check sibling
        my $try = File::Spec->catfile( $parent, $xrepo_name );
        if ( -e $try ) {
            return $self->_quote_path($try);
        }

        # Fallback to config path calculation if the sibling check failed
        if ( $config->{bin} ) {
            my $conf_parent = dirname( $config->{bin} );
            my $target      = File::Spec->catfile( $conf_parent, $xrepo_name );
            return $self->_quote_path($target);
        }

        # Last resort: return bare command
        return $xrepo_name;
    }

    method pkg_config ($package) {
        my $xrepo = $self->xrepo;
        system( $xrepo, 'install', '-y', $package ) == 0 || die "Alien::Xmake: Could not install package '$package'\n";
        my $cflags = qx|$xrepo fetch --cflags "$package"|;
        chomp $cflags;
        my $libs = qx|$xrepo fetch --ldflags "$package"|;
        chomp $libs;
        return { cflags => $cflags, libs => $libs };
    }
    method version ()             { $self->install_type eq 'system' ? $self->_getver : $config->{version} }
    method build ()               { $self->_getbuild }
    method config ( $key //= () ) { defined $key ? $config->{$key} : $config }

    sub alien_helper () {
        { xmake => sub { __PACKAGE__->new->exe }, xrepo => sub { __PACKAGE__->new->xrepo } }
    }
    #
    method _getver() {
        my ( $ver, undef ) = $self->_getver_build;
        "v$ver";
    }

    method _getbuild() {
        my ( undef, $build ) = $self->_getver_build;
        $build;
    }

    method _getver_build() {
        my $cmd = $self->exe;
        state $out //= qx[$cmd --version];
        return ( $1, $2 ) if $out =~ /xmake\s+v?(\d+\.\d+\.\d+)(?:\+(.+),)?/i;
        ( '0.0.0', () );
    }

    # Resolve absolute path without quotes
    method _resolve_path () {
        my $bin = $config->{bin};

        # If ConfigData failed or we are in a fallback state:
        $bin = File::Spec->catfile( $dir, 'xmake' . ( $windows ? '.exe' : '' ) ) if !$bin && $dir;
        $bin //= 'xmake';

        # Ensure we return a stringified absolute path safe for system()
        File::Spec->rel2abs($bin);
    }

    # Quote path if on Windows and spaces exist
    method _quote_path ($path) {
        return qq{"$path"} if $windows && $path =~ /\s/;
        $path;
    }
} 1;
__END__
Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.
