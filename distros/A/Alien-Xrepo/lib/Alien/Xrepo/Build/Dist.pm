use v5.40;

package Alien::Xrepo::Build::Dist v1.0.1 {
    use File::Find;
    use Path::Tiny;

    sub new ( $class, %attr ) {
        $attr{base_dir} //= '.';
        $attr{script}   //= 'Build.PL';    # XXX - I could do this with caller()
        die 'Alien::Xrepo::Build::Dist: module_name is required' unless defined $attr{module_name};
        my %self = map { $_ => $attr{$_} } qw[base_dir module_name script];
        return bless \%self, $class;
    }
    sub base_dir    { $_[0]{base_dir} }
    sub module_name { $_[0]{module_name} }
    sub script      { $_[0]{script} }

    # lib/Alien/Foo.pm for Alien::Foo
    sub module_rel ($self) {
        ( my $rel = $self->{module_name} . '.pm' ) =~ s{::}{/}g;
        return $rel;
    }
    sub module_path ($self) { return path( $self->{base_dir} )->child( 'lib', $self->module_rel )->stringify }
    sub dist_name   ($self) { ( my $dist = $self->{module_name} ) =~ s{::}{-}g; return $dist }

    # The conventional place the hermetic snapshot lands: blib/lib/auto/share/dist/<Dist>/xrepo-snapshot.json
    sub snapshot_path ($self) {
        path( $self->{base_dir} )->child( 'blib', 'lib', 'auto', 'share', 'dist', $self->dist_name, 'xrepo-snapshot.json' )->stringify;
    }

    # The dist's single declaration: the Alien::<Tail> subclass's recipe() (a hashref, an Alien::Xrepo::Build::Recipe
    # object, or a path). The engine normalizes whatever comes back.  Requires lib/<class>.pm by its absolute path so
    # it wins over any pre-installed copy.
    sub recipe ($self) {
        require( path( $self->module_path )->absolute->stringify );
        return $self->{module_name}->new->recipe;
    }

    # Inputs whose freshness determines whether the snapshot needs regenerating: the dist's own recipe inputs (the
    # build script and lib/<class>.pm), whatever engine modules from the given list are loaded into THIS process (%INC,
    # so a parent install bump re-runs the examples), and any local recipes/ tree is folded in by snapshot_stale, not
    # here.
    sub inputs ( $self, @engine_mods ) {
        my @inputs = ( path( $self->{base_dir} )->child( $self->{script} )->stringify, $self->module_path, );
        for my $mod (@engine_mods) {
            push @inputs, $INC{$mod} if defined $INC{$mod};
        }
        return @inputs;
    }

    # True when the snapshot is missing or older than any input (mirroring Module::Build's copy_if_modified semantics)
    # or any file under a local recipes/ tree.
    sub snapshot_stale ( $self, $snapshot, @engine_mods ) {
        return 1 unless -e $snapshot;
        return 1 if !-f $snapshot || -z $snapshot;    # a directory or empty file can't be a valid snapshot
        my $mtime = _mtime($snapshot);
        for my $file ( $self->inputs(@engine_mods) ) {
            next unless -e $file;
            return 1 if _mtime($file) > $mtime;
        }
        my $base  = path( $self->{base_dir} );
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
        my @st = stat($path);
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
