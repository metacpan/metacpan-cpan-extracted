Name:         optperl-Apache2-ScoreBoardFile
License:      Artistic License
Group:        Development/Libraries/Perl
Requires:     opt-perl
BuildRequires: opt-perl  optperl-mod_perl opt-apache-prefork
BuildRequires: opt-apache-prefork-devel optperl-Bundle-BASIC
Autoreqprov:  on
Summary:      Perl interface to the Apache ScoreBoard
Version:      0.01
Release:      1
Source:       Apache2-ScoreBoardFile-%{version}.tar.gz
BuildRoot:      %{_buildrootdir}/%{name}-%{version}-%{release}.%{_arch}

# to be used with:
#   mkfifo ~/FIFO && RPM_NAME_TO=~/FIFO rpmbuild --nobuild SPEC &
#   read RPM_NAME <~/FIFO
%([ "$RPM_NAME_TO" ] &&
  echo >"$RPM_NAME_TO" \
    "%{_rpmdir}/%{_arch}/%{name}-%{version}-%{release}.%{_arch}.rpm")

%define perl /opt/perl/bin/perl
%define perllib %(%perl -MConfig -le 'print $Config{vendorlibexp}')
%define perlarch %(%perl -MConfig -le 'print $Config{vendorarchexp}')
%define perlarchlib %(%perl -MConfig -le 'print $Config{archlibexp}')
%define perlman1 %(%perl -MConfig -le 'print $Config{vendorman1direxp}')
%define perlman3 %(%perl -MConfig -le 'print $Config{vendorman3direxp}')
%define perlbin %(%perl -MConfig -le 'print $Config{vendorscriptexp}')

%define apxs /opt/apache-prefork/sbin/apxs
%define sysconfdir %(%apxs -q sysconfdir)
%define libexecdir %(%apxs -q libexecdir)
%define includedir %(%apxs -q includedir)

%description
Perl interface to the Apache ScoreBoard

%prep
%setup -q -n Apache2-ScoreBoardFile-%{version}
# ---------------------------------------------------------------------------

%build
export APACHE_TEST_NO_STICKY_PREFERENCES=1
%perl Makefile.PL -apxs=%{apxs}
make %{?jobs:-j%jobs} &&
t/TEST -apxs %{apxs} -httpd_conf %{sysconfdir}/original/httpd-modperl.conf
# ---------------------------------------------------------------------------

%install
[ "$RPM_BUILD_ROOT" != "/" ] && [ -d $RPM_BUILD_ROOT ] && rm -rf $RPM_BUILD_ROOT;
make DESTDIR=$RPM_BUILD_ROOT install_vendor
find $RPM_BUILD_ROOT%{perlman1} $RPM_BUILD_ROOT%{perlman3} -type f -print0 |
  xargs -0i^ %{_gzipbin} -9 ^ || true
rm -rf $RPM_BUILD_ROOT%{perlarchlib}

%clean
[ "$RPM_BUILD_ROOT" != "/" ] && [ -d $RPM_BUILD_ROOT ] && rm -rf $RPM_BUILD_ROOT;

%files
%defattr(-, root, root)
%{perlarch}
%doc %{perlman3}
