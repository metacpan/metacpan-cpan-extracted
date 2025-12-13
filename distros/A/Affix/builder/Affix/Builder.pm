# Based on Module::Build::Tiny which is copyright (c) 2011 by Leon Timmermans, David Golden.
# Module::Build::Tiny is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
use v5.40;
use feature 'class';
no warnings 'experimental::class';
class    #
    Affix::Builder {
    use CPAN::Meta;
    use ExtUtils::Install qw[pm_to_blib install];
    use ExtUtils::InstallPaths 0.002;
    use File::Basename        qw[basename dirname];
    use File::Path            qw[make_path remove_tree];
    use File::Spec::Functions qw[catfile catdir rel2abs abs2rel splitdir curdir];
    use JSON::PP 2            qw[encode_json decode_json];
    use File::Temp            qw[tempfile];

    # Not in CORE
    use Path::Tiny qw[path cwd];
    use ExtUtils::Helpers 0.028 qw[make_executable split_like_shell detildefy];

    # infix and Affix stuff
    use Config qw[%Config];
    field $force : param //= 0;
    field $debug : param = 0;
    field $libver;
    field $cflags;
    field $ldflags;
    field $cppver = 'c++17';    # https://en.wikipedia.org/wiki/C%2B%2B20#Compiler_support
    field $cver   = 'c17';      # https://en.wikipedia.org/wiki/C17_(C_standard_revision)
    field $make : param //= $Config{make};
    #
    field $action : param //= 'build';
    field $meta : reader = CPAN::Meta->load_file('META.json');

    # Params to Build script
    field $install_base  : param    //= '';
    field $installdirs   : param    //= '';
    field $uninst        : param    //= 0;    # Make more sense to have a ./Build uninstall command but...
    field $install_paths : param    //= ExtUtils::InstallPaths->new( dist_name => $meta->name );
    field $verbose       : param(v) //= 0;
    field $dry_run       : param    //= 0;
    field $pureperl      : param    //= 0;
    field $jobs          : param    //= 1;
    field $destdir       : param    //= '';
    field $prefix        : param    //= '';
    #
    ADJUST {
        -e 'META.json' or die "No META information provided\n";

        # Configure Flags
        my $is_bsd = $^O =~ /bsd/i;
        my $is_win = $^O =~ /MSWin32/i;
        $cflags  = $is_bsd ? '' : '-fPIC ';
        $ldflags = $is_bsd ? '' : ' -flto=auto ';
        if ( $debug > 0 ) {
            $cflags
                .= '-DDEBUG=' .
                $debug .
                ' -g3 -gdwarf-4 ' .
                ' -Wno-deprecated -pipe ' .
                ' -Wall -Wextra -Wpedantic -Wvla -Wnull-dereference ' .
                ' -Wswitch-enum  -Wduplicated-cond ' .
                ' -Wduplicated-branches';
            $cflags .= ' -fvar-tracking-assignments' unless $Config{osname} eq 'darwin';
        }
        elsif ( !$is_win ) {
            $cflags
                .= ' -DNDEBUG -DBOOST_DISABLE_ASSERTS -Ofast -ftree-vectorize -ffast-math -fno-align-functions -fno-align-loops -fno-omit-frame-pointer -flto=auto';
        }

        # Threading support (Critical for shm_open/librt on Linux)
        if ( !$is_win ) {
            $cflags  .= ' -pthread';
            $ldflags .= ' -pthread';
        }
    }
    method write_file( $filename, $content ) { path($filename)->spew_raw($content) or die "Could not open $filename: $!\n" }
    method read_file ($filename)             { path($filename)->slurp_utf8         or die "Could not open $filename: $!\n" }

    method step_build() {
        $self->step_affix;
        my %modules       = map { $_ => catfile( 'blib', $_ ) } find( qr/\.pm$/,  'lib' );
        my %docs          = map { $_ => catfile( 'blib', $_ ) } find( qr/\.pod$/, 'lib' );
        my %scripts       = map { $_ => catfile( 'blib', $_ ) } find( qr/(?:)/,   'script' );
        my %sdocs         = map { $_ => delete $scripts{$_} } grep {/.pod$/} keys %scripts;
        my %dist_shared   = map { $_ => catfile( qw[blib lib auto share dist],   $meta->name, abs2rel( $_, 'share' ) ) } find( qr/(?:)/, 'share' );
        my %module_shared = map { $_ => catfile( qw[blib lib auto share module], abs2rel( $_, 'module-share' ) ) } find( qr/(?:)/, 'module-share' );
        pm_to_blib( { %modules, %docs, %scripts, %dist_shared, %module_shared }, catdir(qw[blib lib auto]) );
        make_executable($_) for values %scripts;
        make_path( catdir(qw[blib arch]), { chmod => 0777, verbose => $verbose } );
        0;
    }
    method step_clean() { rmtree( $_, $verbose ) for qw[blib temp]; 0 }

    method step_install() {
        $self->step_build() unless -d 'blib';
        install( $install_paths->install_map, $verbose, $dry_run, $uninst );
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

    method get_arguments (@sources) {
        $_ = detildefy($_) for grep {defined} $install_base, $destdir, $prefix, values %{$install_paths};
        $install_paths = ExtUtils::InstallPaths->new( dist_name => $meta->name );
        return;
    }

    method Build(@args) {
        my $method = $self->can( 'step_' . $action );
        $method // die "No such action '$action'\n";
        exit $method->($self);
    }

    method Build_PL() {
        die "Pure perl Affix? Ha! You wish.\n" if $pureperl;
        say sprintf 'Creating new Build script for %s %s', $meta->name, $meta->version;
        $self->write_file( 'Build', sprintf <<'', $^X, __PACKAGE__, __PACKAGE__ );
#!%s
use lib 'builder';
use %s;
%s->new( @ARGV && $ARGV[0] =~ /\A\w+\z/ ? ( action => shift @ARGV ) : (),
    map { /^--/ ? ( shift(@ARGV) =~ s[^--][]r => 1 ) : /^-/ ? ( shift(@ARGV) =~ s[^-][]r => shift @ARGV ) : () } @ARGV )->Build();

        make_executable('Build');
        my @env = defined $ENV{PERL_MB_OPT} ? split_like_shell( $ENV{PERL_MB_OPT} ) : ();
        $self->write_file( '_build_params', encode_json( [ \@env, \@ARGV ] ) );
        if ( my $dynamic = $meta->custom('x_dynamic_prereqs') ) {
            my %meta = ( %{ $meta->as_struct }, dynamic_config => 1 );
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
                $state->{$path} = $path if $path =~ $pattern;
            },
            { recurse => 1 }
        );
        values %$blah;
    }

    # infix builder
    method step_clone_infix() {
        return                      if cwd->absolute->child('infix')->exists;
        die 'Failed to clone infix' if system 'git clone --verbose https://github.com/sanko/infix.git';
    }

    method step_infix () {
        $self->step_clone_infix();
        my $cwd       = cwd->absolute;
        my $infix_dir = $cwd->child('infix');

        # Use architecture-specific directory to avoid collision on shared filesystems (WSL vs Windows)
        my $build_lib = $infix_dir->child( 'build_lib', $Config{archname} );

        # If library already exists and is newer than source, we are good.
        my $is_msvc  = ( $Config{cc} =~ /cl(\.exe)?$/i );
        my $lib_ext  = $is_msvc ? '.lib' : '.a';
        my $lib_pre  = $is_msvc ? ''     : 'lib';
        my $lib_file = $build_lib->child( $lib_pre . 'infix' . $lib_ext );
        my $src_file = $infix_dir->child( 'src', 'infix.c' );
        if ( -e $lib_file && !$force ) {

            # Check timestamps to ensure we rebuild if source changed
            if ( $src_file->stat->mtime <= $lib_file->stat->mtime ) {
                return 0;
            }
        }
        #
        warn "Building infix static library for $Config{archname}..." if $verbose;
        $build_lib->mkpath unless -d $build_lib;
        my @include_dirs = ( $infix_dir->child('include'), $infix_dir->child('src') );

        # 1. Detect Compiler settings using Perl's Config as base
        my $cc_cmd  = $Config{cc} || 'cc';
        my $cc_type = 'gcc';                 # Default flavor
        if    ( $cc_cmd =~ /cl(\.exe)?$/i ) { $cc_type = 'msvc'; }
        elsif ( $cc_cmd =~ /clang/i )       { $cc_type = 'clang'; }
        elsif ( $cc_cmd =~ /gcc/i )         { $cc_type = 'gcc'; }
        elsif ( $cc_cmd =~ /egcc/i )        { $cc_type = 'gcc'; }

        # 2. Setup Flags
        my ( $ar_cmd, @cflags, @arflags, $out_flag_cc, $out_flag_ar );
        my @includes = map { ( $cc_type eq 'msvc' ? '/I' : '-I' ) . $_ } @include_dirs;
        if ( $cc_type eq 'msvc' ) {
            $ar_cmd      = 'lib';
            @cflags      = ( '/nologo', '/c', '/std:c11', '/W3', '/GS', '/MD', '/O2', @includes );
            @cflags      = ( @cflags, '/DINFIX_DEBUG_ENABLED=1' ) if $verbose;
            @arflags     = ('/nologo');
            $out_flag_cc = '/Fo';
            $out_flag_ar = '/OUT:';
        }
        else {
            # GCC / Clang
            $ar_cmd      = 'ar';
            @cflags      = ( '-std=c11', '-Wall', '-Wextra', '-O2', '-fPIC', @includes );
            @cflags      = ( @cflags, '-DINFIX_DEBUG_ENABLED=1' ) if $verbose;
            @arflags     = ('rcs');
            $out_flag_cc = '-o';
            $out_flag_ar = '';

            # Pass pthread to compilation of static lib too (safe practice)
            push @cflags, '-pthread' unless $^O eq 'MSWin32';
        }

        # 3. Compile infix.c -> infix.o
        my $obj_ext  = $cc_type eq 'msvc' ? '.obj' : '.o';
        my $obj_file = $build_lib->child( 'infix' . $obj_ext );
        my @compile_cmd;
        if ( $cc_type eq 'msvc' ) {
            @compile_cmd = ( $cc_cmd, @cflags, $out_flag_cc . $obj_file, $src_file );
        }
        else {
            @compile_cmd = ( $cc_cmd, @cflags, '-c', $src_file, $out_flag_cc, $obj_file );
        }
        warn "  Compiling: @compile_cmd\n" if $verbose;
        if ( system(@compile_cmd) != 0 ) {
            die "Failed to compile infix.c";
        }

        # 4. Archive infix.o -> libinfix.a
        my @archive_cmd;
        if ( $cc_type eq 'msvc' ) {
            @archive_cmd = ( $ar_cmd, @arflags, $out_flag_ar . $lib_file, $obj_file );
        }
        else {
            @archive_cmd = ( $ar_cmd, @arflags, $lib_file, $obj_file );
        }
        warn "  Archiving: @archive_cmd\n" if $verbose;
        if ( system(@archive_cmd) != 0 ) {
            die "Failed to create infix static library";
        }
        warn "Infix library built: $lib_file\n" if $verbose;
        return 0;
    }

    # Detects if linking against librt is required (common on Linux/BSD/Solaris for shm_open)
    method check_for_lrt() {
        return ''                                if $^O eq 'MSWin32';
        warn "Checking if -lrt is required...\n" if $verbose;
        my $cc        = $Config{cc} || 'cc';
        my $test_code = <<'END_C';
#include <sys/mman.h>
#include <fcntl.h>
int main(void) { shm_open("/test", O_RDONLY, 0); return 0; }
END_C
        my ( $fh, $src ) = tempfile( SUFFIX => '.c', UNLINK => 1 );
        print $fh $test_code;
        close $fh;
        my ( $ofh, $out ) = tempfile( UNLINK => 1 );
        close $ofh;
        my $null = '/dev/null';

        # Try without -lrt
        system("$cc -o $out $src >$null 2>&1") == 0 and return '';

        # Try with -lrt
        system("$cc -o $out $src -lrt >$null 2>&1") == 0 and return '-lrt';
        return '';
    }

    sub command_exists {
        my ($cmd)       = @_;
        my $null_device = $Config{osname} eq 'MSWin32' ? 'NUL'                            : '/dev/null';
        my $search_cmd  = $Config{osname} eq 'MSWin32' ? "where $cmd > $null_device 2>&1" : "command -v $cmd > $null_device 2>&1";
        return system($search_cmd) == 0;
    }

    method step_affix {
        $self->step_infix;
        my $cwd = cwd->absolute;
        my @objs;
        require ExtUtils::CBuilder;
        my $builder = ExtUtils::CBuilder->new( quiet => !$verbose, config => {} );
        my $pre     = $cwd->child(qw[blib arch auto])->absolute;
        require DynaLoader;
        my $mod2fname = defined &DynaLoader::mod2fname ? \&DynaLoader::mod2fname : sub { return $_[0][-1] };
        my @parts     = ('Affix');
        my $archdir   = rel2abs catdir( curdir, qw[. blib arch auto], @parts );
        my $err;
        make_path( $archdir, { chmod => 0755, error => \$err, verbose => $verbose } );
        my $lib_file = catfile( $archdir, $mod2fname->( \@parts ) . '.' . $Config{dlext} );
        my @dirs;
        push @dirs, '../';
        my $has_cxx = !1;

        for my $source ( $cwd->child('lib/Affix.c') ) {
            my $cxx       = $source =~ /cx+$/;
            my $file_base = $source->basename(qr[.c$]);
            my $tempdir   = path('lib');
            $tempdir->mkdir( { verbose => $verbose, mode => oct '755' } );
            my $version = $meta->version;
            my $obj     = $builder->object_file($source);
            push @dirs, $source->dirname();
            $has_cxx = 1 if $cxx;
            push @objs,
                ( $force ||
                    ( !-f $obj ) ||
                    ( $source->stat->mtime >= path($obj)->stat->mtime ) ||
                    ( path(__FILE__)->stat->mtime > path($obj)->stat->mtime ) ) ?
                $builder->compile(
                quiet        => 0,
                'C++'        => $cxx,
                source       => $source->stringify,
                defines      => { VERSION => qq/"$version"/, XS_VERSION => qq/"$version"/ },
                include_dirs => [
                    cwd->stringify,                                             cwd->child('infix')->realpath->stringify,
                    cwd->child('infix')->child('include')->realpath->stringify, cwd->child('infix')->child('src')->realpath->stringify,
                    $source->dirname,                                           $pre->child( $meta->name, 'include' )->stringify
                ],
                extra_compiler_flags =>
                    ( '-fPIC -std=' . ( $cxx ? $cppver : $cver ) . ' ' . $cflags . ( $debug ? ' -ggdb3 -g -Wall -Wextra -pedantic' : '' ) )
                ) :
                $obj;
        }

        # Point to the Architecture-specific build lib
        my $infix_build_lib = cwd->absolute->child('infix')->child( 'build_lib', $Config{archname} )->stringify;

        # Check for -lrt requirement
        my $lrt_flag = $self->check_for_lrt();
        my $data     = {

            # Removed incorrect -lstdc++ logic. Added -lm for math.
            # -pthread is already in $ldflags via ADJUST
            extra_linker_flags => ( $ldflags . ' -L' . $infix_build_lib . ' -linfix ' . $lrt_flag . ' -lm' ),
            objects            => [@objs],
            lib_file           => $lib_file,
            module_name        => join '::',
            @parts
        };
        return $builder->link(%$data);
    }
    };
1;
