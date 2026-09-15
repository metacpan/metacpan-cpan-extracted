use v5.40;
use feature 'class';
no warnings 'experimental::class';
#
class Alien::Xrepo::Build::Recipe v1.0.1 {
    use JSON::PP qw[decode_json];
    use Path::Tiny;
    use Scalar::Util qw[looks_like_number];
    #
    field $name        : reader : param //= undef;
    field $file        : param //= undef;
    field $dir         : param //= undef;
    field $packages    : param //= undef;
    field $defaults    : reader : param //= undef;
    field $pkg_roots   : reader : param //= undef;
    field $local_repos : reader : param //= undef;
    field $hooks       : reader : param //= undef;
    #
    field @order : reader(packages);    # package names in recipe order (first = primary)
    field %defs;                        # package name => normalized per-package hashref def
    method package_defs { \%defs }
    #
    ADJUST {
        if ( defined $file || defined $dir ) {
            die 'Recipe: pass exactly one of file / dir / inline data'       if defined $file && defined $dir;
            die q[Recipe: inline 'packages' is ignored when a file is given] if defined $packages;
            my $path = $file // path($dir)->child('xrepo.json');    # Used during testing
            die 'Recipe file not found: ' . $path unless -e $path;
            my $data = eval { decode_json( path($path)->slurp_utf8 ) };
            die "Recipe '$path' is not valid JSON: $@" if !defined $data || ref $data ne 'HASH';
            $name        //= $data->{name};
            $packages    //= $data->{packages};
            $defaults    //= $data->{defaults};
            $pkg_roots   //= $data->{pkg_roots};
            $local_repos //= $data->{local_repos} // [];
            $hooks       //= $data->{hooks}       // [];
        }
        die 'Recipe: packages is required' unless defined $packages;
        @order = ( $self->_normalize_defs($packages) );
        die 'Recipe: at least one package is required' unless @order;
        $defaults    //= {};
        $pkg_roots   //= {};
        $local_repos //= [] if !defined $local_repos;
        $hooks       //= [] if !defined $hooks;
        $self->_validate_profile( $defaults, 'defaults' );
        $self->_validate_strings( $local_repos, 'local_repos' );
        $self->_validate_strings( $hooks,       'hooks' );
        die 'Recipe: pkg_roots must be a hashref' unless ref $pkg_roots eq 'HASH';

        for my $root ( keys %$pkg_roots ) {
            my $v = $pkg_roots->{$root};
            die "Recipe: pkg_roots '$root' must be a plain string" if ref $v || !defined $v;
        }
    }
    my %DEF_KEYS = map { $_ => 1 } qw[
        name version
        plat arch mode kind no_kind toolchain toolchain_host
        vs vs_toolset vs_sdkver ndk sdk mingw
        jobs linkjobs force shallow build debugdir
        yes confirm theme cachedir installdir
        configs includes
    ];
    method version_for ($name) { $defs{$name}{version} // undef; }

    method opts_for ( $name, %ambient ) {
        my $def = $defs{$name};
        return %ambient unless ref $def eq 'HASH';
        my %merged  = %ambient;
        my $g_cfg   = $merged{configs};
        my %configs = ref $g_cfg eq 'HASH' ? %$g_cfg : ();
        %configs = ( %configs, %{ $def->{configs} } ) if ref $def->{configs} eq 'HASH';
        for my $key ( keys %$def ) {
            next if $key eq 'name' || $key eq 'version' || $key eq 'configs';
            $merged{$key} = $def->{$key};
        }
        $merged{configs} = \%configs if ref $g_cfg eq 'HASH' || ref $def->{configs} eq 'HASH';
        return %merged;
    }

    method _normalize_defs ($in) {
        my @raw = ref $in eq 'ARRAY' ? @$in : ($in);
        my %seen;
        my @names;
        for my $entry (@raw) {
            if ( ref $entry eq 'HASH' ) {
                my %def = %$entry;
                die "Recipe: package definition requires a 'name' key" unless defined $def{name} && length $def{name};
                die "Recipe: package '$def{name}' name must be a plain string" if ref $def{name};
                for my $key ( keys %def ) {
                    next if $key eq 'name' || $key eq 'version';
                    if ( $key eq 'configs' ) {
                        die "Recipe: package '$def{name}': configs must be a hashref" unless ref $def{configs} eq 'HASH';
                        next;
                    }
                    die "Recipe: package '$def{name}': unknown key '$key'. Supported keys: @{[ sort keys %DEF_KEYS ]}. " .
                        'Recipe options belong under configs => { ... }.'
                        unless $DEF_KEYS{$key};
                }
                die "Recipe: duplicate package name '$def{name}'" if $seen{ $def{name} };
                $seen{ $def{name} } = 1;
                $defs{ $def{name} } = {%def};
                push @names, $def{name};
            }
            elsif ( ref $entry eq '' && defined $entry && length $entry && !looks_like_number($entry) ) {
                die "Recipe: duplicate package name '$entry'" if $seen{$entry};
                $seen{$entry} = 1;
                push @names, $entry;
            }
            else {
                die 'Recipe: package entries must be a name or a hashref, got ' . ( ref $entry || 'undef' );
            }
        }
        return @names;
    }
    #
    method _validate_profile ( $profile, $where ) {
        die "Recipe: $where must be a hashref" unless ref $profile eq 'HASH';
        for my $key ( keys %$profile ) {
            if ( $key eq 'configs' ) {
                die "Recipe: $where configs must be a hashref" unless ref $profile->{configs} eq 'HASH';
                next;
            }
            die "Recipe: $where: unknown key '$key'" unless $DEF_KEYS{$key} && $key ne 'name' && $key ne 'version';
        }
        return;
    }
    #
    method _validate_strings ( $list, $where ) {
        die "Recipe: $where must be an arrayref" unless ref $list eq 'ARRAY';
        for my $v (@$list) {
            die "Recipe: $where entries must be plain strings, got " . ( ref $v || 'undef' ) if ref $v || !defined $v;
        }
        return;
    }
};
#
1;
__END__
Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms found in
the Artistic License 2. Other copyrights, terms, and conditions may apply to data transmitted
through this module.
