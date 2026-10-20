use v5.40;
use feature qw[class try];
no warnings 'experimental::class';
#
class Alien::Xrepo::Runtime v1.0.10 {
    use Alien::Xrepo;
    use Alien::Xrepo::Build::Recipe;
    use Alien::Xrepo::Runtime::Alt;
    use Config   ();
    use JSON::PP qw[decode_json];
    use Path::Tiny;
    use File::ShareDir ();
    #
    field $pkg_name            : param = undef;
    field $recipe              : param = undef;      # Recipe object (or file/dir) - alternative to inline pkg_name
    field $root                : param = undef;
    field $verbose             : param = 0;
    field $diagnosis           : param = 0;          # forwarded to Alien::Xrepo->diagnosis (xmake -D on installs)
    field $repo                : param //= undef;    # injectable engine
    field $snapshot            : param //= undef;    # path to a snapshot JSON (hermetic mode)
    field $autodetect_snapshot : param //= 1;        # look for dist auto/share snapshots
    field $install_opts        : param = {};         # ambient profile merged under every package def
    field $cache               : param //= 1;        # forward the engine's warm-start cache to Alien::Xrepo

    #
    field $recipe_obj        = undef;                        # resolved Alien::Xrepo::Build::Recipe
    field $infos             = {};                           # package => Alien::Xrepo::PackageInfo
    field $snap              = {};                           # package => raw snapshot data
    field $r                 = undef;                        # resolved Alien::Xrepo engine
    field $snap_install_type = undef;
    field $snap_file   : reader(snapshot_path)   = undef;    # path of the snapshot actually loaded, if any
    field $snap_errors : reader(snapshot_errors) = {};       # package => build error recorded in that snapshot
    field $rdeps   = {};                                     # package => discovered runtime deps (aref)
    field $closure = {};                                     # package => raw fetch --deps closure (aref)
    field $check_runtime_deps : param //= 1;                 # surface the diagnostic through package_info

    #
    ADJUST {
        if ( !defined $pkg_name && !defined $recipe ) {
            if ( $self->can('recipe') ) {
                $recipe = $self->recipe;
            }
            elsif ( $self->can('pkg_name') ) {
                $pkg_name = $self->pkg_name;
            }
        }
        die "pkg_name, recipe, or a subclass recipe() is required" if !defined $pkg_name && !defined $recipe;
        if ( !keys %$install_opts && $self->can('install_opts') ) {
            $install_opts = { $self->install_opts };
        }
        $r = $repo // Alien::Xrepo->new( root => $root, verbose => $verbose, diagnosis => $diagnosis, cache => $cache );
        if ( defined $recipe ) {
            $recipe_obj
                = ref $recipe eq 'HASH' ? Alien::Xrepo::Build::Recipe->new(%$recipe) :
                ref $recipe             ? $recipe :
                Alien::Xrepo::Build::Recipe->new( defined $recipe && -d $recipe ? ( dir => $recipe ) : ( file => $recipe ), );
        }
        else {
            $recipe_obj = Alien::Xrepo::Build::Recipe->new( packages => $pkg_name );
        }
        $self->_load_snapshot;
    }
    #
    method package_names () { $recipe_obj->packages }
    method package_defs ()  { $recipe_obj->package_defs }
    #
    method has_snapshot () { defined $snap_file }
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
        $snap              = $data->{packages} // {};
        $snap_install_type = $data->{install_type};
        $snap_file         = "$file";
        $snap_errors       = $data->{errors} // {};
        my $base = path($file)->parent;

        for my $name ( keys %$snap ) {
            my %pkg = %{ $snap->{$name} };
            $self->_rebase_relative( $base, \%pkg );
            $infos->{$name} = Alien::Xrepo::PackageInfo->new(%pkg);
        }
        return;
    }

    method _rebase_relative ( $base, $data ) {
        $data->{$_} = [ map { $self->_snap_abs( $base, $_ ) } @{ $data->{$_} } ] for qw[includedirs libfiles linkdirs bindirs];
        for my $k (qw[libpath installdir]) {
            $data->{$k} = $self->_snap_abs( $base, $data->{$k} ) if defined $data->{$k};
        }
        if ( ref $data->{runtime_deps} eq 'ARRAY' ) {
            for my $dep ( @{ $data->{runtime_deps} } ) {
                next unless ref $dep eq 'HASH';
                for my $k (qw[path dir]) {
                    $dep->{$k} = $self->_snap_abs( $base, $dep->{$k} ) if defined $dep->{$k};
                }
            }
        }
        return;
    }

    method _snap_abs ( $base, $p ) {
        return $p if !defined $p || length $p == 0 || path($p)->is_absolute;
        return $base->child($p)->stringify;
    }

    sub _snapshot_candidates_for ( $class, $instance ) {
        ( my $dist = $instance ) =~ s{::}{-}g;
        my @cand  = path( 'blib', 'lib', 'auto', 'share', 'dist', $dist )->child('xrepo-snapshot.json')->stringify;
        my $share = eval { File::ShareDir::dist_dir($dist) };
        unshift @cand, path($share)->child('xrepo-snapshot.json')->stringify if $share;
        return @cand;
    }

    # Lazy resolution: so long as we are not serving a snapshot, fetch paths for a package the first time it is asked
    # for and remember them. An unresolvable package settles at undef (safe defaults) instead of killing the caller, so
    # a cold checkout (no snapshot, no store) yields safe defaults.
    method _ensure_info ($pkg) {
        return $infos->{$pkg} if exists $infos->{$pkg};
        my $info = $infos->{$pkg};
        return $info if defined $info;
        my $version = $recipe_obj->version_for($pkg);
        my %ambient = ( %{ $recipe_obj->defaults // {} }, %$install_opts );
        my %opts    = $recipe_obj->opts_for( $pkg, %ambient );
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

    # Prepend the package's shippable binary directories to PATH so a consumer
    # can spawn the tool (e.g. ninja) without knowing where xrepo put it.
    method prepend_to_path ( $pkg = undef ) {
        my @dirs = $self->bin_dir($pkg);
        return () unless @dirs;
        $ENV{PATH} = join( $Config::Config{path_sep} // ':', @dirs, ( $ENV{PATH} // () ) );
        return @dirs;
    }
    method version ( $pkg = undef ) { my $i = $self->_pkg_info($pkg); $i ? $i->version : undef }
    method kind    ( $pkg = undef ) { my $i = $self->_pkg_info($pkg); $i ? $i->kind    : undef }
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
        return $self->_pkg_info($pkg) ? 'share' : 'system';
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

    # An Alien hands Perl a library to dlopen; the dynamic linker resolves that library's *own* dependencies
    # before our symbols are usable, so a vendored provider (freetype behind libsdl3_ttf) has to be findable
    # first. The engine can read those tables (see Alien::Xrepo::runtime_deps); these accessors wrap that with
    # the package dependency closure, so a consumer learns "you also need <dir> on <loader var>" instead of an
    # opaque dlopen failure. All are cached and degrade to empty for spy engines / failures.
    #
    # Raw fetch entries for the package's dependency closure (package + every transitive provider).
    method _closure_entries ($name) {
        return $closure->{$name} if exists $closure->{$name};
        return $closure->{$name} = [] unless $r->can('fetch_closure');
        my %ambient = ( %{ $recipe_obj->defaults // {} }, %$install_opts );
        my %opts    = $recipe_obj->opts_for( $name, %ambient );
        my $version = $recipe_obj->version_for($name);
        my @entries;
        try { @entries = $r->fetch_closure( $name, $version, %opts ) }
        catch ($e) {
            warn "[!] could not fetch the dependency closure for $name: $e\n" if $verbose;
            @entries = ();
        }
        return $closure->{$name} = \@entries;
    }

    # The closure's library directories (search paths) and install roots (for recognising "ours").
    method _closure_dirs ($name) {
        return ( [], [] ) unless $r->can('dep_search_dirs');
        return $r->dep_search_dirs( $self->_closure_entries($name) );
    }

    # Classified direct runtime dependencies of the package's FFI library, e.g.
    #   { name => 'libfreetype.6.dylib', path => '/store/f/freetype/.../lib/...', dir => '...', scope => 'store' }
    # scope is one of store / host / system / unresolved (see Alien::Xrepo::runtime_deps). Cached.
    method runtime_deps ( $pkg = undef ) {
        my $name = $pkg // ( $recipe_obj->packages )[0];
        die "Unknown package '$name'. Known: @{[ $recipe_obj->packages ]}" unless grep { $_ eq $name } $recipe_obj->packages;
        return $rdeps->{$name} if exists $rdeps->{$name};
        return $rdeps->{$name} = [] unless $r->can('runtime_deps');
        my $info    = $self->_pkg_info($name);
        my $libpath = $info ? $info->libpath : undef;
        return $rdeps->{$name} = [] unless defined $libpath && length $libpath && -f $libpath;
        my ( $search, $store ) = $self->_closure_dirs($name);

        if ( $info->libfiles && @{ $info->libfiles } ) {
            unshift @$search, map { path($_)->parent->stringify } @{ $info->libfiles };
        }
        unshift @$search, map { path($_)->stringify } $info->bin_dir;
        unshift @$store,  $info->installdir if defined $info->installdir && length $info->installdir;
        my $deps = $r->runtime_deps( $libpath, search_dirs => $search, store_dirs => $store );
        return $rdeps->{$name} = ( $deps // [] );
    }

    # Everything the loader would NOT find on its own (store / host / unresolved).
    method foreign_runtime_deps ( $pkg = undef ) {
        return grep { ( $_->{scope} // '' ) ne 'system' } @{ $self->runtime_deps($pkg) };
    }

    # Directories to put on the loader search path so foreign_runtime_deps resolve.
    method runtime_dep_dirs ( $pkg = undef ) {
        my %seen;
        return grep { defined && length && !$seen{$_}++ } map { $_->{dir} } $self->foreign_runtime_deps($pkg);
    }

    # The env var this platform's loader consults at dlopen time.
    method loader_env_var () {
        return $r->loader_env_var  if $r->can('loader_env_var');
        return 'PATH'              if $^O eq 'MSWin32';
        return 'DYLD_LIBRARY_PATH' if $^O eq 'darwin';
        return 'LD_LIBRARY_PATH';
    }

    # A post-install summary of the extra libraries a consumer must make loadable, or '' when none.
    method runtime_dep_report ( $pkg = undef ) {
        my @d = $self->foreign_runtime_deps($pkg);
        return '' unless @d;
        my @lines = ('runtime dependencies that must be loadable before this library is dlopen\'d:');
        push @lines, sprintf( '  - %s [%s]%s', $_->{name}, $_->{scope}, defined $_->{path} ? " -> $_->{path}" : '' ) for @d;
        my @dirs = $self->runtime_dep_dirs($pkg);
        push @lines, '  add to ' . $self->loader_env_var . ': ' . join( ( $^O eq 'MSWin32' ? ';' : ':' ), @dirs ) if @dirs;
        return join "\n", @lines;
    }

    # PackageInfo, with the runtime dependency diagnostic attached (unless already recorded in a snapshot, or
    # disabled via `check_runtime_deps => 0`). Spy engines that cannot scan simply yield the plain object.
    method package_info ( $pkg = undef ) {
        my $name = $pkg // ( $recipe_obj->packages )[0];
        my $info = $self->_pkg_info($name);
        return $info unless $info;
        return $info if @{ $info->runtime_deps // [] };
        return $info if $self->has_snapshot;              # a snapshot is authoritative (and must stay hermetic)
        return $info unless $check_runtime_deps;
        return $info unless defined $info->libpath && length $info->libpath;
        my $deps = $self->runtime_deps($name);
        return $info unless $deps && @$deps;
        return $info->with_runtime_deps($deps);
    }
};
#
1;
__END__
Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms found in
the Artistic License 2. Other copyrights, terms, and conditions may apply to data transmitted
through this module.
