#------------------------------------------------------------------------------
# P A C K A G E  I N F O
#------------------------------------------------------------------------------

Summary: Collectd Riemann plugins
Name: perl-Collectd-Plugins-Riemann
Version: 0.2.3
Release: 0%{?dist}
Group: Applications/System
Packager: Fabien Wernli
License: GPL+ or Artistic
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch: noarch
AutoReq: no
Source: http://search.cpan.org/CPAN/Collectd-Plugins-Riemann-v%{version}.tar.gz

Requires: perl(Collectd)
Requires: perl(Riemann::Client)
Requires: perl(Collectd::Plugins::Common)
Requires: perl(version) >= 0.88
Requires: perl(IPC::Cmd)
Requires: perl(Socket)
BuildRequires: perl(Test::MockModule)

%description
This package contains the Riemann read plugins

%prep
%setup -q -n Collectd-Plugins-Riemann-v%{version}

#------------------------------------------------------------------------------
# B U I L D
#------------------------------------------------------------------------------

%build
PERL_MM_USE_DEFAULT=1 %{__perl} Makefile.PL INSTALLDIRS=vendor
make %{?_smp_mflags}

#------------------------------------------------------------------------------
# I N S T A L L 
#------------------------------------------------------------------------------

%install
rm -rf %{buildroot}

make pure_install PERL_INSTALL_ROOT=%{buildroot}
find %{buildroot} -type f -name .packlist -exec rm -f {} ';'
find %{buildroot} -depth -type d -exec rmdir {} 2>/dev/null ';'

### %check
### make test

%clean
rm -rf %{buildroot}

#------------------------------------------------------------------------------
# F I L E S
#------------------------------------------------------------------------------

%files
%defattr(-,root,root,-)
%doc Changes README
%{perl_vendorlib}/*
%{_mandir}/man3/*.3*

%pre

%post

%preun

%postun

%changelog
# output by: date +"* \%a \%b \%d \%Y $USER"
* Thu Feb 23 2012 fwernli 0.1001-0
- release

