package CPANPLUS::Dist::Slackware;

use strict;
use warnings;

our $VERSION = '1.028';

use base qw(CPANPLUS::Dist::Base);

use English qw( -no_match_vars );

use CPANPLUS::Dist::Slackware::PackageDescription;
use CPANPLUS::Dist::Slackware::Util
    qw(can_run run catdir catfile spurt filetype gzip strip);
use CPANPLUS::Error;

use Cwd qw();
use ExtUtils::Packlist;
use File::Find qw();
use Locale::Maketext::Simple ( Style => 'gettext' );
use Module::Pluggable require => 1;
use Params::Check qw();

local $Params::Check::VERBOSE = 1;

my $NONROOT_WARNING = <<'END_NONROOT_WARNING';
In order to manage packages as a non-root user, which is highly recommended,
you must have sudo and, optionally, fakeroot.
END_NONROOT_WARNING

sub format_available {
    my $missing_programs_count = 0;
    for my $program (
        qw(/sbin/makepkg /sbin/installpkg /sbin/upgradepkg /sbin/removepkg))
    {
        if ( !can_run($program) ) {
            error(
                loc(q{You do not have '%1' -- '%2' not available}, $program,
                    __PACKAGE__
                )
            );
            ++$missing_programs_count;
        }
    }
    return ( $missing_programs_count == 0 );
}

sub init {
    my $dist = shift;

    my $status = $dist->status;

    $status->mk_accessors(qw(_pkgdesc _fakeroot_cmd _plugins));

    $status->_fakeroot_cmd( can_run('fakeroot') );

    $status->_plugins( [ grep { $_->available($dist) } $dist->plugins ] );

    return 1;
}

sub prepare {
    my ( $dist, @params ) = @_;

    my $param_ref = $dist->_parse_params(@params) or die;
    my $status    = $dist->status;
    my $module    = $dist->parent;

    my $pkgdesc = CPANPLUS::Dist::Slackware::PackageDescription->new(
        module      => $module,
        installdirs => $param_ref->{installdirs},
    );
    $status->_pkgdesc($pkgdesc);

    $status->dist( $pkgdesc->outputname );

    umask oct '022';

    {

        # CPANPLUS::Dist:MM does not accept multiple options in
        # makemakerflags.  Instead, the options are passed in PERL_MM_OPT.
        # PERL_MB_OPT requires Module::Build 0.36.
        local $ENV{PERL_MM_OPT}   = $dist->_perl_mm_opt;
        local $ENV{PERL_MB_OPT}   = $dist->_perl_mb_opt;
        local $ENV{MODULEBUILDRC} = 'NONE';

        # We are not allowed to write to XML/SAX/ParserDetails.ini.
        local $ENV{SKIP_SAX_INSTALL} = 1;

        $dist->_call_plugins('pre_prepare') or return;

        $dist->SUPER::prepare(@params) or return;

        $dist->_call_plugins('post_prepare') or return;
    }

    return $status->prepared(1);
}

sub create {
    my ( $dist, @params ) = @_;

    my $param_ref = $dist->_parse_params(@params) or return;
    my $status = $dist->status;

    {

        # Some tests fail if PERL_MM_OPT and PERL_MB_OPT are set during the
        # create stage.
        delete local $ENV{PERL_MM_OPT};
        delete local $ENV{PERL_MB_OPT};
        local $ENV{MODULEBUILDRC} = 'NONE';

        $dist->SUPER::create(@params) or return;

        $status->created(0);

        $dist->_fake_install($param_ref) or return;
    }

    $dist->_compress_manual_pages($param_ref) or return;

    $dist->_install_docfiles($param_ref) or return;

    $dist->_process_installed_files($param_ref) or return;

    $dist->_make_installdir($param_ref) or return;

    $dist->_write_slack_desc($param_ref) or return;

    $dist->_call_plugins('pre_package') or return;

    $dist->_write_config_files($param_ref) or return;

    $dist->_makepkg($param_ref) or return;

    return $status->created(1);
}

sub install {
    my ( $dist, @params ) = @_;

    my $param_ref = $dist->_parse_params(@params) or return;
    my $status = $dist->status;

    $dist->_installpkg($param_ref) or return;

    return $status->installed(1);
}

sub _parse_params {
    my ( $dist, %params ) = @_;

    my $module = $dist->parent;
    my $cb     = $module->parent;
    my $conf   = $cb->configure_object;

    my $param_ref;
    {
        local $Params::Check::ALLOW_UNKNOWN = 1;
        my $tmpl = {
            force       => { default => $conf->get_conf('force') },
            verbose     => { default => $conf->get_conf('verbose') },
            keep_source => { default => 0 },
            make        => { default => $conf->get_program('make') },
            perl        => { default => $EXECUTABLE_NAME },
            installdirs => {
                default => $ENV{INSTALLDIRS} || 'vendor',
                allow => [ 'site', 'vendor' ]
            },
        };
        $param_ref = Params::Check::check( $tmpl, \%params ) or return;
    }
    return $param_ref;
}

sub _call_plugins {
    my ( $dist, $method ) = @_;

    my $status = $dist->status;
    my $module = $dist->parent;

    my $orig_dir = Cwd::cwd();
    chdir $module->status->extract or return;

    for my $plugin ( @{ $status->_plugins } ) {
        if ( $plugin->can($method) ) {
            $plugin->$method($dist) or return;
        }
    }

    chdir $orig_dir or return;

    return 1;
}

sub _perl_mm_opt {
    my $dist = shift;

    my $status  = $dist->status;
    my $pkgdesc = $status->_pkgdesc;

    my $installdirs = $pkgdesc->installdirs;
    my $INSTALLDIRS = uc $installdirs;
    my %mandir      = $pkgdesc->mandirs;

    return << "END_PERL_MM_OPT";
INSTALLDIRS=$installdirs
INSTALL${INSTALLDIRS}MAN1DIR=$mandir{1}
INSTALL${INSTALLDIRS}MAN3DIR=$mandir{3}
END_PERL_MM_OPT
}

sub _perl_mb_opt {
    my $dist = shift;

    my $status  = $dist->status;
    my $pkgdesc = $status->_pkgdesc;

    my $installdirs = $pkgdesc->{installdirs};
    my %mandir      = $pkgdesc->mandirs;

    return << "END_PERL_MB_OPT";
--installdirs $installdirs
--config install${installdirs}man1dir=$mandir{1}
--config install${installdirs}man3dir=$mandir{3}
END_PERL_MB_OPT
}

sub _fake_install {
    my ( $dist, $param_ref ) = @_;

    my $status  = $dist->status;
    my $module  = $dist->parent;
    my $pkgdesc = $status->_pkgdesc;

    my $verbose = $param_ref->{verbose};

    my $wrksrc = $module->status->extract;
    if ( !$wrksrc ) {
        error( loc(q{No dir found to operate on!}) );
        return;
    }

    my $destdir = $pkgdesc->destdir;

    my $cmd;
    my $installer_type = $module->status->installer_type;
    if ( $installer_type eq 'CPANPLUS::Dist::MM' ) {
        my $make = $param_ref->{make};
        $cmd = [ $make, 'install', "DESTDIR=$destdir" ];
    }
    elsif ( $installer_type eq 'CPANPLUS::Dist::Build' ) {
        my $perl = $param_ref->{perl};
        $cmd = [
            $perl, '-MCPANPLUS::Internals::Utils::Autoflush',
            'Build', 'install', '--destdir', $destdir,
            split( ' ', $dist->_perl_mb_opt )
        ];
    }
    else {
        error( loc( q{Unknown type '%1'}, $installer_type ) );
        return;
    }

    msg( loc( q{Staging distribution in '%1'}, $destdir ) );

    return run( $cmd, { dir => $wrksrc, verbose => $verbose } );
}

sub _makepkg {
    my ( $dist, $param_ref ) = @_;

    my $status  = $dist->status;
    my $module  = $dist->parent;
    my $cb      = $module->parent;
    my $conf    = $cb->configure_object;
    my $pkgdesc = $status->_pkgdesc;

    my $verbose    = $param_ref->{verbose};
    my $destdir    = $pkgdesc->destdir;
    my $outputname = $pkgdesc->outputname;

    my $needs_chown = 0;
    my $cmd = [ '/sbin/makepkg', '-l', 'y', '-c', 'y', $outputname ];
    if ( $EFFECTIVE_USER_ID > 0 ) {
        my $fakeroot = $status->_fakeroot_cmd;
        if ($fakeroot) {
            unshift @{$cmd}, $fakeroot;
        }
        else {
            my $sudo = $conf->get_program('sudo');
            if ($sudo) {
                unshift @{$cmd}, $sudo;
                $needs_chown = 1;
            }
            else {
                error( loc($NONROOT_WARNING) );
                return;
            }
        }
    }

    msg( loc( q{Creating package '%1'}, $outputname ) );

    my $orig_uid = $UID;
    my $orig_gid = ( split /\s+/, $GID )[0];
    if ($needs_chown) {
        my @stat = stat($destdir);
        if ( !@stat ) {
            error( loc( q{Could not stat '%1': %2}, $destdir, $OS_ERROR ) );
            return;
        }
        $orig_uid = $stat[4];
        $orig_gid = $stat[5];

        $dist->_chown_recursively( 0, 0, $destdir ) or return;
    }

    my $fail = 0;
    if ( !run( $cmd, { dir => $destdir, verbose => $verbose } ) ) {
        ++$fail;
    }

    if ($needs_chown) {
        if ( -d $destdir ) {
            if (!$dist->_chown_recursively( $orig_uid, $orig_gid, $destdir ) )
            {
                ++$fail;
            }
        }
        if ( -f $outputname ) {
            if (!$dist->_chown_recursively(
                    $orig_uid, $orig_gid, $outputname
                )
                )
            {
                ++$fail;
            }
        }
    }

    if ( !$param_ref->{keep_source} ) {

        # Keep the staging directory if something failed.
        if ( !$fail ) {
            msg( loc( q{Removing '%1'}, $destdir ) );
            if ( !$cb->_rmdir( dir => $destdir ) ) {
                ++$fail;
            }
        }
    }

    return ( $fail ? 0 : 1 );
}

sub _installpkg {
    my ( $dist, $param_ref ) = @_;

    my $status  = $dist->status;
    my $module  = $dist->parent;
    my $cb      = $module->parent;
    my $conf    = $cb->configure_object;
    my $pkgdesc = $status->_pkgdesc;

    my $verbose    = $param_ref->{verbose};
    my $outputname = $pkgdesc->outputname;

    my $cmd
        = [ '/sbin/upgradepkg', '--install-new', '--reinstall', $outputname ];
    if ( $EFFECTIVE_USER_ID > 0 ) {
        my $sudo = $conf->get_program('sudo');
        if ($sudo) {
            unshift @{$cmd}, $sudo;
        }
        else {
            error( loc($NONROOT_WARNING) );
            return;
        }
    }

    msg( loc( q{Installing package '%1'}, $outputname ) );

    return run( $cmd, { verbose => $verbose } );
}

sub _compress_manual_pages {
    my ( $dist, $param_ref ) = @_;

    my $status  = $dist->status;
    my $pkgdesc = $status->_pkgdesc;

    my %mandir = $pkgdesc->mandirs;
    my @mandirs = grep { -d $_ }
        map { catdir( $pkgdesc->destdir, $_ ) } values %mandir;

    my $fail   = 0;
    my $wanted = sub {
        my $filename = $_;
        if ( $filename !~ /\.gz$/ && ( -f $filename || -l $filename ) ) {
            if ( !( gzip($filename) && unlink $filename ) ) {
                error( loc( q{Could not compress file '%1'}, $filename ) );
                ++$fail;
            }
        }
    };
    if (@mandirs) {
        File::Find::find( $wanted, @mandirs );
    }

    return ( $fail ? 0 : 1 );
}

sub _install_docfiles {
    my ( $dist, $param_ref ) = @_;

    my $status  = $dist->status;
    my $module  = $dist->parent;
    my $cb      = $module->parent;
    my $pkgdesc = $status->_pkgdesc;

    my $wrksrc = $module->status->extract;
    if ( !$wrksrc ) {
        error( loc(q{No dir found to operate on!}) );
        return;
    }

    my @docfiles = $pkgdesc->docfiles;

    my $docdir = catdir( $pkgdesc->destdir, $pkgdesc->docdir );
    $cb->_mkdir( dir => $docdir ) or return;

    # Create README.SLACKWARE.
    my $readme = $pkgdesc->readme_slackware;
    my $readmefile = catfile( $docdir, 'README.SLACKWARE' );
    spurt( $readmefile, $readme ) or return;

    # Create perl-Some-Module.SlackBuild.
    my $script = $pkgdesc->build_script;
    my $scriptfile
        = catfile( $docdir, $pkgdesc->normalized_name . '.SlackBuild' );
    spurt( $scriptfile, $script ) or return;

    # Copy files like README and Changes.
    my $fail = 0;
    for my $docfile (@docfiles) {
        my $from = catfile( $wrksrc, $docfile );
        if ( !$cb->_copy( file => $from, to => $docdir ) ) {
            ++$fail;
        }
    }

    return ( $fail ? 0 : 1 );
}

sub _process_packlist {
    my ( $dist, $filename ) = @_;

    my $status  = $dist->status;
    my $pkgdesc = $status->_pkgdesc;

    my $destdir = $pkgdesc->destdir;

    my ($old_pl) = ExtUtils::Packlist->new($filename);
    my @keys = grep {m{^\Q$destdir\E}xms} keys %{$old_pl};
    if ( !@keys ) {
        @keys = keys %{$old_pl};
    }
    if (@keys) {
        my ($new_pl) = ExtUtils::Packlist->new();
        for my $key (@keys) {
            my $value = $old_pl->{$key};
            $key =~ s{^\Q$destdir\E}{}xms;

            # Add .gz to manual pages.
            if ( $key =~ m{/man/man}xms ) {
                if ( $key !~ m{\.gz$}xms ) {
                    $key .= '.gz';
                }
                if ( ref $value eq 'HASH' ) {
                    if (   defined $value->{type}
                        && $value->{type} eq 'link'
                        && defined $value->{from} )
                    {
                        my $from = $value->{from};
                        if ( $from =~ m{/man/man}xms ) {
                            if ( $from !~ m{\.gz$}xms ) {
                                $from .= '.gz';
                                $value->{from} = $from;
                            }
                        }
                    }
                }
            }

            if ( -e "$destdir$key" ) {
                $new_pl->{$key} = $value;
            }
        }
        $new_pl->write($filename);
    }
    return 1;
}

sub _process_installed_files {
    my ( $dist, $param_ref ) = @_;

    my $status  = $dist->status;
    my $module  = $dist->parent;
    my $cb      = $module->parent;
    my $pkgdesc = $status->_pkgdesc;

    my $destdir = $pkgdesc->destdir;

    my $orig_dir = Cwd::cwd();
    if ( !$cb->_chdir( dir => $destdir ) ) {
        return;
    }

    my $fail = 0;
    my @packlists;
    my $wanted = sub {
        my $filename = $_;

        return if $filename eq q{.};

        my @stat = lstat($filename);
        if ( !@stat ) {
            error( loc( q{Could not lstat '%1': %2}, $filename, $OS_ERROR ) );
            return;
        }

        # Skip symbolic links.
        return if -l _;

        # Sanitize the file modes.
        my $perm = ( $stat[2] & oct '0755' ) | oct '0200';
        if ( !chmod $perm, $filename ) {
            error( loc( q{Could not chmod '%1': %2}, $filename, $OS_ERROR ) );
            ++$fail;
        }

        if ( -d $filename ) {

            # Remove empty directories.
            rmdir $filename;
        }
        elsif ( -f $filename ) {
            if ( $filename eq 'perllocal.pod'
                || ( $filename =~ /\.bs$/ && -z $filename ) )
            {
                if ( !unlink $filename ) {
                    error(
                        loc(q{Could not unlink '%1': %2}, $filename,
                            $OS_ERROR
                        )
                    );
                    ++$fail;
                }
            }
            elsif ( $filename eq '.packlist' ) {
                push @packlists, $File::Find::name;
            }
            else {
                my $type = filetype($filename);
                if ( $type =~ /ELF.+(?:executable|shared object)/s ) {
                    if ( !strip($filename) ) {
                        ++$fail;
                    }
                }
            }
        }
    };
    File::Find::finddepth( $wanted, q{.} );

    for my $packlist (@packlists) {
        if ( !$dist->_process_packlist($packlist) ) {
            ++$fail;
        }
    }

    if ( !$cb->_chdir( dir => $orig_dir ) ) {
        ++$fail;
    }

    return ( $fail ? 0 : 1 );
}

sub _make_installdir {
    my ( $dist, $param_ref ) = @_;

    my $status  = $dist->status;
    my $module  = $dist->parent;
    my $cb      = $module->parent;
    my $pkgdesc = $status->_pkgdesc;

    my $installdir = catdir( $pkgdesc->destdir, 'install' );
    return $cb->_mkdir( dir => $installdir );
}

sub _write_config_files {
    my ( $dist, $param_ref ) = @_;

    my $status  = $dist->status;
    my $module  = $dist->parent;
    my $cb      = $module->parent;
    my $pkgdesc = $status->_pkgdesc;

    my $destdir = $pkgdesc->destdir;

    return 1 if !-d catdir( $destdir, 'etc' );

    my $orig_dir = Cwd::cwd();
    if ( !$cb->_chdir( dir => $destdir ) ) {
        return;
    }

    # Find and rename the configuration files.
    my $fail = 0;
    my @conffiles;
    my $wanted = sub {
        my $filename = $_;

        # Skip files that have already been renamed.
        return if $filename =~ /\.new$/;

        if ( -l $filename || -f $filename ) {
            if ( !$cb->_move( file => $filename, to => "$filename.new" ) ) {
                ++$fail;
            }
            push @conffiles, $filename;
        }
    };
    File::Find::find( { wanted => $wanted, no_chdir => 1 }, 'etc' );

    if ( !$cb->_chdir( dir => $orig_dir ) ) {
        ++$fail;
    }

    return   if $fail;
    return 1 if !@conffiles;

    @conffiles = sort { uc $a cmp uc $b } @conffiles;

    # List the configuration files in README.SLACKWARE.
    $dist->_append_config_files_to_readme_slackware(@conffiles) or return;

    # Add a config function to doinst.sh.
    my $script = $pkgdesc->config_function;
    for my $conffile (@conffiles) {
        $conffile =~ s/('+)/'"$1"'/g;    # Quote single quotes.
        $script .= "config '$conffile.new'\n";
    }

    my $installdir = catdir( $pkgdesc->destdir, 'install' );
    my $doinstfile = catfile( $installdir, 'doinst.sh' );
    return spurt( $doinstfile, { append => 1 }, $script );
}

sub _append_config_files_to_readme_slackware {
    my ( $dist, @conffiles ) = @_;

    my $status  = $dist->status;
    my $pkgdesc = $status->_pkgdesc;

    my $readme
        = "\n"
        . "Configuration files\n"
        . "-------------------\n\n"
        . "This package provides the following configuration files:\n\n"
        . join( "\n", map {"* /$_"} @conffiles ) . "\n";

    my $docdir = catdir( $pkgdesc->destdir, $pkgdesc->docdir );
    my $readmefile = catfile( $docdir, 'README.SLACKWARE' );
    return spurt( $readmefile, { append => 1 }, $readme );
}

sub _write_slack_desc {
    my ( $dist, $param_ref ) = @_;

    my $status  = $dist->status;
    my $module  = $dist->parent;
    my $cb      = $module->parent;
    my $pkgdesc = $status->_pkgdesc;

    my $installdir = catdir( $pkgdesc->destdir, 'install' );
    my $descfile = catfile( $installdir, 'slack-desc' );
    my $desc = $pkgdesc->slack_desc;
    return spurt( $descfile, $desc );
}

sub _chown_recursively {
    my ( $dist, $uid, $gid, @filenames ) = @_;

    my $module = $dist->parent;
    my $cb     = $module->parent;
    my $conf   = $cb->configure_object;

    my $cmd = [ '/bin/chown', '-R', "$uid:$gid", @filenames ];
    if ( $EFFECTIVE_USER_ID > 0 ) {
        my $sudo = $conf->get_program('sudo');
        if ($sudo) {
            unshift @{$cmd}, $sudo;
        }
        else {
            error( loc($NONROOT_WARNING) );
            return;
        }
    }
    return run($cmd);
}

1;
__END__

=head1 NAME

CPANPLUS::Dist::Slackware - Install Perl distributions on Slackware Linux

=head1 VERSION

This document describes CPANPLUS::Dist::Slackware version 1.028.

=head1 SYNOPSIS

    ### from the cpanp interactive shell
    $ cpanp
    CPAN Terminal> i Some::Module --format=CPANPLUS::Dist::Slackware

    ### using the command-line tool
    $ cpan2dist --format CPANPLUS::Dist::Slackware Some::Module
    $ sudo /sbin/installpkg /tmp/perl-Some-Module-1.0-i586-1_CPANPLUS.tgz

=head1 DESCRIPTION

Do you prefer to manage all software in your operating system's native package
format?

This CPANPLUS plugin creates Slackware compatible packages from Perl
distributions.  You can either install the created packages using the API
provided by CPANPLUS or manually with C<installpkg>.

=head2 Using CPANPLUS::Dist::Slackware

Start an interactive shell to edit the CPANPLUS settings:

    $ cpanp
    CPAN Terminal> s reconfigure

Once CPANPLUS is configured, modules can be installed.  Example:

    CPAN Terminal> i Mojolicious --format=CPANPLUS::Dist::Slackware

You can make CPANPLUS::Dist::Slackware your default format by setting the
C<dist_type> key:

    CPAN Terminal> s conf dist_type CPANPLUS::Dist::Slackware

Some Perl distributions fail to show interactive prompts if the C<verbose>
option is not set.  Thus you might want to enable verbose output:

    CPAN Terminal> s conf verbose 1

Make your changes permanent:

    CPAN Terminal> s save

User settings are stored in F<$HOME/.cpanplus/lib/CPANPLUS/Config/User.pm>.

Packages may also be created from the command-line.  Example:

    $ cpan2dist --format CPANPLUS::Dist::Slackware Mojolicious
    $ sudo /sbin/installpkg /tmp/perl-Mojolicious-7.51-x86_64-1_CPANPLUS.tgz

=head2 Managing packages as a non-root user

The C<sudo> command must be installed and configured.  If the C<fakeroot>
command is installed, packages will be built without the help of C<sudo>.
Installing packages still requires root privileges though.

=head2 Installation location

By default distributions are installed in Perl's vendor location.  Set the
"installdirs" parameter to select the site location, which is usually
F</usr/local>.

    $ cpanp
    CPAN Terminal> i EV --format=CPANPLUS::Dist::Slackware --installdirs=site

    $ env INSTALLDIRS=site cpanp i Minion --format=CPANPLUS::Dist::Slackware

    $ cpan2dist --format CPANPLUS::Dist::Slackware \
                --dist-opts installdirs=site Mojo::Pg

=head2 Documentation files

README files and changelogs are stored in a package-specific subdirectory in
F</usr/doc> or F</usr/local/doc>.  In addition, a F<README.SLACKWARE> file
that lists the package's build dependencies is supplied.

=head2 Configuration files

Few Perl distributions provide configuration files in F</etc> but if such a
distribution, e.g. Mail::SpamAssassin, is updated you have to check for new
configuration files.  The package's F<README.SLACKWARE> file lists the
configuration files.  Updated configuration files have got the filename
extension ".new" and must be merged by the system administrator.

=head1 SUBROUTINES/METHODS

=over 4

=item B<< CPANPLUS::Dist::Slackware->format_available >>

Returns a boolean indicating whether or not the Slackware Linux package
management tools are available.

    $is_available = CPANPLUS::Dist::Slackware->format_available();

=item B<< $dist->init >>

Sets up the CPANPLUS::Dist::Slackware object for use.  Creates all the
needed status accessors.

    $success = $dist->init();

Called automatically whenever a new CPANPLUS::Dist object is created.

=item B<< $dist->prepare(%params) >>

Runs C<perl Makefile.PL> or C<perl Build.PL> and determines what prerequisites
this distribution declared.

    $success = $dist->prepare(
        perl        => '/path/to/perl',
        force       => (1|0),
        verbose     => (1|0),
        installdirs => ('vendor'|'site')
    );

If you set C<force> to true, CPANPLUS will go over all the stages of the
C<prepare> process again, ignoring any previously cached results.

Returns true on success and false on failure.

You may then call C<< $dist->create >> to build the distribution.

=item B<< $dist->create(%params) >>

Builds the distribution, runs the test suite and executes C<makepkg> to create
a Slackware compatible package.  Also scans for and attempts to satisfy any
prerequisites the module may have.

    $success = $dist->create(
        perl        => '/path/to/perl',
        make        => '/path/to/make',
        skiptest    => (1|0),
        force       => (1|0),
        verbose     => (1|0),
        keep_source => (1|0)
    );

If you set C<skiptest> to true, the test stage will be skipped.  If you set
C<force> to true, C<create> will go over all the stages of the build process
again, ignoring any previously cached results.  CPANPLUS will also ignore a
bad return value from the test stage.

Returns true on success and false on failure.

You may then call C<< $dist->install >> to actually install the created
package.

=item B<< $dist->install(%params) >>

Installs the package using C<upgradepkg --install-new --reinstall>.  If the
package is already installed on the system, the existing package will be
replaced by the new package.

    $success = $dist->install(verbose => (1|0));

Returns true on success and false on failure.

=back

=head1 PLUGINS

You can write plugins to patch or customize Perl distributions.  Put your
plugins into the CPANPLUS::Dist::Slackware::Plugin namespace.  Plugins can
provide the following methods.

=over 4

=item B<< $plugin->available($dist) >>

This method, which must exist, returns true if the plugin applies to the given
distribution.

=item B<< $plugin->pre_prepare($dist) >>

Use this method to patch a distribution or to set environment variables that
help to configure the distribution.  Called before the Perl distribution is
prepared.  That is, before the command C<perl Makefile.PL> or C<perl Build.PL>
is run.  Returns true on success.

=item B<< $plugin->post_prepare($dist) >>

Use this method to, for example, unset previously set environment variables.
Called after the Perl distribution has been prepared.  Returns true on
success.

=item B<< $plugin->pre_package($dist) >>

This method is called after the Perl distribution has been installed in the
temporary staging directory and before a Slackware compatible package is
created.  Use this method to install additional files like init scripts or to
append text to the F<README.SLACKWARE> file.  Returns true on success.

=back

=head1 DIAGNOSTICS

=over 4

=item B<< In order to manage packages as a non-root user... >>

You are using CPANPLUS as a non-root user but C<sudo> is not installed.

=item B<< You do not have '/sbin/makepkg'... >>

The Slackware Linux package management tools are not installed.

=item B<< Could not chdir into DIR >>

CPANPLUS::Dist::Slackware could not change its current directory while
building the package.

=item B<< Could not create directory DIR >>

A directory could not be created.  Are the parent directory's owner or
mode bits wrong?  Is the file system mounted read-only?

=item B<< Could not create file FILE >>

A file could not be opened for writing.  Check your file and directory
permissions!

=item B<< Could not write to file FILE >>

Is a file system, e.g. F</tmp> full?

=item B<< Could not compress file FILE >>

A manual page could not be compressed.

=item B<< Failed to copy FILE1 to FILE2 >>

A file could not be copied.

=item B<< Failed to move FILE1 to FILE2 >>

A file could not be renamed.

=item B<< Could not run COMMAND >>

An external command failed to execute.

=item B<< No dir found to operate on! >>

For some reason, CPANPLUS could not extract the Perl distribution's archive
file.

=item B<< Unknown type 'CPANPLUS::Dist::WHATEVER' >>

CPANPLUS::Dist::Slackware supports CPANPLUS::Dist::MM and
CPANPLUS::Dist::Build.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Similar to the build scripts provided by L<http://slackbuilds.org/>,
CPANPLUS::Dist::Slackware respects the following environment variables:

=over 4

=item B<TMP>

The staging directory where the Perl distributions are temporarily installed.
Defaults to F<$TMPDIR/CPANPLUS> or to F</tmp/CPANPLUS> if C<$ENV{TMPDIR}> is
not set.

=item B<OUTPUT>

The package output directory where all created packages are stored.  Defaults
to F<$TMPDIR> or F</tmp>.

=item B<ARCH>

The package architecture.  Defaults to "i586" on x86-based platforms, to "arm"
on ARM-based platforms and to the output of C<uname -m> on all other
platforms.

=item B<BUILD>

The build number that is added to the filename.  Defaults to "1".

As packages may be built recursively, setting this variable is mainly useful
when all packages are rebuilt.  For example, after Perl has been upgraded.

=item B<TAG>

This tag is added to the package filename.  Defaults to "_CPANPLUS".

=item B<PKGTYPE>

The package extension.  Defaults to "tgz".  May be set to "tbz", "tlz" or
"txz".  The respective compression utility needs to be installed on the
machine.

=item B<INSTALLDIRS>

The installation destination. Can be "vendor" or "site". Defaults to "vendor".

=back

=head1 DEPENDENCIES

Requires the Slackware Linux package management tools C<makepkg>,
C<installpkg>, C<updatepkg>, and C<removepkg>.  Other required commands are
C<chown>, C<cp>, C<file>, C<make>, C<strip> and a C compiler.

In order to manage packages as a non-root user, which is highly recommended,
you must have C<sudo> and, optionally, C<fakeroot>.  You can download a script
that builds C<fakeroot> from L<http://slackbuilds.org/>.

Requires the modules CPANPLUS and Module::Pluggable from CPAN.

The lowest supported Module::Build version is 0.36.

The required modules Cwd, ExtUtils::Packlist, File::Find, File::Spec,
File::Temp, IO::Compress::Gzip, IPC:Cmd, Locale::Maketext::Simple,
Module::CoreList 2.32, Params::Check, POSIX, Text::Wrap and version 0.77 are
distributed with Perl 5.12.3 and above.

If available, the modules Parse::CPAN::Meta, Pod::Find and Pod::Simple are used.

=head1 INCOMPATIBILITIES

Packages created with CPANPLUS::Dist::Slackware may provide the same files as
packages built with scripts from L<http://slackbuilds.org/> and packages created
with C<cpan2tgz>.

=head1 SEE ALSO

cpanp(1), cpan2dist(1), sudo(8), fakeroot(1), CPANPLUS::Dist::MM,
CPANPLUS::Dist::Build, CPANPLUS::Dist::Base

=head1 AUTHOR

Andreas Voegele E<lt>voegelas@cpan.orgE<gt>

=head1 BUGS AND LIMITATIONS

Some Perl distributions fail to show interactive prompts if the C<verbose> option
is not set.  This problem has been reported as bug #47818 and bug #72095 at
L<http://rt.cpan.org/>.

Please report any bugs to C<bug-cpanplus-dist-slackware at rt.cpan.org>, or
through the web interface at L<http://rt.cpan.org/>.

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2020 Andreas Voegele

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

See http://dev.perl.org/licenses/ for more information.

=cut
