Name:         perl-Apache2-PodBrowser
License:      Artistic License
Group:        Development/Libraries/Perl
Requires:     perl = %{perl_version} perl(Apache2::RequestRec)
Requires:     perl(ModPerl::MM) perl(Apache::TestMM)
Requires:     perl(Pod::Find) perl(Pod::Simple::HTML) perl(Test::More)
Requires:     perl(File::Spec)
Autoreqprov:  on
Summary:      Apache2::PodBrowser
Version:      0.07
Release:      1
Source:       Apache2-PodBrowser-%{version}.tar.gz
BuildRoot:    %{_tmppath}/%{name}-%{version}-build

%description
View POD documents in a WEB browser.

Authors:
--------
    Torsten Foertsch <torsten.foertsch@gmx.net>

%prep
%setup -n Apache2-PodBrowser-%{version}
# ---------------------------------------------------------------------------

%build
export PERL5LIB=/opt/mod_perl
perl Makefile.PL
make && make test
# ---------------------------------------------------------------------------

%install
[ "$RPM_BUILD_ROOT" != "/" ] && [ -d $RPM_BUILD_ROOT ] && rm -rf $RPM_BUILD_ROOT;
make DESTDIR=$RPM_BUILD_ROOT install_vendor
find $RPM_BUILD_ROOT%{_mandir}/man* -type f -print0 |
  xargs -0i^ %{_gzipbin} -9 ^ || true
%perl_process_packlist

%clean
[ "$RPM_BUILD_ROOT" != "/" ] && [ -d $RPM_BUILD_ROOT ] && rm -rf $RPM_BUILD_ROOT;

%files
%defattr(-, root, root)
%{perl_vendorlib}/Apache2
%{perl_vendorarch}/auto/Apache2
%doc %{_mandir}/man3
/var/adm/perl-modules/%{name}
%doc MANIFEST README
