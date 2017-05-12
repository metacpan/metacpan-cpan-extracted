Summary: Perl module for creating Visitor methods on classes
Name: Class-Visitor
Version: 0.02
Release: 1
Source: ftp://ftp.uu.net/vendor/bitsko/gdo/Class-Visitor-0.02.tar.gz
Copyright: GPL/Perl
Group: Utilities/Text
URL: http://www.bitsko.slc.ut.us/
Packager: ken@bitsko.slc.ut.us (Ken MacLeod)
BuildRoot: /tmp/Class-Visitor

#
# $Id: Class-Visitor.spec,v 1.3 1997/10/18 16:43:27 ken Exp $
#

%description
Class::Visitor extends the getter/setter functions provided by
Class::Template by defining methods for using the Visitor and Iterator
design patterns.

%prep
%setup

perl Makefile.PL INSTALLDIRS=perl

%build

make

%install

make PREFIX="${RPM_ROOT_DIR}/usr" pure_install

%files

%doc README Changes test.pl

/usr/lib/perl5/Class/Iter.pm
/usr/lib/perl5/Class/Visitor.pm
/usr/lib/perl5/man/man3/Class::Iter.3
/usr/lib/perl5/man/man3/Class::Visitor.3
