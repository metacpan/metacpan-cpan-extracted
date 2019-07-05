#==============================================================================
# Specification file for Apache::Session::Browseable
#==============================================================================

%define real_name Apache-Session-Browseable
%define real_version 1.3.1

#==============================================================================
# Main package
#==============================================================================
Name:           perl-%{real_name}
Version:        %{real_version}
Release:        1%{?dist}
Summary:        Add index and search methods to Apache::Session
Group:          Applications/System
License:        GPL+ or Artistic
URL:            http://search.cpan.org/dist/Apache-Session-Browseable/
Source0:        http://search.cpan.org/CPAN/authors/id/G/GU/GUIMARD/%{real_name}-%{real_version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}
BuildArch:      noarch

BuildRequires: perl
BuildRequires: perl(Apache::Session)
BuildRequires: perl(Module::Build)

Requires: perl(Apache::Session)

%description
Virutal Apache::Session backend allowing to browse sessions upon criteria.

%prep
%setup -n %{real_name}-%{real_version} -q

# Redis not mandatory

cat << \EOF > %{name}-req
#!/bin/sh
%{__perl_requires} $* |\
sed -e '/perl(Redis)/d'
EOF

%define __perl_requires %{_builddir}/%{real_name}-%{real_version}/%{name}-req
chmod +x %{__perl_requires}

%if 0%{?rhel} >= 7
%{?perl_default_filter}
%global __requires_exclude perl\\(Redis
%endif

%build
perl Build.PL --installdirs=vendor
./Build

%install
rm -rf %{buildroot}
./Build install --destdir=%{buildroot} --create_packlist=0

%check
./Build test

%files
%defattr(-,root,root,-)
%doc %{_mandir}/man3/Apache::Session::*.3pm.gz
%{perl_vendorlib}/Apache/Session/*
%{perl_vendorlib}/auto/Apache/Session/*

%changelog
* Tue Jan 23 2018 Clement Oudot <clem.oudot@gmail.com> - 1.2.8-1
- Update to 1.2.8
* Mon Jan 12 2015 Clement Oudot <clem.oudot@gmail.com> - 1.0.2-1
- First package for 1.0.2

