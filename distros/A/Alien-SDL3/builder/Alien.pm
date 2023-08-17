package builder::Alien {
    use strict;
    use warnings;
    use base 'Module::Build';
    use HTTP::Tiny;
    use Path::Tiny qw[path tempdir];
    use Archive::Extract;
    use ExtUtils::CBuilder;
    use Config;
    use Env qw[@PATH];
    use Alien::cmake3;
    use Devel::CheckBin;
    $|++;
    #
    unshift @PATH, Alien::cmake3->bin_dir;
    #
    sub fetch_source {
        my ( $self, $liburl, $outfile ) = @_;
        CORE::state $http //= HTTP::Tiny->new();
        printf 'Downloading %s... ', $liburl unless $self->quiet;
        $outfile->parent->mkpath;
        my $response = $http->mirror( $liburl, $outfile, {} );
        if ( $response->{success} ) {    #ddx $response;
            $self->add_to_cleanup($outfile);
            CORE::say 'okay' unless $self->quiet;
            my $outdir = $outfile->parent->child( $outfile->basename( '.tar.gz', '.zip' ) );
            printf 'Extracting to %s... ', $outdir unless $self->quiet;
            my $ae = Archive::Extract->new( archive => $outfile );
            if ( $ae->extract( to => $outdir ) ) {
                CORE::say 'okay' unless $self->quiet;
                $self->add_to_cleanup( $ae->extract_path );
                return Path::Tiny->new( $ae->extract_path );
            }
            else {
                warn 'Failed to extract ' . $outfile;
            }
        }
        else {
            warn 'Failed to download ' . $liburl;
        }
        return 0;
    }

    sub ACTION_code {
        my $self = shift;
        my $p    = path( $self->base_dir )->child('share');
        $p->mkdir;
        $self->share_dir( $p->canonpath );
        my %archives = (
            SDL3       => ['https://github.com/libsdl-org/SDL/archive/refs/heads/main.tar.gz'],
            SDL3_image =>
                ['https://github.com/libsdl-org/SDL_image/archive/refs/heads/main.tar.gz'],
            SDL3_mixer => [
                'https://github.com/libsdl-org/SDL_mixer/archive/refs/heads/main.tar.gz',
                undef,    # flags
                'You may need to install various dev packages (flac, vorbis, opus, etc.)'
            ],
            SDL3_ttf => ['https://github.com/libsdl-org/SDL_ttf/archive/refs/heads/main.tar.gz']
        );
        for my $lib ( sort keys %archives ) {
            if ( !$self->config_data($lib) ) {
                my $store = tempdir()->child( $lib . '.tar.gz' );
                my $build = tempdir()->child('build');
                my $okay  = $self->fetch_source( $archives{$lib}->[0], $store );
                if ( !$okay ) {
                    die if $lib eq 'SDL3';
                    next;
                }
                next if !$okay;
                $self->add_to_cleanup( $okay->canonpath );
                $self->config_data( $lib => 1 );
                $self->feature( $lib => 0 );
                if ( path($okay)->child( 'external', 'download.sh' )->exists &&
                    Devel::CheckBin::check_bin('git') ) {
                    $self->_do_in_dir(
                        path($okay)->child('external'),
                        sub {
                            $self->do_system( 'sh', 'download.sh' );
                        }
                    );
                    $archives{$lib}->[1] = '-DSDL3MIXER_VENDORED=ON';
                }
                $self->_do_in_dir(
                    $okay,
                    sub {
                        $self->do_system(
                            Alien::cmake3->exe,
                            '-S ' . $okay,
                            '-B ' . $build->canonpath,
                            '--install-prefix=' . $p->canonpath,
                            '-Wdeprecated -Wdev -Werror',
                            '-DSDL_SHARED=ON',
                            '-DSDL_TESTS=OFF',
                            '-DSDL_INSTALL_TESTS=OFF',
                            '-DSDL_DISABLE_INSTALL_MAN=ON',
                            '-DSDL_VENDOR_INFO=SDL3.pm',
                            '-DCMAKE_BUILD_TYPE=Release',
                            '-DSDL3_DIR=' . $self->share_dir->{dist},
                            $archives{$lib}->[1]
                        );
                        $self->do_system(
                            Alien::cmake3->exe, '--build',
                            $build->canonpath,  '--config Release',
                            '--parallel'
                        );
                        if (
                            $self->do_system( Alien::cmake3->exe, '--install', $build->canonpath ) )
                        {
                            $self->feature( $lib => 1 );
                        }
                        else {
                            $self->feature( $lib => 0 );
                            printf STDERR "Failed to build %s! %s\n", $lib,
                                $archives{$lib}->[2] // '';
                            die if $lib eq 'SDL3';
                        }
                    }
                );
            }
        }
        $self->SUPER::ACTION_code;
    }
}
