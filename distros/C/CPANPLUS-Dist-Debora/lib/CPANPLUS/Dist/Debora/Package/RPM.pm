package CPANPLUS::Dist::Debora::Package::RPM;

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.016;
use warnings;
use utf8;

our $VERSION = '0.011';

use parent qw(CPANPLUS::Dist::Debora::Package);

use Carp qw(croak);
use Config;
use English qw(-no_match_vars);
use File::Path qw(remove_tree);
use File::Spec::Functions qw(catdir catfile);
use File::Temp qw(tempdir);
use POSIX qw(uname);
use Text::Template 1.22 qw();
use Text::Wrap qw();

use CPANPLUS::Dist::Debora::Util
    qw(can_run run slurp_utf8 spew_utf8 is_testing);
use CPANPLUS::Error qw(error);

# Add some package names.
my %OBSOLETES_FOR = (
    'ack'         => [qw(perl-App-Ack)],
    'Alien-Build' => [qw{
        perl-Alien-Base
        perl-Alien-Build-Plugin-Decode-HTML
        perl-Alien-Build-Plugin-Decode-Mojo
        perl-Alien-Build-tests
    }],
    'App-Licensecheck'    => [qw(perl-App-Licensecheck)],
    'App-perlbrew'        => [qw(perl-App-perlbrew)],
    'Catalyst-Runtime'    => [qw{perl-Catalyst-Runtime-scripts}],
    'Encode'              => [qw{perl-Encode-devel perl-encoding}],
    'Module-CoreList'     => [qw{perl-Module-CoreList-tools}],
    'Mojolicious'         => [qw(perl-Test-Mojo)],
    'Perl-Critic'         => [qw(perl-Test-Perl-Critic-Policy)],
    'perl-ldap'           => [qw(perl-LDAP)],
    'Perl-Tidy'           => [qw(perltidy)],
    'TermReadKey'         => [qw(perl-TermReadKey)],
    'Razor2-Client-Agent' =>
        [qw(perl-Razor-Agent perl-razor-agents razor-agents)],
);

# Add additional capabilities to some packages.
my %PROVIDES_FOR = (
    'libwww-perl' => [qw{
        perl(LWP::Debug::TraceHTTP::Socket)
        perl(LWP::Protocol::http::Socket)
        perl(LWP::Protocol::http::SocketMethods)
    }],
    'Moose'            => [qw{perl(Moose::Conflicts)}],
    'Package-Stash'    => [qw{perl(Package::Stash::Conflicts)}],
    'XS-Parse-Keyword' => [qw{perl(:XS_Parse_Keyword_ABI_2)}],
);

sub format_priority {
    my $class = shift;

    my @commands = qw(rpm rpmbuild tar);

    my $priority = 0;
    if (@commands == grep { can_run($_) } @commands) {
        $priority = 1;
        if (-f '/etc/redhat-release' || -d '/usr/lib/rpm/suse') {
            $priority = 2;
        }
    }

    return $priority;
}

sub create {
    my ($self, %options) = @_;

    my $builddir  = $self->builddir;
    my $outputdir = $self->outputdir;
    my $rpmdir    = $self->rpmdir;
    my $sourcedir = $self->sourcedir;
    my $specfile  = catfile($outputdir, $self->name . '.spec');

    my $buildrootdir = tempdir('buildrootXXXX', DIR => $outputdir);

    my @rpmbuild_cmd = (
        'rpmbuild', '-bb',
        '-D',       "_builddir $builddir",
        '-D',       "_rpmdir $rpmdir",
        '-D',       "_sourcedir $sourcedir",
        '-D',       "_buildrootdir $buildrootdir",
        '-D',       'source_date_epoch_from_changelog 0',
        '-D',       'use_source_date_epoch_as_buildtime 1',
        '-D',       'clamp_mtime_to_source_date_epoch 1',
    );

    if ($self->installdirs eq 'site') {
        my $prefix  = $Config{siteprefix};
        my $datadir = catdir($prefix, 'share');
        push @rpmbuild_cmd, '-D', "_datadir $datadir";
    }

    push @rpmbuild_cmd, $specfile;

    my $ok = 0;

    my $spec = $self->spec;
    if (!$spec) {
        error('Could not render the spec file');
    }
    else {
        $ok = spew_utf8($specfile, $spec);
        if (!$ok) {
            error("Could not create '$specfile': $OS_ERROR");
        }
    }

    if ($ok) {
        local $ENV{SOURCE_DATE_EPOCH} = $ENV{SOURCE_DATE_EPOCH}
            // $self->last_modification;

        $ok = run(
            command => \@rpmbuild_cmd,
            dir     => $builddir,
            verbose => $options{verbose},
        );
    }

    remove_tree($buildrootdir);

    return $ok;
}

sub install {
    my ($self, %options) = @_;

    # We always pass "--force" to rpm.  The CPANPLUS option "force" is more
    # annoying than useful and thus not used here.
    my $sudo_cmd    = $self->sudo_cmd;
    my @install_cmd = ($sudo_cmd, qw(rpm --upgrade --force --verbose));

    if (is_testing) {
        @install_cmd = qw(rpm -qlvp);
    }

    push @install_cmd, $self->outputname;

    my $ok = run(command => \@install_cmd, verbose => $options{verbose});

    return $ok;
}

sub outputname {
    my $self = shift;

    my $outputname = $self->_read(
        'outputname',
        sub {
            catfile($self->rpmdir, $self->arch,
                      $self->name . q{-}
                    . $self->version . q{-}
                    . $self->release . q{.}
                    . $self->arch
                    . q{.rpm});
        }
    );

    return $outputname;
}

sub license {
    my $self = shift;

    my $license = $self->SUPER::license;

    # Fedora's rpmlint expects the licenses in reversed order.
    if ($license eq 'Artistic-1.0-Perl OR GPL-1.0-or-later') {
        $license = 'GPL-1.0-or-later OR Artistic-1.0-Perl';
    }

    return $license;
}

sub rpmdir {
    my $self = shift;

    my $rpmdir = $self->_read('rpmdir', sub { $self->_get_rpmdir });

    return $rpmdir;
}

sub arch {
    my $self = shift;

    my $arch = $self->_read(
        'arch',
        sub {
            $self->is_noarch ? 'noarch' : $self->rpm_eval('%{?_arch}')
                || (uname)[4];
        }
    );

    return $arch;
}

sub dist {
    my $self = shift;

    my $dist = $self->_read('dist', sub { $self->rpm_eval('%{?dist}') });

    return $dist;
}

sub release {
    my $self = shift;

    my $release
        = $self->_read('release', sub { $self->build_number . $self->dist });

    return $release;
}

sub epoch {
    my $self = shift;

    my $epoch = $self->_read('epoch', sub { $self->_get_epoch });

    return $epoch;
}

sub distribution {
    my $self = shift;

    my $distribution
        = $self->_read('distribution', sub { $self->_get_distribution });

    return $distribution;
}

sub provides {
    my $self = shift;

    my $dist_name = $self->dist_name;

    my @provides;
    if (exists $PROVIDES_FOR{$dist_name}) {
        push @provides, @{$PROVIDES_FOR{$dist_name}};
    }

    return \@provides;
}

sub obsoletes {
    my $self = shift;

    my $dist_name = $self->dist_name;

    my @obsoletes;
    if (exists $OBSOLETES_FOR{$dist_name}) {
        push @obsoletes, @{$OBSOLETES_FOR{$dist_name}};
    }

    return \@obsoletes;
}

sub _escape {
    my ($self, $text) = @_;

    if ($text) {
        $text =~ s{%}{%%}xmsg;

        # Insert a non-visible space before "#" characters at the start of
        # a line so that RPM doesn't interpret such lines as comments.
        $text =~ s{^ (\h*) [#]}{$1\N{U+200B}#}xmsg;
    }

    return $text;
}

sub _glob_escape {
    my ($self, $filename) = @_;

    $filename =~ s{([%*?\[\]\\])}{[$1]}xmsg;
    $filename =~ s{[ '{}]}{?}xmsg;

    return $filename;
}

sub _date {
    my ($self, $timestamp) = @_;

    my ($week_day, $month, $day, $time, $year) = split q{ },
        scalar gmtime $timestamp;

    my $date = sprintf '%s %s %02d %s', $week_day, $month, $day, $year;

    return $date;
}

sub _fill_in {
    my ($self, $template, %vars) = @_;

    my $text = $template->fill_in(
        STRICT => 1,
        HASH   => {
            escape      => \sub { $self->_escape(@_) },
            glob_escape => \sub { $self->_glob_escape(@_) },
            package     => \$self,
            date        => $self->_date($self->last_modification),
            %vars
        },
    );

    return $text;
}

sub spec {
    my ($self, %vars) = @_;

    my $template = Text::Template->new(
        DELIMITERS => ['[%', '%]'],
        TYPE       => 'STRING',
        SOURCE     => <<'END_TEMPLATE');
Name:      [% $escape->($package->name) %]
Version:   [% $escape->($package->version) %]
Release:   [% $escape->($package->release) %]
Summary:   [% $escape->($package->summary) %]
License:   [% $escape->($package->license) %]
Packager:  [% $escape->($package->packager) %]
Vendor:    [% $escape->($package->vendor) %]
URL:       [% $escape->($package->url) %]
[%
use Config;

my $perl_version   = $Config{version};
my $perl_vendorlib = $Config{installvendorlib};

my $distdir = "$perl_vendorlib/auto/share/dist/CPANPLUS-Dist-Debora";

my $has_shared_objects = (@{$package->shared_objects} > 0);

my $epoch = $package->epoch;
if ($epoch) {
    $OUT .= 'Epoch:     ' . $escape->($epoch). "\n";
}

my $distribution = $package->distribution;
if ($distribution) {
    $OUT .= '%global distribution '. $escape->($distribution) . "\n";
}

if ($package->is_noarch) {
    $OUT .= "BuildArch: noarch\n";
}

# See "Renaming/Replacing or Removing Existing Packages" in the Fedora
# documentation.
my $evr = $package->version . q{-} . $package->release;
if ($epoch) {
    $evr = $epoch . q{:} . $package->version;
}
my $escaped_evr = $escape->($evr);

for my $name (@{$package->provides}) {
    $OUT .= sprintf "Provides:  %s\n", $escape->($name);
}

for my $name (@{$package->obsoletes}) {
    $OUT .= sprintf "Provides:  %s = %s\n", $escape->($name), $escaped_evr;
    $OUT .= sprintf "Obsoletes: %s < %s\n", $escape->($name), $escaped_evr;
}

$OUT .= "AutoProv:  1\n";

# We have to use an updated perl.prov on CentOS 7.
my $perl_prov = "$distdir/perl.prov";
if (-x $perl_prov) {
    $OUT .= "%global __perllib_provides $perl_prov\n";
}

# /usr/lib/rpm/perl.req finds too many circular, internal and optional
# dependencies, but we have to add shared library dependencies to
# architecture-dependent Perl distributions.
if ($package->is_noarch) {
    $OUT .= "AutoReq:   0\n";
}
else {
    if (!$has_shared_objects) {
        $OUT .= "%global debug_package %{nil}\n";
    }
    $OUT .= "%global __perl_requires /bin/true\n";
    $OUT .= "%global __perllib_requires /bin/true\n";
    $OUT .= "%global __perltest_requires /bin/true\n";
    $OUT .= "AutoReq:   1\n";
}

$OUT .= "%if 0%{?fedora} > 0 || 0%{?rhel} > 0\n";
if ($has_shared_objects) {
    $OUT .= 'Requires:  perl(:MODULE_COMPAT_' . $escape->($perl_version) . ")\n";
}
else {
    $OUT .= "Requires:  perl-libs\n";
}
$OUT .= "%endif\n";
for my $dependency (@{$package->dependencies}) {
    if ($dependency->{is_module}) {
        $OUT .= 'Requires:  perl(' . $escape->($dependency->{module_name}) . ')';
    }
    else {
        $OUT .= 'Requires:  $escape->($dependency->{package_name})';
    }
    if ($dependency->{version}) {
        $OUT .= ' >= ' . $escape->($dependency->{version});
    }
    $OUT .= "\n";
}
$OUT .= "%{?perl_requires}\n";
q{};
%]
%{?perl_default_filter}

%description
[%
local $Text::Wrap::unexpand = 0;
$escape->(Text::Wrap::wrap(q{}, q{}, $package->description))
%]

%{?debug_package}

%prep

%build

%check

%install
tar -C '[% $escape->($package->stagingdir) %]' -cf - . | tar -C %{buildroot} -xf -

%clean

%files
%defattr(-, root, root)
[%
my %format = (
    'changelog' => '%%doc %s',
    'config'    => '%%config(noreplace) %s',
    'dir'       => '%%dir %s',
    'doc'       => '%%doc %s',
    'license'   => '%%license %s',
    'man'       => '%s*',
);
for my $file (@{$package->files}) {
    my $name = $file->{name};
    my $type = $file->{type};
    if (exists $format{$type}) {
        $OUT .= sprintf $format{$type}, $glob_escape->($name);
    }
    else {
        $OUT .= $glob_escape->($name);
    }
    $OUT .= "\n";
}
q{};
%]
%changelog
* [% $date %] [% $escape->($package->packager) %] - [% $escape->($package->version) %]-[% $escape->($package->build_number) %]
- Package [% $escape->($package->dist_name) %] [% $escape->($package->version) %]
END_TEMPLATE

    my $text = $self->_fill_in($template, %vars);

    return $text;
}

sub _get_rpmdir {
    my $self = shift;

    my $topdir = $self->rpm_eval('%{?_topdir}');

    if (!$topdir) {
        my $homedir = $ENV{HOME};
        if ($homedir) {
            $topdir = catdir($homedir, 'rpmbuild');
        }
    }

    if (!$topdir) {
        $topdir = $self->outputdir;
    }

    my $rpmdir = catdir($topdir, 'RPMS');

    return $rpmdir;
}

sub _get_epoch_from_env {
    my $self = shift;

    my $epoch = 0;
    if (defined $ENV{EPOCH} && $ENV{EPOCH} =~ m{\A \d+ \z}xms) {
        $epoch = $ENV{EPOCH};
    }

    return $epoch;
}

sub _get_epoch_from_system {
    my $self = shift;

    my $epoch   = 0;
    my $rpm_cmd = $self->rpm_cmd;
    if ($rpm_cmd) {
        my @query_cmd = ($rpm_cmd, '-q', '--qf', '%{EPOCH}', $self->name);
        my $output    = q{};

        my $ok = run(
            command  => \@query_cmd,
            buffer   => \$output,
            on_error => sub { }
        );
        if ($ok) {
            chomp $output;
            if ($output =~ m{\A \d+ \z}xms) {
                $epoch = $output;
            }
        }
    }

    return $epoch;
}

sub _get_epoch {
    my $self = shift;

    my $epoch_env = $self->_get_epoch_from_env;
    my $epoch_sys = $self->_get_epoch_from_system;
    my $epoch     = $epoch_env > $epoch_sys ? $epoch_env : $epoch_sys;

    return $epoch;
}

sub _get_distribution {
    my $self = shift;

    # Values with escaped characters are deliberately ignored.
    my $BRACKETED_REST = qr{[(] [^\\"]*}xms;
    my $PRETTY_NAME
        = qr{^ PRETTY_NAME = " ([^\\"]+?) \h* (?:$BRACKETED_REST)? " $}xms;

    my $distribution = $self->rpm_eval('%{?distribution}');
    if (!$distribution) {
        OS_RELEASE:
        for my $filename (grep {-f} qw(/etc/os-release /usr/lib/os-release)) {
            my $os_release = eval { slurp_utf8($filename) };
            if ($os_release && $os_release =~ $PRETTY_NAME) {
                $distribution = $1;
                last OS_RELEASE;
            }
        }
    }

    return $distribution;
}

1;
__END__

=encoding UTF-8

=head1 NAME

CPANPLUS::Dist::Debora::Package::RPM - Create binary RPM packages

=head1 VERSION

version 0.011

=head1 SYNOPSIS

  use CPANPLUS::Dist::Debora::Package::RPM;

  my $package =
      CPANPLUS::Dist::Debora::Package::RPM->new(module => $module);

  my $ok = $package->create(verbose => 0|1);
  my $ok = $package->install(verbose => 0|1);

=head1 DESCRIPTION

This L<CPANPLUS::Dist::Debora::Package> subclass creates binary RPM packages
from Perl distributions.

=head1 SUBROUTINES/METHODS

=head2 format_priority

  my $priority = CPANPLUS::Dist::Debora::Package::RPM->format_priority;

Checks if the RPM package tools are available and if the system uses RPM.

=head2 create

  my $ok = $package->create(verbose => 0|1);

Creates a package.

=head2 install

  my $ok = $package->install(verbose => 0|1);

Installs the package.

=head2 outputname

  my $rpm = $package->outputname;

Returns the package filename, e.g.
F<~/rpmbuild/RPMS/noarch/perl-Some-Module-1.0-1.noarch.rpm>.

=head2 rpmdir

  my $rpmdir = $package->rpmdir;

Returns the name of the directory where binary RPM package files are stored.
Defaults to F<%{_topdir}/rpmbuild/RPMS>, which is usually in your home
directory.

=head2 arch

  my $arch = $package->arch;

Returns "noarch" if the Perl distribution is hardware independent.  Otherwise
the hardware architecture is returned, for example "x86_64".

=head2 dist

  my $dist = $package->dist;

Returns the dist suffix, e.g. ".fc34" on Fedora 34 and ".mga8" on Mageia 8, or
the empty string.

=head2 release

  my $release = $package->release;

Returns the package release, which is composed of the build number and the
dist suffix.

=head2 epoch

  my $epoch = $package->epoch;

Returns the package epoch.  Taken from a previously installed package or the
environment variable C<EPOCH>.

=head2 distribution

  my $distribution = $package->distribution;

Gets and returns the distribution, for example "openSUSE Tumbleweed", from the
RPM macro C<%distribution> or the F</etc/os-release> file.

=head2 provides

  for my $capability (@{$package->provides}) {
    say $capability;
  }

Returns additional capabilities, i.e. package and module names, that are
provided by this package.

=head2 obsoletes

  for my $package_name (@{$package->obsoletes}) {
    say $package_name;
  }

Returns packages that are obsoleted by this package.

=head2 spec

  my $text = $package->spec;

Fills in a template and returns a spec file.

=head1 DIAGNOSTICS

See L<CPANPLUS::Dist::Debora> for diagnostics.

=head1 CONFIGURATION AND ENVIRONMENT

See L<CPANPLUS::Dist::Debora> for supported files and environment variables.

=head1 DEPENDENCIES

Requires the Perl modules L<CPANPLUS> and L<Text::Template> from CPAN.

Requires the operating system packages "perl", "rpm-build", "gcc", "make",
"sudo" and, if available, "perl-generators".

=head1 INCOMPATIBILITIES

None.

=head1 BUGS AND LIMITATIONS

The date in the RPM changelog is in Coordinated Universal Time (UTC).

AutoReq is enabled for architecture-dependent packages so that shared library
dependencies are added.  Unfortunately, there are some Perl distributions with
hardcoded dependencies on F</opt/bin/perl> that are picked up by AutoReq.
Create an additional RPM package that provides a symbolic link from
F</opt/bin/perl> to F</usr/bin/perl> if you need to install such Perl
distributions.

This module cannot be used in taint mode.

=head1 SEE ALSO

rpm(8), rpmbuild(8)

=head1 AUTHOR

Andreas Vögele E<lt>voegelas@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2022 Andreas Vögele

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
