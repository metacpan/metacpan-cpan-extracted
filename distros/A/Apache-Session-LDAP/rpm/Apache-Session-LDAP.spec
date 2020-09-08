#==============================================================================
# Specification file for Apache::Session::LDAP
#==============================================================================

%define real_name Apache-Session-LDAP
%define real_version 0.5

#==============================================================================
# Main package
#==============================================================================
Name:           perl-%{real_name}
Version:        %{real_version}
Release:        1%{?dist}
Summary:        LDAP implementation of Apache::Session
Group:          Applications/System
License:        GPL+ or Artistic
URL:            http://search.cpan.org/dist/Apache-Session-LDAP/
Source0:        http://search.cpan.org/CPAN/authors/id/C/CO/COUDOT/%{real_name}-%{real_version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}
BuildArch:      noarch

BuildRequires: perl
BuildRequires: perl(Apache::Session)
BuildRequires: perl(ExtUtils::MakeMaker)
BuildRequires: perl(Net::LDAP)

Requires: perl(Apache::Session)
Requires: perl(Net::LDAP)

%description
LDAP implementation of Apache::Session. Sessions are stored as LDAP entries
inside a branch.

%prep
%setup -n %{real_name}-%{real_version} -q

%build
perl Makefile.PL INSTALLDIRS="vendor"
%{__make} %{?_smp_mflags}

%install
rm -rf %{buildroot}
%{__make} %{?_smp_mflags}
%{__make} %{?_smp_mflags} install DESTDIR=%{buildroot}

# Remove some unwanted files
find %{buildroot} -name .packlist -exec rm -f {} \;
find %{buildroot} -name perllocal.pod -exec rm -f {} \;

%check
%{__make} %{?_smp_mflags} test

%files
%defattr(-,root,root,-)
%doc %{_mandir}/man3/Apache::Session::*.3pm.gz
%{perl_vendorlib}/Apache/Session/LDAP.pm
%{perl_vendorlib}/Apache/Session/Store/LDAP.pm

%changelog
* Sun Sep 06 2020 Clement Oudot <clem.oudot@gmail.com> - 0.5-1
- Update to 0.5
* Tue Jan 23 2018 Clement Oudot <clem.oudot@gmail.com> - 0.4-1
- Update to 0.4
* Mon Jan 12 2015 Clement Oudot <clem.oudot@gmail.com> - 0.3-1
- First package for 0.3
