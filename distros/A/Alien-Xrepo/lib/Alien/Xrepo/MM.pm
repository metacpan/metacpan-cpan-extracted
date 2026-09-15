use v5.40;

package Alien::Xrepo::MM v1.0.1 {
    use Cwd      qw[getcwd];
    use JSON::PP qw[decode_json encode_json];
    use Path::Tiny;
    use Alien::Xrepo::Build;
    use Alien::Xrepo::Build::Dist;
    our $CONFIG = 'xrepo-mm.json';    # build-time config, re-read by run() during make

    sub new ( $class, %attr ) {
        my %self = map { $_ => $attr{$_} } qw[
            module_name dist_abstract dist_author dist_version license
            base_dir xrepo_snapshot xrepo_share_dir xrepo_cache xrepo_update_repo
        ];
        $self{dist_version}      //= 'v1.0.0';
        $self{license}           //= 'artistic_2';
        $self{xrepo_cache}       //= 0;
        $self{xrepo_update_repo} //= 0;
        $self{base_dir}          //= Cwd::getcwd();
        $self{requires}           = { %{ $attr{requires}           // {} } };
        $self{configure_requires} = { %{ $attr{configure_requires} // {} } };
        $self{build_requires}     = { %{ $attr{build_requires}     // {} } };
        $self{test_requires}      = { %{ $attr{test_requires}      // {} } };

        # Thing the dist must own: it cannot be reverse-engineered from the dir name.
        die 'Alien::Xrepo::MM: module_name is required' unless defined $self{module_name};
        return bless \%self, $class;
    }
    sub module_name        { $_[0]{module_name} }
    sub dist_abstract      { $_[0]{dist_abstract} }
    sub dist_author        { $_[0]{dist_author} }
    sub dist_version       { $_[0]{dist_version} }
    sub license            { $_[0]{license} }
    sub xrepo_snapshot     { $_[0]{xrepo_snapshot} }
    sub xrepo_share_dir    { $_[0]{xrepo_share_dir} }
    sub xrepo_cache        { $_[0]{xrepo_cache} }
    sub xrepo_update_repo  { $_[0]{xrepo_update_repo} }
    sub base_dir           { $_[0]{base_dir} }
    sub requires           { $_[0]{requires} }
    sub configure_requires { $_[0]{configure_requires} }
    sub build_requires     { $_[0]{build_requires} }
    sub test_requires      { $_[0]{test_requires} }

    # The record of facts the two builders share: this dist root, the module, and
    # the build script whose mtime counts as a freshness input.
    sub _dist ($self) {
        Alien::Xrepo::Build::Dist->new( script => 'Makefile.PL', map { $_ => $self->{$_} } qw[base_dir module_name] );
    }

    # Engine modules that count as recipe inputs when loaded into this process.
    sub _engine_mods { (qw[Alien/Xrepo/MM.pm Alien/Xrepo/Build.pm Alien/Xrepo/Runtime.pm Alien/Xrepo/Build/Recipe.pm]) }

    # The Makefile gets the xrepo freshness check as a pure_all dependency.  The
    # rule itself is a tiny perl one-liner so every `make` decision happens in
    # Perl, next to the same staleness logic Module::Build uses.  -Ilib is for the
    # source tree (some dists build the build script from a fresh checkout); the
    # config is a file, never shell-quoted.
    # make requires the recipe to start with a real tab.  ``<<~`` dedents on the
    # closing delimiter and can only strip spaces, which MakeMaker then writes
    # space-indented and GNU make rejects as a malformed rule, so the tab is
    # built explicitly instead.
    sub _postamble {
        my $tab = "\t";
        my $run = "Alien::Xrepo::MM::run(q{$CONFIG})";
        return "pure_all :: xrepo\n\nxrepo :\n$tab\$(NOECHO) \$(PERLRUN) -Ilib -MAlien::Xrepo::MM -e \"$run\";\n";
    }
    package    #
        MY {
        sub postamble { Alien::Xrepo::MM::_postamble() }
    }

    # Generate the Makefile. The config below is written first so the pure_all hook the recipe emits has something to read when `make` runs.
    sub Write ($self) {
        my $base = path( $self->{base_dir} );
        $base->mkpath unless -d $base;
        my $cwd = getcwd();
        chdir $base or die "Alien::Xrepo::MM: chdir $base: $!";
        my $dist     = $self->_dist;
        my $snapshot = path( defined $self->{xrepo_snapshot} ? $self->{xrepo_snapshot} : $dist->snapshot_path )->absolute;
        my $share    = defined $self->{xrepo_share_dir} ? path( $self->{xrepo_share_dir} )->absolute : $snapshot->parent;
        $base->child($CONFIG)->spew_utf8(
            encode_json(
                {   module_name => $self->{module_name},
                    snapshot    => $snapshot->stringify,
                    share_dir   => $share->stringify,
                    cache       => $self->{xrepo_cache},
                    update_repo => $self->{xrepo_update_repo}
                }
            )
        );
        my %wm = $self->_write_makefile_args;
        require ExtUtils::MakeMaker;
        ExtUtils::MakeMaker::WriteMakefile(%wm);
        chdir $cwd;
        return;
    }

# ExtUtils::MakeMaker arguments mirror Alarm::Xrepo::MB's properties: test/build requires union into PREREQ_PM (EUMM treats PREREQ_PM as runtime), configure_requires separate, and the config cleaned with `make realclean`.
    sub _write_makefile_args ($self) {
        my %wm = (
            NAME               => $self->{module_name},
            VERSION            => $self->{dist_version},
            ABSTRACT           => ( $self->{dist_abstract} // $self->{module_name} ),
            AUTHOR             => $self->{dist_author},
            LICENSE            => $self->{license},
            PREREQ_PM          => { %{ $self->{build_requires} }, %{ $self->{test_requires} }, %{ $self->{requires} } },
            CONFIGURE_REQUIRES => { %{ $self->{configure_requires} } },
            clean              => { FILES => $CONFIG }
        );
        return %wm;
    }

# What `make` executes on the xrepo target: re-read the config written by Write(), rebuild the snapshot when stale, and do nothing (successfully) when the file is absent so a dist that merely loaded us but never used Write is unharmed.
    sub run ( $config //= $CONFIG ) {
        my $cfg = path($config);
        $cfg = $cfg->absolute unless $cfg->is_absolute;
        my $dist_root = $cfg->parent;
        return !print "Alien::Xrepo::MM: no $config found; skipping xrepo build\n" unless -e $cfg;
        my $data = decode_json( $cfg->slurp_utf8 );
        my $dist = Alien::Xrepo::Build::Dist->new( base_dir => $dist_root->stringify, module_name => $data->{module_name}, script => 'Makefile.PL' );
        my $snapshot = path( $data->{snapshot} );
        $snapshot = $dist_root->child( $data->{snapshot} ) unless $snapshot->is_absolute;
        return !print "=> xrepo: $snapshot is up to date\n" unless $dist->snapshot_stale( $snapshot, _engine_mods() );
        my $share = ( defined $data->{share_dir} && $data->{share_dir} ne '' ) ? path( $data->{share_dir} ) : $snapshot->parent;
        $share->mkpath;
        print "=> xrepo: writing $snapshot\n";
        Alien::Xrepo::Build->new(
            recipe      => $dist->recipe,
            snapshot    => $snapshot,
            share_dir   => $share->stringify,
            cache       => ( $data->{cache}       // 0 ),
            update_repo => ( $data->{update_repo} // 0 )
        )->run;
    }
};
#
1;
__END__
Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms found in
the Artistic License 2. Other copyrights, terms, and conditions may apply to data transmitted
through this module.
