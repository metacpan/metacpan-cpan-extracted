package    #
    MyBuilder {
    use v5.40;
    use File::Find;
    use Path::Tiny;
    use Alien::Xrepo::Build;
    use lib 'lib';
    use Exotic::SDL3;
    use parent 'Module::Build';
    __PACKAGE__->add_property( xrepo_snapshot => undef );
    #
    sub ACTION_code ($self) {
        my $snapshot = path( $self->xrepo_snapshot );
        if ( $self->_snapshot_stale($snapshot) ) {
            my $recipe = $self->_recipe;
            $snapshot->parent->mkpath;
            say "=> xrepo: writing $snapshot";
            Alien::Xrepo::Build->new( recipe => $recipe, snapshot => $snapshot, )->run;
        }
        else {
            $self->log_verbose("=> xrepo: $snapshot is up to date\n");
        }
        return $self->SUPER::ACTION_code;
    }
    sub _recipe ($self) { Exotic::SDL3->new->recipe }

    # Inputs whose freshness determines whether the snapshot needs regenerating.
    my @_xrepo_inputs = qw[Build.PL inc/MyBuilder.pm lib/Exotic/SDL3.pm];

    sub _snapshot_stale( $self, $snapshot ) {
        return 1 unless -e $snapshot;
        my $mtime = _mtime($snapshot);
        my $base  = path( $self->base_dir );
        for my $file (@_xrepo_inputs) {
            my $p = $base->child($file);
            next unless -e $p;
            return 1 if _mtime($p) > $mtime;
        }
        my $stale = 0;
        if ( -d $base->child('recipes') ) {
            find(
                sub {
                    $stale = 1 if -f $_ && _mtime( path($File::Find::name) ) > $mtime;
                },
                $base->child('recipes')->stringify,
            );
        }
        return $stale;
    }

    sub _mtime ($path) {
        my @st = stat($path);
        return $st[9] // -1;
    }
    };
#
1;
