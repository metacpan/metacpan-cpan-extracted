package CPANPLUS::Dist::Debora;

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.016;
use warnings;
use utf8;

our $VERSION = '0.015';

use parent qw(CPANPLUS::Dist::Base);

use Config;
use English qw(-no_match_vars);
use File::Spec;
use Module::Pluggable
    search_path => 'CPANPLUS::Dist::Debora::Package',
    sub_name    => '_formats',
    require     => 1;

use CPANPLUS::Dist::Debora::Util qw(run);
use CPANPLUS::Error qw(error msg);

my @available_formats = do {
    ##no critic (ClassHierarchies::ProhibitOneArgBless)
    my @formats = bless({})->_formats;

    # Sort the formats by priority.
    my %p = map { $_ => $_->format_priority } @formats;
    grep { $p{$_} > 0 } reverse sort { $p{$a} <=> $p{$b} } @formats;
};

sub format_available {
    my $class = shift;

    return @available_formats > 0;
}

sub init {
    my $self = shift;

    my $status = $self->status;

    $status->mk_accessors(qw(_package));

    return 1;
}

sub prepare {
    my ($self, %params) = @_;

    my $status = $self->status;
    my $module = $self->parent;
    my $format = $available_formats[0];

    my $package = $format->new(
        module       => $module,
        installdirs  => $ENV{INSTALLDIRS} // 'vendor',
        build_number => $ENV{BUILD}       // 1,
    );

    $status->_package($package);

    umask oct '022';

    # Run Makefile.PL or Build.PL.
    my $ok = do {
        my $dist_name = $package->dist_name;

        # We use PERL_MM_OPT since CPANPLUS::Dist:MM does not accept multiple
        # options in makemakerflags.  PERL_MB_OPT requires Module::Build 0.36.
        local $ENV{PERL_MM_OPT}   = $package->mm_opt;
        local $ENV{PERL_MB_OPT}   = $package->mb_opt;
        local $ENV{MODULEBUILDRC} = 'NONE';
        $params{buildflags}     = q{};
        $params{makemakerflags} = q{};

        # There are old distributions that expect "." to be in @INC.
        local $ENV{PERL_USE_UNSAFE_INC} = 1;

        # Avoid an interactive prompt.
        if ($dist_name eq 'Data-Dump-Streamer') {
            $params{buildflags} = 'DDS';
        }

        # We are not allowed to write to XML/SAX/ParserDetails.ini.
        local $ENV{SKIP_SAX_INSTALL} = 1;

        $self->SUPER::prepare(%params);
    };

    return $status->prepared($ok);
}

sub create {
    my ($self, %params) = @_;

    my $module  = $self->parent;
    my $backend = $module->parent;
    my $config  = $backend->configure_object;
    my $status  = $self->status;
    my $package = $status->_package;
    my $verbose = $params{verbose};

    my $make = $config->get_program('make') // 'make';
    my $perl = $EXECUTABLE_NAME;

    # Build and test the Perl distribution.
    my $ok = do {
        my $dist_name = $package->dist_name;

        # Some tests fail if PERL_MM_OPT and PERL_MB_OPT are set.
        delete local $ENV{PERL_MM_OPT};
        delete local $ENV{PERL_MB_OPT};
        local $ENV{MODULEBUILDRC} = 'NONE';
        $params{buildflags}     = q{};
        $params{makemakerflags} = q{};

        # There are old distributions that expect "." to be in @INC.
        local $ENV{PERL_USE_UNSAFE_INC} = 1;

        # Required by Term::ReadLine::Gnu if the history-size is set in
        # ~/.inputrc.
        local $ENV{INPUTRC} = File::Spec->devnull;

        # Dist::Zilla and Pinto require Perl 5.20.
        if ($PERL_VERSION < 5.020) {
            my $prereqs = $module->status->prereqs;
            if (defined $prereqs) {
                if ($dist_name =~ m{\A Task-Kensho}xms) {
                    delete $prereqs->{'Dist::Zilla'};
                    delete $prereqs->{'Pinto'};
                }
            }
        }

        $self->SUPER::create(%params);
    };

    if ($ok) {
        $status->created(0);

        # Install the Perl distribution in a staging directory.
        my $stagingdir = $package->stagingdir;

        my @install_cmd;
        my $installer_type = $module->status->installer_type;
        if ($installer_type eq 'CPANPLUS::Dist::MM') {
            @install_cmd = ($make, 'install', "DESTDIR=$stagingdir");
        }
        elsif ($installer_type eq 'CPANPLUS::Dist::Build') {
            @install_cmd = (
                $perl,       '-MCPANPLUS::Internals::Utils::Autoflush',
                'Build',     'install',
                '--destdir', $stagingdir,
                split q{ },  $package->mb_opt,
            );
        }
        else {
            error("Unknown installer type $installer_type");
            $ok = 0;
        }

        if ($ok) {
            $ok = run(
                command => \@install_cmd,
                dir     => $package->builddir,
                verbose => $verbose,
            );
            if ($ok) {
                $ok = $package->sanitize_stagingdir;
            }
        }

        # Create a package.
        if ($ok) {
            my $outputname = $package->outputname;
            msg("Creating '$outputname'");
            $status->dist($outputname);
            $ok = $package->create(verbose => $verbose);
        }

        $package->remove_stagingdir or $ok = 0;
    }

    return $status->created($ok);
}

sub install {
    my ($self, %params) = @_;

    my $status  = $self->status;
    my $package = $status->_package;
    my $verbose = $params{verbose};

    my $ok = 0;

    my $outputname = $package->outputname;
    if (-f $outputname) {
        msg("Installing '$outputname'");
        $ok = $package->install(verbose => $verbose);
    }
    else {
        error("File not found '$outputname'");
    }

    return $status->installed($ok);
}

1;
__END__

=encoding UTF-8

=head1 NAME

CPANPLUS::Dist::Debora - Create Debian or RPM packages from Perl modules

=head1 VERSION

version 0.015

=head1 SYNOPSIS

  ### from the cpanp interactive shell
  $ cpanp
  CPAN Terminal> i Some-Module --format=CPANPLUS::Dist::Debora

  ### using the command-line tool
  $ cpan2dist --format CPANPLUS::Dist::Debora Some-Module

  $ cd ~/rpmbuild/RPMS/noarch
  $ sudo rpm -i perl-Some-Module-1.0-1.noarch.rpm

  $ cd ~/.cpanplus/5.36.1/build/XXXX
  $ sudo dpkg -i libsome-module-perl_1.0-1cpanplus_all.deb

=head1 DESCRIPTION

This L<CPANPLUS> plugin creates Debian or RPM packages from Perl
distributions.  The created packages can be installed with CPANPLUS, dpkg or
rpm.

=head2 Usage

Install Perl distributions from an interactive shell.  The sudo command must
be installed and configured.

  $ cpanp
  CPAN Terminal> i Some-Module --format=CPANPLUS::Dist::Debora

Or create packages from the command-line.

  $ cpan2dist --format CPANPLUS::Dist::Debora Some-Module

=head2 Configuration

Start an interactive shell to edit the CPANPLUS settings.

  $ cpanp

Signature checks might be enabled by default, but many Perl distributions do
not provide signatures.

  CPAN Terminal> s conf signature 0

Some Perl distributions fail to show interactive prompts if the C<verbose>
option is not set.

  CPAN Terminal> s conf verbose 1

CPANPLUS uses less memory if the SQLite backend is enabled.

  CPAN Terminal> s conf source_engine CPANPLUS::Internals::Source::SQLite

Make CPANPLUS::Dist::Debora your default format by setting the C<dist_type>
key.

  CPAN Terminal> s conf dist_type CPANPLUS::Dist::Debora

Make your changes permanent.

  CPAN Terminal> s save

Other settings such as your CPAN mirror can be set interactively.

  CPAN Terminal> s reconfigure

The settings are stored in F<~/.cpanplus/lib/CPANPLUS/Config/User.pm>.

=head1 FREQUENTLY ASKED QUESTIONS

=head2 How can I install a specific version of a Perl distribution?

Append the version to the distribution name.

  cpanp i Some-Module-0.9

=head2 How can I install a Perl distribution from the local filesystem?

Use a file URI.

  cpanp i file:///tmp/Some-Module-1.0.tar.gz
  rm ~/.cpanplus/authors/id/UNKNOWN-ORIGIN/Some-Module-1.0.tar.gz

=head2 How can I list packages installed with CPANPLUS?

  dpkg-query -W -f '${Package} ${Version}\n' | \
  perl -anE 'say $F[0] if $F[1] =~ /cpanplus/' | sort

  rpm -qa --qf '%{NAME} %{VENDOR}\n' | \
  perl -anE 'say $F[0] if $F[1] =~ /CPANPLUS/' | sort

=head2 How can I force a manual update of the CPAN indices?

  cpanp x --update_source

=head1 SUBROUTINES/METHODS

=head2 format_available

  my $is_available = CPANPLUS::Dist::Debora->format_available;

Returns a boolean indicating whether or not the required package
management tools are available.

=head2 init

  my $ok = $dist->init;

Sets up the CPANPLUS::Dist::Debora object for use.  Called automatically
whenever a new object is created.

=head2 prepare

  my $ok = $dist->prepare(verbose => 0|1);

Runs C<perl Makefile.PL> or C<perl Build.PL> and determines what prerequisites
this distribution declared.

=head2 create

  my $ok = $dist->create(skiptest => 0|1, verbose => 0|1);

Builds the prepared distribution, runs the test suite and creates the package.
Also attempts to satisfy any prerequisites the module may have.

=head2 install

  my $ok = $dist->install(verbose => 0|1);

Installs the created package with sudo and dpkg or rpm.  If the package is
already installed on the system, the existing package will be replaced by the
new package.

=head1 DIAGNOSTICS

=over

=item B<< open3: exec failed: Argument list too long >>

CPANPLUS can hit this limit if hundreds of Perl distributions are built in one
run.  Rerun CPANPLUS or build your packages in chunks.

=item B<< Could not run 'COMMAND' >>

A system command such as dpkg or rpm could not be run.

=item B<< Could not render TEMPLATE >>

A template could not be filled in.

=item B<< Could not create 'FILE' >>

A file could not be created.

=item B<< Could not stat 'FILE' >>

File permissions could not be read.

=item B<< Could not chmod 'FILE' >>

File permissions could not be set.

=item B<< Could not remove 'FILE' >>

A file could not be removed.

=item B<< Could not traverse 'DIR' >>

A directory could not be traversed.

=item B<< File not found 'FILE' >>

A file does not exist or was removed while CPANPLUS was running.

=item B<< Unknown installer type >>

CPANPLUS::Dist::Debora supports L<CPANPLUS::Dist::Build> and
L<CPANPLUS::Dist::MM>.

=back

=head1 CONFIGURATION AND ENVIRONMENT

All files and environment variables have to be encoded in ASCII or UTF-8.

=head2 Files

=head3 ~/.rpmmacros

The macros C<%packager>, C<%distribution> and C<%vendor> are used.  RPM
packages are stored in F<%{_topdir}/RPMS>.

=head3 /etc/os-release, /usr/lib/os-release

The F<os-release> files are read unless the macro C<%distribution> is set.

=head3 /var/lib/dpkg/available

The Debian package epochs are read from F</var/lib/dpkg/available>.

=head2 Environment variables

=head3 BUILD

The build number that is added to packages as a Debian revision or RPM
release.  Defaults to 1.

As packages may be built recursively, setting this variable is mainly useful
when all packages are rebuilt after Perl has been upgraded.

=head3 EPOCH

On RPM-based systems, you might have to set the package epoch manually as
there is no standardized database that can be queried for epochs.  On
Debian-based systems, it is generally not necessary to set epochs manually.
Defaults to no package epoch.

=head3 DEBFULLNAME, NAME, GITLAB_USER_NAME

The packager's name.

=head3 DEBEMAIL, EMAIL, GITLAB_USER_EMAIL

The packager's email address.

If the packager's name is unavailable and if the email address has got the
format "name <address>", the name is taken from the email address.

If the packager's name cannot be extracted from the environment, the name is
taken from the gecos field in the password database.

=head3 INSTALLDIRS

The installation location.  Can be "vendor" or "site".  Defaults to "vendor".

=head3 SOURCE_DATE_EPOCH

Clamps timestamps to the specified Unix time.  If not set, the last
modification time of the source is used.

=head1 DEPENDENCIES

Requires Perl 5.16 and the modules L<CPANPLUS>, L<CPANPLUS::Dist::Build>,
L<Module::Pluggable>, L<Software::License> and L<Text::Template> from CPAN.
L<IPC::Run> and L<Term::ReadLine::Gnu> are recommended.

On Debian-based systems, install the packages "perl", "build-essential",
"debhelper", "fakeroot" and "sudo".  The minimum supported debhelper version
is 12.

On RPM-based systems, install the packages "perl", "rpm-build", "gcc", "make",
"sudo" and, if available, "perl-devel" and "perl-generators".

=head1 INCOMPATIBILITIES

None.

=head1 BUGS AND LIMITATIONS

You have to install the appropriate development packages yourself if you would
like to build Perl distributions that require C libraries.  For example,
install the package "libssl-dev" or "openssl-devel" if the distribution uses
the OpenSSL libraries.

Enable C<verbose> mode (see above) if you would like to get feedback while
CPANPLUS downloads the list of Perl distributions from the Comprehensive Perl
Archive Network (CPAN).  Use L<CPAN::Mini> or a repository manager to mirror
the CPAN locally.

Some Perl distributions fail to show interactive prompts if the C<verbose>
option is not set.

L<Software::LicenseUtils> recognizes a lot of common licenses but isn't
perfect.

=head1 SEE ALSO

cpanp(1), cpan2dist(1), sudo(8)

=head1 AUTHOR

Andreas Vögele E<lt>voegelas@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2024 Andreas Vögele

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
