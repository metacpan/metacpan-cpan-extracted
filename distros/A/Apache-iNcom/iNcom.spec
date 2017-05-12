Summary:  mod_perl based Internet Commerce Framework
Name: Apache-iNcom
Version: 0.09
Release: 1i
Source: http://indev.insu.com/sources/%{name}-%{version}.tar.gz
Copyright: GPL
Group: Development/Libraries/Perl
URL: http://indev.insu.com/iNcom/
BuildRoot: /var/tmp/%{name}-%{version}-root
Requires: perl >= 5.00503, libapreq, mod_perl >= 1.21, 
Requires: HTML-Embperl, Storable
Requires: Apache-Session, Digest-MD5, DBI, MIME-Base64
Requires: ApacheDBI
BuildArchitectures: noarch
Provides: perl(DBIx::SearchProfiles) = %{version}
Provides: perl(DBIx::UserDB) = %{version}
Provides: perl(HTML::FormValidator) = %{version}

%description
mod_perl based Internet Commerce Framework.

%prep
%setup -q
# Update all path to the perl interpreter
find -type f -exec sh -c 'if head -c 100 $0 | grep -q "^#!.*perl"; then \
		perl -p -i -e "s|^#!.*perl|#!/usr/bin/perl|g" $0; fi' {} \;

%build
perl Makefile.PL 
make OPTIMIZE="$RPM_OPT_FLAGS"
make test

%install
rm -fr $RPM_BUILD_ROOT
eval `perl '-V:installarchlib'`
mkdir -p $RPM_BUILD_ROOT/$installarchlib
make 	PREFIX=$RPM_BUILD_ROOT/usr \
	INSTALLMAN1DIR=$RPM_BUILD_ROOT/usr/man/man1 \
   	INSTALLMAN3DIR=$RPM_BUILD_ROOT/`dirname $installarchlib`/man/man3 \
   	pure_install

# Fix packing list
for packlist in `find $RPM_BUILD_ROOT -name '.packlist'`; do
	mv $packlist $packlist.old
	sed -e "s|$RPM_BUILD_ROOT||g" < $packlist.old > $packlist
	rm -f $packlist.old
done

# Make a file list
find $RPM_BUILD_ROOT -type d -path '*/usr/lib/perl5/site_perl/5.005/*' \
    -not -path '*/auto' -not -path "*/*-linux" -not -path '*/Apache' | \
    sed -e "s!$RPM_BUILD_ROOT!%dir !" > %{name}-file-list
    
find $RPM_BUILD_ROOT -type f -o -type l -not -name "perllocal.pod" | \
	sed -e "s|$RPM_BUILD_ROOT||" \
	    -e 's!\(.*/man/man|.*\.pod$\)!%doc \1!' >> %{name}-file-list

%clean
rm -fr $RPM_BUILD_ROOT

%files -f %{name}-file-list
%defattr(-,root,root)
%doc README ChangeLog demo *.patch

%changelog
* Thu Mar 30 2000  Francis J. Lacoste <francis.lacoste@iNsu.COM> 
  [0.09-i]
- Released 0.09.

* Fri Feb 25 2000  Francis J. Lacoste <francis.lacoste@iNsu.COM> 
  [0.08-1i]
- Release 0.08.

* Wed Feb 23 2000  Francis J. Lacoste <francis.lacoste@iNsu.COM> 
  [0.07-1i]
- Release 0.07.

* Wed Feb 16 2000  Francis J. Lacoste <francis.lacoste@iNsu.COM> 
  [0.06-1i]
- Released 0.06.

* Fri Dec 03 1999  Francis J. Lacoste <francis.lacoste@iNsu.COM> 
  [0.05-1i]
- Released 0.05.
- Added provides of module names in the perl namespace.

* Mon Nov 29 1999  Francis J. Lacoste <francis.lacoste@iNsu.COM> 
  [0.04-19991129i]
- Snapshot release.

* Sat Nov 20 1999  Francis J. Lacoste <francis.lacoste@iNsu.COM> 
  [0.04-1i]
- Released version 0.04.

* Sun Nov 14 1999  Francis J. Lacoste <francis.lacoste@iNsu.COM> 
  [0.04-19991114]
- Another snapshot release.

* Fri Oct 22 1999  Francis J. Lacoste <francis.lacoste@iNsu.COM> 
  [0.04-19991109]
- Snapshot release.

* Fri Oct 22 1999  Francis J. Lacoste <francis.lacoste@iNsu.COM> 
  [0.04-19991022]
- Snapshot release.

* Fri Oct 15 1999  Francis J. Lacoste <francis.lacoste@iNsu.COM> 
  [0.03-1i]
- Updated to version 0.03.

* Thu Oct 14 1999 Francis J. Lacoste <francis.lacoste@iNsu.COM>
  [0.02-1i]
- Updated to version 0.02.

* Tue Oct 12 1999 Francis J. Lacoste <francis.lacoste@iNsu.COM>
  [0.01-1i]
- Packaged for iNs/linux


