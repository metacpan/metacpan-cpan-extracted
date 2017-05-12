Name:           perl-DBIx-Array
Version:        0.49
Release:        1%{?dist}
Summary:        This module is a wrapper around DBI with array interfaces
License:        BSD
Group:          Development/Libraries
URL:            http://search.cpan.org/dist/DBIx-Array/
Source0:        http://www.cpan.org/modules/by-module/DBIx/DBIx-Array-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:      noarch
Requires:       perl(DBI)
Requires:       perl(Package::New)
BuildRequires:  perl(DBD::CSV)
BuildRequires:  perl(DBD::XBase)
BuildRequires:  perl(DBI)
BuildRequires:  perl(ExtUtils::MakeMaker)
BuildRequires:  perl(IO::Scalar)
BuildRequires:  perl(Package::New)
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
%doc Changes LICENSE README Todo
%{perl_vendorlib}/*
%{_mandir}/man3/*

%changelog
* Sun Apr 22 2012 Michael R. Davis (mdavis@stopllc.com) 0.24
- Updated for new version

* Fri Nov 25 2011 Michael R. Davis (mdavis@stopllc.com) 0.23-2
- Updated changelog (#754892)

* Mon Nov 21 2011 Michael R. Davis (mdavis@stopllc.com) 0.23-1
- Updated for version 0.23
- Removed hard coded requires for DBI since rpmbuild finds them from sources (#754892)

* Sun Aug 28 2011 Michael R. Davis (mdavis@stopllc.com) 0.22-1
- Created spec file with cpanspec
