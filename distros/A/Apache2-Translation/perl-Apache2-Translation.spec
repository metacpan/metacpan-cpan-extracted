%define apxs /opt/apache22-worker/sbin/apxs
%define httpd /opt/apache22-worker/sbin/httpd
%define httpd_version %(%httpd -v | perl -ne '/server\\s*version:.*?(\\d+(?:\\.\\d+)*)/i and print "$1"')
%define sysconfdir %(%{apxs} -q SYSCONFDIR)
%define libexecdir %(%{apxs} -q LIBEXECDIR)
%define includedir %(%{apxs} -q INCLUDEDIR)

%define apxs2 /opt/apache22-prefork/sbin/apxs
%define httpd2 /opt/apache22-prefork/sbin/httpd
%define httpd_version2 %(%httpd2 -v | perl -ne '/server\\s*version:.*?(\\d+(?:\\.\\d+)*)/i and print "$1"')
%define sysconfdir2 %(%{apxs2} -q SYSCONFDIR)
%define libexecdir2 %(%{apxs2} -q LIBEXECDIR)
%define includedir2 %(%{apxs2} -q INCLUDEDIR)

Name:         perl-Apache2-Translation
License:      Artistic License
Group:        Development/Libraries/Perl
Requires:     perl = %{perl_version} p_mod_perl >= 2.000002010
Requires:     perl-Class-Member perl-Tie-Cache-LRU perl-MMapDB
Requires:     perl-Apache2-ModSSL perl-BerkeleyDB perl-YAML perl-DBI
Requires:     perl-DBD-SQLite perl-Template-Toolkit
BuildRequires: perl = %{perl_version} p_mod_perl >= 2.000002010
BuildRequires: perl-Class-Member perl-Tie-Cache-LRU perl-MMapDB
BuildRequires: perl-Apache2-ModSSL perl-BerkeleyDB perl-YAML perl-DBI
BuildRequires: perl-DBD-SQLite perl-Template-Toolkit
Requires:     opt-modperl opt-apache
Autoreqprov:  on
Summary:      Apache2::Translation
Version:      0.32
Release:      2
Source:       Apache2-Translation-%{version}.tar.gz
BuildRoot:    %{_tmppath}/%{name}-%{version}-build
BuildRequires: httpd22-prefork-devel httpd22-worker-devel
BuildRequires: httpd22-prefork-config httpd22-worker-config
BuildRequires: httpd22-prefork httpd22-worker
BuildRequires: opt-modperl opt-apache

%define layout_base /opt/mod_perl
%define perl_v %(perl -e 'printf "%vd", $^V')
%define perl_arch %(perl -MConfig -e 'print $Config{archname}')
%define _mandir %layout_base/man
%define perl_sitebin %layout_base/bin

%description
Apache2::Translation



Authors:
--------
    Torsten Foertsch <torsten.foertsch@gmx.net>

%prep
%setup -n Apache2-Translation-%{version}
# ---------------------------------------------------------------------------

%build
export PERL5LIB=/opt/mod_perl
perl Makefile.PL
make &&
  t/TEST -httpd %{httpd}  -apxs %{apxs}  -httpd_conf %{sysconfdir}/original/httpd.conf  &&
  t/TEST -httpd %{httpd2} -apxs %{apxs2} -httpd_conf %{sysconfdir2}/original/httpd.conf &&
# ---------------------------------------------------------------------------

%install
[ "$RPM_BUILD_ROOT" != "/" ] && [ -d $RPM_BUILD_ROOT ] && rm -rf $RPM_BUILD_ROOT;
make DESTDIR=$RPM_BUILD_ROOT \
     INSTALLSITEARCH=%layout_base/%{perl_v}/%{perl_arch} \
     INSTALLSITELIB=%layout_base/%{perl_v} \
     INSTALLSITEBIN=%perl_sitebin \
     INSTALLSITESCRIPT=%perl_sitebin \
     INSTALLBIN=%perl_sitebin \
     INSTALLSCRIPT=%perl_sitebin \
     INSTALLSITEMAN1DIR=%_mandir/man1 \
     INSTALLSITEMAN3DIR=%_mandir/man3 \
     install
find $RPM_BUILD_ROOT%{_mandir}/man* -type f -print0 |
  xargs -0i^ %{_gzipbin} -9 ^ || true
%perl_process_packlist

%clean
[ "$RPM_BUILD_ROOT" != "/" ] && [ -d $RPM_BUILD_ROOT ] && rm -rf $RPM_BUILD_ROOT;

%files
%defattr(-, root, root)
%layout_base/%{perl_v}
%perl_sitebin/cpprov
%perl_sitebin/diffprov
%doc %{_mandir}
%doc /var/adm/perl-modules/%{name}
%doc MANIFEST README
