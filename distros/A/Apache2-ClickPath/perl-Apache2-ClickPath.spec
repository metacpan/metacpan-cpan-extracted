%define instbase %(perl -Mmod_perl2 -MConfig -e '$d=$INC{"mod_perl2.pm"};$d=~s!(?:/[^/]+){2}$!!; print($d=~m!^/opt!?$d:$Config{vendorlib});')
%define archbase %(perl -Mmod_perl2 -MConfig -e '$d=$INC{"mod_perl2.pm"};$d=~s!(?:/[^/]+){1}$!!; print($d=~m!^/opt!?$d:$Config{vendorarch});')
%define binbase  %(perl -Mmod_perl2 -MConfig -e '$d=$INC{"mod_perl2.pm"};$d=~s!(?:/[^/]+){3}$!!; print($d=~m!^/opt!?$d."/bin":$Config{vendorbin});')
%define manbase  %(perl -Mmod_perl2 -MConfig -e '$d=$INC{"mod_perl2.pm"};$d=~s!(?:/[^/]+){3}$!!; print($d=~m!^/opt!?$d."/man":do{$x=$Config{vendorman3dir}; $x=~s!/[/]+$!!;$x;});')
%define namebase %(perl -Mmod_perl2 -e '$d=$INC{"mod_perl2.pm"};$d=~s!(?:/[^/]+){4}$!!;$d=~tr!/!-!;print(($d=~/^-opt/?$d:"")."-Apache2-ClickPath");')

Name:         perl%{namebase}
License:      Artistic License
Group:        Development/Libraries/Perl
Requires:     perl = %{perl_version}
Requires:     p_mod_perl >= 1.999022
Requires:     perl-Crypt-CBC >= 2.14
Autoreqprov:  on
Summary:      Apache2::ClickPath
Version:      1.901
Release:      3
Source:       Apache2-ClickPath-%{version}.tar.gz
BuildRoot:    %{_tmppath}/%{name}-%{version}-build

%description
Apache2::ClickPath



Authors:
--------
    Torsten Foertsch <torsten.foertsch@gmx.net>

%prep
%setup -n Apache2-ClickPath-%{version}
# ---------------------------------------------------------------------------

%build
perl Makefile.PL
make && make test
# ---------------------------------------------------------------------------

%install
[ "$RPM_BUILD_ROOT" != "/" ] && [ -d $RPM_BUILD_ROOT ] && rm -rf $RPM_BUILD_ROOT;
make DESTDIR=$RPM_BUILD_ROOT \
     INSTALLSITEARCH=%{archbase} \
     INSTALLSITELIB=%{instbase} \
     INSTALLSITEBIN=%{binbase} \
     INSTALLSCRIPT=%{binbase} \
     INSTALLSITEMAN1DIR=%{manbase}/man1 \
     INSTALLSITEMAN3DIR=%{manbase}/man3 \
     install
rm -f $RPM_BUILD_ROOT%{manbase}/man3/Apache2::decode-session.3pm
%{_gzipbin} -9 $RPM_BUILD_ROOT%{manbase}/man3/Apache2::ClickPath.3pm || true
%{_gzipbin} -9 $RPM_BUILD_ROOT%{manbase}/man3/Apache2::ClickPath::Decode.3pm || true
%{_gzipbin} -9 $RPM_BUILD_ROOT%{manbase}/man3/Apache2::ClickPath::Store.3pm || true
%{_gzipbin} -9 $RPM_BUILD_ROOT%{manbase}/man3/Apache2::ClickPath::StoreClient.3pm || true
%perl_process_packlist

%clean
[ "$RPM_BUILD_ROOT" != "/" ] && [ -d $RPM_BUILD_ROOT ] && rm -rf $RPM_BUILD_ROOT;

%files
%defattr(-, root, root)
%{instbase}/Apache2
%{archbase}/auto/Apache2
%doc %{manbase}/man3/Apache2::ClickPath.3pm.gz
%doc %{manbase}/man3/Apache2::ClickPath::Decode.3pm.gz
%doc %{manbase}/man3/Apache2::ClickPath::Store.3pm.gz
%doc %{manbase}/man3/Apache2::ClickPath::StoreClient.3pm.gz
/var/adm/perl-modules/%{name}
%doc MANIFEST README
