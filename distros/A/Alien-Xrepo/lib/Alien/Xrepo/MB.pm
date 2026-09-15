use v5.40;

package Alien::Xrepo::MB v1.0.1 {
    use Alien::Xrepo::Build;
    use Alien::Xrepo::Build::Dist;
    use Path::Tiny;
    use parent 'Module::Build';
    __PACKAGE__->add_property( xrepo_snapshot    => undef );    # JSON to (re)write, auto-derived when undef
    __PACKAGE__->add_property( xrepo_share_dir   => undef );    # shallow-install root, defaults to the snapshot's dir
    __PACKAGE__->add_property( xrepo_cache       => 0 );        # bypass Alien::Xrepo's on-disk cache by default
    __PACKAGE__->add_property( xrepo_update_repo => 0 );        # refresh xrepo repositories once when an install fails

    sub ACTION_code($self) {
        my $dist     = $self->_dist;
        my $snapshot = path( defined $self->xrepo_snapshot ? $self->xrepo_snapshot : $dist->snapshot_path );
        if ( $dist->snapshot_stale( $snapshot, $self->_engine_mods ) ) {
            my $share = defined $self->xrepo_share_dir ? path( $self->xrepo_share_dir ) : $snapshot->parent;
            $share->mkpath;
            say '=> xrepo: writing ' . $snapshot;
            Alien::Xrepo::Build->new(
                recipe      => $dist->recipe,
                snapshot    => $snapshot,
                share_dir   => $share->stringify,
                cache       => $self->xrepo_cache,
                update_repo => $self->xrepo_update_repo
            )->run;
        }
        else {
            $self->log_verbose("=> xrepo: $snapshot is up to date\n");
        }
        return $self->SUPER::ACTION_code;
    }

    # The record of facts the two builders share: this dist root, the module, and the build script whose mtime counts as a freshness input.
    sub _dist ($self) {
        my $class = $self->module_name or die 'Alien::Xrepo::MB: module_name is required';
        return Alien::Xrepo::Build::Dist->new( base_dir => $self->base_dir, module_name => $class, script => 'Build.PL', );
    }

    # Engine modules that count as recipe inputs when loaded into this process.
    sub _engine_mods {qw[Alien/Xrepo/MB.pm Alien/Xrepo/Build.pm Alien/Xrepo/Runtime.pm Alien/Xrepo/Build/Recipe.pm]}

    # Kept for interface stability with existing `./Build` consumers and tests; the real work delegates to Alien::Xrepo::Build::Dist
    sub _recipe         ($self)              { $self->_dist->recipe }
    sub _xrepo_snapshot ($self)              { defined $self->xrepo_snapshot ? $self->xrepo_snapshot : $self->_dist->snapshot_path }
    sub _xrepo_inputs   ($self)              { $self->_dist->inputs( $self->_engine_mods ) }
    sub _snapshot_stale ( $self, $snapshot ) { $self->_dist->snapshot_stale( $snapshot, $self->_engine_mods ) }
};
#
1;
