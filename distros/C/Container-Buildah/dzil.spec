Name: Container-Buildah
Version: 0.3.0
Release: 1

Summary: wrapper around containers/buildah tool for multi-stage builds of OCI/Docker-compatible Linux containers
License: GPL+ or Artistic
Group: Applications/CPAN
BuildArch: noarch
URL: http://www.apache.org/licenses/LICENSE-2.0.txt
Source: Container-Buildah-0.3.0.tar.gz

BuildRoot: %{_tmppath}/%{name}-%{version}-BUILD

%description
wrapper around containers/buildah tool for multi-stage builds of OCI/Docker-compatible Linux containers

%prep
%setup -q

%build
perl Makefile.PL
make test

%install
if [ "%{buildroot}" != "/" ] ; then
	rm -rf %{buildroot}
fi
make pure_install DESTDIR=%{buildroot}
find %{buildroot} | sed -e 's#%{buildroot}##' > %{_tmppath}/filelist

%clean
if [ "%{buildroot}" != "/" ] ; then
	rm -rf %{buildroot}
fi

%files -f %{_tmppath}/filelist
%defattr(-,root,root)
