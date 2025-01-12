Name: Astro-Constants
Version: 0.1405
Release: 1
 
Summary: This library provides physical constants for use in Physics and Astronomy
License: GPL+ or Artistic
Group: Applications/CPAN
BuildArch: noarch
URL: http://dev.perl.org/licenses/
Source: Astro-Constants-0.1405.tar.gz
 
BuildRoot: %{_tmppath}/%{name}-%{version}-BUILD
 
%description
This library provides physical constants for use in Physics and Astronomy
 
%prep
%setup -q
 
%build
perl Makefile.PL
make test
 
%install
if [ "%{buildroot}" != "/" ] ; then
    rm -rf %{buildroot}
fi
make install DESTDIR=%{buildroot}
find %{buildroot} | sed -e 's#%{buildroot}##' > %{_tmppath}/filelist
 
%clean
if [ "%{buildroot}" != "/" ] ; then
    rm -rf %{buildroot}
fi
 
%files -f %{_tmppath}/filelist
%defattr(-,root,root)
