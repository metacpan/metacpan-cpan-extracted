package CPANPLUS::Dist::Debora::Package::Debian;

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.016;
use warnings;
use utf8;

our $VERSION = '0.015';

use parent qw(CPANPLUS::Dist::Debora::Package);

use Carp qw(croak);
use Config;
use English qw(-no_match_vars);
use File::Path qw(remove_tree);
use File::Spec::Functions qw(catdir catfile);
use Text::Template 1.22 qw();
use Text::Wrap qw();

use CPANPLUS::Dist::Debora::Util
    qw(parse_version can_run run spew_utf8 is_testing);
use CPANPLUS::Error qw(error);

# Map common machine architectures to Debian architectures.
#
# Only used if "dpkg --print-architecture" is not available.
my %ARCH_FOR = (
    'aarch64' => 'arm64',
    'armv6l'  => 'armhf',
    'armv7l'  => 'armhf',
    'i386'    => 'i386',
    'i486'    => 'i386',
    'i586'    => 'i386',
    'i686'    => 'i386',
    'ppc64le' => 'ppc64el',
    's390x'   => 's390x',
    'x86_64'  => 'amd64',
);

# Map some distribution names to special package names.
#
# Taken from "/var/lib/dpkg/available" on Ubuntu 20.04.  Some modules cannot
# be built without patches.
my %PACKAGE_NAME_FOR = (
    'ack'                  => 'ack',
    'AcePerl'              => 'libace-perl',
    'AllKnowingDNS'        => 'all-knowing-dns',
    'Apache-AuthCookie'    => 'libapache2-authcookie-perl',
    'Apache-Reload'        => 'libapache2-reload-perl',
    'App-Asciio'           => 'asciio',
    'App-ccdiff'           => 'ccdiff',
    'App-Cleo'             => 'cleo',
    'App-Cme'              => 'cme',
    'App-cpanminus'        => 'cpanminus',
    'App-Inotify-Hookable' => 'inotify-hookable',
    'App-Licensecheck'     => 'licensecheck',
    'App-perlbrew'         => 'perlbrew',
    'App-perlrdf'          => 'perlrdf',
    'App-pmuninstall'      => 'pmuninstall',
    'App-Prolix'           => 'prolix',
    'App-PRT'              => 'prt',
    'App-Stacktrace'       => 'perl-stacktrace',
    'App-Whiff'            => 'whiff',
    'asterisk-perl'        => 'libasterisk-agi-perl',
    'BIND-Conf_Parser'     => 'libbind-confparser-perl',
    'BioPerl'              => 'libbio-perl-perl',
    'BioPerl-Run'          => 'libbio-perl-run-perl',
    'Carton'               => 'carton',
    'Catalyst-Runtime'     => 'libcatalyst-perl',
    'CGI'                  => 'libcgi-pm-perl',
    'Courier-Filter'       => 'courier-filter-perl',
    'cpan-listchanges'     => 'cpan-listchanges',
    'cpan-outdated'        => 'cpanoutdated',
    'Crypt-HCE_SHA'        => 'libcrypt-hcesha-perl',
    'CursesWidgets'        => 'libcurses-widgets-perl',
    'DateConvert'          => 'libdate-convert-perl',
    'DBD-SQLite'           => 'libdbd-sqlite3-perl',
    'EasyTCP'              => 'libnet-easytcp-perl',
    'Feersum'              => 'feersum',
    'File-Rename'          => 'rename',
    'GDGraph'              => 'libgd-graph-perl',
    'GDTextUtil'           => 'libgd-text-perl',
    'Gearman'              => 'libgearman-client-perl',
    'Gearman-Server'       => 'gearman-server',
    'gettext'              => 'liblocale-gettext-perl',
    'IO-Tty'               => 'libio-pty-perl',
    'libintl-perl'         => 'libintl-perl',
    'libwww-perl'          => 'libwww-perl',
    'libxml-perl'          => 'libxml-perl',
    'Mail-MtPolicyd'       => 'mtpolicyd',
    'MIDI-Perl'            => 'libmidi-perl',
    'Net-SMTP_auth'        => 'libnet-smtpauth-perl',
    'NetxAP'               => 'libnet-imap-perl',
    'NNTPClient'           => 'libnews-nntpclient-perl',
    'perl-ldap'            => 'libnet-ldap-perl',
    'Perl-Tidy'            => 'perltidy',
    'perlindex'            => 'perlindex',
    'Pinto'                => 'pinto',
    'pmtools'              => 'pmtools',
    'pod2pdf'              => 'pod2pdf',
    'podlators'            => 'podlators-perl',
    'pRPC-modules'         => 'libprpc-perl',
    'Razor2-Client-Agent'  => 'razor',
    'rpm-build-perl'       => 'libb-perlreq-perl',
    'Sepia'                => 'sepia',
    'SMTP-Server'          => 'libnet-smtp-server-perl',
    'SOCKS'                => 'libnet-socks-perl',
    'Starlet'              => 'starlet',
    'Starman'              => 'starman',
    'Template-Toolkit'     => 'libtemplate-perl',
    'Template-DBI'         => 'libtemplate-plugin-dbi-perl',
    'Template-GD'          => 'libtemplate-plugin-gd-perl',
    'Template-XML'         => 'libtemplate-plugin-xml-perl',
    'TermReadKey'          => 'libterm-readkey-perl',
    'Tk'                   => 'perl-tk',
    'Tree-DAG_Node'        => 'libtree-dagnode-perl',
    'Twiggy'               => 'twiggy',
    'Verilog-Perl'         => 'libverilog-perl',
    'W3C-LinkChecker'      => 'w3c-linkchecker',
    'X12'                  => 'libx12-parser-perl',
);

# Add virtual packages to some Perl distributions.
my %PROVIDES_FOR = (
    'App-CPANTS-Lint'   => [qw(cpants-lint)],
    'App-Nopaste'       => [qw(nopaste)],
    'BioPerl-Run'       => [qw(bioperl-run)],
    'circle-be'         => [qw(circle-backend)],
    'circle-fe-gtk'     => [qw(circle-gtk)],
    'Data-Pager'        => [qw(libdatapager-perl)],
    'GD'                => [qw(libgd-gd2-perl libgd-gd2-noxpm-perl)],
    'Hostfile-Manager'  => [qw(hostfiles)],
    'HTML-Lint'         => [qw(weblint-perl)],
    'IO-Tty'            => [qw(libio-tty-perl)],
    'libintl-perl'      => [qw(libintl-xs-perl)],
    'Mail-SPF'          => [qw(spf-tools-perl)],
    'Mail-SRS'          => [qw(srs)],
    'Markdent'          => [qw(markdent)],
    'Net-IPv4Addr'      => [qw(libnetwork-ipv4addr-perl)],
    'RTSP-Server'       => [qw(rtsp-server-perl)],
    'String-HexConvert' => [qw(libtext-string-hexconvert-perl)],
    'Text-BibTeX'       => [qw(libbtparse2 libbtparse-dev)],
    'XML-SimpleObject'  =>
        [qw(libxml-simpleobject-enhanced-perl libxml-simpleobject-libxml-perl)],
    'XML-Twig' => [qw(xml-twig-tools)],
);

# Files, that are also provided by Debian's "perl" package, cannot be
# overwritten and have to be put into "/usr/local".
my %INSTALLDIRS_FOR = map { $_ => 'site' } qw(
    Archive-Tar
    CPAN
    Digest-SHA
    Encode
    ExtUtils-MakeMaker
    ExtUtils-ParseXS
    IO-Compress
    JSON-PP
    Module-CoreList
    Pod-Checker
    Pod-Parser
    Pod-Perldoc
    Pod-Usage
    podlators
    Test-Harness
);

# Version quirks.
my %VERSION_FOR
    = ('JSON-PP' => sub { sprintf '%.5f', parse_version($_[0]) });

sub format_priority {
    my $class = shift;

    my @commands = qw(dpkg dpkg-buildpackage dh fakeroot find tar);

    my $priority = 0;
    if (@commands == grep { can_run($_) } @commands) {
        $priority = 1;
        if (-f '/etc/debian_version') {
            $priority = 2;
        }
    }

    return $priority;
}

sub create {
    my ($self, %options) = @_;

    # Populate the debian directory.
    my $ok = $self->_write_debian('changelog', $self->changelog);
    if ($ok) {
        $ok = $self->_write_debian('control', $self->control);
    }
    if ($ok) {
        $ok = $self->_write_debian('copyright', $self->copyright);
    }
    if ($ok) {
        $ok = $self->_write_debian('docs', $self->docs);
    }
    if ($ok) {
        $ok = $self->_write_debian('rules', $self->rules, oct '0755');
    }

    # Create the package.
    if ($ok) {
        my @buildpackage_cmd = qw(dpkg-buildpackage -b -nc -rfakeroot);
        push @buildpackage_cmd, '-uc';    # No signing for now.

        $ok = run(
            command => \@buildpackage_cmd,
            dir     => $self->builddir,
            verbose => $options{verbose},
        );
    }

    return $ok;
}

sub install {
    my ($self, %options) = @_;

    my $sudo_cmd    = $self->sudo_cmd;
    my @install_cmd = ($sudo_cmd, qw(dpkg --install));

    if (is_testing) {
        @install_cmd = qw(dpkg --contents);
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
            catfile($self->outputdir,
                      $self->name . q{_}
                    . $self->version . q{-}
                    . $self->revision . q{_}
                    . $self->arch
                    . q{.deb});
        }
    );

    return $outputname;
}

sub installdirs {
    my $self = shift;

    my $installdirs = $INSTALLDIRS_FOR{$self->dist_name}
        // $self->SUPER::installdirs;

    return $installdirs;
}

sub arch {
    my $self = shift;

    my $arch = $self->_read('arch', sub { $self->_get_arch });

    return $arch;
}

sub version_with_epoch {
    my $self = shift;

    my $version = $self->_read('version_with_epoch',
        sub { $self->_get_version_with_epoch });

    return $version;
}

sub revision {
    my $self = shift;

    my $revision = $self->_read('revision',
        sub { $self->build_number . $self->_get_mangled_vendor });

    return $revision;
}

sub debiandir {
    my $self = shift;

    my $debiandir = $self->_read('debiandir', sub { $self->_get_debiandir });

    return $debiandir;
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

sub _date {
    my ($self, $timestamp) = @_;

    my ($week_day, $month, $day, $time, $year) = split q{ },
        scalar gmtime $timestamp;

    my $date = sprintf '%s, %02d %s %s %s +0000', $week_day, $day, $month,
        $year, $time;

    return $date;
}

sub _fill_in {
    my ($self, $template, %vars) = @_;

    my $text = $template->fill_in(
        STRICT => 1,
        HASH   => {
            package => \$self,
            date    => $self->_date($self->last_modification),
            %vars
        },
    );

    return $text;
}

sub changelog {
    my ($self, %vars) = @_;

    my $template = Text::Template->new(
        DELIMITERS => ['[%', '%]'],
        TYPE       => 'STRING',
        SOURCE     => <<'END_TEMPLATE');
[% $package->name %] ([% $package->version_with_epoch %]-[% $package->revision %]) unstable; urgency=low

  * Package [% $package->dist_name %] [% $package->version %]

 -- [% $package->packager %]  [% $date %]

END_TEMPLATE

    my $text = $self->_fill_in($template, %vars);

    return $text;
}

sub control {
    my ($self, %vars) = @_;

    my $template = Text::Template->new(
        DELIMITERS => ['[%', '%]'],
        TYPE       => 'STRING',
        SOURCE     => <<'END_TEMPLATE');
Source: [% $package->name %]
Maintainer: [% $package->packager %]
Section: perl
Priority: optional
Build-Depends: debhelper-compat (= 12)
Standards-Version: 4.6.0
Homepage: [% $package->url %]

Package: [% $package->name %]
[%
$OUT .= 'Architecture: ';
$OUT .=  $package->is_noarch ? 'all' : 'any';
my @provides = @{$package->provides};
if (@provides) {
    $OUT .= "\n";
    $OUT .= 'Provides: ';
    $OUT .= shift @provides;
    for my $name (@provides) {
        $OUT .= ", $name";
    }
}
q{};
%]
[%
$OUT .= 'Depends: ${misc:Depends}, ${perl:Depends}';
if (!$package->is_noarch) {
    $OUT .= ', ${shlibs:Depends}';
}
my %unique_dependencies =
    map { $_->{package_name} => $_ } @{$package->dependencies};
my @dependencies =
    sort { $a->{package_name} cmp $b->{package_name} }
    grep { !$_->{is_core} } values %unique_dependencies;
for my $dependency (@dependencies) {
    my $name    = $dependency->{package_name};
    my $version = $dependency->{version};
    $OUT .= ", $name";
    if ($version) {
        $OUT .= " (>= $version)";
    }
    if ($name eq 'libdata-uuid-perl') {
        $OUT .= ' | libossp-uuid-perl';
    }
}
q{};
%]
Description: [% $package->summary %]
[%
local $Text::Wrap::unexpand = 0;
my $text = Text::Wrap::wrap(q{ }, q{ }, $package->description);
$text =~ s{^ [ ] [.]}{ \N{U+200B}.}xmsg; # Put a non-visible space before dots.
$text =~ s{^ [ ] (\h*) $}{ .$1}xmsg;     # Put a dot into empty lines.
$text;
%]
END_TEMPLATE

    my $text = $self->_fill_in($template, %vars);

    return $text;
}

sub copyright {
    my ($self, %vars) = @_;

    my $template = Text::Template->new(
        DELIMITERS => ['[%', '%]'],
        TYPE       => 'STRING',
        SOURCE     => <<'END_TEMPLATE');
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/

Files: *
[%
my @copyrights = @{$package->copyrights};
my @licenses   = @{$package->licenses};

my $is_first = 1;
for my $copyright (@copyrights) {
    my $year   = $copyright->{year};
    my $holder = $copyright->{holder};

    $OUT .= $is_first ? 'Copyright: ' : q{ } x 11;
    $OUT .= "$year $holder\n";

    $is_first = 0;
}

$OUT .= 'License: ' . $package->license . "\n";

for my $license (@licenses) {
    my $text = $package->_get_license_text($license);

    if (@licenses > 1) {
        my $name = $license->spdx_expression;
        $OUT .= "\nLicense: $name\n";
    }

    $OUT .= $text;

    if (@licenses > 1) {
        $OUT .= "\n";
    }
}
q{};
%]
END_TEMPLATE

    my $text = $self->_fill_in($template, %vars);

    return $text;
}

sub docs {
    my ($self, %vars) = @_;

    # Ignore the first changelog file, which is installed with
    # dh_installchangelogs.
    my (undef, @files) = @{$self->files_by_type('changelog')};
    push @files, @{$self->files_by_type('doc')};

    my $text = join q{}, map { $_ . "\n" } @files;

    return $text;
}

sub rules {
    my ($self, %vars) = @_;

    my $template = Text::Template->new(
        DELIMITERS => ['[%', '%]'],
        TYPE       => 'STRING',
        SOURCE     => <<'END_TEMPLATE');
#!/usr/bin/make -f

%:
	dh $@

override_dh_auto_configure:

override_dh_auto_build:

override_dh_auto_test:

override_dh_auto_install:
	mkdir -p '[% $package->_buildrootdir %]'
	tar -C '[% $package->stagingdir %]' -cf - . | tar -C '[% $package->_buildrootdir %]' -xf -
[%
my ($first_changelog) = @{$package->files_by_type('changelog')};
if ($first_changelog) {
    $OUT .= "\noverride_dh_installchangelogs:\n";
    $OUT .= "\tdh_installchangelogs $first_changelog";
}
q{};
%]
[%
my $installdirs = $package->installdirs;
if ($installdirs eq 'site') {
    my $buildrootdir = $package->_buildrootdir;
    my $debiandocdir = $package->_debiandocdir;
    my $sitedocdir   = $package->_sitedocdir;

    $OUT .= "\noverride_dh_usrlocal:\n";

    $OUT .= "\nexecute_before_dh_installdeb:\n";
    $OUT .= "\tmkdir -p '$sitedocdir' && \\\n";
    $OUT .= "\ttar -C '$debiandocdir' -cf - . | tar -C '$sitedocdir' -xf - && \\\n";
    $OUT .= "\trm -rf '$debiandocdir'\n";
    $OUT .= "\tfind '$buildrootdir' -type d -empty -delete";
}
q{};
%]
END_TEMPLATE

    my $text = $self->_fill_in($template, %vars);

    return $text;
}

sub DESTROY {
    my $self = shift;

    my $debiandir = $self->{debiandir};
    if (defined $debiandir) {
        ##no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
        eval { remove_tree($debiandir) };
    }

    $self->SUPER::DESTROY;

    return;
}

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)

sub _normalize_name {
    my ($self, $dist_name) = @_;

    my $name;
    if (exists $PACKAGE_NAME_FOR{$dist_name}) {
        $name = $PACKAGE_NAME_FOR{$dist_name};
    }
    else {
        $name = 'lib' . lc($dist_name) . '-perl';
        $name =~ tr{_}{-};
    }

    return $name;
}

sub _normalize_version {
    my ($self, $dist_version) = @_;

    my $dist_name = $self->dist_name;

    my $version
        = exists $VERSION_FOR{$dist_name}
        ? $VERSION_FOR{$dist_name}->($dist_version)
        : $self->SUPER::_normalize_version($dist_version);

    return $version;
}

sub _buildrootdir {
    my $self = shift;

    my $buildrootdir = $self->_read('_buildrootdir',
        sub { catdir($self->debiandir, $self->name) });

    return $buildrootdir;
}

sub _debiandocdir {
    my $self = shift;

    my $docdir = $self->_read('_debiandocdir',
        sub { catdir($self->_buildrootdir, 'usr', 'share', 'doc') });

    return $docdir;
}

sub _sitedocdir {
    my $self = shift;

    my $docdir = $self->_read(
        'sitedocdir',
        sub {
            catdir($self->_buildrootdir, $Config{siteprefix}, 'share', 'doc');
        }
    );

    return $docdir;
}

sub _get_debiandir {
    my $self = shift;

    my $debiandir = catdir($self->builddir, 'debian');

    # Remove a possibly existing debian directory.
    if (-e $debiandir) {
        remove_tree($debiandir);
    }

    # Create the debian directory.
    if (!mkdir $debiandir) {
        croak "Could not create '$debiandir': $OS_ERROR";
    }

    return $debiandir;
}

sub _get_arch {
    my $self = shift;

    my $arch;

    if ($self->is_noarch) {
        $arch = 'all';
    }
    else {
        my $dpkg_cmd = can_run('dpkg');
        if ($dpkg_cmd) {
            my $output   = q{};
            my @arch_cmd = ($dpkg_cmd, '--print-architecture');
            if (run(command => \@arch_cmd, buffer => \$output)) {
                chomp $output;
                $arch = $output;
            }
        }
    }

    if (!$arch) {
        my $machine = (POSIX::uname)[4];
        if (exists $ARCH_FOR{$machine}) {
            $arch = $ARCH_FOR{$machine};
        }
        else {
            croak "Unknown hardware architecture: '$machine'";
        }
    }

    return $arch;
}

sub _read_epochs {
    my $self = shift;

    my %epoch_for = ('libscalar-list-utils-perl' => 1);

    my $name;
    if (open my $fh, '<', '/var/lib/dpkg/available') {
        while (my $line = <$fh>) {
            chomp $line;

            if ($line =~ m{^ Package: \h+ (.+) $}xms) {
                $name = $1;
            }
            elsif ($line =~ m{^ Version: \h+ (\d+) :}xms) {
                my $epoch = $1;

                if (defined $name) {
                    $epoch_for{$name} = $epoch;
                    undef $name;
                }
            }
            elsif ($line eq q{}) {
                undef $name;
            }
        }
        close $fh or undef;
    }

    return \%epoch_for;
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

    my %epoch_for = %{$self->_read_epochs};
    my $epoch     = $epoch_for{$self->name} // 0;

    return $epoch;
}

sub _get_epoch {
    my $self = shift;

    my $epoch_env = $self->_get_epoch_from_env;
    my $epoch_sys = $self->_get_epoch_from_system;
    my $epoch     = $epoch_env > $epoch_sys ? $epoch_env : $epoch_sys;

    return $epoch;
}

sub _get_version_with_epoch {
    my $self = shift;

    my $version = $self->SUPER::version;

    my $epoch = $self->_get_epoch;
    if ($epoch) {
        $version = $epoch . q{:} . $version;
    }

    return $version;
}

sub _get_mangled_vendor {
    my $self = shift;

    my $vendor = lc $self->vendor;
    $vendor =~ tr{a-z0-9}{}cd;    # Remove anything but alphanumeric characters.
    $vendor =~ s{\A \d+}{}xms;    # Remove leading numbers.

    return $vendor;
}

sub _write_debian {
    my ($self, $name, $text, $mode) = @_;

    my $debiandir = $self->debiandir;

    my $ok = 0;

    if (!defined $text) {
        error("Could not render the $name file");
    }
    else {
        my $filename = catfile($debiandir, $name);
        $ok = spew_utf8($filename, $text);
        if (!$ok) {
            error("Could not create '$filename': $OS_ERROR");
        }
        else {
            if (defined $mode) {
                $ok = chmod $mode, $filename;
                if (!$ok) {
                    error("Could not chmod '$filename': $OS_ERROR");
                }
            }
        }
    }

    return $ok;
}

sub _get_license_apache_2_0 {
    my $self = shift;

    return <<'END_LICENSE';
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

On Debian systems, the complete text of version 2.0 of the Apache
License can be found in `/usr/share/common-licenses/Apache-2.0'.
END_LICENSE
}

sub _get_license_cc0_1_0 {
    my $self = shift;

    return <<'END_LICENSE';
To the extent possible under law, the author(s) have dedicated all
copyright and related and neighboring rights to this software to the
public domain worldwide. This software is distributed without any
warranty.

On Debian systems, the complete text of the CC0 1.0 Universal license
can be found in `/usr/share/common-licenses/CC0-1.0'.
END_LICENSE
}

sub _get_license_fsf {
    my ($self, $file, $version) = @_;

    my $name = q{};
    if ($file =~ m{\A GPL-}xms) {
        $name = 'GNU General Public License';
    }
    elsif ($file =~ m{\A LGPL-}xms) {
        $name = 'GNU Lesser General Public License';
    }
    else {
        croak "Unknown license: '$file'";
    }

    my $text = <<"END_LICENSE";
This is free software; you can redistribute it and/or modify it under
the terms of the $name as published by the Free Software Foundation;
either version $version of the License, or (at your option) any later
version.

On Debian systems, the complete text of version $version of the $name
can be found in `/usr/share/common-licenses/$file'.
END_LICENSE

    return Text::Wrap::wrap(q{ }, q{ }, $text);
}

sub _get_license_mozilla {
    my ($self, $file, $version) = @_;

    return <<"END_LICENSE";
This is free software; you can redistribute it and/or modify it under
the terms of the Mozilla Public License, version $version.

On Debian systems, the complete text of version $version of the Mozilla
Public License can be found in `/usr/share/common-licenses/$file'.
END_LICENSE
}

sub _get_license_perl_5 {
    my $self = shift;

    return <<'END_LICENSE';
This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself, i.e. the terms of either:

a) the GNU General Public License as published by the Free Software
   Foundation; either version 1, or (at your option) any later version,
   or

b) the "Artistic License".

On Debian systems, the complete text of version 1 of the GNU General
Public License can be found in `/usr/share/common-licenses/GPL-1'.

The complete text of the "Artistic License" can be found in
`/usr/share/common-licenses/Artistic'.
END_LICENSE
}

sub _get_license_text {
    my ($self, $license) = @_;

    my $name       = $license->spdx_expression;
    my $meta2_name = $license->meta2_name;
    if ($meta2_name eq 'open_source') {
        if ($name eq 'MPL-2.0') {
            $meta2_name = 'mozilla_2_0';
        }
    }
    elsif ($meta2_name eq 'unrestricted') {
        if ($name eq 'CC0-1.0') {
            $meta2_name = 'cc0_1_0';
        }
    }

    my %license_text_for = (
        apache_2_0  => sub { $self->_get_license_apache_2_0 },
        cc0_1_0     => sub { $self->_get_license_cc0_1_0 },
        gpl_1       => sub { $self->_get_license_fsf('GPL-1',    '1') },
        gpl_2       => sub { $self->_get_license_fsf('GPL-2',    '2') },
        gpl_3       => sub { $self->_get_license_fsf('GPL-3',    '3') },
        lgpl_2_1    => sub { $self->_get_license_fsf('LGPL-2.1', '2.1') },
        lgpl_3_0    => sub { $self->_get_license_fsf('LGPL-3',   '3.0') },
        mozilla_1_1 => sub { $self->_get_license_mozilla('MPL-1.1', '1.1') },
        mozilla_2_0 => sub { $self->_get_license_mozilla('MPL-2.0', '2.0') },
        perl_5      => sub { $self->_get_license_perl_5 },
    );

    my $text
        = exists $license_text_for{$meta2_name}
        ? $license_text_for{$meta2_name}->()
        : $license->license;
    $text =~ s{\s+ \z}{}xms;                # Remove trailing spaces.
    $text =~ s{^}{ }xmsg;                   # Indent the license text.
    $text =~ s{^ [ ] (\h*) $}{ .$1}xmsg;    # Put a dot into empty lines.

    return $text;
}

1;
__END__

=encoding UTF-8

=head1 NAME

CPANPLUS::Dist::Debora::Package::Debian - Create Debian packages

=head1 VERSION

version 0.015

=head1 SYNOPSIS

  use CPANPLUS::Dist::Debora::Package::Debian;

  my $package =
      CPANPLUS::Dist::Debora::Package::Debian->new(module => $module);

  my $ok = $package->create(verbose => 0|1);
  my $ok = $package->install(verbose => 0|1);

=head1 DESCRIPTION

This L<CPANPLUS::Dist::Debora::Package> subclass creates Debian packages from
Perl distributions.

=head1 SUBROUTINES/METHODS

=head2 format_priority

  my $priority = CPANPLUS::Dist::Debora::Package::Debian->format_priority;

Checks if the Debian package tools are available and if the system uses Debian
packages.

=head2 create

  my $ok = $package->create(verbose => 0|1);

Creates a package.

=head2 install

  my $ok = $package->install(verbose => 0|1);

Installs the package.

=head2 outputname

Returns the package filename, for example
F<~/.cpanplus/5.36.1/build/XXXX/libsome-module-perl_1.0-1cpanplus_all.deb>.

=head2 arch

  my $arch = $package->arch;

Returns "all" if the Perl distribution is hardware independent.  Otherwise
the hardware architecture is returned, for example "amd64".

=head2 version_with_epoch

  my $version = $package->version_with_epoch;

Returns the version with the epoch prepended if there is an epoch.  The epochs
are read from F</var/lib/dpkg/available> or the environment variable C<EPOCH>.

=head2 revision

  my $revision = $package->revision;

Returns the package revision, which is composed of the build number and the
suffix 'cpanplus'.

=head2 debiandir

  my $debiandir = $package->debiandir;

Returns the path to the debian subdirectory, e.g.
F<~/.cpanplus/5.36.1/build/XXXX/Some-Module-1.0/debian>.

=head2 provides

  for my $package_name (@{$package->provides}) {
    say $package_name;
  }

Returns virtual packages that are provided by this package.

=head2 changelog

  my $text = $package->changelog;

Fills in a template and returns a changelog file.

=head2 control

  my $text = $package->control;

Fills in a template and returns a control file.

=head2 copyright

  my $text = $package->copyright;

Fills in a template and returns a copyright file.

=head2 docs

  my $text = $package->docs;

Returns a docs file.

=head2 rules

  my $text = $package->rules;

Fills in a template and returns a rules file.

=head1 DIAGNOSTICS

See L<CPANPLUS::Dist::Debora> for diagnostics.

=head1 CONFIGURATION AND ENVIRONMENT

See L<CPANPLUS::Dist::Debora> for supported files and environment variables.

=head1 DEPENDENCIES

Requires the Perl modules L<CPANPLUS> and L<Text::Template> from CPAN.

Requires the operating system packages "perl", "build-essential", "debhelper",
"fakeroot" and "sudo".  The minimum supported debhelper version is 12.

=head1 INCOMPATIBILITIES

None.

=head1 BUGS AND LIMITATIONS

None known.

=head1 SEE ALSO

dpkg(1), dpkg-buildpackage(1), debhelper(7)

=head1 AUTHOR

Andreas Vögele E<lt>voegelas@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2024 Andreas Vögele

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
