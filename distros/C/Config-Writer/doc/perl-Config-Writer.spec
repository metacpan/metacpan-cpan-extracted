Name:           perl-Config-Writer
Version:        0.0.4
Release:        1%{?dist}
Summary:        Config::Writer - a module to write configuration files in an easy and safe way
License:        Distributable, see LICENSE
Group:          Development/Libraries
URL:            https://github.com/kornix/perl-Config-Writer
Source0:        Config-Writer-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:      noarch
BuildRequires:  perl(ExtUtils::MakeMaker)
Requires:       perl >= 0:5.022000
Requires:	perl(Cwd)
Requires:	perl(Fcntl)
Requires:	perl(File::Basename)
Requires:	perl(File::Temp)
Requires:	perl(IO::File)
Requires:	perl(Taint::Util)
Provides:	perl(Config::Writer)

%description
Config::Writer - a module to write configuration files in an easy and safe way

%prep
%setup -q -n Config-Writer-%{version}
rm -f pm_to_blib

%build
%{__perl} Makefile.PL INSTALLDIRS=vendor
make %{?_smp_mflags}

%install
rm -rf $RPM_BUILD_ROOT
make pure_install PERL_INSTALL_ROOT=$RPM_BUILD_ROOT
find $RPM_BUILD_ROOT -type f -name .packlist -exec rm -f {} \;
find $RPM_BUILD_ROOT -depth -type d -exec rmdir {} 2>/dev/null \;
mkdir -p $RPM_BUILD_ROOT/doc/%name
%{_fixperms} $RPM_BUILD_ROOT/*

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%doc Changes LICENSE MYMETA.json MYMETA.yml README.md doc/perl-Config-Writer.spec
%dir %{perl_vendorlib}/Config
%{perl_vendorlib}/Config/*
%{_mandir}/man3/Config*

%changelog
* Mon Sep 29 2025 Volodymyr Pidgornyi <vp@dtel-ix.net> 0.0.4
- Minor CPAN compatibility fixes;
- README.md is generated from Netbox/Config.pm now.

* Thu Sep 18 2025 Volodymyr Pidgornyi <vp@dtel-ix.net> 0.0.3-1
- PAUSE compatibility issues fixed.

* Tue Sep  2 2025 Volodymyr Pidgornyi <vp@dtel-ix.net> 0.0.2-1
- sayf() method added.

* Mon Aug 18 2025 Volodymyr Pidgornyi <vp@dtel-ix.net> 0.0.1-1
- Initial public release.
