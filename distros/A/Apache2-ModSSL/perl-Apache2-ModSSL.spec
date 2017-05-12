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

Name:         perl-Apache2-ModSSL
License:      Artistic License
Group:        Development/Libraries/Perl
Requires:     perl = %{perl_version}
Requires:     opt-modperl opt-apache
Autoreqprov:  on
Summary:      Perl interface to mod_ssl
Version:      0.07
Release:      3
Source:       Apache2-ModSSL-%{version}.tar.gz
BuildRoot:    %{_tmppath}/%{name}-%{version}-build
BuildRequires: httpd22-prefork-devel httpd22-worker-devel
BuildRequires: httpd22-prefork-config httpd22-worker-config
BuildRequires: httpd22-prefork httpd22-worker
BuildRequires: opt-modperl opt-apache perl-Crypt-SSLeay

%define layout_base /opt/mod_perl
%define perl_v %(perl -e 'printf "%vd", $^V')
%define perl_arch %(perl -MConfig -e 'print $Config{archname}')
%define _mandir %layout_base/man
%define perl_sitebin %layout_base/bin

%description
Perl interface to mod_ssl



Authors:
--------
    Torsten Förtsch <torsten.foertsch@gmx.net>

%prep
%setup -n Apache2-ModSSL-%{version}
# ---------------------------------------------------------------------------

%build
export PERL5LIB=/opt/mod_perl
perl Makefile.PL -apxs "%apxs"
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
find $RPM_BUILD_ROOT%{_mandir} -type f \! -name \*.gz -print0 | xargs -0 gzip -9
%perl_process_packlist

%clean
[ "$RPM_BUILD_ROOT" != "/" ] && [ -d $RPM_BUILD_ROOT ] && rm -rf $RPM_BUILD_ROOT;

%files
%defattr(-, root, root)
%layout_base/%{perl_v}
%doc %{_mandir}
%doc /var/adm/perl-modules/%{name}
%doc MANIFEST README
