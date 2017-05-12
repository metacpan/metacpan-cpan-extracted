
use Test::More tests => 269;
use Data::Dumper;

use CPAN::DistnameInfo;

local $/ ="";

while(<DATA>) {
  chomp;
  my($file,%exp) = split(/[\t\n]+/, $_);
  $exp{pathname} = $file;
  my $d = CPAN::DistnameInfo->new($file);
  my %got = $d->properties;
  while (my($k, $v) = each %got) {
    is($d->$k(), $v);
  }
  ok(eq_hash(\%got, \%exp))
    or print "\n",Data::Dumper->Dump([\%exp,\%got],[qw(expected got)]);
}


__DATA__
CPAN/authors/id/J/JA/JAMCC/ngb-101.zip
	filename	ngb-101.zip
	dist		ngb
	maturity	released
	distvname	ngb-101
	version		101
	cpanid		JAMCC
	extension	zip

CPAN/authors/id/J/JS/JSHY/DateTime-Fiscal-Year-0.01.tar.gz
	filename	DateTime-Fiscal-Year-0.01.tar.gz
	dist		DateTime-Fiscal-Year
	maturity	released
	distvname	DateTime-Fiscal-Year-0.01
	version		0.01
	cpanid		JSHY
	extension	tar.gz

CPAN/authors/id/G/GA/GARY/Math-PRSG-1.0.tgz
	filename	Math-PRSG-1.0.tgz
	dist		Math-PRSG
	maturity	released
	distvname	Math-PRSG-1.0
	version		1.0
	cpanid		GARY
	extension	tgz

CPAN/authors/id/G/GA/GARY/Math-BigInteger-1.0.tar.gz
	filename	Math-BigInteger-1.0.tar.gz
	dist		Math-BigInteger
	maturity	released
	distvname	Math-BigInteger-1.0
	version		1.0
	cpanid		GARY
	extension	tar.gz

CPAN/authors/id/T/TE/TERRY/VoiceXML-Server-1.6.tar.gz
	filename	VoiceXML-Server-1.6.tar.gz
	dist		VoiceXML-Server
	maturity	released
	distvname	VoiceXML-Server-1.6
	version		1.6
	cpanid		TERRY
	extension	tar.gz

CPAN/authors/id/J/JA/JAMCC/ngb-100.tar.gz
	filename	ngb-100.tar.gz
	dist		ngb
	maturity	released
	distvname	ngb-100
	version		100
	cpanid		JAMCC
	extension	tar.gz

CPAN/authors/id/J/JS/JSHY/DateTime-Fiscal-Year-0.02.tar.gz
	filename	DateTime-Fiscal-Year-0.02.tar.gz
	dist		DateTime-Fiscal-Year
	maturity	released
	distvname	DateTime-Fiscal-Year-0.02
	version		0.02
	cpanid		JSHY
	extension	tar.gz

CPAN/authors/id/G/GA/GARY/Crypt-DES-1.0.tar.gz
	filename	Crypt-DES-1.0.tar.gz
	dist		Crypt-DES
	maturity	released
	distvname	Crypt-DES-1.0
	version		1.0
	cpanid		GARY
	extension	tar.gz

CPAN/authors/id/G/GA/GARY/Stream-1.00.tar.gz
	filename	Stream-1.00.tar.gz
	dist		Stream
	maturity	released
	distvname	Stream-1.00
	version		1.00
	cpanid		GARY
	extension	tar.gz

CPAN/authors/id/G/GS/GSPIVEY/Text-EP3-Verilog-1.00.tar.gz
	filename	Text-EP3-Verilog-1.00.tar.gz
	dist		Text-EP3-Verilog
	maturity	released
	distvname	Text-EP3-Verilog-1.00
	version		1.00
	cpanid		GSPIVEY
	extension	tar.gz

CPAN/authors/id/T/TM/TMAEK/DBIx-Cursor-0.14.tar.gz
	filename	DBIx-Cursor-0.14.tar.gz
	dist		DBIx-Cursor
	maturity	released
	distvname	DBIx-Cursor-0.14
	version		0.14
	cpanid		TMAEK
	extension	tar.gz

CPAN/authors/id/G/GA/GARY/Crypt-IDEA-1.0.tar.gz
	filename	Crypt-IDEA-1.0.tar.gz
	dist		Crypt-IDEA
	maturity	released
	distvname	Crypt-IDEA-1.0
	version		1.0
	cpanid		GARY
	extension	tar.gz

CPAN/authors/id/G/GA/GARY/Math-TrulyRandom-1.0.tar.gz
	filename	Math-TrulyRandom-1.0.tar.gz
	dist		Math-TrulyRandom
	maturity	released
	distvname	Math-TrulyRandom-1.0
	version		1.0
	cpanid		GARY
	extension	tar.gz

CPAN/authors/id/T/TE/TERRY/VoiceXML-Server-1.13.tar.gz
	filename	VoiceXML-Server-1.13.tar.gz
	dist		VoiceXML-Server
	maturity	released
	distvname	VoiceXML-Server-1.13
	version		1.13
	cpanid		TERRY
	extension	tar.gz

JWILLIAMS/MasonX-Lexer-MSP-0.02.tar.gz
	filename	JWILLIAMS/MasonX-Lexer-MSP-0.02.tar.gz
	dist		MasonX-Lexer-MSP
	maturity	released
	distvname	MasonX-Lexer-MSP-0.02
	version		0.02
	extension	tar.gz

CPAN/authors/id/J/JA/JAMCC/Tie-CacheHash-0.50.tar.gz
	filename	Tie-CacheHash-0.50.tar.gz
	dist		Tie-CacheHash
	maturity	released
	distvname	Tie-CacheHash-0.50
	version		0.50
	cpanid		JAMCC
	extension	tar.gz

CPAN/authors/id/T/TM/TMAEK/DBIx-Cursor-0.13.tar.gz
	filename	DBIx-Cursor-0.13.tar.gz
	dist		DBIx-Cursor
	maturity	released
	distvname	DBIx-Cursor-0.13
	version		0.13
	cpanid		TMAEK
	extension	tar.gz

CPAN/authors/id/G/GS/GSPIVEY/Text-EP3-1.00.tar.gz
	filename	Text-EP3-1.00.tar.gz
	dist		Text-EP3
	maturity	released
	distvname	Text-EP3-1.00
	version		1.00
	cpanid		GSPIVEY
	extension	tar.gz

CPAN/authors/id/J/JD/JDUTTON/Parse-RandGen-0.100.tar.gz
	filename	Parse-RandGen-0.100.tar.gz
	dist		Parse-RandGen
	maturity	released
	distvname	Parse-RandGen-0.100
	version		0.100
	cpanid		JDUTTON
	extension	tar.gz

id/N/NI/NI-S/Tk400.202.tar.gz
	filename	Tk400.202.tar.gz
	dist		Tk
	maturity	released
	distvname	Tk400.202
	version		400.202
	cpanid		NI-S
	extension	tar.gz

authors/id/G/GB/GBARR/perl5.005_03.tar.gz
	filename	perl5.005_03.tar.gz
	dist		perl
	maturity	released
	distvname	perl5.005_03
	version		5.005_03
	cpanid		GBARR
	extension	tar.gz

M/MS/MSCHWERN/Test-Simple-0.48_01.tar.gz
	filename	Test-Simple-0.48_01.tar.gz
	dist		Test-Simple
	maturity	developer
	distvname	Test-Simple-0.48_01
	version		0.48_01
	cpanid		MSCHWERN
	extension	tar.gz

id/J/JV/JV/PostScript-Font-1.09.tar.gz
	filename	PostScript-Font-1.09.tar.gz
	dist		PostScript-Font
	maturity	released
	distvname	PostScript-Font-1.09
	version		1.09
	cpanid		JV
	extension	tar.gz

id/I/IB/IBMTORDB2/DBD-DB2-0.77.tar.gz
	filename	DBD-DB2-0.77.tar.gz
	dist		DBD-DB2
	maturity	released
	distvname	DBD-DB2-0.77
	version		0.77
	cpanid		IBMTORDB2
	extension	tar.gz

id/I/IB/IBMTORDB2/DBD-DB2-0.99.tar.bz2
	filename	DBD-DB2-0.99.tar.bz2
	dist		DBD-DB2
	maturity	released
	distvname	DBD-DB2-0.99
	version		0.99
	cpanid		IBMTORDB2
	extension	tar.bz2

CPAN/authors/id/L/LD/LDS/CGI.pm-2.34.tar.gz
	filename	CGI.pm-2.34.tar.gz
	dist		CGI
	maturity	released
	distvname	CGI.pm-2.34
	version		2.34
	cpanid		LDS
	extension	tar.gz

CPAN/authors/id/J/JE/JESSE/perl-5.12.0-RC0.tar.gz
	filename	perl-5.12.0-RC0.tar.gz
	dist		perl
	maturity	developer
	distvname	perl-5.12.0-RC0
	version		5.12.0-RC0
	cpanid		JESSE
	extension	tar.gz

CPAN/authors/id/G/GS/GSAR/perl-5.6.1-TRIAL3.tar.gz
	filename	perl-5.6.1-TRIAL3.tar.gz
	dist		perl
	maturity	developer
	distvname	perl-5.6.1-TRIAL3
	version		5.6.1-TRIAL3
	cpanid		GSAR
	extension	tar.gz

CPAN/authors/id/R/RJ/RJBS/Dist-Zilla-2.100860-TRIAL.tar.gz
	filename	Dist-Zilla-2.100860-TRIAL.tar.gz
	dist		Dist-Zilla
	maturity	developer
	distvname	Dist-Zilla-2.100860-TRIAL
	version		2.100860-TRIAL
	cpanid		RJBS
	extension	tar.gz

CPAN/authors/id/M/MI/MINGYILIU/Bio-ASN1-EntrezGene-1.10-withoutworldwriteables.tar.gz
	filename	Bio-ASN1-EntrezGene-1.10-withoutworldwriteables.tar.gz
	dist		Bio-ASN1-EntrezGene
	maturity	released
	distvname	Bio-ASN1-EntrezGene-1.10-withoutworldwriteables
	version		1.10
	cpanid		MINGYILIU
	extension	tar.gz
