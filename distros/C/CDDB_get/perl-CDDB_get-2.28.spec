%define module	CDDB_get
%define version 2.28
%define release 1
Summary:	%{module} module for perl
Name:		perl-%{module}
Version:	%{version}
Release:	%{release}
License:	distributable
Group:		Applications/Multimedia
Source0:	%{module}-%{version}.tar.gz
Url:		http://armin.emx.at/cddb/
BuildRoot:	%{_tmppath}/%{name}-buildroot/
Requires:	perl >= 5.6.1
BuildArch:	noarch

%description
%{module} module for perl

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
make PREFIX=$RPM_BUILD_ROOT%{_prefix} install

# call spec-helper before creating the file list
s=/usr/share/spec-helper/spec-helper ; [ -x $s ] && $s

%files 
%defattr(-,root,root)
%{_mandir}/*/*
%{_prefix}/lib/perl5/site_perl/*/auto/CDDB_get/*
%{_prefix}/lib/perl5/site_perl/*/cddb.pl
%{_prefix}/lib/perl5/site_perl/*/CDDB_get.pm
%doc Changes Copying README DATABASE

%changelog
* Tue Mar  6 19:16:36 CET 2012 Armin Obersteiner <armin(at)xos(dot)net> 2.28
* Mon Mar 11 04:14:26 MET 2002 Armin Obersteiner <armin(at)xos(dot)net> 2.01-1
* Sun Nov 25 2001 Peter Bieringer <pb@bieringer.de> 1.66-1
- initial (creditds to spec file creators of perl-DateManip)
