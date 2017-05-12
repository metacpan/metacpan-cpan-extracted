Name:           DJabberd-Authen-LDAP
Version:        0.04
Release:        1%{?dist}
Summary:        LDAP Authentication Plugin for DJabberd
License:        Artistic
Group:          Development/Libraries
URL:            http://search.cpan.org/dist/DJabberd-Authen-LDAP/
Source0:        http://www.cpan.org/modules/by-module/DJabberd/DJabberd-Authen-LDAP-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:      noarch
BuildRequires:  perl(DJabberd) >= 0.83
BuildRequires:  perl(ExtUtils::MakeMaker)
BuildRequires:  perl(Net::LDAP) >= 0.34
Requires:       perl(DJabberd) >= 0.83
Requires:       perl(Net::LDAP) >= 0.34
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))

%description
LDAP Authentication module for DJabberd

%prep
%setup -q -n DJabberd-Authen-LDAP-%{version}

%build
%{__perl} Makefile.PL INSTALLDIRS=vendor
make %{?_smp_mflags}

%install
rm -rf $RPM_BUILD_ROOT

make pure_install PERL_INSTALL_ROOT=$RPM_BUILD_ROOT

find $RPM_BUILD_ROOT -type f -name .packlist -exec rm -f {} \;
find $RPM_BUILD_ROOT -depth -type d -exec rmdir {} 2>/dev/null \;

%{_fixperms} $RPM_BUILD_ROOT/*

%check
make test

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%doc Changes README
%{perl_vendorlib}/*
%{_mandir}/man3/*

%changelog
* Mon Feb 15 2010 Edward Rudd <rpms@outoforder.cc>  0.04-1
- Updated to 0.04

* Thu Jul 26 2007 Edward Rudd <rpms@outoforder.cc>  0.01-1
- Initial package
