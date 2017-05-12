package CPANPLUS::Dist::SUSE;
our $VERSION = '0.03';

use strict;
use warnings;
use base 'CPANPLUS::Dist::RPM';

use English;
# imports error(), msg()
use CPANPLUS::Error;
use IPC::Cmd qw{ run can_run };
use Path::Class;
use SUPER;

=head1 NAME

CPANPLUS::Dist::SUSE - To build RPM files from cpan for SUSE

=head1 VERSION

Version 0.03

=cut

=head1 SYNOPSIS

CPANPLUS::Dist::SUSE is a distribution class to create SUSE packages
from CPAN modules, and all its dependencies. This allows you to have
the most recent copies of CPAN modules installed, using your package
manager of choice, but without having to wait for central repositories
to be updated.

You can either install them using the API provided in this package, or
manually via rpm.

This is a simple module which inherits from CPANPLUS::Dist::RPM that
allows for creating RPM packages under SUSE. In particular, this
RPM spec file has been tested in SLES 11.

It also honors Module::Build if Build.PL is in the distribution.

Simple way of creating and installing a module is:

 cpan2dist --verbose --format CPANPLUS::Dist::SUSE --buildprereq --dist-opts="--replacefiles=" --install Module::Builder

"--replacefiles=" can be used when you want to install with rpm option 
"--replacefiles"

You can also check for CPANPLUS::Dist::Fedora for information.

=head1 SUBROUTINES/METHODS

=head2 format_available

Checks if /etc/SuSE-release file exists

=cut

sub format_available {

    # Check SUSE release file
    if ( !-f '/etc/SuSE-release' ) {
        error('Not on a SUSE system');
        return 0;
    }

    return super;
}

# my $bool = $self->_has_been_built;
#
# Returns true if there's already a package built for this module.
#
sub _has_been_built {
    my ( $self, $name, $vers ) = @_;

    # FIXME this entire method should be overridden to first check the local
    # rpmdb, then check the yum repos via repoquery.  As is we're pretty
    # broken right now
    #
    # For now, just call super
    return super;
}

sub _is_module_build_compat {
    my $self = shift @_;
    my $module = shift @_ || $self->parent;

    my $makefile = $module->_status->extract . '/Makefile.PL';

    #my $buildfile = $module->_status->extract . '/Build.PL';
    if ( !-f $makefile ) {
        return 0;
    }
    $makefile = file $makefile;
    my $content = $makefile->slurp;

    return $content =~ /Module::Build::Compat/;
}

=head2 install

Overrides the install method of RPM allowing for extra
rpm install arguments in dist-opts, be aware that you
need to specify it as

cpan2dist ... --dist-opts="--aid= --allfiles= --relocate=/a=/b"

        --aid --allfiles --badreloc
        --excludedocs --force -h,--hash
        --ignoresize --ignorearch --ignoreos
        --includedocs --justdb --nodeps
        --nodigest --nosignature --nosuggest
        --noorder --noscripts --notriggers
        --oldpackage --percent
        --repackage --replacefiles --replacepkgs
        --test

=cut

sub install {
    my $self                = shift @_;
    my %opts                = $self->_parse_args(@_);
    my @valid_singleoptions = (
        "--aid",       "--allfiles",     "--badreloc",    "--excludedocs",
        "--force",     "--hash",         "--ignoresize",  "--ignorearch",
        "--ignoreos",  "--includedocs",  "--justdb",      "--nodeps",
        "--nodigest",  "--nosignature",  "--nosuggest",   "--noorder",
        "--noscripts", "--notriggers",   "--oldpackage",  "--percent",
        "--repackage", "--replacefiles", "--replacepkgs", "--test"
    );

    #my $rpm = $self->status->rpm;

    my $otheropts = '';

    foreach my $o (@valid_singleoptions) {
        $otheropts .= $o if ( exists( $opts{$o} ) );
    }

    my $rpmcmd = 'rpm -Uvh ' . $otheropts . ' ' . $self->status->rpmpath;

    if ( $EUID != 0 ) {

        msg 'trying to invoke rpm via sudo';

        $rpmcmd = "sudo $rpmcmd";
    }

    my $buffer;

    my $success = run(
        command => $rpmcmd,
        verbose => $opts{verbose},
        buffer  => \$buffer,
    );

    if ( !( defined($success) ) || not $success ) {
        error "error installing! ($success)";
        printf STDERR $buffer;

        #die;
        return $self->status->installed(0);
    }

    return $self->status->installed(1);
}
1;

__DATA__
__[ spec ]__
#
# spec file for package [% status.rpmname %] (Version [% status.distvers %])
#
# Copyright (c) 2011 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#
 
# norootforbuild

Name:           [% status.rpmname %]
Version:        [% status.distvers %]
Release:        [% status.rpmvers %]%{?dist}
License:        [% status.license %]
Group:          Development/Libraries/Perl
Summary:        [% status.summary %]
Source:         http://search.cpan.org/CPAN/[% module.path %]/[% status.distname %]-%{version}.[% module.package_extension %]
Url:            http://search.cpan.org/dist/[% status.distname %]
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Requires:       perl = %(eval "`%{__perl} -V:version`"; echo $version)
[% IF status.is_noarch %]
BuildArch:  noarch
[% END -%]

[% brs = buildreqs; FOREACH br = brs.keys.sort -%]
BuildRequires: perl([% br %])[% IF (brs.$br != 0) %] >= [% brs.$br %][% END %]
[% END -%]

%description
[% status.description -%]

%prep
%setup -q -n [% status.distname %]-%{version}

%build
[% IF (!status.is_noarch) -%]
if [ -f Build.PL ]; then
    %{__perl} Build.PL --installdirs vendor
else
    [ -f Makefile.PL ] || exit 2
    %{__perl} Makefile.PL INSTALLDIRS=vendor OPTIMIZE="%{optflags}"
fi
[% ELSE -%]
if [ -f Build.PL ]; then
    %{__perl} Build.PL --installdirs vendor
else
    %{__perl} Makefile.PL INSTALLDIRS=vendor
fi
[% END -%]
if [ -f Build.PL ]; then
    ./Build build flags=%{?_smp_mflags}
else
    %{__make} %{?_smp_mflags}
fi

%install
if [ -f Build.PL ]; then
    ./Build pure_install --destdir %{buildroot}
else
    %{__make} pure_install PERL_INSTALL_ROOT=%{buildroot}
fi

find %{buildroot} -type f -name .packlist -exec rm -f {} ';'

[% IF (!status.is_noarch) -%]
find %{buildroot} -type f -name '*.bs' -a -size 0 -exec rm -f {} ';'
[% END -%]

find %{buildroot} -depth -type d -exec rmdir {} 2>/dev/null ';'

find %{buildroot}/%{perl_vendorlib} -type d > %{_tmppath}/file.list.%{name}
find %{buildroot} -type f >> %{_tmppath}/file.list.%{name}

%{__sed} -i -e 's|^%{buildroot}||g' %{_tmppath}/file.list.%{name}

%{__sed} -i -r -e 's|(/share/man/man[1-9]/.*\.[1-9]pm)$|\1.gz|; 
    s|(/share/man/man[1-9]/.*)(\.[1-9])$|\1\2.gz|' %{_tmppath}/file.list.%{name}

%{_fixperms} %{buildroot}/*

[% IF (!skiptest) -%]
%check
if [ -f Build.PL ]; then
    ./Build test
else
    %{__make} test
fi
[% END -%]

%clean
[ "$RPM_BUILD_ROOT" != "/" ] && [ -d $RPM_BUILD_ROOT ] && %{__rm} -rf $RPM_BUILD_ROOT

%files -f %{_tmppath}/file.list.%{name}
%defattr(-,root,root,-)

%changelog
* [% date %] [% packager %]
- initial SUSE packaging
- generated with cpan2dist (CPANPLUS::Dist::SUSE version [% packagervers %])

__[ pod ]__

__END__

=head1 AUTHOR

Qindel Formacion y Servicios, SL, C<< <Nito at Qindel.ES> >>

Matthias Weckbecker, <matthias@weckbecker.name>

=head1 BUGS

Please report any bugs or feature requests to C<bug-cpanplus-dist-rpm-suse at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CPANPLUS-Dist-SUSE>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CPANPLUS::Dist::SUSE

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CPANPLUS-Dist-SUSE>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CPANPLUS-Dist-SUSE>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CPANPLUS-Dist-SUSE>

=item * Search CPAN

L<http://search.cpan.org/dist/CPANPLUS-Dist-SUSE/>

=back

=head1 ACKNOWLEDGEMENTS
=head1 LICENSE AND COPYRIGHT

Copyright 2010 Qindel Formacion y Servicios, SL.

Copyright 2011 Matthias Weckbecker, <matthias@weckbecker.name>

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of CPANPLUS::Dist::SUSE
