use v5.40;
use experimental 'class';
use builtin 'is_bool';
no warnings 'experimental::builtin';
#
class Alien::Xmake v1.0.0 {
    use File::Spec;
    use File::Basename qw[dirname];
    use File::Temp     qw[tempdir];
    use JSON::PP       qw[decode_json];
    use Capture::Tiny  qw[capture];
    #
    field $windows = $^O eq 'MSWin32';
    field $verbose : param //= 0;
    field $yes     : param //= 0;
    field $confirm : param //= ();
    field $file    : param //= ();
    field $config  : param //= sub {
        my $conf;
        try {
            require Alien::Xmake::ConfigData;    # Try to load the ConfigData module generated during install
            $conf = { map { $_ => Alien::Xmake::ConfigData->config($_) } Alien::Xmake::ConfigData->config_names };

            # The raw 'bin' value in config is a relative path string.
            # We must call the generated helper method to get the absolute path.
            $conf->{bin} = Alien::Xmake::ConfigData->bin if Alien::Xmake::ConfigData->can('bin');
        }
        catch ($e) {    # Fallback / manual install detection
            $conf = { install_type => 'system' };
        }
        return $conf;
        }
        ->();

    # We don't really need $dir detection if ConfigData is working, but we keep it for fallback
    # scenarios (running from blib/lib, etc).
    field $dir;
    ADJUST {
        if ( !$config->{bin} || !-e $config->{bin} ) {
            my @parts = qw[auto share dist Alien-Xmake];
            push @parts, 'bin' unless $windows;

            # Look through @INC for the share directory
            foreach my $inc (@INC) {
                my $d = File::Spec->catdir( $inc, @parts );
                if ( -d $d ) {
                    $dir = $d;
                    last;
                }
            }
        }
    }
    method blah ($msg) { return unless $verbose; say $msg; }

    # Pointless stubs required by some Alien::Base consumers
    method cflags ()       {''}
    method libs ()         {''}
    method dynamic_libs () { }

    # Valuable
    method install_type () { $config->{install_type} }

    method bin_dir () {    # Return the directory of the raw path (unquoted)
        my $exe = $self->_resolve_path;
        return dirname($exe);
    }

    # Return the bare executable path. NEVER embed quote characters here: every
    # LIST-form spawn (`system @cmd`, Capture::Tiny around it) treats the path as
    # the literal image name, so quotes make CreateProcess fail even for paths
    # with spaces. Only single-string/`qx` call sites quote, and they do it
    # themselves (see _getver_build and pkg_config).
    method exe () { $self->_resolve_path }

    method xrepo () {    # xrepo is usually in the same folder as Xmake; bare path, see exe()
        my $exe_path   = $self->_resolve_path;
        my $parent     = dirname($exe_path);
        my $xrepo_name = 'xrepo' . ( $windows ? '.bat' : '' );

        # Check sibling
        my $try = File::Spec->catfile( $parent, $xrepo_name );
        return $try if -e $try;

        # Fallback to config path calculation if the sibling check failed
        if ( $config->{bin} ) {
            my $conf_parent = dirname( $config->{bin} );
            my $target      = File::Spec->catfile( $conf_parent, $xrepo_name );
            return $target;
        }

        # Last resort: return bare command
        return $xrepo_name;
    }

    method pkg_config ($package) {
        my $xrepo = $self->xrepo;
        system( $xrepo, 'install', '-y', $package ) == 0 || die "Alien::Xmake: Could not install package '$package'\n";
        my ( $cflags, undef, undef ) = capture_cmd( $xrepo, 'fetch', '--cflags', $package );
        chomp $cflags;
        my ( $libs, undef, undef ) = capture_cmd( $xrepo, 'fetch', '--ldflags', $package );
        chomp $libs;
        return { cflags => $cflags, libs => $libs };
    }

    sub capture_cmd (@cmd) {
        return capture { system @cmd }
    }
    method version ()             { $self->install_type eq 'system' ? $self->_getver : $config->{version} }
    method buildid ()             { $self->_getbuild }
    method config ( $key //= () ) { defined $key ? $config->{$key} : $config }

    sub alien_helper () {
        { xmake => sub { __PACKAGE__->new->exe }, xrepo => sub { __PACKAGE__->new->xrepo } }
    }

    # Task plumbing
    method _cmd ( $action, @args ) {

        # Inject auto-confirm flags so captured/streamed installs never hang on a prompt.
        unshift @args, '--confirm=' . $confirm if defined $confirm && length $confirm;
        unshift @args, '-y'                    if $yes             && !( defined $confirm && length $confirm );

        # Inject the build file so every action reads the given xmake.lua rather than one in the cwd.
        unshift @args, '-F', $file if defined $file && length $file;
        my @cmd = ( $self->exe, $action, @args );
        $self->blah("Running: @cmd");
        @cmd;
    }

    # Stream a task to the terminal (builds, runs, installs ...) and return success.
    method _run ( $action, @args ) {
        my @cmd = $self->_cmd( $action, @args );
        return system(@cmd) == 0;
    }

    # Run a task capturing output; returns ($out, $err, $exit).
    method _capture ( $action, @args ) {
        my @cmd = $self->_cmd( $action, @args );
        return capture { system @cmd };
    }

    # Slurp the extra trailing arguments out of %opts.
    method _extra_args ($opts) {
        my @args;
        push @args, @{ $opts->{targets} // [] };
        push @args, @{ $opts->{args}    // [] };
        @args;
    }

    # Format a scalar or arrayref as a comma/separator joined flag value.
    method _join ( $value, $sep //= ',' ) {
        return () unless defined $value;
        ref $value eq 'ARRAY' ? join( $sep, map { _bool_str($_) } @$value ) : _bool_str($value);
    }

    sub _bool_str ($value) {
        return $value ? 'true' : 'false' if is_bool($value);
        return $value;
    }

    # Generic escape hatch: run any task/plugin by name.
    method task ( $name, %opts ) {
        my @args = $self->_extra_args( \%opts );
        $self->_run( $name, @args );
    }

    # Actions
    method build ( $target //= (), %opts ) {
        my @args;
        push @args, '-r'        if $opts{rebuild};
        push @args, '-a'        if $opts{all};
        push @args, '--shallow' if $opts{shallow};
        push @args, '-g', $opts{group} if $opts{group};
        push @args, '--dry-run' if $opts{dry_run};
        push @args, '-j', $opts{jobs} if $opts{jobs};
        push @args, '--linkjobs=' . $opts{linkjobs}                if $opts{linkjobs};
        push @args, '--linkonly'                                   if $opts{linkonly};
        push @args, '--files=' . $self->_join( $opts{files}, ';' ) if $opts{files};
        push @args, $target                                        if defined $target && length $target;
        push @args, $self->_extra_args( \%opts );
        $self->_run( 'build', @args );
    }

    method clean ( $target //= (), %opts ) {
        my @args;
        push @args, '-a' if $opts{all};
        push @args, '-g', $opts{group} if $opts{group};
        push @args, $target if defined $target && length $target;
        push @args, $self->_extra_args( \%opts );
        $self->_run( 'clean', @args );
    }

    method create ( $target //= (), %opts ) {
        my @args;
        push @args, '-f'     if $opts{force};
        push @args, '--list' if $opts{list};
        push @args, '-l', $opts{language} if $opts{language};
        push @args, '-t', $opts{template} if $opts{template};
        push @args, '-P', $opts{project}  if $opts{project};
        push @args, $target if defined $target && length $target;
        push @args, $self->_extra_args( \%opts );
        $self->_run( 'create', @args );
    }

    method configure (%opts) {
        my @args = $self->_config_args( \%opts );
        push @args, '-c'                        if $opts{clean};
        push @args, '--check'                   if $opts{check};
        push @args, '--menu'                    if $opts{menu};
        push @args, '--export=' . $opts{export} if $opts{export};
        push @args, '--import=' . $opts{import} if $opts{import};
        push @args, '-o', $opts{builddir} if $opts{builddir};
        push @args, $self->_extra_args( \%opts );
        $self->_run( 'config', @args );
    }

    method global (%opts) {
        my @args;
        push @args, '-c'                                                             if $opts{clean};
        push @args, '--check'                                                        if $opts{check};
        push @args, '--menu'                                                         if $opts{menu};
        push @args, '--theme=' . $opts{theme}                                        if $opts{theme};
        push @args, '--debugger=' . $opts{debugger}                                  if $opts{debugger};
        push @args, '--ccache=' . $opts{ccache}                                      if defined $opts{ccache};
        push @args, '--cachedir=' . $opts{cachedir}                                  if $opts{cachedir};
        push @args, '--policies=' . $opts{policies}                                  if $opts{policies};
        push @args, '--network=' . $opts{network}                                    if $opts{network};
        push @args, '--insecure-ssl'                                                 if $opts{insecure_ssl};
        push @args, '--proxy=' . $opts{proxy}                                        if $opts{proxy};
        push @args, '--proxy_hosts=' . $opts{proxy_hosts}                            if $opts{proxy_hosts};
        push @args, '--proxy_pac=' . $opts{proxy_pac}                                if $opts{proxy_pac};
        push @args, '--pkg_searchdirs=' . $self->_join( $opts{pkg_searchdirs}, ';' ) if $opts{pkg_searchdirs};
        push @args, '--pkg_cachedir=' . $opts{pkg_cachedir}                          if $opts{pkg_cachedir};
        push @args, '--pkg_installdir=' . $opts{pkg_installdir}                      if $opts{pkg_installdir};
        push @args, $self->_global_config_args( \%opts );
        push @args, $self->_extra_args( \%opts );
        $self->_run( 'global', @args );
    }

    method install ( $target //= (), %opts ) {
        my @args;
        push @args, '-o', $opts{installdir} if $opts{installdir};
        push @args, '--bindir=' . $opts{bindir}         if $opts{bindir};
        push @args, '--libdir=' . $opts{libdir}         if $opts{libdir};
        push @args, '--includedir=' . $opts{includedir} if $opts{includedir};
        push @args, '-g', $opts{group} if $opts{group};
        push @args, '-a'                              if $opts{all};
        push @args, '--binaries=' . $opts{binaries}   if defined $opts{binaries};
        push @args, '--headers=' . $opts{headers}     if defined $opts{headers};
        push @args, '--libraries=' . $opts{libraries} if defined $opts{libraries};
        push @args, '--packages=' . $opts{packages}   if defined $opts{packages};
        push @args, '--admin'                         if $opts{admin};
        push @args, $target                           if defined $target && length $target;
        push @args, $self->_extra_args( \%opts );
        $self->_run( 'install', @args );
    }

    method uninstall ( $target //= (), %opts ) {
        my @args;
        push @args, '--installdir=' . $opts{installdir} if $opts{installdir};
        push @args, '--bindir=' . $opts{bindir}         if $opts{bindir};
        push @args, '--libdir=' . $opts{libdir}         if $opts{libdir};
        push @args, '--includedir=' . $opts{includedir} if $opts{includedir};
        push @args, '-g', $opts{group} if $opts{group};
        push @args, '--admin' if $opts{admin};
        push @args, $target   if defined $target && length $target;
        push @args, $self->_extra_args( \%opts );
        $self->_run( 'uninstall', @args );
    }

    method package ( $target //= (), %opts ) {
        my @args;
        push @args, '-o', $opts{outputdir} if $opts{outputdir};
        push @args, '-a' if $opts{all};
        push @args, '-f', $opts{format} if $opts{format};
        push @args, '--homepage=' . $opts{homepage}       if $opts{homepage};
        push @args, '--description=' . $opts{description} if $opts{description};
        push @args, '--url=' . $opts{url}                 if $opts{url};
        push @args, '--version=' . $opts{version}         if defined $opts{version};
        push @args, '--shasum=' . $opts{shasum}           if $opts{shasum};
        push @args, $target                               if defined $target && length $target;
        push @args, $self->_extra_args( \%opts );
        $self->_run( 'package', @args );
    }

    method pack ( $package //= (), %opts ) {
        my @args;
        push @args, '-o', $opts{outputdir} if $opts{outputdir};
        push @args, '--basename=' . $opts{basename}   if $opts{basename};
        push @args, '--autobuild=' . $opts{autobuild} if defined $opts{autobuild};
        push @args, '-j', $opts{jobs}                    if $opts{jobs};
        push @args, '-f', $self->_join( $opts{formats} ) if $opts{formats};
        push @args, $package if defined $package && length $package;
        push @args, $self->_extra_args( \%opts );
        $self->_run( 'pack', @args );
    }

    method require ( $pkg //= (), %opts ) {
        my @args;
        push @args, '-c'                                                  if $opts{clean};
        push @args, '--clean_modes=' . $self->_join( $opts{clean_modes} ) if $opts{clean_modes};
        push @args, '-f'                                                  if $opts{force};
        push @args, '-j', $opts{jobs} if $opts{jobs};
        push @args, '--linkjobs=' . $opts{linkjobs} if $opts{linkjobs};
        push @args, '--shallow'                     if $opts{shallow};
        push @args, '--build'                       if $opts{build};
        push @args, '--addon'                       if $opts{addon};
        push @args, '-l'                            if $opts{list};
        push @args, '--scan'                        if $opts{scan};
        push @args, '--info'                        if $opts{info};
        push @args, '--depgraph'                    if $opts{depgraph};
        push @args, '--format=' . $opts{format}     if $opts{format};
        push @args, '--check'                       if $opts{check};
        push @args, $pkg                            if defined $pkg && length $pkg;
        push @args, $self->_extra_args( \%opts );

        # Query modes: return the output instead of streaming it.
        return $self->_out( 'require', \%opts, @args ) if $opts{list} || $opts{scan} || $opts{info} || $opts{depgraph};
        $self->_run( 'require', @args );
    }

    method run ( $target //= (), %opts ) {
        my @args;
        push @args, '-d' if $opts{debug};
        push @args, '-a' if $opts{all};
        push @args, '-g', $opts{group}   if $opts{group};
        push @args, '-w', $opts{workdir} if $opts{workdir};
        push @args, '-j', $opts{jobs}    if $opts{jobs};
        push @args, '--detach' if $opts{detach};
        push @args, $target    if defined $target && length $target;
        push @args, $self->_extra_args( \%opts );
        $self->_run( 'run', @args );
    }

    method test ( $test //= (), %opts ) {
        my @args;
        push @args, '-g', $opts{group}   if $opts{group};
        push @args, '-w', $opts{workdir} if $opts{workdir};
        push @args, '-j', $opts{jobs}    if $opts{jobs};
        push @args, '-r'  if $opts{rebuild};
        push @args, $test if defined $test && length $test;
        push @args, $self->_extra_args( \%opts );
        $self->_run( 'test', @args );
    }

    method update ( $version //= (), %opts ) {
        my @args;
        push @args, '--uninstall' if $opts{uninstall};
        push @args, '-s'          if $opts{scriptonly};
        push @args, '--integrate' if $opts{integrate};
        push @args, '-f'          if $opts{force};
        push @args, $version      if defined $version && length $version;
        push @args, $self->_extra_args( \%opts );
        $self->_run( 'update', @args );
    }

    method service (%opts) {
        my @args;
        push @args, '--start'                     if $opts{start};
        push @args, '--restart'                   if $opts{restart};
        push @args, '--stop'                      if $opts{stop};
        push @args, '--connect'                   if $opts{connect};
        push @args, '--reconnect'                 if $opts{reconnect};
        push @args, '--disconnect'                if $opts{disconnect};
        push @args, '--remote'                    if $opts{remote};
        push @args, '--distcc'                    if $opts{distcc};
        push @args, '--ccache'                    if $opts{ccache};
        push @args, '--sync'                      if $opts{sync};
        push @args, '--session=' . $opts{session} if $opts{session};
        push @args, '--host=' . $opts{host}       if $opts{host};
        push @args, $self->_extra_args( \%opts );
        $self->_run( 'service', @args );
    }

    method addon ( $addon //= (), %opts ) {
        my @args;
        push @args, '-i'    if $opts{install};
        push @args, '-r'    if $opts{remove};
        push @args, '-s'    if $opts{search};
        push @args, '-l'    if $opts{list};
        push @args, '-u'    if $opts{upgrade};
        push @args, '--all' if $opts{all};
        push @args, '-f'    if $opts{force};
        push @args, $addon  if defined $addon && length $addon;
        push @args, $self->_extra_args( \%opts );
        return $self->_out( 'addon', \%opts, @args ) if $opts{search} || $opts{list};
        $self->_run( 'addon', @args );
    }

    # Plugins
    method check ( $checker //= (), %opts ) {
        my @args;
        push @args, '-l'                    if $opts{list};
        push @args, '--info=' . $opts{info} if $opts{info};
        push @args, $checker                if defined $checker && length $checker;
        push @args, $self->_extra_args( \%opts );
        return $self->_out( 'check', \%opts, @args ) if $opts{list} || $opts{info};
        $self->_run( 'check', @args );
    }

    method doxygen ( $srcdir //= (), %opts ) {
        my @args;
        push @args, '-o', $opts{outputdir} if $opts{outputdir};
        push @args, $srcdir if defined $srcdir && length $srcdir;
        push @args, $self->_extra_args( \%opts );
        $self->_run( 'doxygen', @args );
    }

    method format ( $target //= (), %opts ) {
        my @args;
        push @args, '-s', $opts{style} if $opts{style};
        push @args, '--create' if $opts{create};
        push @args, '-n'       if $opts{dry_run};
        push @args, '-e'       if $opts{error};
        push @args, '-j', $opts{jobs} if $opts{jobs};
        push @args, '-a' if $opts{all};
        push @args, '-g', $opts{group}                      if $opts{group};
        push @args, '-f', $self->_join( $opts{files}, ';' ) if $opts{files};
        push @args, $target if defined $target && length $target;
        push @args, $self->_extra_args( \%opts );
        $self->_run( 'format', @args );
    }

    method lua ( $script //= (), %opts ) {
        my @args;
        push @args, '-l' if $opts{list};
        push @args, '-d', $opts{deserialize} if $opts{deserialize};
        if ( defined $script && length $script ) {
            if ( $opts{command} || $opts{stdin} || !-f $script ) {
                push @args, $self->_lua_script_file($script);
            }
            else {
                push @args, $script;    # an existing script file on disk
            }
        }
        push @args, $self->_extra_args( \%opts );
        return $self->_out( 'lua', \%opts, @args ) if $opts{list};
        $self->_run( 'lua', @args );
    }

    # Write inline Lua to a temporary .lua file and return its path. The file lives in a temp dir
    # created per call and is removed once the argument list is no longer needed.
    method _lua_script_file ($code) {
        my $dir  = tempdir( 'alien-xmake-lua-XXXXXX', CLEANUP => 1 );
        my $file = File::Spec->catfile( $dir, 'script.lua' );
        open my $fh, '>', $file or die "Alien::Xmake: cannot write $file: $!";
        print {$fh} $code;
        close $fh or die "Alien::Xmake: cannot close $file: $!";
        return $file;
    }

    method macro ( $name //= (), %opts ) {
        my @args;
        push @args, '-b'                        if $opts{begin};
        push @args, '-e'                        if $opts{end};
        push @args, '--show'                    if $opts{show};
        push @args, '-l'                        if $opts{list};
        push @args, '-d'                        if $opts{delete};
        push @args, '-c'                        if $opts{clear};
        push @args, '--import=' . $opts{import} if $opts{import};
        push @args, '--export=' . $opts{export} if $opts{export};
        push @args, $name                       if defined $name && length $name;
        push @args, $self->_extra_args( \%opts );
        return $self->_out( 'macro', \%opts, @args ) if $opts{list} || $opts{show};
        $self->_run( 'macro', @args );
    }

    method project (%opts) {
        my @args;
        push @args, '-k', $opts{kind}                  if $opts{kind};
        push @args, '-m', $self->_join( $opts{modes} ) if $opts{modes};
        push @args, '-a', $self->_join( $opts{archs} ) if $opts{archs};
        push @args, '-t', $opts{target}                if $opts{target};
        push @args, '--lsp=' . $opts{lsp} if $opts{lsp};
        push @args, $self->_extra_args( \%opts );
        $self->_run( 'project', @args );
    }

    method repo ( $name //= (), %opts ) {
        my @args;
        push @args, '-a'          if $opts{add};
        push @args, '-r'          if $opts{remove};
        push @args, '-u'          if $opts{update};
        push @args, '-c'          if $opts{clear};
        push @args, '-l'          if $opts{list};
        push @args, '-g'          if $opts{global};
        push @args, $name         if defined $name && length $name;
        push @args, $opts{url}    if $opts{url};
        push @args, $opts{branch} if $opts{branch};
        push @args, $self->_extra_args( \%opts );
        return $self->_out( 'repo', \%opts, @args ) if $opts{list};
        $self->_run( 'repo', @args );
    }

    method show ( $list //= (), %opts ) {
        my @args;
        push @args, '-l', $list        if defined $list && length $list;
        push @args, '-g', $opts{group} if $opts{group};
        push @args, '--pretty'                  if $opts{pretty};
        push @args, '--format=' . $opts{format} if $opts{format};
        push @args, '--target=' . $opts{target} if $opts{target};
        push @args, '--info=' . $opts{info}     if $opts{info};
        push @args, $self->_extra_args( \%opts );
        my ( $out, $err, $exit ) = $self->_capture( 'show', @args );
        return () if $exit != 0;
        $out =~ s/\e\[[0-9;]*m//g;
        $out =~ s/\[0m//g;
        return decode_json($out) if ( $opts{format} // '' ) eq 'json' && $out =~ /[\{\[]/;
        return grep {/\S/} split( /\s+/, $out ) if defined $list && length $list;
        return split /\n/, $out;
    }

    # xmake show -t <target> rich target info (JSON by default; pass format/pretty/plain to tune).
    method target_info ( $name, %opts ) {
        my $plain = $opts{plain} || ( ( $opts{format} // '' ) eq 'plain' );
        my @args;
        push @args, '-t', $name if defined $name && length $name;
        push @args, '--format=json' unless $plain;
        push @args, '--pretty'                if $opts{pretty} && $plain;
        push @args, '--group=' . $opts{group} if $opts{group};
        push @args, $self->_extra_args( \%opts );
        my ( $out, $err, $exit ) = $self->_capture( 'show', @args );
        return () if $exit != 0;
        $out =~ s/\e\[[0-9;]*m//g;
        return $out if $plain;
        my $data = eval { decode_json($out) };
        return ()         if !$data;
        return $data      if ref $data eq 'HASH';
        return $data->[0] if ref $data eq 'ARRAY' && ref( $data->[0] ) eq 'HASH';
        return $data;
    }

    # Whatever Lua the user runs, xmake's lua runner always appends a stray, empty "{ }" chunk
    # (even on success), so we can't blindly decode_json the whole line. Strip that artifact plus
    # surrounding whitespace, then decode whatever single JSON value remains.
    method _first_json ($out) {
        $out =~ s/\e\[[0-9;]*m//g;
        $out =~ s/\s*\{\s*\}\s*$//;    # drop xmake's trailing empty-object artifact
        $out =~ s/^\s+//;
        $out =~ s/\s+$//;
        return undef unless length $out;
        my $json = eval { decode_json($out) };
        return undef if !$json;
        return $json;
    }

    # Run inline Lua that emits (or returns) one JSON value and return the decoded structure.
    method lua_json ( $code //= '', %opts ) {
        my $src = length( $opts{code} // '' ) ? $opts{code} : $code;
        if ( $opts{return} ) {
            $src =~ s/^\s*return\b//;    # allow "return <expr>" as well as a bare <expr>
            $src = qq{local j = import("core.base.json")\nlocal v = ($src)\nprint(j.encode(v))};
        }
        my $file = $self->_lua_script_file($src);
        my ( $out, $err, $exit ) = $self->_capture( 'lua', $file );
        my $data = $self->_first_json($out);
        return () if !defined $data;
        return $data;
    }

    method watch (%opts) {
        my @args;
        push @args, '-c', $opts{commands}                       if $opts{commands};
        push @args, '-s', $opts{script}                         if $opts{script};
        push @args, '-d', $self->_join( $opts{watchdirs}, ';' ) if $opts{watchdirs};
        push @args, '-p', $self->_join( $opts{plaindirs}, ';' ) if $opts{plaindirs};
        push @args, '-r' if $opts{run};
        push @args, '-t', $opts{target} if $opts{target};
        push @args, '--' if $opts{argv};
        push @args, @{ $opts{argv} // [] };
        push @args, $self->_extra_args( \%opts );
        $self->_run( 'watch', @args );
    }

    # Run a task and return its captured output (string or decoded JSON for --format=json).
    method _out ( $action, $opts, @args ) {
        my ( $out, $err, $exit ) = $self->_capture( $action, @args );
        return ()                if $exit != 0;
        return decode_json($out) if ( $opts->{format} // '' ) eq 'json' && $out =~ /[\{\[]/;
        $out;
    }

    # config-style keys that `xmake global` actually accepts.
    method _global_config_args ($opts) {
        my @args;
        for my $key (qw[android_sdk build_toolver cuda emsdk mingw ndk ndk_sdkver qt qt_host vcpkg vs wdk]) {
            push @args, "--$key=" . $self->_join( $opts->{$key}, ';' ) if defined $opts->{$key};
        }
        push @args, "--$_=$opts->{set}{$_}" for sort keys %{ $opts->{set} // {} };
        @args;
    }

    # Translate the shared xmake `f`-style option names into command line switches.
    method _config_args ($opts) {
        my @args;
        push @args, '-p', $opts->{plat} if $opts->{plat};
        push @args, '-a', $opts->{arch} if $opts->{arch};
        push @args, '-m', $opts->{mode} if $opts->{mode};
        push @args, '-k', $opts->{kind} if $opts->{kind};
        for my $key (
            qw[toolchain toolchain_host cross target_os bin sdk runtimes ndk ndk_sdkver android_sdk
            build_toolver ndk_stdcxx cuda cuda_sdkver qt qt_host qt_sdkver vcpkg mingw emsdk vs vs_toolset
            vs_sdkver vs_runtime wdk wdk_sdkver wdk_winver debugger ccache ccachedir trybuild tryconfigs
            require pkg_searchdirs pkg_cachedir pkg_installdir rc rcld rcar rcsh fc fcld fcsh linkdirs links
            syslinks includedirs ]
        ) {
            push @args, "--$key=" . $self->_join( $opts->{$key}, ';' ) if defined $opts->{$key};
        }
        push @args, "--$_=$opts->{set}{$_}" for sort keys %{ $opts->{set} // {} };
        @args;
    }

    # Introspection helpers
    method _getver() {
        my ( $ver, undef ) = $self->_getver_build;
        "v$ver";
    }

    method _getbuild() {
        my ( undef, $build ) = $self->_getver_build;
        $build;
    }

    method _getver_build() {
        my $cmd = $self->exe;
        state $out //= do {
            my ( $stdout, undef, $exit ) = capture_cmd( $cmd, '--version' );
            $exit == 0 ? $stdout : '';
        };
        return ( $1, $2 ) if $out =~ /xmake\s+v?(\d+\.\d+\.\d+)(?:\+(.+),)?/i;
        ( '0.0.0', () );
    }

    # Resolve absolute path without quotes
    method _resolve_path () {
        my $bin = $config->{bin};

        # If ConfigData failed or we are in a fallback state:
        $bin = File::Spec->catfile( $dir, 'xmake' . ( $windows ? '.exe' : '' ) ) if !$bin && $dir;
        $bin //= 'xmake';

        # Ensure we return a stringified absolute path safe for system()
        File::Spec->rel2abs($bin);
    }

    # Quote path if on Windows and spaces exist
    method _quote_path ($path) {
        return qq{"$path"} if $windows && $path =~ /\s/;
        $path;
    }

    # Safely quote arguments for Windows cmd.exe
    method _escape_args (@args) { return @args }
};
#
1;
__END__
Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms found in
the Artistic License 2. Other copyrights, terms, and conditions may apply to data transmitted
through this module.
