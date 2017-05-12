Name: perl-DBD-ODBC
Version: 1.39
Release: 1%{?dist}
Summary: ODBC Driver for Perl DBI

Group: Development/Libraries
License: GPL+ or Artistic
URL: https://metacpan.org/module/DBD::ODBC
Source0: http://cpan.metacpan.org/authors/id/M/MJ/MJEVANS/DBD-ODBC-1.39.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

# build dependencies from MEYA.yml
BuildRequires: perl(ExtUtils::MakeMaker)
BuildRequires: perl(DBI) >= 1.609
BuildRequires: perl(Test::Simple) >= 0.90
BuildRequires: unixODBC-devel > 2.2.5
Requires: perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))
Requires: perl(DBI) >= 1.6909
Requires: unixODBC > 2.2.5

%{?perl_default_filter}

%description
Provides ODBC driver for Perls DBI module.

%prep
%setup -q -n DBD-ODBC-%{version}


%build
%{__perl} Makefile.PL INSTALLDIRS=vendor OPTIMIZE="$RPM_OPT_FLAGS"
make %{?_smp_mflags}


%install
rm -rf $RPM_BUILD_ROOT
make pure_install PERL_INSTALL_ROOT=$RPM_BUILD_ROOT
find $RPM_BUILD_ROOT -type f -name .packlist -exec rm -f {} ';'
find $RPM_BUILD_ROOT -type f -name '*.bs' -a -size 0 -exec rm -f {} ';'
find $RPM_BUILD_ROOT -depth -type d -exec rmdir {} 2>/dev/null ';'
chmod -R u+w $RPM_BUILD_ROOT/*


%check
make test


%clean
rm -rf $RPM_BUILD_ROOT


%files
%defattr(-,root,root,-)
%doc Changes README examples/
%{perl_vendorarch}/*
%exclude %dir %{perl_vendorarch}/auto/
%{_mandir}/man3/*.3*


%changelog
* Sat Jul 21 2012 Michiel Beijen <michiel.beijen@otrs.com> 1.0
- Initial RPM release