package builder::xmake {
    use strict;
    use warnings;
    use parent 'Module::Build';
    use HTTP::Tiny            qw[];
    use File::Spec            qw[];
    use File::Basename        qw[];
    use Env                   qw[@PATH];              # Windows
    use File::Temp            qw[tempdir tempfile];
    use File::Spec::Functions qw[rel2abs];
    use File::Which           qw[which];

    #~ use File::ShareDir qw[];
    #
    #~ use Data::Dump;
    #
    my $version = 'v2.8.3';    # Target install version
    my $branch  = 'master';

    #~ my $installer_sh = 'https://xmake.io/shget.text';
    my $installer_exe
        = "https://github.com/xmake-io/xmake/releases/download/${version}/xmake-${version}.win64.exe";
    my $share = rel2abs 'share';
    #
    sub http {
        CORE::state $http //= HTTP::Tiny->new(
            agent => 'Alien::xmake/' .
                shift->dist_version() . '; '    # space at the end asks HT to appended default UA
        );
        $http;
    }
    #
    sub locate_xmake {
        my ($s) = @_;
        my $path = which('xmake');
        $path ? rel2abs($path) : ();
    }
    sub install_with_exe { my ($s) = @_; }
    sub install_via_bash { my ($s) = @_; }

    #~ use File::ShareDir::Install;
    #~ warn File::ShareDir::Install::install_share( module => 'Alien::xmake');
    #~ warn File::Spec->rel2abs(
    #~ File::Basename::dirname(__FILE__), 'share'
    #~ );
    sub download_exe {
        my ($s)      = @_;
        my $local    = File::Spec->rel2abs( File::Spec->catfile( $s->cwd, 'xmake_installer.exe' ) );
        my $response = $s->http->mirror( $installer_exe, $local );
        if ( $response->{success} ) {
            $s->log_debug( 'Install executable mirrored at ' . $local );
            $s->make_executable($local);    # get it ready to run
            return $local;
        }
        $s->log_debug( 'Status: [' . $response->{status} . '] ' . $response->{content} );
        $s->log_warn( 'Failed to download installer from ' . $response->{url} );
        exit 1;
    }

    #~ sub download_shget {
    #~ my ($s)      = @_;
    #~ my $local    = File::Spec->rel2abs( File::Spec->catfile( $s->cwd, 'xmake_installer.sh' ) );
    #~ my $response = $s->http->mirror( $installer_sh, $local );
    #~ if ( $response->{success} ) {
    #~ $s->log_debug( 'Install script mirrored at ' . $local );
    #~ $s->make_executable($local);    # get it ready to run
    #~ return $local;
    #~ }
    #~ $s->log_debug( 'Status: [' . $response->{status} . '] ' . $response->{content} );
    #~ $s->log_warn( 'Failed to download installer script from ' . $response->{url} );
    #~ exit 1;
    #~ }
    sub gather_info {
        my ( $s, $xmake ) = @_;
        $s->config_data( xmake_exe => $xmake );
        $s->config_data( xmake_dir => File::Basename::dirname($xmake) );
        my $run = `$xmake --version`;
        my ($ver) = $run =~ m[xmake (v.+?), A cross-platform build utility based on Lua];
        $s->config_data( xmake_ver       => $ver );
        $s->config_data( xmake_installed => 1 );
    }

    sub slurp {
        my ( $s, $file ) = @_;
        open my $fh, '<', $file or die;
        local $/ = undef;
        my $cont = <$fh>;
        close $fh;
        return $cont;
    }

    # Module::Build subclass
    sub ACTION_xmake_install {
        my ($s) = @_;

        #~ ddx $s->config_data;
        return 1 if $s->config_data('xmake_install');
        #
        my $os = $s->os_type;    # based on Perl::OSType
        if ( !defined $os ) {
            $s->log_warn(
                q[Whoa. Perl has no idea what this OS is so... let's try installing with a shell script and hope for the best!]
            );
            exit 1;
        }
        elsif ( $os eq 'Windows' ) {
            $s->config_data( xmake_type => 'share' );
            my $installer = $s->download_exe();
            my $dest      = File::Spec->rel2abs(
                File::Spec->catdir( $s->base_dir, @{ $s->share_dir->{dist} } ) );
            $s->log_info(qq[Running installer [$installer]...\n]);
            warn $s->do_system( $installer, '/NOADMIN', '/S', '/D=' . $dest );
            $s->log_info(qq[Installer complete\n]);
            push @PATH, $dest;
            my $xmake = $s->locate_xmake();
            $s->config_data( xmake_type => 'share' );
            $s->gather_info($xmake);

# D:\a\_temp\1aa1c77c-ff7b-41bc-8899-98e4cd421618.exe /NOADMIN /S /D=C:\Users\RUNNER~1\AppData\Local\Temp\xmake-15e5f277191e8a088998d0f797dd1f44b5491e17
#~ $s->warn_info('Windows is on the todo list');
#~ exit 1;
        }
        else {
            unshift @PATH, 'share/bin';
            my $xmake = $s->locate_xmake();
            if ($xmake) {
                $s->config_data( xmake_type => 'system' );
            }
            else {
                build_from_source();
                $xmake = $s->locate_xmake();
                #
                $s->config_data( xmake_type => 'share' );
            }
            $s->gather_info($xmake);
            return File::Spec->rel2abs($xmake);
        }
    }

    sub ACTION_code {
        my ($s) = @_;
        $s->depends_on('xmake_install');
        $s->SUPER::ACTION_code;
    }

    sub sudo {    # `id -u`;
        CORE::state $sudo;
        return $sudo if defined $sudo;
        $sudo = 'sudo' if !system 'sudo', '--version';
        $sudo //= '';
        return $sudo;
    }

    sub package_installer {
        CORE::state $pkg;
        return $pkg if defined $pkg;
        my %options = (
            apt        => 'apt --version',            # debian, etc.
            yum        => 'apt --version',
            zypper     => 'zypper --version',
            pacman     => 'pacman -V',                # arch, etc.
            emerge     => 'emerge -V',                # Gentoo
            pkg_termux => 'pkg list-installed',       # termux (Android)
            pkg_bsd    => 'pkg help',                 # freebsd
            nixos      => 'nix-env --version',
            apk        => 'apk --version',
            xbps       => 'xbps-install --version',
            scoop      => 'scoop --version',          # Windows
            winget     => 'winget --version',         # Windows
            brew       => 'brew --version',           # MacOS
            dnf        => 'dnf --help',               # Fedora, RHEL, OpenSUSE, CentOS
        );
        warn 'Looking for package manager...';
        no warnings 'exec';
        for my $plat ( keys %options ) {
            if ( system( $options{$plat} ) == 0 ) {
                $pkg = $plat;
                return $pkg;
            }
        }
    }

    sub build_from_source {

        # get make
        my $make;
        {
            for (qw[make gmake]) {
                if ( system( $_, '--version' ) == 0 ) {
                    $make = $_;
                    last;
                }
            }
            $make // warn 'Please install make/gmake';
        }
        my $compiler;
        {
            my ( $fh, $filename ) = tempfile();
            syswrite $fh, "#include <stdio.h>\nint main(){return 0;}";
            die 'Please install git' if system 'git', '--version';
            for (qw[gcc cc clang]) {
                if ( !system $_, qw'-x c', $filename,
                    qw'-o /dev/null -I/usr/include -I/usr/local/include' ) {
                    $compiler = $_;
                }
            }
            $compiler // warn 'Please install a C compiler';
        }
        my $git;
        {
            for (qw[git]) {
                if ( system( $_, '--version' ) == 0 ) {
                    $git = $_;
                    last;
                }
            }
            $git // warn 'Please install git';
        }
        if ( !defined $make || !defined $git || !defined $compiler ) {
            my $sudo      = sudo();
            my $installer = package_installer();
            my %options   = (
                apt => "$sudo apt install -y git build-essential libreadline-dev ccache"
                ,    # debian, etc.
                yum =>
                    "yum install -y git readline-devel ccache bzip2 && $sudo yum groupinstall -y 'Development Tools'",
                zypper =>
                    "$sudo zypper --non-interactive install git readline-devel ccache && $sudo zypper --non-interactive install -t pattern devel_C_C++",
                pacman =>
                    "$sudo pacman -S --noconfirm --needed git base-devel ncurses readline ccache"
                ,                                                                 # arch, etc.
                emerge     => "$sudo emerge -atv dev-vcs/git ccache",             # Gentoo
                pkg_termux => "$sudo pkg install -y git getconf build-essential readline ccache"
                ,                                                                 # termux (Android)
                pkg_bsd => "$sudo pkg install -y git readline ccache ncurses",    # freebsd
                nixos   => "nix-env -i git gcc readline ncurses;",
                apk     =>
                    "$sudo apk add git gcc g++ make readline-dev ncurses-dev libc-dev linux-headers",
                xbps => "$sudo xbps-install -Sy git base-devel ccache",

                #scoop  => "$sudo ",                                               # Windows
                #winget => "$sudo ",                                               # Windows
                #brew   => 'brew --version',                                       # MacOS
                #dnf    => 'dnf --help',    # Fedora, RHEL, OpenSUSE, CentOS
            );
            system $options{$installer} if defined $options{$installer};
        }

        sub get_host_speed {
            my ($host) = @_;
            my $output = `ping -c 1 -W 1 $host 2>/dev/null`;
            $output =~ /time=([\d.]+)/ if $output;
            return $1 // 65535;
        }

        sub get_fast_host {
            my $gitee_speed  = get_host_speed("gitee.com");
            my $github_speed = get_host_speed("github.com");

            #~ CORE::say "gitee.com mirror took $gitee_speed ms";
            #~ CORE::say "github.com mirror took $github_speed ms";
            if ( $gitee_speed <= $github_speed ) {
                return 'gitee.com';
            }
            else {
                return 'github.com';
            }
        }
        my $mirror = get_fast_host();
        CORE::say "Using $mirror mirror...";
        my ( $gitrepo, $gitrepo_raw );
        if ( $mirror eq 'github.com' ) {
            $gitrepo = 'https://github.com/xmake-io/xmake.git';

            #$gitrepo_raw='https://github.com/xmake-io/xmake/raw/master';
            $gitrepo_raw = 'https://fastly.jsdelivr.net/gh/xmake-io/xmake@master';
        }
        else {
            $gitrepo     = "https://gitee.com/tboox/xmake.git";
            $gitrepo_raw = "https://gitee.com/tboox/xmake/raw/master";
        }
        #
        my $projectdir = tempdir( CLEANUP => 1 );
        #
        `git clone --depth=1 -b "$branch" "$gitrepo" --recurse-submodules $projectdir`
            unless -f $projectdir;
        my $cwd = rel2abs('.');
        chdir $projectdir;
        `./configure` unless -f "$projectdir/makefile";
        chdir $cwd;    # I really should go to dist base dir
        warn 'Building with ' . $make;
        `$make -C $projectdir`;
        `$make -C $projectdir install PREFIX=$share`;
        return $share;
    }

    sub install_prebuilt {
        my $installer = package_installer();
        my $Win32 if $^O eq 'MSWin32';
        my $sudo    = sudo();
        my %options = (
            apt =>
                "$sudo add-apt-repository ppa:xmake-io/xmake && $sudo apt update && $sudo apt install xmake"
            ,                                                                   # debian, etc.
            pacman => ( $Win32 ? 'pacman -Sy mingw-w64-x86_64-xmake' : "$sudo pacman -Sy xmake" )
            ,                                                                   # arch, etc.
            emerge     => "$sudo emerge -a --autounmask dev-util/xmake",        # Gentoo
            pkg_termux => "$sudo pkg install -y xmake",                         # termux (Android)
            xbps       => "$sudo xbps-install -Sy git base-devel ccache",
            scoop      => "scoop install xmake",                                # Windows
            winget     => "winget install xmake",                               # Windows
            brew       => 'brew install xmake',                                 # MacOS
            dnf        =>
                "$sudo dnf copr enable waruqi/xmake && $sudo dnf install xmake" # Fedora, RHEL, OpenSUSE, CentOS
        );
        return $options{$installer} // ();
    }
}
1;
