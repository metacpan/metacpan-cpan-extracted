use v5.40;
use feature 'class';
no warnings 'experimental::class';
class    #
    Alien::Xmake::Builder {
    use CPAN::Meta;
    use ExtUtils::Install qw[pm_to_blib install];
    use ExtUtils::InstallPaths;
    use Digest::SHA;
    use JSON::PP;
    use Config;
    use HTTP::Tiny;
    use Path::Tiny        qw[path cwd];
    use ExtUtils::Helpers qw[make_executable split_like_shell detildefy];
    use Capture::Tiny     qw[capture];
    use Symbol            qw[gensym];
    use IPC::Open3;

    # Configuration
    field $target_version : param : reader //= '';    # empty means "latest release" (resolved from the GitHub API)
    field $force  : param  //= 0;
    field $meta   : reader //= CPAN::Meta->load_file('META.json');
    field $action : param  //= 'build';
    field $target_config = 'lib/Alien/Xmake/ConfigData.pm';

    # GitHub release discovery
    field $owner         = 'xmake-io';
    field $repo          = 'xmake';
    field $http : reader = do {
        my %headers = ( 'X-GitHub-Api-Version' => '2026-03-10', accept => 'application/vnd.github+json' );
        my $token   = $ENV{GITHUB_TOKEN} // $ENV{GH_TOKEN};
        $headers{Authorization} = 'Bearer ' . $token if $token && length $token;
        HTTP::Tiny->new( default_headers => \%headers, verify_SSL => 1 );
    };
    field $gh_release;          # decoded latest/pinned release hashref (lazy)
    field $resolved_version;    # target version tag (lazy, from the API when needed)

    # Params to Build script
    field $install_base  : param    //= '';
    field $installdirs   : param    //= '';
    field $uninst        : param    //= 0;
    field $install_paths : param    //= ExtUtils::InstallPaths->new( dist_name => $meta->name );
    field $verbose       : param(v) //= 0;
    field $dry_run       : param    //= 0;
    field $pureperl      : param    //= 0;
    field $jobs          : param    //= 1;
    field $destdir       : param    //= '';
    field $prefix        : param    //= '';
    ADJUST {
        -e 'META.json' or die "No META information provided\n";
    }

    method Build_PL() {
        say 'Pure perl Alien? Ha! You wish.' if $pureperl;
        say sprintf 'Creating new Build script for %s %s', $meta->name, $meta->version;

        # We must capture the current INC to ensure the builder finds itself
        # when running the generated script.
        my $inc_str = join( ' ', map {"-I$_"} @INC );
        $self->write_file( 'Build', sprintf <<'', $^X, $inc_str, __PACKAGE__, __PACKAGE__ );
#!%s %s
use lib 'builder';
use %s;
%s->new( @ARGV && $ARGV[0] =~ /\A\w+\z/ ? ( action => shift @ARGV ) : (),
    map { /^--/ ? ( shift(@ARGV) =~ s[^--][]r => 1 ) : /^-/ ? ( shift(@ARGV) =~ s[^-][]r => shift @ARGV ) : () } @ARGV )->Build();

        make_executable('Build');
        my @env = defined $ENV{PERL_MB_OPT} ? split_like_shell( $ENV{PERL_MB_OPT} ) : ();
        $self->write_file( '_build_params', encode_json( [ \@env, \@ARGV ] ) );
        if ( my $dynamic = $meta->custom('x_dynamic_prereqs') ) {
            my %meta_struct = ( %{ $meta->as_struct }, dynamic_config => 1 );
            require CPAN::Requirements::Dynamic;
            my $dynamic_parser = CPAN::Requirements::Dynamic->new();
            my $prereq         = $dynamic_parser->evaluate($dynamic);
            $meta_struct{prereqs} = $meta->effective_prereqs->with_merged_prereqs($prereq)->as_string_hash;
            $meta = CPAN::Meta->new( \%meta_struct );
        }
        $meta->save(@$_) for ['MYMETA.json'];
    }

    # Actions
    method ACTION_build ( ) {
        say 'Building Alien-Xmake...' if $verbose;

        # Prepare blib
        path('blib/lib')->mkpath;
        path('blib/arch')->mkpath;
        path('blib/script')->mkpath;
        path('blib/bin')->mkpath;

        # Copy Libs
        $self->_copy_libs();

        # Alien Logic: Check or Install Xmake
        my $config_data = $self->_resolve_xmake();

        # Stage the bundled xmake into the standard sharedir location so the
        # regular install step ships it and tests find it via @INC. This is the
        # Module::Build::Tiny 'dist_shared' model: build copies share/ into
        # blib/lib/auto/share/dist/<Name>/ and install just moves blib/lib.
        $self->_stage_sharedir();

        # Generate ConfigData.pm
        $self->_write_config_data($config_data);
        say 'Build complete' if $verbose;
        true;
    }

    method _stage_sharedir () {
        my $src = path('share');
        return unless $src->is_dir;
        my $auto = path('blib/lib/auto/share/dist')->child( $meta->name );
        my $iter = $src->iterator( { recurse => 1 } );
        while ( my $s = $iter->() ) {
            next unless $s->is_file;
            my $target = $auto->child( $s->relative($src) );
            $target->parent->mkpath;
            $s->copy($target) or die "Copy failed: $!";
            $target->chmod( $s->stat->mode | 0600 );
        }
        say 'Staged bundled xmake to ' . $auto if $verbose;
    }

    method ACTION_install ( ) {
        say 'Installing...' if $verbose;
        my %install_results;
        ExtUtils::Install::install(
            [   from_to           => { 'blib/lib' => $Config{installprivlib}, 'blib/arch' => $Config{installarchlib} },
                verbose           => $verbose,
                dry_run           => 0,
                uninstall_shadows => 1,
                skip              => undef,
                always_copy       => 1,
                result            => \%install_results
            ]
        );

        # XXX: Should I bother with the $install_results{install_fail}?
        true;
    }

    method ACTION_clean () {
        say 'Cleaning...' if $verbose;
        path('blib')->remove_tree;
        path('_build_xmake')->remove_tree;
        path('config.log')->remove;
        path('Build')->remove;
        path('_build_params')->remove;
        true;
    }

    method ACTION_test ( ) {
        die "Run `./Build build` first.\n" unless -d 'blib';
        say 'Running tests...' if $verbose;
        require Test::Harness;
        my @tests = glob('t/*.t');
        return Test::Harness::runtests(@tests) if @tests;
        true;
    }

    method _copy_libs ( ) {
        my $src_root = path('lib');
        return unless $src_root->exists;
        my $iter = $src_root->iterator( { recurse => 1 } );
        while ( my $file = $iter->() ) {
            next unless $file->is_file;

            # Skip hidden files/dirs
            my $rel = $file->relative($src_root);
            next if $rel =~ m{(^|/)\.};
            my $dest = path('blib/lib')->child($rel);
            $dest->parent->mkpath;
            $file->copy($dest) or die "Copy failed: $!";
        }
    }

    method _copy_directory ( $src, $dest ) {
        my $src_path  = path($src)->absolute;
        my $dest_path = path($dest)->absolute;
        return unless $src_path->is_dir;
        $dest_path->mkpath;
        my $iter = $src_path->iterator( { recurse => 1 } );
        while ( my $p = $iter->() ) {
            next if $p eq $src_path;    # Skip root

            # Skip if we are inside the destination directory
            # (prevents infinite loop if dest is inside src)
            if ( $p eq $dest_path || $dest_path->subsumes($p) ) {
                next;
            }
            my $rel    = $p->relative($src_path);
            my $target = $dest_path->child($rel);
            $p = $p->realpath if -l $p;
            if ( $p->is_dir ) {
                $target->mkpath;
            }
            else {
                $p->copy($target) or die "Failed to copy $p to $target: $!";
                $target->chmod( $p->stat->mode | 0600 );
            }
        }
    }
    method _run_cmd (@args) { system(@args) == 0 }

    method _cmd_exists (@cmd) {
        my ( undef, undef, $exit ) = capture { system @cmd };
        return $exit == 0;
    }

    # Query the GitHub releases API for the target release (latest unless a
    # --target_version was pinned).
    method _github_release () {
        return $gh_release if defined $gh_release;
        my $tag = $self->target_version;
        my $url = $tag ? "https://api.github.com/repos/$owner/$repo/releases/tags/$tag" : "https://api.github.com/repos/$owner/$repo/releases/latest";
        say 'Resolving Xmake release info from the GitHub API...' if $verbose;
        my $res = $self->http->get($url);
        my %rl  = map { $_ => $res->{headers}{$_} // '' } qw[x-ratelimit-remaining x-ratelimit-limit x-ratelimit-reset retry-after];
        if ( $res->{status} == 403 || $res->{status} == 429 ) {
            if ( $rl{'x-ratelimit-remaining'} eq '0' ) {
                my $when = $rl{'x-ratelimit-reset'} =~ /^\d+$/ ? '; resets at ' . scalar gmtime( $rl{'x-ratelimit-reset'} + 0 ) : '';
                die 'GitHub API rate limit exceeded (limit=' .
                    $rl{'x-ratelimit-limit'} .
                    $when . ').' .
                    " Recommend setting GITHUB_TOKEN (5,000 req/hr) to raise the 60 req/hr unauth limit\n";
            }
            my $retry = $rl{'retry-after'}       =~ /^\d+$/ ? '; retry after ' . $rl{'retry-after'} . 's'                              : '';
            my $reset = $rl{'x-ratelimit-reset'} =~ /^\d+$/ ? '; remaining resets at ' . scalar gmtime( $rl{'x-ratelimit-reset'} + 0 ) : '';
            die 'GitHub API rate limited (status ' . $res->{status} . $retry . $reset . "). Set GITHUB_TOKEN to raise the limit\n";
        }
        die 'GitHub releases API failed (' . $res->{status} . ' ' . $res->{reason} . " ) for $url\n" unless $res->{success};
        $gh_release = decode_json( $res->{content} );
        return $gh_release;
    }

    # The version tag we build against: '' -> latest release from the API.
    method _desired_version () {
        return $resolved_version if defined $resolved_version;
        $resolved_version = $self->_github_release->{tag_name};
        return $resolved_version;
    }

    # Locate a release asset by name pattern. Returns the asset hashref.
    method _find_asset ($re) {
        my $assets = $self->_github_release->{assets} // [];
        for my $a (@$assets) {
            return $a if ( $a->{name} // '' ) =~ $re;
        }
        return undef;
    }

    method _resolve_xmake ( ) {    # Check for system install
        unless ($force) {
            my $sys_path = $self->_find_system_xmake();
            if ($sys_path) {
                my $ver = $self->_get_xmake_version($sys_path);
                if ( $self->_version_cmp( $ver, $self->_desired_version ) >= 0 ) {
                    say "Found suitable system Xmake: $sys_path ($ver)";
                    return { install_type => 'system', version => $ver, bin => "$sys_path" };
                }
                say "System Xmake found ($ver) but is older than required (" . $self->_desired_version . ').';
            }
        }

        # Check build dir (idempotency)
        my $install_dir = path('share')->absolute;
        $install_dir->mkpath;
        my $bin_name = ( $^O eq 'MSWin32' ) ? 'xmake.exe' : 'xmake';
        my $blib_bin = $install_dir->child( 'bin', $bin_name );
        unless ( -x $blib_bin ) {
            my $fallback = $install_dir->child($bin_name);
            $blib_bin = $fallback if -x $fallback;
        }
        if ( -x $blib_bin ) {
            my $ver = $self->_get_xmake_version($blib_bin);
            if ( $self->_version_cmp( $ver, $self->_desired_version ) >= 0 ) {
                say "Alien-Xmake build up-to-date ($ver).";
                return $self->_generate_share_config( $blib_bin, $ver );
            }
        }

        # Check existing shared installation for upgrading
        my $existing = $self->_check_existing_share();
        if ( 0 && $existing ) {    # Disabled for now... I need to use the sharedir in a less dumb way.
            my $ex_ver = $existing->{version};
            my $ex_dir = path( $existing->{install_dir} )->absolute;
            if ( $self->_version_cmp( $ex_ver, $self->_desired_version ) >= 0 ) {
                say "Found valid private Xmake ($ex_ver) in $ex_dir";
                if ( $ex_dir->stringify ne $install_dir->stringify ) {
                    say 'Copying existing installation to share directory...';
                    $self->_copy_directory( $ex_dir, $install_dir );
                }

                # Re-locate binary in new dir
                my $bin_path = $install_dir->child( 'bin', $bin_name );
                unless ( -x $bin_path ) { $bin_path = $install_dir->child($bin_name); }
                return $self->_generate_share_config( $bin_path, $ex_ver );
            }
        }

        # Download and Install
        say 'Installing a private copy of Xmake...' if $verbose;
        $^O eq 'MSWin32' ? $self->_install_windows($install_dir) : $self->_install_unix($install_dir);

        # Verify Install
        my $bin_path = $install_dir->child( 'bin', $bin_name );
        unless ( -x $bin_path ) {
            my $fallback = $install_dir->child($bin_name);
            $bin_path = $fallback if -x $fallback;
        }
        die "Installation finished, but binary not found at $bin_path" unless -x $bin_path;
        my $ver = $self->_get_xmake_version($bin_path);
        say 'Private install successful: ' . $ver if $verbose;
        $self->_generate_share_config( $bin_path, $ver );
    }

    method _generate_share_config( $bin_path, $version ) {

        # Calculate relative path from Alien/xmake/ConfigData.pm to the binary
        # ConfigData is in lib/Alien/xmake/
        # Bin is in      lib/Alien/xmake/share/bin/
        { install_type => 'share', version => $version, bin => $bin_path->relative( path('blib/lib/Alien/Xmake')->absolute )->stringify };
    }

    method _check_existing_share() {
        eval { require Alien::Xmake::ConfigData; 1; } or return undef;
        my $type = eval { Alien::Xmake::ConfigData->config('install_type') } // '';
        return undef unless $type eq 'share';
        my $bin = eval { Alien::Xmake::ConfigData->bin };
        return undef unless $bin && -x $bin;
        my $ver      = $self->_get_xmake_version($bin);
        my $bin_path = path($bin);
        my $dir      = $bin_path->parent;
        $dir = $dir->parent if $dir->basename eq 'bin';
        { version => $ver, bin => $bin, install_dir => $dir };
    }

    method _find_system_xmake ( ) {
        my $sep       = ( $^O eq 'MSWin32' ) ? ';' : ':';
        my $own_share = path('share')->absolute;
        for my $dir ( split /$sep/, $ENV{PATH} ) {
            next unless length $dir;
            my $p = path($dir);

            # Don't treat our own share/ bundle (a future sharedir install) as a system install.
            next if $p->absolute eq $own_share;
            my $exts = ( $^O eq 'MSWin32' ) ? [qw[.exe .cmd .bat]] : [''];
            for my $ext (@$exts) {
                my $full = $p->child("xmake$ext");
                return $full if -x $full;
            }
        }
        return undef;
    }

    method _get_xmake_version ($cmd) {
        local @ENV{qw[XMAKE_PROGRAM_DIR XMAKE_PROGRAM_FILE XMAKE_ROOTDIR]};
        my ( $out, undef, $exit ) = capture { system $cmd, '--version' };
        return "v$1" if $exit == 0 && $out =~ /xmake\s+v?(\d+\.\d+\.\d+)/i;
        return 'v0.0.0';
    }

    method _version_cmp ( $v1, $v2 ) {
        require version;
        $v1 =~ s/^v//;
        $v2 =~ s/^v//;
        return version->parse($v1) <=> version->parse($v2);
    }

    method _write_config_data ($data) {
        my $dest = path('blib')->child($target_config);
        $dest->parent->mkpath;
        my $json = encode_json($data);
        $json =~ s/\\/\\\\/g;
        $json =~ s/'/\\'/g;
        my $content = sprintf <<~'PERL', $json;
        package Alien::Xmake::ConfigData {
            use v5.40;
            use JSON::PP qw[decode_json];
            use File::Spec;
            use File::Basename qw[dirname basename];
            my $DIST = 'Alien-Xmake';

            my $config = decode_json('%s');

            sub config ($s, $key //= ()) { defined $key ? $config->{$key} : $config }
            sub config_names { sort keys %%$config }

            # Cribbed from File::ShareDir
            sub bin {
                my $bin = $config->{bin};
                return unless defined $bin;
                return $bin                                     if $config->{install_type} eq 'system';
                my $abs = File::Spec->rel2abs( $bin, dirname(__FILE__) );
                return $config->{bin} = $abs if -e $abs;
                my $dist_bin = dist_dir();
                $dist_bin = File::Spec->catdir( $dist_bin, 'bin' ) unless $^O eq 'MSWin32';
                return $config->{bin} = File::Spec->catfile( $dist_bin, basename($bin) );
            }

            sub firstres ( $test, @opts ) {
                for (@opts) {
                    my $testval = $test->();
                    return $testval if $testval;
                }
                return undef;
            }

            sub dist_dir {
                my $dir = _search_inc_path( File::Spec->catdir( 'auto', 'share', 'dist', $DIST ) ) ||
                    _search_inc_path( File::Spec->catdir( 'auto', split( /-/, $DIST ) ) );
                return $dir if defined $dir;
                require Carp;
                Carp::croak("Failed to find share dir for dist '$DIST'");
            }

            sub _search_inc_path ($path) {
                my $dir = firstres(
                    sub {
                        my $d;
                        $d = File::Spec->catdir( $_, $path ) if defined _STRING($_);
                        defined $d and -d $d ? $d : 0;
                    },
                    @INC
                    ) or
                    return;
                require Carp;
                Carp::croak("Found directory '$dir', but no read permissions") unless -r $dir;
                return $dir;
            }

            sub _STRING (@parts) {
                ( defined $parts[0] and !ref $parts[0] and length( $parts[0] ) ) ? $parts[0] : undef;
            }
        };
        1;
        PERL
        $dest->spew_utf8($content);
        say "Generated $dest";
    }

    method _install_windows ($installdir) {
        my $temppath = path('_build_xmake');
        $temppath->mkpath;
        my $arch_env   = $ENV{PROCESSOR_ARCHITECTURE} // '';
        my $arch64_env = $ENV{PROCESSOR_ARCHITEW6432} // '';
        my $target     = $self->_desired_version;
        my $filename;
        if ( $arch_env eq 'ARM64' || $arch64_env eq 'ARM64' ) {    # Check for ARM64
            $filename = "xmake-bundle-$target.arm64.exe";          # ARM64 releases use the 'bundle' naming convention
        }
        elsif ( $arch_env eq 'AMD64' || $arch_env eq 'IA64' || $arch64_env eq 'AMD64' || $arch64_env eq 'IA64' ) {    # Check for x64 (AMD64/IA64)
            $filename = "xmake-$target.win64.exe";
        }
        else {                                                                                                        # Fallback to x86
            $filename = "xmake-$target.win32.exe";
        }

        # Preferred: the exact asset URL reported by the GitHub API. Fall back to
        # the canonical hardcoded URL if the release metadata is unavailable.
        my $asset   = $self->_find_asset(qr/\Q$filename\E\z/i);
        my $url     = $asset ? $asset->{browser_download_url} : "https://github.com/$owner/$repo/releases/download/$target/$filename";
        my $outfile = $temppath->child('xmake-installer.exe');
        die 'Download failed for ' . $url unless $self->_download_file( $url, $outfile );
        $self->_verify_download( $outfile, $asset );
        my $install_str = $installdir->stringify;
        $install_str =~ s{/}{\\}g;
        my $outfile_str = $outfile->stringify;
        $outfile_str =~ s{/}{\\}g;
        say "Installing to $install_str..." if $verbose;

        # /NOADMIN: Avoid UAC prompt if possible (installs to local user path if allowed)
        # /S: Silent
        # /D: Destination directory
        my $ret = system( $outfile_str, '/NOADMIN', '/S', "/D=$install_str" );
        die "Installer failed with code $ret" if $ret != 0;

        # Ensure all extracted files/templates are writable (NSIS on Windows may set read-only attributes)
        my $iter = $installdir->iterator( { recurse => 1 } );
        while ( my $p = $iter->() ) {
            next unless $p->is_file;
            $p->chmod(0666);
        }

        # Cleanup
        path('_build_xmake')->remove_tree;
    }

    method _install_unix ($installdir) {
        my $build_dir = path('_build_xmake');
        $build_dir->remove_tree;
        $build_dir->mkpath;
        my $sudo = '';
        if ( $> != 0 && $self->_cmd_exists( 'sudo', '-n', '--version' ) ) {
            $sudo = 'sudo';
        }
        unless ( $self->_test_tools() ) {

            # Do not auto-install system tools unless requested.
            if ( $ENV{ALIEN_INSTALL_SYSTEM_TOOLS} ) {
                say 'Attempting to install system tools via package manager...' if $verbose;
                if ( $self->_install_tools($sudo) ) {
                    $self->_test_tools() or $self->_raise_dep_error();
                }
                else {
                    $self->_raise_dep_error();
                }
            }
            else {
                $self->_raise_dep_error();
            }
        }
        my $version  = $self->_desired_version;
        my $filename = "xmake-$version.gz.run";

        # Preferred: the exact asset URL reported by the GitHub API. Fall back to
        # the canonical hardcoded URL if the release metadata is unavailable.
        my $asset   = $self->_find_asset(qr/\Q$filename\E\z/i);
        my $gh_url  = $asset ? $asset->{browser_download_url} : "https://github.com/$owner/$repo/releases/download/$version/$filename";
        my $outfile = $build_dir->child('xmake.run');
        say "Attempting download from $gh_url..." if $verbose;
        die 'Download failed for ' . $gh_url unless $self->_download_file( $gh_url, $outfile );
        $self->_verify_download( $outfile, $asset );
        say 'Extracting source bundle...' if $verbose;
        $self->_run_cmd( 'sh', $outfile, '--noexec', '--quiet', '--target', $build_dir ) or die 'Failed to extract .run file';
        my $cwd = cwd();
        chdir $build_dir or die 'Cannot chdir to build dir';
        say 'Building Xmake...' if $verbose;

        # DETERMINE MAKE
        # On FreeBSD/NetBSD/OpenBSD/DragonFly, 'make' is BSD make.
        # Xmake generates GNU makefiles. We MUST use gmake.
        my $make_cmd = 'make';
        if ( $^O =~ /bsd/i || $^O eq 'dragonfly' ) {
            if ( $self->_cmd_exists( 'gmake', '--version' ) ) {
                $make_cmd = 'gmake';
            }
            else {
                # This should have been caught by _test_tools, but safe guard here
                die 'gmake is required on BSD systems to build Xmake.';
            }
        }
        elsif ( $self->_cmd_exists( 'gmake', '--version' ) ) {
            $make_cmd = 'gmake';
        }
        if ( -f 'configure' ) {
            say "Configuring with make=$make_cmd..." if $verbose;
            system( './configure', "--make=$make_cmd" ) == 0 or die 'Configure failed';
            system( $make_cmd,     '-j4' ) == 0              or die 'Make failed';
            say "Installing to $installdir..." if $verbose;
            system( $make_cmd, 'install', "PREFIX=$installdir" ) == 0 or die 'Install failed';
        }
        else {
            system( $make_cmd, 'build',   '-j4' ) == 0                or die 'Make build failed';
            system( $make_cmd, 'install', "prefix=$installdir" ) == 0 or die 'Make install failed';
        }
        chdir $cwd;
    }

    method _download_file ( $url, $dest ) {
        my $dest_str = "$dest";
        try {
            require IO::Socket::SSL;
            say 'Downloading with HTTP::Tiny...' if $verbose;
            CORE::state $http //= HTTP::Tiny->new( verify_SSL => 1 );
            my $res = $http->mirror( $url, $dest_str );
            return 1                                               if $res->{success};
            say "HTTP::Tiny failed: $res->{status} $res->{reason}" if $verbose;
        }
        catch ($e) {
            say 'HTTP::Tiny error: ' . $e;
        }
        if ( $self->_cmd_exists( 'curl', '--version' ) ) {
            say 'Downloading with curl...' if $verbose;

            # -L: Follow redirects, -f: Fail on error, -o: Output
            return 1 if $self->_run_cmd( 'curl', '-L', '-f', '-o', $dest_str, $url );
            say 'curl failed.';
        }
        if ( $self->_cmd_exists( 'wget', '--version' ) ) {
            say 'Downloading with wget...' if $verbose;
            return 1                       if $self->_run_cmd( 'wget', '--quiet', '-O', $dest_str, $url );
            say 'wget failed.';
        }
        return 0;
    }

    method _verify_download ( $file, $asset ) {
        my $digest = $asset && $asset->{digest};
        unless ( defined $digest && length $digest ) {
            say 'No digest reported for this release asset; skipping verification.';
            return;
        }
        my $expected = $digest =~ /^sha256:(.+)$/ ? $1 : undef;
        unless ( defined $expected && length $expected ) {
            say "Unsupported digest scheme '$digest'; skipping verification.";
            return;
        }
        say "Verifying sha256 of $file..." if $verbose;
        my $got = path($file)->digest;    #Digest::SHA->new(256)->addfile( "$file", 'b' )->hexdigest;
        die <<~"" unless lc $got eq lc $expected;
        Checksum mismatch for $file:
            expected sha256:$expected
            got      sha256:$got

        say 'sha256 OK.' if $verbose;
        return;
    }

    method _test_tools ( ) {
        say 'Checking build tools...' if $verbose;
        my $ok = 1;

        # GNU or BSD make
        my $found_make = 0;
        if ( $self->_cmd_exists( 'gmake', '--version' ) ) {
            say ' - make: Found (gmake)' if $verbose;
            $found_make = 1;
        }
        elsif ( $self->_cmd_exists( 'make', '--version' ) ) {
            say ' - make: Found (make - likely GNU compatible)' if $verbose;
            $found_make = 1;
        }
        elsif ( $self->_cmd_exists( 'make', '-V', 'MACHINE' ) ) {
            say ' - make: Found (make - BSD)' if $verbose;

            # If we are on BSD, this is technically 'found', but we know it won't work for Xmake.
            # We must fail here to trigger the installer if we are on BSD.
            if ( $^O =~ /bsd/i || $^O eq 'dragonfly' ) {
                say '   ! Note: BSD make is not compatible with Xmake build (needs gmake).' if $verbose;
            }
            else {
                $found_make = 1;    # On non-BSD systems, maybe they have a different make setup.
            }
        }

        # STRICT CHECK for BSDs
        if ( $^O =~ /bsd/i || $^O eq 'dragonfly' ) {
            unless ( $self->_cmd_exists( 'gmake', '--version' ) ) {
                say ' - make: Missing gmake (Required on FreeBSD/BSD for Xmake build)' if $verbose;
                $found_make = 0;
                $ok         = 0;
            }
            else {
                $found_make = 1;
            }
        }
        unless ($found_make) {
            say ' - make: Missing' if $verbose;
            $ok = 0;
        }

        # Compiler
        my $found_cc  = 0;
        my $prog      = "#include <stdio.h>\nint main(){return 0;}";
        my @compilers = ( [qw[cc -xc - -o /dev/null]], [qw[gcc -xc - -o /dev/null]], [qw[clang -xc - -o /dev/null]] );
        for my $cmd_ref (@compilers) {
            my $name = $cmd_ref->[0];
            my $err  = gensym;
            my $pid  = open3( my $in, my $out, $err, @$cmd_ref );
            if ($pid) {
                print $in $prog;
                close $in;
                waitpid( $pid, 0 );
                if ( $? == 0 ) {
                    say " - compiler: Found ($name)" if $verbose;
                    $found_cc = 1;
                    last;
                }
            }
        }
        unless ($found_cc) {
            say ' - compiler: Missing (checked cc, gcc, clang)' if $verbose;
            $ok = 0;
        }
        return $ok;
    }

    method _install_tools ($sudo) {
        my @installers = (
            [ 'apt --version', 'apt install -y build-essential libreadline-dev' ],
            [ 'dnf --version', 'dnf install -y readline-devel bzip2 @development-tools' ],
            [ 'yum --version', qq[yum install -y readline-devel bzip2 && $sudo yum groupinstall -y 'Development Tools'] ],
            [   'zypper --version',
                qq[zypper --non-interactive install readline-devel && $sudo zypper --non-interactive install -t pattern devel_C_C++]
            ],
            [ 'pacman -V',              'pacman -S --noconfirm --needed base-devel ncurses readline' ],
            [ 'emerge -V',              'emerge -atv dev-vcs/git' ],
            [ 'pkg list-installed',     'pkg install -y gmake' ],
            [ 'nix-env --version',      'nix-env -i gcc readline ncurses' ],
            [ 'apk --version',          'apk add gcc g++ make readline-dev ncurses-dev libc-dev linux-headers' ],
            [ 'xbps-install --version', 'xbps-install -Sy base-devel' ]
        );
        for my $pair (@installers) {
            my ( $check, $install ) = @$pair;
            my @check_args = split /\s+/, $check;
            if ( $self->_cmd_exists(@check_args) ) {
                say 'Detected package manager via: ' . $check if $verbose;
                say 'Attempting to install dependencies...'   if $verbose;
                my @install_cmd = ( '/bin/sh', '-c', $sudo . ' ' . $install );
                my ( undef, undef, $exit ) = capture { system @install_cmd };
                return $exit == 0;
            }
        }
        return 0;
    }
    method _raise_dep_error () { die <<~'MSG' }
    Dependencies Installation Failed or Skipped.

    We could not find the necessary tools (make, compiler) to build Xmake from source.

    You have three options:

    1. Install Xmake manually (Recommended if you lack build tools):
       See: https://xmake.io/guide/quick-start.html#installation
       Alien::Xmake will detect and use the system installation.

    2. Install build tools manually:
       * build-essential (make, gcc/clang, etc)
       * libreadline-dev / readline-devel

    3. Allow this builder to try installing system tools:
       Set ENV ALIEN_INSTALL_SYSTEM_TOOLS=1
    MSG
    method write_file( $filename, $content ) { path($filename)->spew_raw($content) }

    method Build(@args) {
        my $method = $self->can( 'ACTION_' . $action );
        $method // die "No such action '$action'\n";
        exit !$method->($self);
    }
    };
#
1;
