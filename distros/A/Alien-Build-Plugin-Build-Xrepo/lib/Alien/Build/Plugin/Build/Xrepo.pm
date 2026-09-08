package Alien::Build::Plugin::Build::Xrepo v1.0.0 {
    use v5.40;
    use Alien::Build::Plugin;
    use Carp       ();
    use Cwd        ();
    use Path::Tiny ();
    use File::Spec ();
    #
    has '+packages' => sub { Carp::croak 'packages is a required property' };
    has name        => undef;
    has version     => undef;
    has kind        => undef;
    has root        => undef;
    has ffi         => 0;
    has verbose     => 0;
    has repo        => undef;
    has local_repos => undef;
    has __build     => undef;

    sub init ( $self, $meta ) {
        my $verbose = $self->verbose;
        $meta->add_requires( 'configure', 'Alien::Build' => '2.84' );
        $meta->add_requires( 'configure', 'Alien::Xrepo' => 'v1.0.0' );
        require Alien::Xrepo;
        require Alien::Xrepo::Build::Recipe;
        require Alien::Xmake;
        my $recipe = Alien::Xrepo::Build::Recipe->new(
            ( defined $self->name        ? ( name        => $self->name )        : () ),
            ( defined $self->local_repos ? ( local_repos => $self->local_repos ) : () ),
            packages => $self->packages,
        );
        my %ambient;
        $ambient{version} = $self->version if defined $self->version;
        $ambient{kind}    = $self->kind    if defined $self->kind;
        my $repo = $self->repo;
        my $engine;
        my $engine_for = sub {
            return $engine if defined $engine;
            if ( ref $repo eq 'CODE' ) {
                $engine = $repo->();
            }
            elsif ( ref $repo ) {
                $engine = $repo;
            }
            elsif ( defined $repo ) {
                $engine = $repo->new();
            }
            else {
                $engine = Alien::Xrepo->new( root => $self->root, verbose => $verbose );
            }
            $engine;
        };
        $meta->register_hook(
            probe => sub ($build) {
                my $r = eval { $engine_for->() };
                if ( !$r ) {
                    my $err = $@ || 'unknown error';
                    $err =~ s/\s+/ /g;
                    $err = substr( $err, 0, 300 ) . '...' if length($err) > 300;
                    die "Alien::Build::Plugin::Build::Xrepo: could not construct the xrepo engine during probe: $err\n";
                }
                my %probed;
                for my $name ( $recipe->packages ) {
                    my $version = $recipe->version_for($name);
                    $version = $ambient{version} unless defined $version;
                    my %opts = $recipe->opts_for( $name, %ambient );
                    my ( $found, $satisfied );
                    eval {
                        my $info = $r->info( $name, format => 'json', %opts );
                        if ( ref $info eq 'HASH' ) {
                            $found = $info->{version} // $info->{package}{version} // undef;
                        }
                    };
                    $satisfied = ( defined $found && defined $version ) ? ( $found eq $version ) : ( defined $found ) ? 1 : 0;
                    $probed{$name} = { version => $found, satisfied => $satisfied };
                    my $status = $satisfied ? 'satisfied' : 'missing';
                    say "[xrepo] probe: $name " . ( $found // 'not installed' ) . " ($status)\n" if $verbose;
                }
                $build->install_prop->{xrepo} ||= {};
                $build->install_prop->{xrepo}{probed} = \%probed;
                return 'share';
            }
        );
        $meta->register_hook(
            download => sub ($build) {
                $self->__build($build);
                unless ( ref $repo ) {
                    my $xrepo = eval { Alien::Xmake->new->xrepo } || 'xrepo';
                    my $ok    = File::Spec->file_name_is_absolute($xrepo) ? ( -e $xrepo ) : _which_in_path($xrepo);
                    die "Alien::Build::Plugin::Build::Xrepo: could not locate xrepo ($xrepo). " .
                        'Install xmake, or inject an engine via the repo property.'
                        unless $ok;
                }
                my $r   = $engine_for->();
                my $src = Cwd::getcwd();

                # Register any local repo trees (patched/private package recipes) with the engine
                # before installing, mirroring the engine's configure stage.
                for my $repo_def ( @{ $recipe->local_repos || [] } ) {
                    my $dir = Path::Tiny->new($repo_def)->absolute;
                    next unless $dir->child('packages')->is_dir;
                    my $nm = 'alien-' . $dir->basename;
                    say "[xrepo] no engine support for add_repo (local repo $nm ignored)" if !$r->can('add_repo');
                    eval { $r->add_repo( $nm, $dir->stringify ) };
                }
                my %packages;
                my %errors;
                for my $name ( $recipe->packages ) {

                    # a per-package recipe version wins; otherwise the ambient plugin version (the
                    # alienfile `version` property) is the install-time default.
                    my $version = $recipe->version_for($name);
                    $version = $ambient{version} unless defined $version;
                    my %opts = $recipe->opts_for( $name, %ambient );
                    my $info;
                    eval { $info = $r->install( $name, $version, %opts ) };
                    if ($@) {
                        $errors{$name} = "$@";
                        next;
                    }
                    if ( ref $info && eval { $info->can('_data_printer') } ) {
                        $packages{$name} = $info->_data_printer(undef);
                    }
                    my $target = Path::Tiny->new($src)->child($name);
                    $target->mkpath;
                    eval { $r->export( $name, $version, %opts, packagedir => $target->stringify ) };
                    if ($@) {
                        $target->remove_tree if $target->exists;
                        delete $packages{$name};
                        $errors{$name} = 'export failed: ' . ( $@ || 'unknown error' );
                    }
                }

                # A failed sibling does not sink the surviving packages (partial installs are by
                # design), but it must never be silent: prune export-failures from the success set,
                # flag every failure in the returned install/runtime prop so consumers can see what
                # is missing, and warn loudly.
                my $spared = Path::Tiny->new($src)->child('xrepo.manifest');
                $spared->spew_utf8( join "\n", grep { exists $packages{$_} } $recipe->packages );
                if (%errors) {
                    $build->runtime_prop->{errors} = { map { $_ => $errors{$_} } sort keys %errors };
                    my $failed = join ', ', sort keys %errors;
                    warn "Alien::Build::Plugin::Build::Xrepo: partial failure - these packages failed to install or export: $failed\n";
                    my ( $ok, $bad ) = ( scalar( keys %packages ), scalar( keys %errors ) );
                    warn "[xrepo] $ok packages installed, $bad failed (see install_prop->{xrepo}{errors} / runtime_prop->{errors} for details)\n"
                        if $verbose;
                }
                my $xrepo = $build->install_prop->{xrepo} ||= {};
                $xrepo->{packages}     = \%packages;
                $xrepo->{errors}       = \%errors;
                $xrepo->{download_dir} = $src;

                # The produced content is local (xrepo store exports, not a network fetch), so
                # declare it to Alien::Build as a 'file' protocol download. Without
                # download_details the extract step warns about a missing digest and a future
                # Alien::Build will die by default.
                my $dl = Path::Tiny->new('.')->absolute->stringify;
                $build->install_prop->{download_detail}{$dl} = { protocol => 'file' };
                die 'Alien::Build::Plugin::Build::Xrepo: no packages installed successfully' unless %packages;
            }
        );
        $meta->default_hook(
            extract => sub ( $build, $dest ) {
                $self->__build($build);
                my $xrepo = $build->install_prop->{xrepo};
                die 'Alien::Build::Plugin::Build::Xrepo: the plugin download stage must run before extract'
                    unless $xrepo && defined $xrepo->{download_dir};
                my $src = Path::Tiny->new( $xrepo->{download_dir} );

                # The extract-hook contract makes the current working directory the staging
                # scaffold: Alien::Build chdirs every extract into a fresh, empty TempDir and
                # expects the content there (Alien::Build::Manual::PluginAuthor, "extract hook").
                # $dest is the *source* for a file protocol for this plugin it is the same download
                # temp dir $xrepo->{download_dir} points at, so copying into it would be a
                # self-copy. Copy into the cwd scaffold, not $dest.
                my $dst = Path::Tiny->new( Cwd::getcwd() );
                for my $child ( $src->children ) {
                    next if $child->basename eq '.';
                    my $out = $dst->child( $child->basename );
                    $child->is_dir ? _copy_tree( $child, $out ) : $child->copy($out);
                }
                1;
            }
        );
        $meta->default_hook(
            build => sub ($build) {
                $self->__build($build);
                my $xrepo = $build->install_prop->{xrepo};
                die 'Alien::Build::Plugin::Build::Xrepo: the plugin download stage must run before build'
                    unless $xrepo && defined $xrepo->{download_dir};
                my $src    = Path::Tiny->new( $xrepo->{download_dir} );
                my $prefix = Path::Tiny->new( $build->install_prop->{prefix} ) || die 'Alien::Build::Plugin::Build::Xrepo: prefix is not set';
                $prefix->mkpath;
                my %exported;
                for my $name ( $recipe->packages ) {
                    my $from = $src->child($name);
                    next unless -d $from;
                    my $to = $prefix->child($name);
                    $to->mkpath;
                    my $content = _locate_content_dir($from);
                    my $base    = $content || $from;
                    for my $child ( $base->children ) {
                        my $dest = $to->child( $child->basename );
                        $child->is_dir ? _copy_tree( $child, $dest ) : $child->copy($dest);
                    }
                    $exported{$name} = $to->stringify;
                    my $bin = $to->child('bin');
                    next unless -d $bin;
                    my $destbin = $prefix->child('bin');
                    $destbin->mkpath;
                    for my $file ( $bin->children ) {
                        my $out = $destbin->child( $file->basename );
                        next if -e $out;
                        $file->copy($out);
                    }
                }
                $xrepo->{exported} = \%exported;
            }
        );
        $meta->register_hook(
            gather_share => sub ($build) {
                $self->__build($build);
                my $xrepo = $build->install_prop->{xrepo};
                my $data  = $xrepo && $xrepo->{packages};
                my $exp   = $xrepo && $xrepo->{exported};
                die 'Alien::Build::Plugin::Build::Xrepo: no package data to gather; ' . 'did the plugin download/build stages run?'
                    unless $data && %$data && $exp && %$exp;
                my $rp   = $build->runtime_prop;
                my @pkgs = $recipe->packages;
                if ( my $p = _pkg_props( $data->{ $pkgs[0] }, $exp->{ $pkgs[0] } ) ) {
                    $rp->{$_}      = $p->{$_} for qw( cflags cflags_static libs libs_static );
                    $rp->{version} = $p->{version}                         if defined $p->{version};
                    $rp->{bin_dir} = _reroot_bins( $build, $p->{bin_dir} ) if $p->{bin_dir};
                }
                if ( @pkgs > 1 ) {
                    my %alt;
                    for my $name ( @pkgs[ 1 .. $#pkgs ] ) {
                        my $p = _pkg_props( $data->{$name}, $exp->{$name} );
                        $p->{bin_dir} = _reroot_bins( $build, $p->{bin_dir} ) if $p && $p->{bin_dir};
                        $alt{$name}   = $p                                    if $p;
                    }
                    $rp->{alt} = \%alt if keys %alt;
                }
            }
        );
        if ( $self->ffi ) {
            $meta->register_hook(
                gather_ffi => sub ($build) {
                    $self->__build($build);
                    my $xrepo   = $build->install_prop->{xrepo} or return;
                    my $data    = $xrepo->{packages}            or return;
                    my $exp     = $xrepo->{exported}            or return;
                    my $rp      = $build->runtime_prop;
                    my $primary = $data->{ ( $recipe->packages )[0] };
                    my @links   = @{ $primary->{links} || [] };
                    $rp->{ffi_name} ||= $links[0] if $links[0];
                    my @dyn;

                    for my $dir ( values %$exp ) {
                        for my $sub (qw[bin lib]) {
                            my $d = Path::Tiny->new($dir)->child($sub);
                            next unless -d $d;
                            push @dyn, map { $_->stringify } grep { $_->basename =~ /\.(?:dll|so|dylib)$/i } $d->children;
                        }
                    }
                    $rp->{dynamic_libs} ||= _reroot_dyn( $build, \@dyn ) if @dyn;
                }
            );
        }
        my $intr = $meta->interpolator;
        $intr->add_helper( xrepo => sub { Alien::Xmake->new->xrepo } );
        $intr->add_helper( xmake => sub { Alien::Xmake->new->exe } );
        $intr->add_helper(
            xrepo_cflags => sub {
                my $b = $self->__build;
                defined $b ? ( $b->runtime_prop->{cflags} || '' ) : '';
            }
        );
        $intr->add_helper(
            xrepo_libs => sub {
                my $b = $self->__build;
                defined $b ? ( $b->runtime_prop->{libs} || '' ) : '';
            }
        );
        $intr->add_helper(
            xrepo_version => sub {
                my $b = $self->__build;
                defined $b ? ( $b->runtime_prop->{version} || '' ) : '';
            }
        );
        $intr->add_helper(
            xrepo_dynamic_libs => sub {
                my $b = $self->__build;
                my $d = defined $b ? $b->runtime_prop->{dynamic_libs} : undef;
                return '' unless $d;
                join ' ', @$d;
            }
        );
        $self;
    }

    sub _reroot_bins ( $build, $bins //= () ) {
        return $bins unless $bins;
        my $root = $build->install_prop->{prefix};
        my $rr   = $build->runtime_prop->{prefix};
        return $bins unless defined $root && defined $rr;
        [   map {
                my $rel = File::Spec->abs2rel( $_, $root );
                File::Spec->catdir( $rr, $rel );
            } @$bins
        ];
    }

    sub _reroot_dyn ( $build, $dyn ) {
        return $dyn unless $dyn && @$dyn;
        my $root = $build->install_prop->{prefix};
        my $rr   = $build->runtime_prop->{prefix};
        return $dyn unless defined $root && defined $rr;
        [   map {
                my $rel = File::Spec->abs2rel( $_, $root );
                File::Spec->catdir( $rr, $rel );
            } @$dyn
        ];
    }

    sub _copy_tree ( $src, $dst ) {
        $dst->mkpath;
        for my $child ( $src->children ) {
            my $out = $dst->child( $child->basename );
            $child->is_dir ? _copy_tree( $child, $out ) : $child->copy($out);
        }
        1;
    }

    sub _locate_content_dir ($root) {
        my $found;
        my $depth = -1;
        my @stack = ( [ $root, 0 ] );
        while (@stack) {
            my ( $dir, $d ) = @{ shift @stack };
            my @kids = $dir->children;
            my @with;
            for my $k (@kids) {
                next unless $k->is_dir;
                next unless $k->basename =~ /^(?:include|lib|bin)$/;
                next unless _has_entries($k);
                push @with, $k;
            }
            if ( @with && $d > $depth ) {
                $found = $dir;
                $depth = $d;
            }
            push @stack, map { [ $_, $d + 1 ] } grep { $_->is_dir && $_->basename !~ /^(?:include|lib|bin)$/ } @kids;
        }
        return $found;
    }
    sub _has_entries ($dir) { scalar @{ [ $dir->children ] }; }

    sub _which_in_path ($exec) {
        my $sep  = ( $^O eq 'MSWin32' ) ? ';'                : ':';
        my @exts = ( $^O eq 'MSWin32' ) ? qw(.exe .bat .cmd) : ('');
        for my $dir ( split /\Q$sep\E/, $ENV{PATH} ) {
            next if !length $dir;
            for my $ext (@exts) {
                my $cand = File::Spec->catfile( $dir, "$exec$ext" );
                return $cand if -e $cand && !-d $cand;
            }
        }
        return undef;
    }

    sub _pkg_props ( $info, $dir ) {
        return undef unless $info && $dir;
        my $t     = Path::Tiny->new($dir);
        my @inc   = ();
        my @ldirs = ();
        my @bins  = ();
        push @inc,   $t->child('include')->stringify if -d $t->child('include');
        push @ldirs, $t->child('lib')->stringify     if -d $t->child('lib');
        push @bins,  $t->child('bin')->stringify     if -d $t->child('bin');
        push @inc,   $t->stringify                   if !@inc;
        push @ldirs, $t->stringify                   if !@ldirs;
        my $cflags = join ' ', map {"-I$_"} @inc;
        my $libs   = join ' ', map {"-L$_"} @ldirs;
        $libs .= ' ' . join ' ', map {"-l$_"} @{ $info->{links} || [] };
        { cflags => $cflags, cflags_static => $cflags, libs => $libs, libs_static => $libs, version => $info->{version}, bin_dir => \@bins };
    }
};
#
1;
