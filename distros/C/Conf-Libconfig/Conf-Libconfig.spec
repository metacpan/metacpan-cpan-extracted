%define _tmppath %{_topdir}/BUILDROOT
%define pkgname Conf-Libconfig
%define NVR %{pkgname}-%{version}-%{release}
%define maketest 1

Name:           perl-Conf-Libconfig
Summary:        Perl extension for libconfig
Version:        1.1.2
Release:        1%{?dist}
Vendor:         Cnangel <cnangel@gmail.com>
Packager:       Cnangel <cnangel@gmail.com>
License:        BSD
URL:            https://github.com/cnangel/Conf-Libconfig
Source0:        %{name}-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%(id -u -n)
Prefix:         %{_prefix}

BuildRequires:  gcc
BuildRequires:  make
BuildRequires:  libconfig-devel
BuildRequires:  perl-devel
BuildRequires:  perl-generators
BuildRequires:  perl(ExtUtils::MakeMaker)
BuildRequires:  perl(ExtUtils::PkgConfig)
BuildRequires:  perl(Test::Deep)
BuildRequires:  perl(Test::Exception)
BuildRequires:  perl(Test::More)
BuildRequires:  perl(Test::Warn)
BuildRequires:  perl(Data::Dumper)
BuildRequires:  perl(Exporter)
BuildRequires:  perl(XSLoader)

%description
Conf::Libconfig is a Perl extension for the libconfig C library.
It supports Scalar, Array, Hash and List data structures, and provides
full bindings to libconfig 1.8.x including options, formatting,
safe getters, and error handling.

%prep
%setup -q

%build
perl Makefile.PL INSTALLDIRS=vendor NO_PACKLIST=1 NO_PERLLOCAL=1
%{make_build}

%check
%if %maketest
%{__make} test
%endif

%install
rm -rf %{buildroot}
%{make_install}
# Remove files not intended for packaging
find %{buildroot} -name '.packlist' -delete 2>/dev/null || true
find %{buildroot} -name 'perllocal.pod' -delete 2>/dev/null || true
find %{buildroot} -name '*.bs' -delete 2>/dev/null || true

%clean
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

%files
%defattr(-,root,root)
%doc Changes.md README.md
%{perl_vendorarch}/auto/Conf/Libconfig/Libconfig.so
%{perl_vendorarch}/Conf/Libconfig.pm
%{_mandir}/man3/Conf::Libconfig.3pm.gz

%changelog
* Tue May 20 2026 Cnangel <cnangel@gmail.com> 1.1.2-1
- Fix set_hook/get_hook to use config-level API
- Fix get_item zero-value bug via config_setting_get_elem + type check
- Fix auto_check_and_create strrchr -> strchr path resolution
- Add bindings: set_destructor, set_include_func, set_fatal_error_func, get_elem, setting hooks
- Add Devel::CheckLib configure-time check for libconfig
- Clean up dead commented-out code

* Sat May 16 2026 Cnangel <cnangel@gmail.com> 1.1.1-1
- Fix version guards for multi-version libconfig compatibility (1.1.x ~ 1.8.x)
- Fix config_setting_lookup_int type for pre-1.4 (long* vs int*)
- Fix config_setting_source_file, config_set_default_format, config_setting_lookup guards
- Fix config_set_hook to use config_setting_set_hook
- Add version guards for error_type/error_file (1.4+)

* Fri May 15 2026 Cnangel <cnangel@gmail.com> 1.1.0-1
- Upgrade to support libconfig 1.8.x API
- Add options, format, precision, tab_width, hook, clear, error handling
- Add setting-level lookup, safe getters, type checks, source info
- Add CONFIG_FORMAT_* and CONFIG_OPTION_* constants
- Fix stray semicolon bugs in get_general_list and get_general_object
- Optimize fragile type detection logic
- Switch build system to ExtUtils::MakeMaker

* Sun Sep 03 2023 Cnangel <cnangel@gmail.com> 1.0.3-1
- Fix some issues.

* Sun Mar 19 2023 Cnangel <cnangel@gmail.com> 1.0.0-1
- Upgrade version 1.0.0

* Sun Mar 19 2023 Cnangel <cnangel@gmail.com> 0.200-1
- Update general value.

* Sun May 29 2022 Cnangel <cnangel@gmail.com> 0.101-1
- Update for libconfig-1.7.3

* Mon Aug 5 2013 cnangel@localhost.localdomain
- Initial build.