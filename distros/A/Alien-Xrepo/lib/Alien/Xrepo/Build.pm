use v5.40;
use feature 'class';
no warnings 'experimental::class';
#
class Alien::Xrepo::Build v1.0.0 {
    use Alien::Xrepo;
    use Alien::Xrepo::Build::Recipe;
    use Path::Tiny;
    use JSON::PP qw[encode_json decode_json];
    #
    my @STAGES = qw[configure probe install gather export test];
    #
    field $recipe       : param;               # Recipe object (or path/dir, normalized in ADJUST)
    field $root         : param //= undef;     # xrepo store root (XMAKE_PKG_INSTALLDIR)
    field $verbose      : param //= 0;
    field $cache        : param //= 1;         # forward the engine's warm-start cache to Alien::Xrepo
    field $repo         : param //= undef;     # injectable engine (spy-able)
    field $checkpoint   : param //= undef;     # state file path; enables resume
    field $snapshot     : param //= undef;     # write gathered runtime data as JSON here
    field $export_dir   : param //= undef;     # also xrepo-export each package into this dir
    field $probe_policy : param //= 'skip';    # skip|always|off
    field $resume       : param //= 0;
    #
    field $loaded_hooks = {};                  # recipe hook modules already registered

    #
    field $hooks = {};                                 # stage => [ coderef, ... ]
    field $meta_prop    : reader         = {};
    field $install_prop : reader         = {};
    field $runtime_prop : reader         = {};
    field $stage_done   : reader         = {};
    field $install_type : reader         = 'system';
    field $r            : reader(engine) = undef;      # resolved Alien::Xrepo engine

    #
    method packages ()     { return $recipe->packages }
    method package_defs () { return $recipe->package_defs }
    #
    ADJUST {
        unless ( ref $recipe ) {
            $recipe = Alien::Xrepo::Build::Recipe->new( defined $recipe && -d $recipe ? ( dir => $recipe ) : ( file => $recipe ), );
        }
        die "probe_policy must be skip|always|off" unless $probe_policy =~ /^(?:skip|always|off)$/;
        $r = $repo // Alien::Xrepo->new( root => $root, verbose => $verbose, cache => $cache );
        if ($resume) {
            $self->_load_checkpoint;
            $self->configure( resume => 1 ) unless $stage_done->{configure};
        }
    }

    # Hooks. A hook is invoked with ($self) immediately before its stage body.
    method register_hook ( $stage, $hook ) {
        die "Unknown stage '$stage'. Stages: @STAGES" unless grep { $_ eq $stage } @STAGES;
        die 'hook must be a coderef'                  unless ref $hook eq 'CODE';
        push @{ $hooks->{$stage} //= [] }, $hook;
        return;
    }
    method has_hook ($stage) { return $hooks->{$stage} && @{ $hooks->{$stage} } ? 1 : 0 }

    method run_hooks ($stage) {
        $self->$_($self) for @{ $hooks->{$stage} // [] };
        return;
    }

    method run (%opts) {
        $self->configure(%opts);
        $self->probe;
        $self->install;
        $self->gather;
        $self->export;
        $self->test;
        $self;
    }

    method configure (%opts) {
        $self->_load_recipe_hooks;
        return if $stage_done->{configure};
        $self->run_hooks('configure');
        $meta_prop = {
            name         => $recipe->name,
            packages     => [ $recipe->packages ],
            package_defs => $recipe->package_defs,
            defaults     => $recipe->defaults,
            pkg_roots    => $recipe->pkg_roots,
            local_repos  => [ @{ $recipe->local_repos } ],
            hooks        => [ @{ $recipe->hooks } ]
        };
        my %profile = ( %{ $recipe->defaults }, %opts );
        $profile{configs} = { %{ $recipe->defaults->{configs} // {} }, %{ $opts{configs} // {} } }
            if ref $recipe->defaults->{configs} eq 'HASH' || ref $opts{configs} eq 'HASH';
        my $store;
        eval { $store = $r->_store_dir( installdir => $root ) };
        $store //= $root;
        $install_prop = { root => $root, profile => \%profile, probed => {}, store => $store, };

        for my $repo_def ( @{ $recipe->local_repos } ) {
            my $dir = path($repo_def)->absolute;
            my $nm  = 'alien-' . $dir->basename;
            next unless $dir->child('packages')->is_dir;
            say "[xrepo] registering local recipe repo $nm from $dir..." if $verbose;
            eval { $r->add_repo( $nm, $dir->stringify ) };
        }
        $install_type = 'system';
        $self->_checkpoint;
        $stage_done->{configure} = 1;
        $self;
    }

    method probe () {
        return if $stage_done->{probe};
        $self->run_hooks('probe');
        $install_prop->{probed} ||= {};
        if ( $probe_policy ne 'off' ) {
            for my $name ( $recipe->packages ) {
                if ( my $root = $self->_pkg_root($name) ) {
                    $install_prop->{probed}{$name} = { version => undef, satisfied => 1, root => $root };
                    next;
                }
                my %opts     = $recipe->opts_for( $name, %{ $install_prop->{profile} // {} } );
                my $expected = $recipe->version_for($name);
                my $found;
                eval {
                    my $info = $r->info( $name, format => 'json', %opts );
                    $found = ref $info eq 'HASH' ? ( $info->{version} // $info->{package}{version} // undef ) : undef;
                };
                $install_prop->{probed}{$name} = { version => $found, satisfied => $self->_probe_satisfied( $found, $expected ) };
            }
        }
        $self->_checkpoint;
        $stage_done->{probe} = 1;
        $self;
    }

    method install () {
        return if $stage_done->{install};
        $self->run_hooks('install');
        $runtime_prop->{packages} ||= {};
        $runtime_prop->{errors}   ||= {};
        my $profile = $install_prop->{profile} // {};
        for my $name ( $recipe->packages ) {
            if ( my $root = $self->_pkg_root($name) ) {
                $runtime_prop->{packages}{$name} = $self->_root_entry($root);
                say "[xrepo] $name satisfied by " . $recipe->pkg_roots->{$name} . "=$root; skipping install" if $verbose;
                next;
            }
            my %opts = $recipe->opts_for( $name, %$profile );
            if ( $self->_can_skip_install($name) ) {
                say "[xrepo] $name already satisfied by the store; skipping install" if $verbose;
                next;
            }
            my $version = $recipe->version_for($name);
            say "Installing $name" . ( defined $version && length $version ? " $version" : '' ) . '...' if $verbose;
            my $info;
            eval { $info = $r->install( $name, $version, %opts ); };
            if ($@) {
                warn "[!] $name failed to install: $@\n";
                $runtime_prop->{errors}{$name} = "$@";
                next;
            }
            if ( ref $info eq 'Alien::Xrepo::PackageInfo' ) {
                $runtime_prop->{packages}{$name} = $info->_data_printer(undef);
                $install_type = 'share';
            }
        }
        $self->_checkpoint;
        $stage_done->{install} = 1;
        $self;
    }

    method gather () {
        return if $stage_done->{gather};
        $self->run_hooks('gather');
        $runtime_prop->{packages} ||= {};
        my $profile = $install_prop->{profile} // {};
        for my $name ( $recipe->packages ) {
            next if exists $runtime_prop->{packages}{$name} || exists $runtime_prop->{errors}{$name};
            if ( my $root = $self->_pkg_root($name) ) {
                $runtime_prop->{packages}{$name} = $self->_root_entry($root);
                next;
            }
            my %opts = $recipe->opts_for( $name, %$profile );
            my $info;
            eval { $info = $r->fetch( $name, $recipe->version_for($name), %opts ); };
            if ($@) {
                warn "[!] $name could not be gathered: $@\n";
                $runtime_prop->{errors}{$name} //= "$@";
                next;
            }
            if ( ref $info eq 'Alien::Xrepo::PackageInfo' ) {
                $runtime_prop->{packages}{$name} = $info->_data_printer(undef);
                $install_type = 'share';
            }
        }
        $self->_checkpoint;
        $stage_done->{gather} = 1;
        $self;
    }

    method export () {
        return if $stage_done->{export};
        $self->run_hooks('export');
        if ( my $dir = $export_dir ) {
            for my $name ( $recipe->packages ) {
                next                               if exists $runtime_prop->{errors}{$name};
                say "Exporting $name into $dir..." if $verbose;
                eval { $r->export( $name, $recipe->version_for($name), packagedir => path($dir)->child($name)->absolute ); };
                warn "[!] $name could not be exported: $@\n" if $@;
            }
        }
        if ($snapshot) {
            my $data = {
                dist_name    => $recipe->name,
                install_type => $install_type,
                pkg_roots    => $recipe->pkg_roots,
                packages     => $runtime_prop->{packages} // {},
                errors       => $runtime_prop->{errors}   // {},
                digest       => $self->_config_digest
            };
            path($snapshot)->parent->mkpath if defined $snapshot;
            path($snapshot)->spew_utf8( encode_json($data) . "\n" );
            say "Wrote runtime snapshot $snapshot" if $verbose;
        }
        $self->_checkpoint;
        $stage_done->{export} = 1;
        $self;
    }

    method test () {
        return if $stage_done->{test};
        $self->run_hooks('test');
        $stage_done->{test} = 1;
        $self;
    }
    method _version_for_pkg ($name)          { $recipe->version_for($name) }
    method _opts_for_pkg    ( $name, %opts ) { $recipe->opts_for( $name, %opts ) }

    method _config_digest () {
        require Digest::SHA;
        my @parts;
        for my $name ( $recipe->packages ) {
            my $version = $recipe->version_for($name);
            my %opts    = $recipe->opts_for( $name, %{ $install_prop->{profile} // {} } );
            push @parts, $name, ( defined $version ? $version : '' );
            push @parts, map { $_ . '=' . ( defined $opts{$_} ? $opts{$_} : '' ) } sort keys %opts;
        }
        Digest::SHA::sha256_hex( join "\x1f", @parts );
    }

    method _probe_satisfied ( $found, $expected ) {
        return 0 unless defined $found    && length $found;
        return 1 unless defined $expected && length $expected;
        return $found eq $expected;
    }

    # Recipe hook modules are loaded once per engine and invited to register their own stage hooks the same way code
    # can: module->register_hooks($self).
    method _load_recipe_hooks () {
        for my $mod ( @{ $recipe->hooks || [] } ) {
            next if $loaded_hooks->{$mod};
            my $file = $mod;
            $file =~ s{::}{/}g;
            $file .= '.pm';
            require $file;
            my $register = $mod->can('register_hooks');
            die "Alien::Xrepo::Build: recipe hook module '$mod' must expose register_hooks(\$build), got '$mod'" unless $register;
            $register->($self);
            $loaded_hooks->{$mod} = 1;
        }
        return;
    }

    # pkg_roots mirror Alien::Build's: name => environment variable whose value holds the package root. When the
    # variable is set and points at an existing directory the package is treated as system-provided there and xrepo is
    # never consulted (probe reports it satisfied; install/gather record it directly).
    method _pkg_root ($name) {
        my $pr = $recipe->pkg_roots->{$name};
        return () unless defined $pr && length $pr;
        my $dir = $ENV{$pr};
        return () unless defined $dir && length $dir && -d $dir;
        return path($dir)->absolute->stringify;
    }

    method _root_entry ($root) {
        my @inc = -d path($root)->child('include') ? ( path($root)->child('include')->stringify ) : ();
        my @lib = -d path($root)->child('lib')     ? ( path($root)->child('lib')->stringify )     : ();
        my @bin = -d path($root)->child('bin')     ? ( path($root)->child('bin')->stringify )     : ();
        {   includedirs => \@inc,
            libfiles    => [],
            license     => undef,
            linkdirs    => \@lib,
            links       => [],
            shared      => 1,
            static      => 0,
            version     => undef,
            libpath     => undef,
            bindirs     => \@bin,
            installdir  => $root,
            kind        => 'system'
        };
    }

    method _can_skip_install ($name) {
        return 0 unless $probe_policy eq 'skip';
        my $probe = $install_prop->{probed}{$name} // {};
        return 0 unless $probe->{satisfied};
        my %opts = $self->_opts_for_pkg( $name, %{ $install_prop->{profile} // {} } );
        !$opts{force};
    }

    method _checkpoint () {
        return unless defined $checkpoint;
        path($checkpoint)->parent->mkpath;
        my $data = {
            install_type => $install_type,
            stage_done   => $stage_done,
            meta_prop    => $meta_prop,
            install_prop => $install_prop,
            runtime_prop => $runtime_prop
        };
        path($checkpoint)->spew_utf8( encode_json($data) . "\n" );
        return;
    }
    #
    method _load_checkpoint () {
        return 0 unless defined $checkpoint && -e $checkpoint;
        my $data = eval { decode_json( path($checkpoint)->slurp_utf8 ) };
        return 0 unless ref $data eq 'HASH';
        $install_type = $data->{install_type} // 'system';
        $stage_done   = $data->{stage_done}   // {};
        $meta_prop    = $data->{meta_prop}    // {};
        $install_prop = $data->{install_prop} // {};
        $runtime_prop = $data->{runtime_prop} // {};
        return 1;
    }
};
#
1;
__END__
Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms found in
the Artistic License 2. Other copyrights, terms, and conditions may apply to data transmitted
through this module.
