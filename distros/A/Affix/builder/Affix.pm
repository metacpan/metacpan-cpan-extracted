package builder::Affix;
use strict;
use warnings;
use Exporter 5.57 'import';
our @EXPORT = qw/Build Build_PL/;
use CPAN::Meta;
use ExtUtils::Config 0.003;
use ExtUtils::Helpers 0.020
    qw/make_executable split_like_shell man1_pagename man3_pagename detildefy/;
use ExtUtils::Install qw/pm_to_blib install/;
use ExtUtils::InstallPaths 0.002;
use File::Basename        qw/basename dirname/;
use File::Find            ();
use File::Path            qw/mkpath rmtree/;
use File::Spec::Functions qw/catfile catdir rel2abs abs2rel splitdir splitpath curdir/;
use Getopt::Long 2.36     qw/GetOptionsFromArray/;
use JSON::PP 2            qw/encode_json decode_json/;
use HTTP::Tiny;
use Path::Tiny;
use Archive::Tar;
use IO::File;
use IO::Uncompress::Unzip qw($UnzipError);
use File::stat;
#
my $libver;
my $CFLAGS
    = ' -DNDEBUG -DBOOST_DISABLE_ASSERTS -O2 -ffast-math -funroll-loops -fno-align-functions -fno-align-loops';
my $LDFLAGS = ' ';    # https://wiki.freebsd.org/LinkTimeOptimization
#
sub write_file {
    my ( $filename, $content ) = @_;
    open my $fh, '>', $filename or die "Could not open $filename: $!\n";
    print $fh $content;
}

sub read_file {
    my ( $filename, $mode ) = @_;
    open my $fh, '<', $filename or die "Could not open $filename: $!\n";
    return do { local $/; <$fh> };
}

sub get_meta {
    my ($metafile) = grep { -e $_ } qw/META.json META.yml/ or die "No META information provided\n";
    return CPAN::Meta->load_file($metafile);
}

sub manify {
    my ( $input_file, $output_file, $section, $opts ) = @_;
    return if -e $output_file && -M $input_file <= -M $output_file;
    my $dirname = dirname($output_file);
    mkpath( $dirname, $opts->{verbose} ) if not -d $dirname;
    require Pod::Man;
    Pod::Man->new( section => $section )->parse_from_file( $input_file, $output_file );
    print "Manifying $output_file\n" if $opts->{verbose} && $opts->{verbose} > 0;
    return;
}

sub alien {
    my (%opt) = @_;
    die "Can't build xs files under --pureperl-only\n" if $opt{'pureperl-only'};
    if ( -d Path::Tiny->cwd->child('dyncall') ) {
        my ($kid) = Path::Tiny->cwd->child('dyncall');
        my $cwd   = Path::Tiny->cwd->absolute;
        my $pre   = Path::Tiny->cwd->child( qw[blib arch auto], $opt{meta}->name )->absolute;
        chdir $kid->absolute->stringify;
        warn Path::Tiny->cwd->absolute;
        if (1) {
            my $make = $opt{config}->get('make');
            my $configure
                = './configure --prefix=' . $pre->absolute . ' CFLAGS="-fPIC ' .
                ( $opt{config}->get('osname') =~ /bsd/ ? '' : $CFLAGS ) . '" LDFLAGS="' .
                ( $opt{config}->get('osname') =~ /bsd/ ? '' : $LDFLAGS ) . '"';
            if ( $opt{config}->get('osname') eq 'MSWin32' ) {
                require Devel::CheckBin;
                for my $exe ( $make, qw[make nmake mingw32-make] ) {
                    next unless Devel::CheckBin::check_bin($exe);
                    $make      = $exe;
                    $configure = '.\configure.bat /tool-' . $opt{config}->get('cc') . ' /make-';
                    if ( $exe eq 'nmake' ) {
                        $configure .= 'nmake';
                        $make      .= ' -f Nmakefile';
                    }
                    else {
                        $configure .= 'make';
                        $make      .= ' CC=gcc VPATH=. PREFIX="' . $pre->absolute . '"';
                    }
                    last;
                }
                warn($_) && system($_ ) for $configure, $make;
                my %libs = (
                    dyncall => [
                        qw[dyncall_version.h dyncall_macros.h dyncall_config.h
                            dyncall_types.h dyncall.h dyncall_signature.h
                            dyncall_value.h dyncall_callf.h dyncall_alloc.h
                        ]
                    ],
                    dyncallback => [
                        qw[dyncall_thunk.h dyncall_thunk_x86.h
                            dyncall_thunk_ppc32.h dyncall_thunk_x64.h
                            dyncall_thunk_arm32.h dyncall_thunk_arm64.h
                            dyncall_thunk_mips.h dyncall_thunk_mips64.h
                            dyncall_thunk_ppc64.h dyncall_thunk_sparc32.h
                            dyncall_thunk_sparc64.h dyncall_args.h
                            dyncall_callback.h
                        ]
                    ],
                    dynload => [qw[dynload.h]],
                );
                $pre->child('include')->mkdir;
                $pre->child('lib')->mkdir;
                for my $lib ( keys %libs ) {

                    #chdir $kid->child($lib)->absolute;
                    #warn $kid->child( $lib, 'lib' . $lib . '_s' . $opt{config}->get('_a') );
                    $kid->child( $lib, 'lib' . $lib . '_s' . $opt{config}->get('_a') )
                        ->copy( $pre->child('lib')->absolute );
                    for ( @{ $libs{$lib} } ) {

                        #warn sprintf '%s => %s', $kid->child( $lib, $_ ),
                        #    $pre->child( 'include', $_ )->absolute;
                        #warn
                        $kid->child( $lib, $_ )->copy( $pre->child( 'include', $_ )->absolute );
                    }
                }
            }
            else {
                $make = $opt{config}->get('make');
                warn($_) && system($_ ) for $configure, $make, $make . ' install';
            }
        }
        else {    # Future, maybe...
            require ExtUtils::CBuilder;
            my $builder = ExtUtils::CBuilder->new( config => ( $opt{config}->values_set ) );
            $pre->child('lib')->mkdir;
            $pre->child('include')->mkdir;
            my %libs = (
                dyncall => {
                    c => [
                        qw[dyncall_vector.c dyncall_api.c dyncall_callvm.c
                            dyncall_callvm_base.c dyncall_call.S dyncall_callf.c
                            dyncall_aggregate.c]
                    ],
                    h => [
                        qw[dyncall_version.h dyncall_macros.h dyncall_config.h
                            dyncall_types.h dyncall.h dyncall_signature.h
                            dyncall_value.h dyncall_callf.h dyncall_alloc.h
                        ]
                    ]
                },
                dyncallback => {
                    c => [
                        qw[dyncall_alloc_wx.c dyncall_args.c dyncall_callback.c
                            dyncall_callback_arch.S dyncall_thunk.c]
                    ],
                    h => [
                        qw[dyncall_thunk.h dyncall_thunk_x86.h
                            dyncall_thunk_ppc32.h dyncall_thunk_x64.h
                            dyncall_thunk_arm32.h dyncall_thunk_arm64.h
                            dyncall_thunk_mips.h dyncall_thunk_mips64.h
                            dyncall_thunk_ppc64.h dyncall_thunk_sparc32.h
                            dyncall_thunk_sparc64.h dyncall_args.h
                            dyncall_callback.h
                        ]
                    ]
                },
                dynload => { c => [qw[dynload.c dynload_syms.c]], h => [qw[dynload.h]] },
            );
            #
            for my $lib (qw[dyncall dyncallback dynload]) {
                my @objs;
                chdir $kid->child($lib)->absolute;
                for my $c ( @{ $libs{$lib}{c} } ) {
                    my $ob_file = $builder->compile(
                        source => $c,

                       #defines      => { VERSION => qq/"$version"/, XS_VERSION => qq/"$version"/ },
                        include_dirs => [
                            curdir, $kid->child('dyncall')->stringify,
                            $pre->child('include')->stringify,
                        ],

                        #extra_compiler_flags => (
                        #    '-fPIC ' . ( $opt{config}->get('osname') =~ /bsd/ ? '' : $CFLAGS ) .
                        #        ( $DEBUG ? ' -ggdb3 ' : '' )
                        #)
                    );
                    push @objs, $ob_file;
                }
                $builder->link(

             #extra_linker_flags => (
             #    ( $opt{config}->get('osname') =~ /bsd/ ? '' : $LDFLAGS ) . ' -L' .
             #        dirname($source) . ' -L' . $pre->child( $opt{meta}->name, 'lib' )->stringify .
             #        ' -ldyncall_s -ldyncallback_s -ldynload_s'
             #),
                    objects  => [@objs],
                    lib_file => $pre->child( 'lib', 'lib' . $lib . '_s' . $opt{config}->get('_a') )
                        ->stringify
                );
                for ( @{ $libs{$lib}{h} } ) {
                    warn sprintf '%s => %s', $kid->child( $lib, $_ ),
                        $pre->child( 'include', $_ )->absolute;
                    warn $kid->child( $lib, $_ )->copy( $pre->child( 'include', $_ )->absolute );
                }
            }
            #
        }
        chdir $cwd->stringify;
    }
    else {
        my $http     = HTTP::Tiny->new;
        my $response = $http->get('https://dyncall.org/download');
        die sprintf "Failed to download %s: %s!", $response->{url}, $response->{content}
            unless $response->{success};

        #print "$response->{status} $response->{reason}\n";
        #while ( my ( $k, $v ) = each %{ $response->{headers} } ) {
        #    for ( ref $v eq 'ARRAY' ? @$v : $v ) {
        #        print "$k: $_\n";
        #    }
        #}
        #print $response->{content} if length $response->{content};
        # https://dyncall.org/r1.2/dyncall-1.2-windows-xp-x64-r.zip
        # https://dyncall.org/r1.2/dyncall-1.2-windows-xp-x86-r.zip
        # https://dyncall.org/r1.2/dyncall-1.2-windows-10-arm64-r.zip
        if ( $opt{config}->get('osname') eq 'MSWin32' ) {    # Use prebuilt libs on Windows
            my $x64  = $opt{config}->get('ptrsize') == 8;
            my $plat = $x64 ? '64' : '86';
            my %versions;
            for my $url ( map { 'https://dyncall.org/' . $_ }
                $response->{content}
                =~ m[href="(.+/dyncall-\d\.\d+\-windows-xp-x${plat}(?:-r)?\.zip)"]g ) {
                my ($version) = $url =~ m[-(\d+\.\d+)-windows];
                $versions{$version} = $url;
            }
            for my $version ( reverse sort keys %versions ) {
                $libver //= $version;

             #printf "%s %s => %s\n", ($pick eq $version ? '*': ' '), $version, $versions{$version};
            }

            #ddx \@src;
            # https://dyncall.org/r1.2/dyncall-1.2-windows-xp-x64-r.zip
            # https://dyncall.org/r1.2/dyncall-1.2-windows-xp-x86-r.zip
            # https://dyncall.org/r1.2/dyncall-1.2-windows-10-arm64-r.zip
            my $filename = Path::Tiny->new( $versions{$libver} )->basename;
            my $dest =    #Path::Tiny::tempdir( { realpath => 1 } );
                Path::Tiny->cwd;
            $response = $http->mirror( $versions{$libver}, $dest->child($filename), {} );
            if ( $response->{success} ) {

                #print $dest->child($filename) . " is up to date\n";
                my $extract = $dest->child('extract');
                my $output  = $dest->child('output');
                my $ret     = unzip( $filename, $extract );
                warn $ret;
                my $pre = Path::Tiny->cwd->child( qw[blib arch auto], $opt{meta}->name )->absolute;

                #$pre->mkpath;
                for my $sub (qw[lib include]) {
                    for my $kid ( $ret->child($sub)->children ) {
                        $pre->child( $sub, $kid->basename )->parent->mkpath;
                        $kid->copy( $pre->child( $sub, $kid->basename ) );
                    }
                }
            }
            else {
                die sprintf 'Failed to download %s: %s!', $response->{url}, $response->{content}
                    unless $response->{success};
            }
        }
        else {    # Build from source on all other platforms
            my %versions;
            for my $url ( map { 'https://dyncall.org/' . $_ }
                $response->{content} =~ m[href="(.+/dyncall-\d\.\d+\.tar\.gz)"]g ) {
                my ($version) = $url =~ m[/r(\d\.\d+)/];
                $versions{$version} = $url;
            }
            for my $version ( reverse sort keys %versions ) {
                $libver //= $version;

             #printf "%s %s => %s\n", ($pick eq $version ? '*': ' '), $version, $versions{$version};
            }
            my $filename = Path::Tiny->new( $versions{$libver} )->basename;
            my $dest     = Path::Tiny::tempdir( { realpath => 1 } );
            $dest     = Path::Tiny->cwd;
            $response = $http->mirror( $versions{$libver}, $dest->child($filename), {} );

            #use Data::Dump;
            #ddx $response;
            if ( $response->{success} ) {

                #print $dest->child($filename) . " is up to date\n";
                my $tar     = Archive::Tar->new;
                my $extract = $dest->child('extract');
                my $output  = $dest->child('output');
                $tar->setcwd( $extract->stringify );
                $tar->read( $dest->child($filename) );
                $tar->extract;
                my ($kid) = $extract->children;

                #die;
                my $cwd = Path::Tiny->cwd->absolute;
                my $pre = Path::Tiny->cwd->child( qw[blib arch auto], $opt{meta}->name )->absolute;
                chdir $kid->absolute->stringify;
                warn($_) && system($_ )
                    for './configure --prefix=' .
                    $pre->absolute,    # . ' CFLAGS="-Ofast" LDFLAGS="-Ofast"',
                    'make', 'make install';
                chdir $cwd->stringify;
            }
            else {
                die sprintf 'Failed to download %s: %s!', $response->{url}, $response->{content}
                    unless $response->{success};
            }
        }
    }
}

sub process_xs {
    my ( $source, %opt ) = @_;
    die "Can't build xs files under --pureperl-only\n" if $opt{'pureperl-only'};
    my $DEBUG = 0;
    warn $@ if $@;
    my ( undef, @parts ) = splitdir( dirname($source) );
    push @parts, my $file_base = basename( $source, '.xs' );
    my $archdir = catdir( qw/blib arch auto/, @parts );
    my $tempdir = 'temp';
    my $c_file  = catfile( $tempdir, "$file_base.c" );
    require ExtUtils::ParseXS;
    mkpath( $tempdir, $opt{verbose}, oct '755' );
    ExtUtils::ParseXS::process_file(
        prototypes  => 1,
        linenumbers => 1,
        'C++'       => 1,
        filename    => $source,
        prototypes  => 1,
        output      => $c_file
    );
    my $version = $opt{meta}->version;
    require ExtUtils::CBuilder;
    my $builder = ExtUtils::CBuilder->new( config => ( $opt{config}->values_set ) );
    my $pre     = Path::Tiny->cwd->child(qw[blib arch auto])->absolute;
    my $obj     = $builder->object_file($c_file);
    warn $pre->child( $opt{meta}->name, 'include' )->stringify;
    my $ob_file = $builder->compile(
        'C++'        => 1,
        source       => $c_file,
        defines      => { VERSION => qq/"$version"/, XS_VERSION => qq/"$version"/ },
        include_dirs =>
            [ curdir, dirname($source), $pre->child( $opt{meta}->name, 'include' )->stringify ],
        extra_compiler_flags => (
            '-fPIC ' . ( $opt{config}->get('osname') =~ /bsd/ ? '' : $CFLAGS ) .
                ( $DEBUG ? ' -ggdb3 ' : '' )
        )
    );
    require DynaLoader;
    my $mod2fname
        = defined &DynaLoader::mod2fname ? \&DynaLoader::mod2fname : sub { return $_[0][-1] };
    mkpath( $archdir, $opt{verbose}, oct '755' ) unless -d $archdir;
    my $lib_file = catfile( $archdir, $mod2fname->( \@parts ) . '.' . $opt{config}->get('dlext') );

    #my $op_lib_file = catfile(
    #    $paths->install_destination('arch'),
    #qw[auto Object],
    #'Pad' . $opt{config}->get('dlext')
    #);
    return $builder->link(
        extra_linker_flags => (
            ( $opt{config}->get('osname') =~ /bsd/ ? '' : $LDFLAGS ) . ' -L' .
                dirname($source) . ' -L' . $pre->child( $opt{meta}->name, 'lib' )->stringify .
                ' -ldyncall_s -ldyncallback_s -ldynload_s'
        ),
        objects     => [$ob_file],
        lib_file    => $lib_file,
        module_name => join '::',
        @parts
    );
}

sub find {
    my ( $pattern, $dir ) = @_;
    my @ret;
    File::Find::find( sub { push @ret, $File::Find::name if /$pattern/ && -f }, $dir ) if -d $dir;
    return @ret;
}
my %actions = (
    build => sub {
        my %opt = @_;
        for my $pl_file ( find( qr/\.PL$/, 'lib' ) ) {
            ( my $pm = $pl_file ) =~ s/\.PL$//;
            system $^X, $pl_file, $pm and die "$pl_file returned $?\n";
        }
        my %modules = map { $_ => catfile( 'blib', $_ ) } find( qr/\.p(?:m|od)$/, 'lib' );
        my %scripts = map { $_ => catfile( 'blib', $_ ) } find( qr//,             'script' );
        my %shared  = map {
            $_ => catfile( qw/blib lib auto share dist/, $opt{meta}->name, abs2rel( $_, 'share' ) )
        } find( qr//, 'share' );
        pm_to_blib( { %modules, %scripts, %shared }, catdir(qw/blib lib auto/) );
        make_executable($_) for values %scripts;
        mkpath( catdir(qw/blib arch/), $opt{verbose} );
        alien(%opt);
        process_xs( $_, %opt ) for find( qr/.xs$/, 'lib' );
        if ( $opt{install_paths}->install_destination('bindoc') &&
            $opt{install_paths}->is_default_installable('bindoc') ) {
            manify(
                $_,
                catfile( 'blib', 'bindoc', man1_pagename($_) ),
                $opt{config}->get('man1ext'), \%opt
            ) for keys %scripts;
        }
        if ( $opt{install_paths}->install_destination('libdoc') &&
            $opt{install_paths}->is_default_installable('libdoc') ) {
            manify(
                $_,
                catfile( 'blib', 'libdoc', man3_pagename($_) ),
                $opt{config}->get('man3ext'), \%opt
            ) for keys %modules;
        }
        return 0;
    },
    test => sub {
        my %opt = @_;
        die "Must run `./Build build` first\n" if not -d 'blib';
        require TAP::Harness::Env;
        my %test_args = (
            ( verbosity => $opt{verbose} ) x !!exists $opt{verbose},
            ( jobs  => $opt{jobs} ) x !!exists $opt{jobs},
            ( color => 1 ) x !!-t STDOUT,
            lib => [ map { rel2abs( catdir( qw/blib/, $_ ) ) } qw/arch lib/ ],
        );
        my $tester = TAP::Harness::Env->create( \%test_args );
        return $tester->runtests( sort +find( qr/\.t$/, 't' ) )->has_errors;
    },
    install => sub {
        my %opt = @_;
        die "Must run `./Build build` first\n" if not -d 'blib';
        install( $opt{install_paths}->install_map, @opt{qw/verbose dry_run uninst/} );
        return 0;
    },
    clean => sub {
        my %opt = @_;
        rmtree( $_, $opt{verbose} ) for qw/blib temp/;
        return 0;
    },
    realclean => sub {
        my %opt = @_;
        rmtree( $_, $opt{verbose} ) for qw/blib temp Build _build_params MYMETA.yml MYMETA.json/;
        return 0;
    }
);

sub Build {
    my $action = @ARGV && $ARGV[0] =~ /\A\w+\z/ ? shift @ARGV : 'build';
    die "No such action '$action'\n" if not $actions{$action};
    my ( $env, $bargv ) = @{ decode_json( read_file('_build_params') ) };
    my %opt;
    GetOptionsFromArray( $_, \%opt,
        qw/install_base=s install_path=s% installdirs=s destdir=s prefix=s config=s% uninst:1 verbose:1 dry_run:1 pureperl-only:1 create_packlist=i jobs=i/
    ) for ( $env, $bargv, \@ARGV );
    $_ = detildefy($_)
        for grep {defined} @opt{qw/install_base destdir prefix/}, values %{ $opt{install_path} };
    @opt{ 'config', 'meta' } = ( ExtUtils::Config->new( $opt{config} ), get_meta() );
    exit $actions{$action}->(
        %opt, install_paths => ExtUtils::InstallPaths->new( %opt, dist_name => $opt{meta}->name )
    );
}

sub Build_PL {
    my $meta = get_meta();
    printf "Creating new 'Build' script for '%s' version '%s'\n", $meta->name, $meta->version;
    my $dir = $meta->name eq 'Module-Build-Tiny' ? "use lib '../lib';" : '';
    write_file( 'Build', "#!perl\n$dir\nuse lib '.';use " . __PACKAGE__ . ";\nBuild();\n" );
    make_executable('Build');
    my @env = defined $ENV{PERL_MB_OPT} ? split_like_shell( $ENV{PERL_MB_OPT} ) : ();
    write_file( '_build_params', encode_json( [ \@env, \@ARGV ] ) );
    $meta->save(@$_) for ['MYMETA.json'], [ 'MYMETA.yml' => { version => 1.4 } ];
}

sub unzip {
    my ( $file, $dest ) = @_;
    my $retval;
    my $u = IO::Uncompress::Unzip->new($file) or die "Cannot open $file: $UnzipError";
    my %dirs;
    for ( my $status = 1; $status > 0; $status = $u->nextStream() ) {
        last if $status < 0;    # bail on error
        my $header = $u->getHeaderInfo();

        #ddx $header;
        my $destfile = $dest->child( $header->{Name} );
        next if $header->{Name} =~ m[/$];    # Directory
        next if $destfile->is_dir;
        next
            if $destfile->is_file &&
            stat( $destfile->absolute->stringify )->mtime < $header->{Time};
        warn $destfile;
        $destfile->parent->mkpath;
        my $raw = '';
        while ( ( $status = $u->read( my $buff ) ) > 0 ) { $raw .= $buff }
        $destfile->spew_raw($raw);
        $destfile->touch;
        $retval = $destfile->parent if $destfile =~ 'build.log';
    }
    return $retval;
}
1;
