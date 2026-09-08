use v5.40;
use feature qw[class try];
no warnings 'experimental::class';
#
class Alien::Xrepo::Runtime v1.0.0 {
    use Alien::Xrepo;
    use Alien::Xrepo::Build::Recipe;
    use JSON::PP qw[decode_json];
    use Path::Tiny;
    use File::ShareDir ();
    #
    field $pkg_name     : param = undef;
    field $recipe       : param = undef;    # Recipe object (or file/dir) - alternative to inline pkg_name
    field $root         : param = undef;
    field $verbose      : param = 0;
    field $repo         : param //= undef;  # injectable engine
    field $snapshot     : param //= undef;  # path to a snapshot JSON (hermetic mode)
    field $autodetect_snapshot : param //= 1;  # look for dist auto/share snapshots
    field $install_opts : param = {};       # ambient profile merged under every package def
    field $cache        : param //= 1;      # forward the engine's warm-start cache to Alien::Xrepo
    #
    field $recipe_obj = undef;              # resolved Alien::Xrepo::Build::Recipe
    field $infos  = {};                     # package => Alien::Xrepo::PackageInfo
    field $snap   = {};                     # package => raw snapshot data
    field $r      = undef;                  # resolved Alien::Xrepo engine
    field $snap_install_type = undef;
    #
    ADJUST {
        if ( !defined $pkg_name && !defined $recipe && $self->can('pkg_name') ) {
            $pkg_name = $self->pkg_name;
        }
        die "pkg_name or a recipe is required" if !defined $pkg_name && !defined $recipe;
        if ( !keys %$install_opts && $self->can('install_opts') ) {
            $install_opts = { $self->install_opts };
        }
        $r = $repo // Alien::Xrepo->new( root => $root, verbose => $verbose, cache => $cache );
        if ( defined $recipe ) {
            $recipe_obj = ref $recipe
                ? $recipe
                : Alien::Xrepo::Build::Recipe->new(
                    defined $recipe && -d $recipe ? ( dir => $recipe ) : ( file => $recipe ),
                );
        }
        else {
            $recipe_obj = Alien::Xrepo::Build::Recipe->new( packages => $pkg_name );
        }
        $self->_load_snapshot;
    }
    #
    method package_names () {   $recipe_obj->packages }
    method package_defs  () {   $recipe_obj->package_defs }
    #
    # Hermetic mode: a snapshot file wins entirely (no xrepo subprocess).
    method _load_snapshot () {
        my $file = $snapshot;
        if ( !defined $file && $autodetect_snapshot ) {
            for my $cand ( __PACKAGE__->_snapshot_candidates_for( ref $self ) ) {
                if ( -e $cand ) { $file = $cand; last; }
            }
        }
        return unless defined $file && -e $file;
        my $data = eval { decode_json( path($file)->slurp_utf8 ) };
        return unless ref $data eq 'HASH';
        $snap = $data->{packages}       // {};
        $snap_install_type = $data->{install_type};
        for my $name ( keys %$snap ) {
            $infos->{$name} = Alien::Xrepo::PackageInfo->new( %{ $snap->{$name} } );
        }
        return;
    }

    # Where autodetect looks for a subclass: the installed dist's share dir then the source-tree build artifact layout.
    # The snapshot written by the Build engine lives at <share>/<dist>/xrepo-snapshot.json, where <dist> is
    # Alien-<module tail> (e.g. Alien::Zstandard -> Alien-Zstandard).
    sub _snapshot_candidates_for ( $class, $instance ) {
        my @parts = split /::/, $instance;
        shift @parts if $parts[0] eq 'Alien';
        my $dist = 'Alien-' . join '-', @parts;
        my @cand = path('blib', 'lib', 'auto', 'share', 'dist', $dist)->child('xrepo-snapshot.json')->stringify;
        my $share = eval { File::ShareDir::dist_dir($dist) };
        unshift @cand, path($share)->child('xrepo-snapshot.json')->stringify if $share;
        return @cand;
    }

    # Lazy resolution: so long as we are not serving a snapshot, fetch paths for a package the first time it is asked
    # for and remember them. An unresolvable package settles at undef (safe defaults) instead of killing the caller, so
    # a cold checkout (no snapshot, no store) yields safe defaults.
    method _ensure_info ($pkg) {
        my $info = $infos->{$pkg};
        return $info if defined $info;
        my $version = $recipe_obj->version_for($pkg);
        my %opts    = $recipe_obj->opts_for( $pkg, %$install_opts );
        my $resolved;
        try { $resolved = $r->fetch( $pkg, $version, %opts ) }
        catch ($e) {
            warn "[!] could not resolve $pkg: $e\n" if $verbose;
            $resolved = undef;
        }
        $infos->{$pkg} = $resolved;
        return $resolved;
    }
    #
    method _pkg_info ( $pkg = undef ) {
        my $name = $pkg // ( $recipe_obj->packages )[0];
        die "Unknown package '$name'. Known: @{[ $recipe_obj->packages ]}" unless grep { $_ eq $name } $recipe_obj->packages;
        return $self->_ensure_info($name);
    }
    #
    method libpath ( $pkg = undef ) { my $i = $self->_pkg_info($pkg); $i ? $i->libpath : undef }
    method ffi_lib ( $pkg = undef ) { $self->libpath($pkg) }
    method bin_dir ( $pkg = undef ) { my $i = $self->_pkg_info($pkg); $i ? $i->bin_dir : () }
    method version ( $pkg = undef ) { my $i = $self->_pkg_info($pkg); $i ? $i->version : undef }
    method kind    ( $pkg = undef ) { my $i = $self->_pkg_info($pkg); $i ? $i->kind : undef }
    #
    method cflags ( $pkg = undef ) {
        my $i = $self->_pkg_info($pkg);
        return '' unless $i;
        return join ' ', map {"-I$_"} @{ $i->includedirs };
    }
    method cflags_static ( $pkg = undef ) { $self->cflags($pkg) }
    #
    method libs ( $pkg = undef ) {
        my $i = $self->_pkg_info($pkg);
        return '' unless $i;
        my $libs = join ' ', map {"-L$_"} @{ $i->linkdirs // [] };
        $libs .= ' ' . join ' ', map {"-l$_"} @{ $i->links // [] };
        return $libs;
    }
    method libs_static ( $pkg = undef ) { $self->libs($pkg) }
    #
    method dynamic_libs ( $pkg = undef ) {
        my $i = $self->_pkg_info($pkg);
        return () unless $i;
        return map { $_ // () } @{ $i->libfiles // [] };
    }
    #
    method dist_dir ( $pkg = undef ) {
        my $i = $self->_pkg_info($pkg);
        return $i ? $i->installdir : undef;
    }
    #
    method install_type ( $pkg = undef ) {
        return $snap_install_type if defined $snap_install_type;
        return $self->_pkg_info($pkg)         ? 'share' : 'system';
    }
    #
    method split_flags ( $flags, $pkg = undef ) {
        return () unless defined $flags;
        return grep {length} split ' ', $flags;
    }
    #
    method alt ( $name = undef ) {
        my $primary = ( $recipe_obj->packages )[0];
        my $pkg     = $name // $primary;
        die "Unknown package '$pkg'. Known: @{[ $recipe_obj->packages ]}" unless grep { $_ eq $pkg } $recipe_obj->packages;
        return $self if $pkg eq $primary;
        return Alien::Xrepo::Runtime::Alt->new( base => $self, pkg => $pkg );
    }
    #
    method find_header ( $filename, $pkg = undef ) {
        my $i = $self->_pkg_info($pkg);
        return $i ? $i->find_header($filename) : undef;
    }
    method package_info ( $pkg = undef ) { $self->_pkg_info($pkg) }
};
#
class Alien::Xrepo::Runtime::Alt v1.0.0 {
    field $base : param;
    field $pkg  : param;
    method package_names ()      { $base->package_names }
    method package_info ()       { $base->package_info($pkg) }
    method pkg_name ()           {$pkg}
    method alt ( $name = undef ) { $base->alt( $name // $pkg ) }
    method libpath ()            { $base->libpath($pkg) }
    method ffi_lib ()            { $base->libpath($pkg) }
    method bin_dir ()            { $base->bin_dir($pkg) }
    method version ()            { $base->version($pkg) }
    method kind ()               { $base->kind($pkg) }
    method cflags ()             { $base->cflags($pkg) }
    method cflags_static ()      { $base->cflags($pkg) }
    method libs ()               { $base->libs($pkg) }
    method libs_static ()        { $base->libs($pkg) }
    method dynamic_libs ()       { $base->dynamic_libs($pkg) }
    method dist_dir ()           { $base->dist_dir($pkg) }
    method install_type ()       { $base->install_type($pkg) }
    method split_flags ($flags)    { $base->split_flags( $flags, $pkg ) }
    method find_header ($filename) { $base->find_header( $filename, $pkg ) }
};
#
1;
__END__
Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms found in
the Artistic License 2. Other copyrights, terms, and conditions may apply to data transmitted
through this module.
