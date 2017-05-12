# these variables are set (and configurable) using "make rpm-dist" procedure
%define ver 0.0.0
%define rel 1
%define c_p --not-used
%define m_p JUST=/an/example

%define _prefix /usr
%define _sourcedir /tmp

%define module Arch
%define m_dist Arch

Name:      perl-%module
Version:   %ver
Release:   %rel
Summary:   Perl library for GNU Arch
Group:     Development/Perl
License:   GPL
URL:       http://migo.sixbit.org/software/arch-perl/
Source:    http://migo.sixbit.org/software/arch-perl/releases/%m_dist-%version.tar.gz
Requires:  tla >= 1.1, perl >= 5.005
BuildArch: noarch
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-%(%{__id_u} -n)

%description
The Arch-Perl library allows Perl developers to create GNU Arch front-ends
in an object oriented fashion. GNU Arch is a decentralized, changeset-oriented
revision control system.

Currently, a pragmatic high-level interface is built around tla or baz.
This functionality was initially developed for ArchZoom project,
and was highly enhanced to serve AXP and ArchWay projects as well.

%define perl_vendorlib %(eval `perl -V:vendorlib`; echo $vendorlib)

%prep
%setup -q -n %m_dist-%version

%build
perl Makefile.PL PREFIX=$RPM_BUILD_ROOT%{_prefix} INSTALLDIRS=vendor
make %m_p
make test

%clean
rm -rf $RPM_BUILD_ROOT

%install
rm -rf $RPM_BUILD_ROOT
make install

# need this line to build with some rpm versions
find $RPM_BUILD_ROOT \( -name .packlist -o -name perllocal.pod \) -exec rm {} \;

%files
%defattr(-,root,root)
%perl_vendorlib/%module
%perl_vendorlib/%module.pm
%{_mandir}/*
%doc AUTHORS COPYING MANIFEST INSTALL NEWS README TODO doc/CodingStyle

%define date %(env LC_ALL=C date +"%a %b %d %Y")
%changelog
* %{date} Mikhael Goikhman <migo@homemail.com>
- auto build %{PACKAGE_VERSION}
