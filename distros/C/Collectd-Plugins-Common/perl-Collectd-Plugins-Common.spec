Name:       perl-Collectd-Plugins-Common
Version:    0.1001
Release:    0%{?dist}
Epoch:      0
# license auto-determination failed
License:    GPL
Group:      Development/Libraries
Summary:    Common library for Collectd perl plugins
Source:     Collectd-Plugins-Common-%{version}.tar.gz
Url:        http://search.cpan.org/dist/Collectd-Plugins-Common
BuildRoot:  %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n) 
Requires:   perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))
BuildArch:  noarch
AutoReq:    no

Requires: perl(Collectd)

BuildRequires: perl(Test::More)

%description
Common modules for Collectd::Plugins

%prep
%setup -q -n Collectd-Plugins-Common-%{version}

%build
PERL_AUTOINSTALL=--skipdeps PERL_MM_USE_DEFAULT=1 %{__perl} Makefile.PL INSTALLDIRS=vendor
make %{?_smp_mflags}

%install
rm -rf %{buildroot}

make pure_install PERL_INSTALL_ROOT=%{buildroot}
find %{buildroot} -type f -name .packlist -exec rm -f {} ';'
find %{buildroot} -depth -type d -exec rmdir {} 2>/dev/null ';'

%{_fixperms} %{buildroot}/*

%check
make test

%clean
rm -rf %{buildroot} 

%files
%defattr(-,root,root,-)
%doc Changes README 
%{perl_vendorlib}/*
%{_mandir}/man3/*.3*
###%{_mandir}/man1/*.1*
###%{_bindir}/*

# output by: date +"* \%a \%b \%d \%Y $USER"
%changelog
* Mon Dec 10 2012 fwernli 0.1001
- release

