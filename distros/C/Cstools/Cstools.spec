Summary: Czech laguage tools
Summary(cs): Nástroje pro práci s èeským jazykem (koverze kódování, tøídìní)
Name: cstools
Version: 3.44
Release: 1
Group: Applications/Text
Group(cs): Aplikace/Text
Source: Cstools-%{version}.tar.gz
Copyright: 1997--2002 Jan Pazdziora
Buildroot: /tmp/cstools-root
Packager: Milan Kerslager <kerslage@linux.cz>

%description
This package includes modules that are usefull when dealing with
Czech (and Slovak) texts in Perl.

Program cstocs:
   This version of popular charset reencoding utility uses the above
   mentioned module to convert text between various charsets.

Module Cz::Cstocs:
   Implements object for various charset encodings, used for the Czech
   language -- either as objects, or as direct conversion functions.  One
   of the charsets is tex for things like \v{c}.

Module Cz::Sort:
   Sorts according to Czech sorting conventions, regardless on (usually
   broken) locales. Exports functions czcmp and czsort which can be used
   in similar way as as Perl's internals cmp and sort.

%description -l cs
V tomto balíku jsou moduly, které mohou být u¾iteèné pøi práci s èeskými
(a slovenskými) texty v Perlu.

Program cstocs:
   Tato verze konverzího programu cstocs je zalo¾ena na vý¹e uvedeném
   modulu. Provádí pøevody kódování nad danými soubory nebo nad
   standardním vstupem.

Modul Cz::Cstocs:
   Objekt, pomocí nìho¾ je mo¾no konvertovat mezi znakovými sadami bez
   nutnosti vnìj¹ího programu -- buï formou objektovou, nebo pøímými
   konverzními funkcemi.  Jednou ze znakových sad je i sada tex, tedy
   napø.  \v{c}.

Modul Cz::Sort:
   Implementuje ètyøprùchodové èeské tøídìní, nezávislé na pou¾itých
   locales, proto¾e kdo má správné locales, ¾e? Exportuje funkce czcmp
   a czsort, které pracují podobnì jako perlovské vestavìné cmp a sort.

%prep

%setup -n Cstools-%{version}

%build

perl Makefile.PL
make
make test

%install

rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/usr

# make install wants to append to perllocal.pod which is politically
# incorrect behaviour; let's disable it: it's RPM that is supposed to
# keep track of installed software

make	PREFIX=$RPM_BUILD_ROOT/usr \
	DOC_INSTALL="-#" \
	install

# .packlist is incorrect and useless (see above)

rm `find $RPM_BUILD_ROOT -name .packlist`

%clean

rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
/usr/bin/*
/usr/lib/perl5/site_perl/*/Cz/*
%{_mandir}/man[0-9]/*
%doc Changes README

%changelog
* Fri Dec  1 2000, included Fri Jun 28 2002 Milan Kerslager <kerslage@linux.cz>
- fixes for 7.0

* Thu Jul 15 1999 Milan Kerslager <milan.kerslager@spsselib.hiedu.cz>
- added descriptions (en, cs)

