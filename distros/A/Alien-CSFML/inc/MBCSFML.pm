package MBCSFML;
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
use File::Path            qw/mkpath/;
use File::Spec::Functions qw/catfile catdir rel2abs abs2rel splitdir/;
use Getopt::Long          qw/GetOptions/;
use JSON::Tiny            qw/encode_json decode_json/;
use File::pushd;
use File::Copy;
use File::Copy::Recursive qw[dircopy];
use Devel::CheckBin       qw[can_run];
use Env                   qw[@PATH];

sub write_file {
    my ( $filename, $mode, $content ) = @_;
    open my $fh, ">:$mode", $filename or die "Could not open $filename: $!\n";
    print $fh $content;
}

sub read_file {
    my ( $filename, $mode ) = @_;
    open my $fh, "<:$mode", $filename or die "Could not open $filename: $!\n";
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

sub process_xs {
    my ( $source, $options ) = @_;
    die "Can't build xs files under --pureperl-only\n" if $options->{'pureperl-only'};
    my ( undef, @dirnames ) = splitdir( dirname($source) );
    my $file_base = basename( $source, '.xs' );
    my $archdir   = catdir( qw/blib arch auto/, @dirnames, $file_base );
    my $c_file    = catfile( 'lib', @dirnames, "$file_base.c" );
    require ExtUtils::ParseXS;
    ExtUtils::ParseXS::process_file( filename => $source, prototypes => 0, output => $c_file );
    my $version = $options->{meta}->version;
    require ExtUtils::CBuilder;
    my $builder = ExtUtils::CBuilder->new( config => $options->{config}->values_set );
    my $ob_file = $builder->compile(
        source  => $c_file,
        defines => { VERSION => qq/"$version"/, XS_VERSION => qq/"$version"/ }
    );
    mkpath( $archdir, $options->{verbose}, oct '755' ) unless -d $archdir;
    return $builder->link(
        objects     => $ob_file,
        lib_file    => catfile( $archdir, "$file_base." . $options->{config}->get('dlext') ),
        module_name => join '::',
        @dirnames, $file_base
    );
}

sub _mirror_extract {
    my ( $options, $url, $dest ) = @_;
    {
        require HTTP::Tiny;
        print "\nDownloading $url... ";
        my $out      = catdir( $dest, basename($url) );
        my $response = HTTP::Tiny->new->mirror( $url, $out );
        if ( $response->{success} ) {
            print " Done\n";
            print "Extracting $out... ";
            require Archive::Extract;
            my $ae = Archive::Extract->new( archive => $out );
            exit print " Fail! " . $ae->error if !$ae->extract();
            print "Done\n";
            return $ae->extract_path;
        }
        exit !!print " Fail!";
    }
}

sub build_libs {
    my ($options) = @_;
    my ( %libinfo, $dir );
    my $meta = $options->{meta};
    my $cwd  = rel2abs './';       # XXX - use Cwd;

    # This is an ugly cludge. A working, ugly cludge though. :\
    if ( !-d catdir( $cwd, 'share' ) ) {
        mkpath( catdir( $cwd, 'share' ), $options->{verbose}, oct '755' ) unless -d 'share';
        $dir = tempd();
        my $archdir = catdir( $cwd, qw[share] );
        if ( $^O eq 'MSWin32' ) {
            require ExtUtils::CBuilder;
            my $cb   = ExtUtils::CBuilder->new;
            my $cc   = $cb->_compiler_type;
            my %urls = ( sfml => (), cfml => () );
            my $url;
            if ( $cc eq 'MSVC' ) {
                $urls{sfml}
                    = 'https://www.sfml-dev.org/files/SFML-2.5.1-windows-gcc-7.3.0-mingw-64-bit.zip';
                $urls{csfml} = 'https://www.sfml-dev.org/files/CSFML-2.5.1-windows-64-bit.zip';
            }
            else    #if ( $cc eq 'GCC' || $cc eq 'BCC' )
            {
                $urls{sfml}
                    = 'https://www.sfml-dev.org/files/SFML-2.5.1-windows-gcc-7.3.0-mingw-64-bit.zip';
                $urls{csfml} = 'https://www.sfml-dev.org/files/CSFML-2.5.1-windows-64-bit.zip';
            }
            my $dir = tempd();
            for my $lib (qw[sfml csfml]) {
                {
                    my $out = _mirror_extract( $options, $urls{sfml}, $dir );
                    dircopy catdir( $out, 'bin' ), catdir( $archdir, qw[sfml lib] ) or die $!;
                    dircopy catdir( $out, 'lib' ), catdir( $archdir, qw[sfml lib] ) or die $!;
                    dircopy catdir( $out, 'include' ), catdir( $archdir, qw[sfml include] ) or
                        die $!;
                }
                {
                    my $out = _mirror_extract( $options, $urls{csfml}, $dir );
                    dircopy catdir( $out, 'bin' ), catdir( $archdir, qw[csfml lib] ) or die $!;
                    dircopy catdir( $out, 'lib', ( $cc eq 'MSVC' ? 'msvc' : 'gcc' ) ),
                        catdir( $archdir, qw[csfml lib] ) or
                        die $!;
                    dircopy catdir( $out, 'include' ), catdir( $archdir, qw[csfml include] ) or
                        die $!;
                }
            }
            return;
        }
        require Alien::cmake3;
        unshift @PATH, Alien::cmake3->bin_dir;
        require Alien::git;
        unshift @PATH, Alien::git->bin_dir;
        my $exe = Alien::cmake3->exe;
        my $win = $^O eq 'MSWin32' ? 1 : 0;
        my $mac = $^O eq 'darwin'  ? 1 : 0;
        $exe = qq["$exe" -G"MinGW Makefiles"] if $win;    # uses prebuilt libs but don't remove yet

        #$exe = qq[sudo $exe]                  if $mac;
        for my $cmd (
            $exe .
            " -S $cwd/cmake/sfml -B ./build/sfml -DCMAKE_INSTALL_PREFIX=$cwd/share/sfml -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=TRUE -DSFML_BUILD_EXAMPLES=FALSE -DSFML_BUILD_TEST_SUITE=FALSE"
            . ( $mac ? ' -DSFML_BUILD_FRAMEWORKS=FALSE' : '' ), (
                $win ? ( 'mingw32-make -C ./build/sfml', 'mingw32-make -C ./build/sfml install' ) :
                    $exe . " --build ./build/sfml --config Release --parallel 5 --target install"
            ),
            $exe .
            " -S $cwd/cmake/csfml -B ./build/csfml -DCMAKE_INSTALL_PREFIX=$cwd/share/csfml -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=TRUE -DCSFML_LINK_SFML_STATICALLY=FALSE -DSFML_DIR=$cwd/share/sfml/lib/cmake/SFML/"
            . ( $mac ? ' -DSFML_BUILD_FRAMEWORKS=FALSE' : '' ), (
                $win ?
                    ( 'mingw32-make -C ./build/csfml', 'mingw32-make -C ./build/csfml install' ) :
                    $exe . " --build ./build/csfml --config Release --parallel 5 --target install"
            )
        ) {
            print "# $cmd\n";
            system($cmd) == 0 or die "system failed: $?";    # quick
            if ( $? == -1 ) {
                die "# failed to execute: $!\n";
            }
            elsif ( $? & 127 ) {
                die sprintf "# child died with signal %d, %s coredump\n", ( $? & 127 ),
                    ( $? & 128 ) ? 'with' : 'without';
            }
            elsif ( $? != 0 ) {
                die sprintf "# system call failed: %d\n", $?;
            }
        }
    }
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
        system $^X, $_ and die "$_ returned $?\n" for find( qr/\.PL$/, 'lib' );
        my %modules = map { $_ => catfile( 'blib', $_ ) } find( qr/\.p(?:m|od)$/, 'lib' );
        my %scripts = map { $_ => catfile( 'blib', $_ ) } find( qr//,             'script' );
        build_libs( \%opt );
        my %shared = map {
            $_ => catfile( qw/blib lib auto share dist/, $opt{meta}->name, abs2rel( $_, 'share' ) )
        } find( qr//, 'share' );
        pm_to_blib( { %modules, %scripts, %shared }, catdir(qw/blib lib auto/) );
        make_executable($_) for values %scripts;
        mkpath( catdir(qw/blib arch/), $opt{verbose} );
        process_xs( $_, \%opt ) for find( qr/.xs$/, 'lib' );
        if ( $opt{install_paths}->install_destination('libdoc') &&
            $opt{install_paths}->is_default_installable('libdoc') ) {
            manify(
                $_,
                catfile( 'blib', 'bindoc', man1_pagename($_) ),
                $opt{config}->get('man1ext'), \%opt
            ) for keys %scripts;
            manify(
                $_,
                catfile( 'blib', 'libdoc', man3_pagename($_) ),
                $opt{config}->get('man3ext'), \%opt
            ) for keys %modules;
        }
    },
    test => sub {
        my %opt = @_;
        die "Must run `./Build build` first\n" if not -d 'blib';
        require TAP::Harness;
        my $tester = TAP::Harness->new(
            {   verbosity => $opt{verbose},
                lib       => [ map { rel2abs( catdir( qw/blib/, $_ ) ) } qw/arch lib/ ],
                color     => -t STDOUT
            }
        );
        $tester->runtests( sort +find( qr/\.t$/, 't' ) )->has_errors and exit 1;
    },
    install => sub {
        my %opt = @_;
        die "Must run `./Build build` first\n" if not -d 'blib';
        install( $opt{install_paths}->install_map, @opt{qw/verbose dry_run uninst/} );
    },
);

sub Build {
    my $action = @ARGV && $ARGV[0] =~ /\A\w+\z/ ? shift @ARGV : 'build';
    die "No such action '$action'\n" if not $actions{$action};
    unshift @ARGV, @{ decode_json( read_file( '_build_params', 'utf8' ) ) };
    GetOptions(
        \my %opt,
        qw/install_base=s install_path=s% installdirs=s destdir=s prefix=s config=s% uninst:1 verbose:1 dry_run:1 pureperl-only:1 create_packlist=i/
    );
    $_ = detildefy($_)
        for grep {defined} @opt{qw/install_base destdir prefix/}, values %{ $opt{install_path} };
    @opt{ 'config', 'meta' } = ( ExtUtils::Config->new( $opt{config} ), get_meta() );
    $actions{$action}->(
        %opt, install_paths => ExtUtils::InstallPaths->new( %opt, dist_name => $opt{meta}->name )
    );
}

sub Build_PL {
    my $meta = get_meta();
    printf "Creating new 'Build' script for '%s' version '%s'\n", $meta->name, $meta->version;
    my $dir = $meta->name eq 'MBCSFML' ? '' : "use lib 'inc';";
    write_file( 'Build', 'raw', "#!perl\n$dir\nuse MBCSFML;\n\$|++;\nBuild();\n" );
    make_executable('Build');
    my @env = defined $ENV{PERL_MB_OPT} ? split_like_shell( $ENV{PERL_MB_OPT} ) : ();
    write_file( '_build_params', 'utf8', encode_json( [ @env, @ARGV ] ) );
    $meta->save(@$_) for ['MYMETA.json'], [ 'MYMETA.yml' => { version => 1.4 } ];
}
1;

=head1 SEE ALSO

L<Module::Build::Tiny>

=head1 ORIGINAL AUTHORS

=over 4

=item *

Leon Timmermans <leont@cpan.org>

=item *

David Golden <dagolden@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Leon Timmermans, David Golden.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
