Summary: Perl module to allow constructors to be defined.
Name: perl-Attribute-Constructor
Version: 0.04
Release: 2
Copyright: Perl
Group: Development/Libraries

%define realname Attribute-Constructor
Packager: Eric Anderson <eric.anderson@cordata.net>
BuildRoot: %{_tmppath}/%{name}-%{version}-root
Source: %{realname}-%{version}.tar.gz
Requires: perl
BuildArchitectures: noarch

%description
A Perl module which a programmer to mark a method in a object as
a constructor. This will cause that method to automatically
create the object, bless it, and return it. The method will work
as a static method or a virtual method

# Provide perl-specific find-{provides,requires}.
%define __find_provides /usr/lib/rpm/find-provides.perl
%define __find_requires /usr/lib/rpm/find-requires.perl

%prep
%setup -n %{realname}-%{version}

%build
CFLAGS="$RPM_OPT_FLAGS" %{__perl} Makefile.PL
make

%clean
rm -rf $RPM_BUILD_ROOT

%install
rm -rf $RPM_BUILD_ROOT
eval `%{__perl} '-V:installarchlib'`
eval `${__perl} '-V:installsitearch'`
mkdir -p $RPM_BUILD_ROOT/$installarchlib
make PREFIX=$RPM_BUILD_ROOT/usr install
rm -f $RPM_BUILD_ROOT/$installarchlib/perllocal.pod
rm -f $RPM_BUILD_ROOT/$installsitearch/auto/Attribute/Handlers/.packlist

%files
%defattr(-,root,root)
%doc Changes README
/usr/lib/perl5/*
%doc %{_mandir}/*/*

%changelog
* Wed Oct 30 2002 Eric Anderson <eric.anderson@cordata.net>
- Build for version 0.04
* Wed Oct 30 2002 Eric Anderson <eric.anderson@cordata.net>
- initial packaging of Attribute::Constructor module
