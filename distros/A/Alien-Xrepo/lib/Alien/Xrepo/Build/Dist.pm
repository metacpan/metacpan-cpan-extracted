use v5.40;
use feature 'class';
no warnings 'experimental::class';
#
class Alien::Xrepo::Build::Dist v1.0.10 {
    use File::Find;
    use Path::Tiny;
    #
    field $base_dir    : reader : param //= '.';
    field $script      : reader : param //= 'Build.PL';    # XXX - I could do this with caller()
    field $module_name : reader : param;                   # Required

    # lib/Alien/Foo.pm for Alien::Foo
    method module_rel () {
        ( my $rel = $module_name . '.pm' ) =~ s{::}{/}g;
        $rel;
    }
    method module_path () { path($base_dir)->child( 'lib', $self->module_rel )->stringify }
    method dist_name ()   { $module_name =~ s{::}{-}gr }

    # The conventional place the hermetic snapshot lands: blib/lib/auto/share/dist/<Dist>/xrepo-snapshot.json
    method snapshot_path () {
        path($base_dir)->child( 'blib', 'lib', 'auto', 'share', 'dist', $self->dist_name, 'xrepo-snapshot.json' )->stringify;
    }

    # The dist's single declaration: the Alien::<Tail> subclass's recipe() (a hashref, an Alien::Xrepo::Build::Recipe
    # object, or a path). The engine normalizes whatever comes back.  Requires lib/<class>.pm by its absolute path so
    # it wins over any pre-installed copy.
    method recipe () {
        require( path( $self->module_path )->absolute->stringify );
        return $module_name->new->recipe;
    }

    # Inputs whose freshness determines whether the snapshot needs regenerating: the dist's own recipe inputs (the
    # build script and lib/<class>.pm), whatever engine modules from the given list are loaded into THIS process (%INC,
    # so a parent install bump re-runs the examples), and any local recipes/ tree is folded in by snapshot_stale, not
    # here.
    method inputs (@engine_mods) {
        my @inputs = ( path($base_dir)->child($script)->stringify, $self->module_path );
        for my $mod (@engine_mods) {
            push @inputs, $INC{$mod} if defined $INC{$mod};
        }
        return @inputs;
    }

    # True when the snapshot is missing or older than any input (mirroring Module::Build's copy_if_modified semantics)
    # or any file under a local recipes/ tree.
    method snapshot_stale ( $snapshot, @engine_mods ) {
        return 1 unless -e $snapshot;
        return 1 if !-f $snapshot || -z $snapshot;    # a directory or empty file can't be a valid snapshot
        my $mtime = _mtime($snapshot);
        for my $file ( $self->inputs(@engine_mods) ) {
            next unless -e $file;
            return 1 if _mtime($file) > $mtime;
        }
        my $base  = path($base_dir);
        my $stale = 0;
        if ( -d $base->child('recipes') ) {
            find(
                sub {
                    $stale = 1 if -f $_ && _mtime( path($File::Find::name) ) > $mtime;
                },
                $base->child('recipes')->stringify
            );
        }
        $stale;
    }

    sub _mtime ($path) {
        my @st = stat $path;
        return $st[9] // -1;
    }
};
#
1;
__END__
Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms found in
the Artistic License 2. Other copyrights, terms, and conditions may apply to data transmitted
through this module.
