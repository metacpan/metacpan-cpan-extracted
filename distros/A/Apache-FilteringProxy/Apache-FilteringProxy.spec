%define module Apache-FilteringProxy
%define name perl-%{module}
%define version 0.1
%define release 1

Packager: David Castro <arimus@apu.edu>
Summary: %{module} module for perl
Name: %{name}
Version: %{version}
Release: %{release}
License: GNU/GPL
Group: WWW/HTTP
Source: %{module}-%{version}.tar.gz
URL: http://cpan.org/modules/by-module/Apache/%{module}-%{version}.tar.gz
BuildRoot: %{_tmppath}/%{name}%{version}-root
Requires: perl >= 5.6.0

%description
%{module} module for perl

# Provide perl-specific find-{provides,requires}.
%define __find_provides /usr/lib/rpm/find-provides
%define __find_requires /usr/lib/rpm/find-requires

%prep
%setup -q -n %{module}-%{version}

%build
CFLAGS="$RPM_OPT_FLAGS" perl Makefile.PL
make
make test

%clean 
rm -rf $RPM_BUILD_ROOT

%install
rm -rf $RPM_BUILD_ROOT
eval `perl '-V:installarchlib'`
mkdir -p $RPM_BUILD_ROOT/$installarchlib
make PREFIX=$RPM_BUILD_ROOT/usr install

[ -x /usr/lib/rpm/brp-compress ] && /usr/lib/rpm/brp-compress

find $RPM_BUILD_ROOT/usr -type f -print | 
	sed "s@^$RPM_BUILD_ROOT@@g" |
	grep -v perllocal.pod > %{module}-%{version}-filelist
if [ "$(cat %{module}-%{version}-filelist)X" = "X" ] ; then
    echo "ERROR: EMPTY FILE LIST"
    exit -1
fi

%files -f %{module}-%{version}-filelist
%defattr(0600,root,root,0755)
%defattr(0644,root,root,0755)
%doc Changes MANIFEST README

%changelog
* Wed Feb 12 2003 David Castro <dcastro@apu.edu>
- created the initial RPM
