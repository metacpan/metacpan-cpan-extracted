# Based on Module::Build::Tiny which is copyright (c) 2011 by Leon Timmermans, David Golden.
# Module::Build::Tiny is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
use v5.38;
use feature 'class';
no warnings 'experimental::class', 'experimental::builtin';
$|++;
class    #
    Alien::SDL3_image::Builder {
    use CPAN::Meta;
    use ExtUtils::Install qw[pm_to_blib install];
    use ExtUtils::InstallPaths 0.002;
    use File::Basename        qw[basename dirname];
    use File::Find            ();
    use File::Path            qw[mkpath rmtree];
    use File::Spec::Functions qw[catfile catdir rel2abs abs2rel splitdir curdir];
    use JSON::PP 2            qw[encode_json decode_json];
    use Config;
    use Carp qw[croak];
    use Env  qw[@PATH];
    use HTTP::Tiny;

    # Not in CORE
    use Path::Tiny qw[cwd path tempdir];
    use ExtUtils::Helpers 0.028 qw[make_executable split_like_shell detildefy];
    use Devel::CheckBin;
    #
    field $action : param //= 'build';
    field $meta = CPAN::Meta->load_file('META.json');

    # https://wiki.libsdl.org/SDL3/Installation
    #~ apt-get install libsdl2-dev libsdl2-image-dev libsdl2-mixer-dev libsdl2-ttf-dev
    #~ pacman -S sdl2 sdl2_image sdl2_mixer sdl2_ttf
    #~ dnf install SDL2-devel SDL2_image-devel SDL2_mixer-devel SDL2_ttf-devel
    #~ https://github.com/libsdl-org/setup-sdl/issues/20
    # TODO: Write a GH action to test with libs preinstalled
    field $version  : param //= '3.2.4';
    field $prebuilt : param //= 1;
    field $archive  : param //= sprintf 'https://github.com/libsdl-org/SDL_image/releases/download/release-%s/SDL3_image-' . (
        $^O eq 'MSWin32' ?
            !$prebuilt ?
                '%s.zip' :
                ( $Config{cc} =~ m[gcc]i ? 'devel-%s-mingw.zip' : 'devel-%s-VC.zip' ) :

            #~ $Config{archname} =~ /x64/ ? 'x86_64-w64-mingw32' : 'i686-w64-mingw32'
            #~ $^O eq 'darwin' ? '%s.dmg' :
            '%s.tar.gz'
        ),
        $version, $version;
    field $http;
    field %config;
    #
    # Params to Build script
    field $install_base  : param //= '';
    field $installdirs   : param //= '';
    field $uninst        : param //= 0;    # Make more sense to have a ./Build uninstall command but...
    field $install_paths : param //= ExtUtils::InstallPaths->new( dist_name => $meta->name );
    field $verbose       : param //= 0;
    field $dry_run       : param //= 0;
    field $pureperl      : param //= 0;
    field $jobs          : param //= 1;
    field $destdir       : param //= '';
    field $prefix        : param //= '';
    field $cwd = cwd()->absolute;
    #
    #
    ADJUST {
        -e 'META.json' or die "No META information provided\n";
    }
    method write_file( $filename, $content ) { path($filename)->spew_raw($content) or die "Could not open $filename: $!\n" }
    method read_file ($filename)             { path($filename)->slurp_utf8         or die "Could not open $filename: $!\n" }

    method step_build() {
        $self->step_build_libs;
        for my $pl_file ( find( qr/\.PL$/, 'lib' ) ) {
            ( my $pm = $pl_file ) =~ s/\.PL$//;
            system $^X, $pl_file->stringify, $pm and die "$pl_file returned $?\n";
        }
        my %modules       = map { $_ => catfile( 'blib', $_ ) } find( qr/\.pm$/,  'lib' );
        my %docs          = map { $_ => catfile( 'blib', $_ ) } find( qr/\.pod$/, 'lib' );
        my %scripts       = map { $_ => catfile( 'blib', $_ ) } find( qr/(?:)/,   'script' );
        my %sdocs         = map { $_ => delete $scripts{$_} } grep {/.pod$/} keys %scripts;
        my %dist_shared   = map { $_ => catfile( qw[blib lib auto share dist],   $meta->name, abs2rel( $_, 'share' ) ) } find( qr/(?:)/, 'share' );
        my %module_shared = map { $_ => catfile( qw[blib lib auto share module], abs2rel( $_, 'module-share' ) ) } find( qr/(?:)/, 'module-share' );
        pm_to_blib( { %modules, %docs, %scripts, %dist_shared, %module_shared }, catdir(qw[blib lib auto]) );
        make_executable($_) for values %scripts;
        mkpath( catdir(qw[blib arch]), $verbose );
        0;
    }
    method step_clean() { rmtree( $_, $verbose ) for qw[blib temp]; 0 }

    method step_install() {
        $self->step_build() unless -d 'blib';
        install(
            [   from_to           => $install_paths->install_map,
                verbose           => $verbose,
                dry_run           => $dry_run,
                uninstall_shadows => $uninst,
                skip              => undef,
                always_copy       => 1
            ]
        );
        0;
    }
    method step_realclean () { rmtree( $_, $verbose ) for qw[blib temp Build _build_params MYMETA.yml MYMETA.json]; 0 }

    method step_test() {
        $self->step_build() unless -d 'blib';
        require TAP::Harness::Env;
        my %test_args = (
            ( verbosity => $verbose ),
            ( jobs  => $jobs ),
            ( color => -t STDOUT ),
            lib => [ map { rel2abs( catdir( 'blib', $_ ) ) } qw[arch lib] ],
        );
        TAP::Harness::Env->create( \%test_args )->runtests( sort map { $_->stringify } find( qr/\.t$/, 't' ) )->has_errors;
    }

    method _do_in_dir( $path, $sub ) {
        my $cwd = cwd()->absolute;
        chdir $path->absolute->stringify if -d $path->absolute;
        $sub->();
        chdir $cwd->stringify;
    }

    method step_build_libs() {
        my $pre = cwd->absolute->child( qw[blib arch auto], $meta->name );
        return 0 if -d $pre;
        my $p = $cwd->child('share')->realpath;
        if ( $^O eq 'MSWin32' && $prebuilt ) {
            say 'Using prebuilt SDL3_image...' if $verbose;
            next                               if $config{okay};
            my $store = tempdir()->child('SDL3_image.zip');
            my $okay  = $self->fetch( $archive, $store );
            die 'Failed to fetch SDL3_image binaries' unless $okay;
            if ( $Config{cc} =~ m[gcc]i ) {
                my $platform = $Config{archname} =~ /x64/ ? 'x86_64-w64-mingw32' : 'i686-w64-mingw32';

                #~ $self->add_to_cleanup( $okay->canonpath );
                $okay->child($platform)->visit(
                    sub {
                        my ( $path, $state ) = @_;
                        $path->is_dir ? $p->child( $path->relative( $okay->child($platform) ) )->mkdir( { verbose => $verbose } ) :
                            $path->copy( $p->child( $path->relative( $okay->child($platform) ) ) );
                    },
                    { recurse => 1 }
                );
            }
            else {    # Assume VC
                my $platform = $Config{archname} =~ /x64/ ? 'x64' : 'x86';    # XXX - arm64 is untested, well so is VC right now...
                $okay->child('include')->visit(
                    sub {
                        my ( $path, $state ) = @_;
                        $path->is_dir ? $p->child( $path->relative( $okay->child('include') ) )->mkdir( { verbose => $verbose } ) :
                            $path->copy( $p->child( $path->relative( $okay->child('include') ) ) );
                    },
                    { recurse => 1 }
                );
                $okay->child( 'lib', $platform )->visit(
                    sub {
                        my ( $path, $state ) = @_;
                        $path->is_dir ? $p->child( $path->relative( $okay->child( 'lib', $platform ) ) )->mkdir( { verbose => $verbose } ) :
                            $path->copy( $p->child( $path->relative( $okay->child( 'lib', $platform ) ) ) );
                    },
                    { recurse => 1 }
                );
            }
            $config{type}    = 'share';
            $config{okay}    = 1;
            $config{version} = $version;
        }
        else {
            require DynaLoader;
            require Alien::cmake3;
            unshift @PATH, Alien::cmake3->bin_dir;
            say 'Looking for SDL3_image library...' if $verbose;
            my ($path) = DynaLoader::dl_findfile('-lSDL3_image');
            if ($path) {
                $config{type} = 'system';
                $config{path} = path($path)->realpath->stringify;
                say 'Library found at ' . $config{path} if $verbose;
            }
            else {
                say 'Building SDL3_image from source...' if $verbose;
                my $store = tempdir()->child( path($archive)->basename );
                my $build = tempdir()->child('build');
                my $okay  = $self->fetch( $archive, $store );
                die 'Failed to download SDL3_image source' unless $okay;

                #~ $self->add_to_cleanup( $okay->canonpath );
                $config{path} = 'share';
                $config{okay} = 0;
                my $cflags = '';
                require Alien::SDL3;
                {
                    $self->_do_in_dir(
                        $okay,
                        sub {
                            system( Alien::cmake3->exe, grep {length} '-S ' . $okay,
                                '-B ' . $build->canonpath,      '--install-prefix=' . $p->canonpath,
                                '-Wdeprecated -Wdev -Werror',   '-DSDL_SHARED=ON',
                                '-DSDL_TESTS=OFF',              '-DSDL_INSTALL_TESTS=OFF',
                                '-DSDL_DISABLE_INSTALL_MAN=ON', '-DSDL_VENDOR_INFO=SDL3.pm',
                                '-DCMAKE_BUILD_TYPE=Release',   '-DSDL3_DIR=' . Alien::SDL3->sdldir->child(qw[lib cmake SDL3])->absolute,
                                $cflags
                            );
                            system( Alien::cmake3->exe, '--build', $build->canonpath

                                #, '--config Release', '--parallel'
                            );
                            die "Failed to build SDL3_image! %s\n", $archive // '' if system( Alien::cmake3->exe, '--install', $build->canonpath );
                            $config{okay}    = 1;
                            $config{version} = $version;
                        }
                    );
                }
            }
        }
        {
            my @out;
            push @out, sprintf '%s = %s', $_, $config{$_} for sort keys %config;
            $p->child('.config')->spew( join "\n", @out );
        }
    }

    method get_arguments (@sources) {
        $_ = detildefy($_) for grep {defined} $install_base, $destdir, $prefix, values %{$install_paths};
        $install_paths = ExtUtils::InstallPaths->new( dist_name => $meta->name );
        return;
    }

    method fetch ( $liburl, $outfile ) {
        $http //= HTTP::Tiny->new();
        printf 'Downloading %s... ', $liburl if $verbose;
        $outfile->parent->mkpath;
        my $response = $http->mirror( $liburl, $outfile, {} );
        say $response->{reason} if $verbose;
        if ( $response->{success} ) {    #ddx $response;

            #~ $self->add_to_cleanup($outfile);
            my $outdir = $outfile->parent->child( $outfile->basename( '.tar.gz', '.zip' ) );
            printf 'Extracting %s to %s... ', $outfile, $outdir if $verbose;
            require Archive::Extract;
            my $ae = Archive::Extract->new( archive => $outfile );
            if ( $ae->extract( to => $outdir ) ) {
                say 'done' if $verbose;

                #~ $self->add_to_cleanup( $ae->extract_path );
                return path( $ae->extract_path );
            }
            else {
                croak 'Failed to extract ' . $outfile;
            }
        }
        else {
            croak 'Failed to download ' . $liburl;
        }
        return 0;
    }

    method Build(@args) {
        my $method = $self->can( 'step_' . $action );
        $method // die "No such action '$action'\n";
        exit $method->($self);
    }

    method Build_PL() {
        say sprintf 'Creating new Build script for %s %s', $meta->name, $meta->version;
        $self->write_file( 'Build', sprintf <<'', $^X, __PACKAGE__, __PACKAGE__ );
#!%s
use lib 'builder';
use %s;
use Getopt::Long qw[GetOptionsFromArray];
my %%opts = ( @ARGV && $ARGV[0] =~ /\A\w+\z/ ? ( action => shift @ARGV ) : () );
GetOptionsFromArray \@ARGV, \%%opts, qw[install_base=s install_path=s%% installdirs=s destdir=s prefix=s config=s%% uninst:1 verbose:1 dry_run:1 jobs=i prebuilt:1];
%s->new(%%opts)->Build();

        make_executable('Build');
        my @env = defined $ENV{PERL_MB_OPT} ? split_like_shell( $ENV{PERL_MB_OPT} ) : ();
        $self->write_file( '_build_params', encode_json( [ \@env, \@ARGV ] ) );
        if ( my $dynamic = $meta->custom('x_dynamic_prereqs') ) {
            my %meta = ( %{ $meta->as_struct }, dynamic_config => 0 );
            $self->get_arguments( \@env, \@ARGV );
            require CPAN::Requirements::Dynamic;
            my $dynamic_parser = CPAN::Requirements::Dynamic->new();
            my $prereq         = $dynamic_parser->evaluate($dynamic);
            $meta{prereqs} = $meta->effective_prereqs->with_merged_prereqs($prereq)->as_string_hash;
            $meta = CPAN::Meta->new( \%meta );
        }
        $meta->save(@$_) for ['MYMETA.json'];
    }

    sub find ( $pattern, $base ) {
        $base = path($base) unless builtin::blessed $base;
        my $blah = $base->visit(
            sub ( $path, $state ) {
                $state->{$path} = $path if -f $path && $path =~ $pattern;

                #~ return \0 if keys %$state == 10;
            },
            { recurse => 1 }
        );
        values %$blah;
    }
    };
1;
