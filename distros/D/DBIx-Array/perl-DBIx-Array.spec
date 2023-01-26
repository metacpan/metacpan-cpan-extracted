Name:           perl-DBIx-Array
Version:        0.65
Release:        1%{?dist}
Summary:        DBI Wrapper with Perl style data structure interfaces
License:        MIT
Group:          Development/Libraries
URL:            http://search.cpan.org/dist/DBIx-Array/
Source0:        http://www.cpan.org/modules/by-module/DBIx/DBIx-Array-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:      noarch
Requires:       perl(DBI)
Requires:       perl(Tie::Cache)
BuildRequires:  perl(DBD::CSV)
BuildRequires:  perl(DBI)
BuildRequires:  perl(Tie::Cache)
BuildRequires:  perl(ExtUtils::MakeMaker)
BuildRequires:  perl(IO::Scalar)
BuildRequires:  perl(Spreadsheet::WriteExcel::Simple::Tabs)
BuildRequires:  perl(SQL::Abstract)
BuildRequires:  perl(Test::Simple)
BuildRequires:  perl(Text::CSV_XS)
BuildRequires:  perl(XML::Simple)
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))

%description
This module is for people who truly understand SQL and who understand Perl
data structures. If you understand how to modify your SQL to meet your data
requirements then this module is for you. 

%prep
%setup -q -n DBIx-Array-%{version}

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
%doc LICENSE README.md
%{perl_vendorlib}/*
%{_mandir}/man3/*

%changelog
