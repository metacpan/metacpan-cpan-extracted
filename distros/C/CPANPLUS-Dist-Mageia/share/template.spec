%define upstream_name    DISTNAME
%define upstream_version DISTVERS

%{?perl_default_filter}

Name:       perl-%{upstream_name}
Version:    %perl_convert_version %{upstream_version}
Release:    %mkrel 1

Summary:    DISTSUMMARY
License:    GPLv1+ or Artistic
Group:      Development/Perl
Url:        http://metacpan.org/release/%{upstream_name}
Source0:    http://www.cpan.org/modules/by-module/DISTTOPLEVEL/%{upstream_name}-%{upstream_version}.DISTEXTENSION

DISTBUILDREQUIRES
DISTARCH

%description
DISTDESCR

%prep
%setup -q -n %{upstream_name}-%{upstream_version}

%build
DISTBUILDBUILDER
DISTMAKER

%check
DISTMAKER test

%install
DISTINSTALL

%files
DISTDOC
%{_mandir}/man3/*
%perl_vendorlib/*
DISTEXTRA

%changelog
* DISTDATE cpan2dist DISTVERS-1mga
- initial mageia release, generated with cpan2dist
