Name:           perl-DR-Tarantool
Version:        0.38
Release:        1
Summary:        A Perl driver for Tarantool

Group:          Development/Libraries
License:        Artistic
URL:            http://search.cpan.org/~unera/DR-Tarantool-0.38/
Source0:        http://search.cpan.org/CPAN/authors/id/U/UN/UNERA/DR-Tarantool-0.38.tar.gz
Source1:        filter-requires-dr-tarantool.sh
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

%define __perl_requires %{SOURCE1}

%description
This module provides a synchronous and asynchronous driver for Tarantool.
The driver does not have external dependencies, but includes the official light-weight Tarantool C client (a single C header which implements all protocol formatting) for packing requests and unpacking server responses.
This driver implements "iproto" protocol described in https://github.com/mailru/tarantool/blob/master/doc/box-protocol.txt
It is built on top of AnyEvent - an asynchronous event framework, and is therefore easiest to integrate into a program which is already based on AnyEvent. A synchronous version of the driver exists as well, it starts AnyEvent event machine for every request.


%prep
%setup -q -n DR-Tarantool-%{version}

%build
CFLAGS="$RPM_OPT_FLAGS" %{__perl} Makefile.PL INSTALLDIRS=vendor
make %{?_smp_mflags} OPTIMIZE="$RPM_OPT_FLAGS"

%install
rm -rf $RPM_BUILD_ROOT
make pure_install PERL_INSTALL_ROOT=$RPM_BUILD_ROOT
find $RPM_BUILD_ROOT -type f -name .packlist -exec rm -f {} ';'
find $RPM_BUILD_ROOT -type f -name '*.bs' -empty -exec rm -f {} ';'
find $RPM_BUILD_ROOT -type d -depth -exec rmdir {} 2>/dev/null ';'

%check || :
mv t/010-xs.t t/010-xs.t.disabled
make test

%clean
rm -rf $RPM_BUILD_ROOT


%files
%defattr(-,root,root,-)
%doc README.pod
%{perl_vendorarch}/DR/
%{perl_vendorarch}/auto/DR/Tarantool/Tarantool.so
/usr/share/man/man3/DR::README.3pm.gz
/usr/share/man/man3/DR::Tarantool.3pm.gz
/usr/share/man/man3/DR::Tarantool::AsyncClient.3pm.gz
/usr/share/man/man3/DR::Tarantool::CoroClient.3pm.gz
/usr/share/man/man3/DR::Tarantool::Iterator.3pm.gz
/usr/share/man/man3/DR::Tarantool::LLClient.3pm.gz
/usr/share/man/man3/DR::Tarantool::Spaces.3pm.gz
/usr/share/man/man3/DR::Tarantool::StartTest.3pm.gz
/usr/share/man/man3/DR::Tarantool::SyncClient.3pm.gz
/usr/share/man/man3/DR::Tarantool::Tuple.3pm.gz
