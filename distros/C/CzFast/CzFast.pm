
# $Id: CzFast.pm,v 1.7 2001/03/21 15:30:32 trip Exp $

=head1 NAME

B<CzFast - Perl module for czech charsets manipulation>


=head1 SYNOPSIS

Further documentation of this module is available only in czech language.

	use CzFast qw( &czrecode &czregexp &detect_client_charset );
	
	my $str = 'Drogy ne !';

	# Prekodovani retezce z jednoho kodovani do druheho:
	my $recoded_str = &czrecode('windows-1250', 'iso-8859-2', $str);

	# Ziskani regulerniho vyrazu pro porovnavani bez ohledu
	# na diakritiku a velka/mala pismena:	
	my $diacritics_unsensitive_regexp = &czregexp($str);
	
	# Detekce kodovani WWW klienta:	
	my $charset = &detect_client_charset();	


=head1 DESCRIPTION

Modul rozeznava tyto identifikatory znakovych sad a jejich varianty:

	us-ascii        nebo ascii
	iso-8859-1
	iso-8859-2      nebo unix
	windows-1250    nebo windows
	kam             nebo kamenicti
	pclatin2
	koi8cs	  
	apple-ce        nebo mac          nebo macintosh
	cp850 

V identifikatorech se B<nerozlisuji mala a velka pismena>.

Funkce B<czregexp> je velmi uzitecna zejmena pro vyhledavani v databazich,
podporujicich regulerni vyrazy. Implementace pocita s sesti kombinacemi
pro pismena E a U - varianty s carkou i hackem, resp. carkou i krouzkem.
Vstupem teto funkce B<musi byt retezec v kodovani iso-8859-2 (unix)>.

Funkce provadi eskejpovani znaku, ktere maji v tride charakteru regulernich
vyrazu specialni vyznam - '^', '-' a ']'. Toto eskejpovani je mozne provest
dvema zpusoby, standardnim POSIX pouzivanym napr. programem grep, nebo
zpusobem nutnym v Perlove implementaci. V pripade Perlu je eskejpovani
provadeno jinak a s ohledem na dalsi skupiny znaku se specialnim vyznamem,
jako je napr. '\w' nebo znak '\'. Funkce implicitne eskejpuje pro Perl,
eskejpovani POSIX lze aktivovat pomoci volitelneho druheho parametru.
Pokud je tento druhy parametr true - napr. retezec 'posix' nebo hodnota '1',
eskejpuje funkce dle POSIXU.

Pro pouziti v SQL je nutne zvolit spravny format eskejpovani podle toho,
ktery pouziva vase databaze. Napr. databaze MySQL pouziva eskejpovani
POSIX, a je pak tedy nutne tuto funkci volat jako &czregexp($str, 1).


Prvnim parametrem funkce B<czrecode> je vstupni kodovani, druhym vystupni
kodovani a tretim retezec, ktery ma byt prekodovan. Vstupni retezec neni
modifikovan, funkce vraci prekodovany vstup jako svou navratovou hodnotu.


Funkce B<detect_client_charset> vyuziva promenne prostredi, nastavovane
webserverem pro spoustene CGI programy na zaklade HTTP hlavicek zaslanych
klientem, pro urceni jake kodovani cestiny tento klient pouziva.
Vraci kodovani klienta ve forme identifikatoru popsanych vyse, v jejich
zakladni variante (ie. jako napr. 'windows-1250').

Jadro modulu je z duvodu vyssi rychlosti napsano v jazyce C, jako dynamicky
zavadeny objekt interpretu Perlu. Pro systemy nepodporujici dynamicke
zavadeni za behu, je mozne modul staticky slinkovat s interpretem pri
jeho kompilaci. Toto je blize popsano v dokumentaci Perlu. Modul je takto
vyrazne rychlejsi nez jine dostupne Perl moduly pro prekodovani. Modul
vyuziva konverzni mapy vytvorene Jaromirem Doleckem pro projekt csacek
(http://www.csacek.cz) a je csackem inspirovan i v reseni detekce kodovani
klienta.


=head1 AUTHOR

B<Tomas Styblo>, tripiecz@yahoo.com

Prague, the Czech republic

This program uses character tables created by Jaromir Dolecek for
the Csacek project (http://www.csacek.cz).


=head1 LICENSE

CzFast - Perl module for czech charsets manipulation

Copyright (C) 2000 Tomas Styblo (tripiecz@yahoo.com)

This program uses character tables created by Jaromir Dolecek for
the Csacek project (http://www.csacek.cz).

This module is free software; you can redistribute it and/or modify it
under the terms of either:

a) the GNU General Public License as published by the Free Software
Foundation; either version 1, or (at your option) any later version,
or

b) the "Artistic License" which comes with this module.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either
the GNU General Public License or the Artistic License for more details.

You should have received a copy of the Artistic License with this
module, in the file ARTISTIC.  If not, I'll be glad to provide one.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
USA


=head1 SEE ALSO

perl(1).

=cut


package CzFast;	# CzFast.xs

use strict;
use integer;
# use warnings;		# uncomment if you have a recent Perl version
use Carp;

use Exporter;
use DynaLoader;

BEGIN {
	use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS );
	@ISA = qw( Exporter DynaLoader );
	%EXPORT_TAGS = ();
	@EXPORT_OK = qw( &czrecode &czregexp &detect_client_charset );
	@EXPORT = ();
	$VERSION = '0.10';
}

# functions
sub czrecode;
sub czregexp;
sub czvardiac;
sub detect_client_charset;
sub lookup_charset;

# XS:
sub _czgetmap;
sub _czrecode;


sub czrecode {
	return &_czrecode (&lookup_charset($_[0]), &lookup_charset($_[1]), $_[2]);
}


sub czregexp {
	my $input = $_[0];
	my $posix_escaping = $_[1];
	my $ascii = &_czrecode (&lookup_charset('iso-8859-2'), 
		&lookup_charset('us-ascii'), $input);
	my $no_diac_lc = lc($ascii);
	my $no_diac_uc = uc($ascii);
	my $var_no_diac_lc = &czvardiac($no_diac_lc);
	my $var_no_diac_uc = &czvardiac($no_diac_uc);
	my @no_diac_lc = split(//, $no_diac_lc);
	my @no_diac_uc = split(//, $no_diac_uc);
	my @var_no_diac_lc = split(/\x0/, $var_no_diac_lc);
	my @var_no_diac_uc = split(/\x0/, $var_no_diac_uc);
	my $ret;

	for(my $i = 0; $i < @no_diac_lc; $i++) {
		$ret .= '[';
		$_ = $no_diac_lc[$i];
		$_ .= $no_diac_uc[$i];
		$_ .=	$var_no_diac_lc[$i];
		$_ .= $var_no_diac_uc[$i];

		if ($posix_escaping) {
			# posix eskejpovani
			# od kazdeho eskejpovaneho specialniho znaku staci mit ve
			# vyslednem retezci pouze jednu kopii
			s/^\^(.*)$/$1^/;	# premistit '^' na prvni pozici nakonec
			$_ .= '-' if (tr/-//d);		# premistit '-' nakonec
			$_ = ']'.$_ if (tr/]//d);	# premistit '-' na prvni pozici	
		}
		else {		
			# perl eskejpovani (implicitni)
			s/\\/\\\\/g;
			s/\^/\\^/g;
			s/\]/\\]/g;
			s/\[/\\[/g;
			s/\-/\\-/g; 			 
		}
		
		$ret .= $_;
		$ret .= ']';
	}

return $ret;
}


sub czvardiac {
	my @str = split(//, $_[0]);
	my $ret;
	
	foreach my $char (@str) {
		if ($char eq "\x75") { $ret .= "\xFA\xF9\x0" }	  # male U
		elsif ($char eq "\x55") { $ret .= "\xDA\xD9\x0" } # velke U
		elsif ($char eq "\x65") { $ret .= "\xE9\xEC\x0" } # male E
		elsif ($char eq "\x45") { $ret .= "\xC9\xCC\x0" } # velke E
		else {	
			$char =~ tr/\x41\x43\x44\x49\x4E\x4F\x52\x53\x54\x59\x5A\x61\x63\x64\x69\x6E\x6F\x72\x73\x74\x79\x7A/\xC1\xC8\xCF\xCD\xD2\xD3\xD8\xA9\xAB\xDD\xAE\xE1\xE8\xEF\xED\xF2\xF3\xF8\xB9\xBB\xFD\xBE/;
			$ret .= $char."\x0";
		}
	}
	return $ret;
}


sub detect_client_charset {
	my ($ch, $ua, $lang);
	if (@_) {
		($ch, $ua, $lang) = @_;
	}
	else {
		$ch = $ENV{'HTTP_ACCEPT_CHARSET'};
		$ua = $ENV{'HTTP_USER_AGENT'};
		$lang = $ENV{'HTTP_ACCEPT_LANGUAGE'};	
	}
	
	# ch = Accept-Charset
	# ua = User-Agent
	# lang = Accept-Language	
	
	if ($ch and ($ua !~ /Mozilla\/4/i or $ua !~ /mac/i)) {
		if ($ch =~ /windows-1250/i) {
			return "windows-1250";
		}
		elsif ($ch =~ /iso-8859-2/i) {
			return "iso-8859-2";
		}
		elsif ($ch =~ /apple-ce/i or $ch =~ /mac-ce/i) {
			return "apple-ce";
		}
		elsif ($ch =~ /\*/) {
			return "iso-8859-2";
		}
		else {
			return "us-ascii";
		}
	}
	elsif ($ua)	{	
		if ($ua =~ /win/i) {
			return "windows-1250";
		}	
		elsif ($ua =~ /(mac|m68m|ppc|mac)/i) {
			return "apple-ce";
		}
		elsif ($ua =~ /os\/2|ibm-webexplorer|amiga|x11/i) {
			return "iso-8859-2";
		}
		else {
			return "us-ascii";
		}
	}
	elsif ($lang) {	
		if ($lang =~ /cs|cz|sk/i) {
			return "windows-1250";
		}
		else {
			return "us-ascii";
		}
	}
	else {
		return "us-ascii";		
	}
}


sub lookup_charset {
	my $name = lc($_[0]);
	my %charsets = (
		'us-ascii'		=> 0,
		'iso-8859-1'	=> 1, 
		'iso-8859-2'	=> 2, 
		'windows-1250'	=> 3,
		'kam'			=> 4,
		'pclatin2'		=> 5,	
		'koi8cs'		=> 6,	
		'apple-ce'		=> 7,
		'cp850'			=> 8,
		
		# non standard
		
		'ascii'			=> 0,
		'unix'			=> 2,
		'windows'		=> 3,
		'win'			=> 3,
		'kamenicti'		=> 4,
		'macintosh'		=> 7,
		'mac'			=> 7				
	);
	
	if (exists ($charsets{$name})) {
		return $charsets{$name};
	}
	else {
		croak 
		("CzFast - Unknown charset $_[0]. Consult perldoc CzFast.");
	}
}


bootstrap CzFast $VERSION;


1;
__END__

