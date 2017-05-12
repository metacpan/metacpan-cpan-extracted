Name:         perl-Apache-DBI-Cache
License:      Artistic License
Group:        Development/Libraries/Perl
Provides:     p_Apache_DBI_Cache
Obsoletes:    p_Apache_DBI_Cache
Requires:     perl = %{perl_version}
Autoreqprov:  on
Summary:      Apache::DBI::Cache
Version:      0.07
Release:      1
Source:       Apache-DBI-Cache-%{version}.tar.gz
BuildRoot:    %{_tmppath}/%{name}-%{version}-build

%description
Apache::DBI::Cache caches DBI connections.

Authors:
--------
    Torsten Foertsch <torsten.foertsch@gmx.net>

%prep
%setup -n Apache-DBI-Cache-%{version}
# ---------------------------------------------------------------------------

%build
perl Makefile.PL
make && make test
# ---------------------------------------------------------------------------

%install
[ "$RPM_BUILD_ROOT" != "/" ] && [ -d $RPM_BUILD_ROOT ] && rm -rf $RPM_BUILD_ROOT;
make DESTDIR=$RPM_BUILD_ROOT install_vendor
%{_gzipbin} -9 $RPM_BUILD_ROOT%{_mandir}/man3/Apache::DBI::Cache.3pm || true
%{_gzipbin} -9 $RPM_BUILD_ROOT%{_mandir}/man3/Apache::DBI::Cache::mysql.3pm || true
%{_gzipbin} -9 $RPM_BUILD_ROOT%{_mandir}/man3/Apache::DBI::Cache::ImaDBI.3pm || true
%perl_process_packlist

%clean
[ "$RPM_BUILD_ROOT" != "/" ] && [ -d $RPM_BUILD_ROOT ] && rm -rf $RPM_BUILD_ROOT;

%files
%defattr(-, root, root)
%{perl_vendorlib}/Apache
%{perl_vendorarch}/auto/Apache
%doc %{_mandir}/man3
/var/adm/perl-modules/perl-Apache-DBI-Cache
%doc MANIFEST README
