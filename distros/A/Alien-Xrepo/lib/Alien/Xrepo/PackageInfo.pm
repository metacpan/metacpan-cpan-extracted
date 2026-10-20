use v5.40;
use feature 'class';
no warnings 'experimental::class';
#
class Alien::Xrepo::PackageInfo v1.0.10 {
    use Path::Tiny;
    field $includedirs  : param : reader;
    field $libfiles     : param : reader;
    field $license      : param : reader;
    field $linkdirs     : param : reader;
    field $links        : param : reader;
    field $shared       : param : reader;
    field $static       : param : reader;
    field $version      : param : reader;
    field $libpath      : param : reader //= ();
    field $bindirs      : param : reader //= [];
    field $installdir   : param : reader;
    field $deps         : param : reader //= [];
    field $runtime_deps : param : reader //= [];
    field $kind         : param : reader //= ();

    # Helper to find a specific header inside the includedirs
    method find_header ($filename) {
        for my $dir (@$includedirs) {
            my $p = path($dir)->child($filename);
            return $p->stringify if $p->exists;
        }

        # Fallback check: sometimes xrepo returns the generic include root, and the file is in a subdir (e.g. GL/gl.h)
        warn "Header '$filename' not found in package include directories:\n" . join( "\n", @$includedirs ) . "\n";
        return;
    }
    method bin_dir {@$bindirs}

    # Rebuild with a discovered runtime dependency list attached. A consumer that has to dlopen C<libpath>
    # needs to know which *other* shared libraries must be findable first (the dynamic linker resolves them
    # before our symbols are usable); this is where that list lands.
    method with_runtime_deps ($list) {
        return $self if @{ $runtime_deps // [] };
        return Alien::Xrepo::PackageInfo->new(
            includedirs  => $includedirs,
            libfiles     => $libfiles,
            license      => $license,
            linkdirs     => $linkdirs,
            links        => $links,
            shared       => $shared,
            static       => $static,
            version      => $version,
            libpath      => $libpath,
            bindirs      => $bindirs,
            deps         => $deps,
            runtime_deps => $list,
            installdir   => $installdir,
            kind         => $kind
        );
    }

    method _data_printer ($ddp) {
        {   includedirs  => $includedirs,
            libfiles     => $libfiles,
            license      => $license,
            linkdirs     => $linkdirs,
            links        => $links,
            shared       => $shared,
            static       => $static,
            version      => $version,
            libpath      => $libpath,
            bindirs      => $bindirs,
            deps         => $deps,
            runtime_deps => $runtime_deps,
            installdir   => $installdir,
            kind         => $kind
        }
    }
};
#
1;
