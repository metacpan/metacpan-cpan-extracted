#!/usr/bin/perl
# # # # # #
# Diversar funcoes para algum tipo
# de comunicacao com o browser do
# usuario.
# Tue Mar 20 12:34:00 BRT 2001
# # # # # #

package Ananke::Utils;
use strict;

our $VERSION = '1.0.2';
$SIG{__WARN__} = sub { };

sub getCookies {
	# cookies are seperated by a semicolon and a space, this will split
   # them and return a hash of cookies
   my(@rawCookies) = split (/; /,$ENV{'HTTP_COOKIE'});
   my(%cookies);

   my($key,$val);
   foreach(@rawCookies){
   	($key, $val) = split (/=/,$_);
      $cookies{$key} = $val;
   }
        
   return %cookies;
}

# Trata os dados do form
# Formata timestamp.
# Sat Mar 17 22:31:06 BRT 2001
sub getTime {
   my($time) = @_;
   my ($seg,$min,$hora) = localtime($time);
   return sprintf("(%02d:%02d:%02d)",$hora,$min,$seg);
}

# Substitui chars proibidos
sub replace_chars {
   my($msg) = @_;
	$_ = $msg;

	s/©/&copy;/g; s/õ/&otilde;/g; s/®/&reg;/g; s/ö/&ouml;/g;
	s/ø/&oslash;/g; s/"/&quot;/g; s/ù/&ugrave;/g;
	s/ú/&uacute;/g; s/</&lt;/g; s/û/&ucirc;/g;
	s/>/&gt;/g; s/ý/&yacute;/g; s/À/&Agrave;/g; s/þ/&thorn;/g;
	s/Á/&Aacute;/g; s/ÿ/&yuml;/g; s/Â/&Acirc;/g; s/:/&#58;/g;
	s/Ã/&Atilde;/g; s/Ä/&Auml;/g; s/Å/&Aring;/g; 
	s/Æ/&AElig;/g; s/Ç/&Ccedil;/g; s/È/&Egrave;/g; s/É/&Eacute;/g;
	s/Ê/&Ecirc;/g; s/Ë/&Euml;/g; s/Ì/&Igrave;/g; s/Í/&Iacute;/g;
	s/Î/&Icirc;/g; s/Ï/&Iuml;/g; s/Ð/&ETH;/g; s/Ñ/&Ntilde;/g;
	s/Õ/&Otilde;/g; s/Ö/&Ouml;/g; s/Ø/&Oslash;/g; s/Ù/&Ugrave;/g;
	s/Ú/&Uacute;/g; s/Û/&Ucirc;/g; s/Ü/&Uuml;/g; s/Ý/&Yacute;/g;
	s/Þ/&THORN;/g; s/ß/&szlig;/g; s/à/&agrave;/g; s/á/&aacute;/g;
	s/å/&aring;/g; s/æ/&aelig;/g; s/ç/&ccedil;/g; s/è/&egrave;/g;
	s/é/&eacute;/g; s/ê/&ecirc;/g; s/ë/&euml;/g; s/ì/&igrave;/g;
	s/í/&iacute;/g; s/î/&icirc;/g; s/ï/&iuml;/g; s/ð/&eth;/g;
	s/ñ/&ntilde;/g; s/ò/&ograve;/g; s/ó/&oacute;/g; s/ô/&ocirc;/g;
	s/ã/&atilde;/g;
	s/£/&pound;/g; s/§/&sect;/g; s/«/&laquo;/g; s/¥/&yen;/g;
   s/¯/&macr;/g; s/»/&raquo;/g; s/×/&times;/g; s/ð/&eth;/g;
   s/¢/&cent;/g; s/¤/&curren;/g; s/¦/&brvbar;/g; s/¬/&not;/g;
   s/º/&ordm;/g; s/½/&frac12;/g; s/¼/&frac14;/g; s/¾/&frac34;/g;
   s/ª/&ordf;/g; s/´/&acute;/g; s/¶/&para;/g; s/·/&middot;/g;
   s/¸/&cedil;/g; s/¹/&sup1;/g; s/÷/&divide;/g; s/³/&sup3;/g;
   s/¿/&iquest;/g; s/Ð/&ETH;/g; s/¨/&uml;/g; s/¡/&iexcl;/g;
   eval { s/±/&plusmn;/g;  };

	s/!/&#33;/g; s/@/&#64;/g; s/\$/&#36;/g; s/%/&#37;/g;
	s/\*/&#42;/g; s/\(/&#40;/g; s/\)/&#41;/g;
	s/\//&#47;/g; s/\\/&#92;/g;
	
   return $_;

}

# Recupega Post com multiples values
sub getForm {
   my($r,$rr) = @_;
   my($i,@j,$k,%r);

   # Printa conteudo
   if ($r) { $r = $r; }
   elsif ($rr) { $r = $rr; }
   else { return; }

   $i = $r;

   while ($i =~ s/^([a-zA-Z0-9-_\%\.\,\+]+)=([a-zA-Z0-9-_\*\@\%\.\,\+]+)?&?//sx) {
      $j[0] = $1;
      $j[1] = $2;

      # Trasnforma os chars especiais em normais
      $j[0] =~ tr/+/ /;
      $j[0] =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
      $j[1] =~ tr/+/ /;
      $j[1] =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;

      # Verifica quantas vezes se repete     
      $k = $r =~ s/(^|&)($j[0]=)/$1$2/gi;

      # Verifica se joga em array ou hash
      if ($k > 1) { push (@{$r{$j[0]}},$j[1]); }
      else { $r{$j[0]} = $j[1] }

      $k = 0;
   }

   return %r if %r;
   return 0;
}

# see /usr/src/usr.bin/passwd/local_passwd.c or librcypt, crypt(3)
sub salt {
    my($salt);               # initialization
    my($i, $rand);
    my(@itoa64) = ( '0' .. '9', 'a' .. 'z', 'A' .. 'Z' ); # 0 .. 63

    # to64
    for ($i = 0; $i < 27; $i++) {
        srand(time + $rand + $$);
        $rand = rand(25*29*17 + $rand);
        $salt .=  $itoa64[$rand & $#itoa64];
    }

    return $salt;
}

# Esconda a string
sub escape {
   my ($str,$pat) = @_;
   $pat = '^A-Za-z0-9 ' if ( $pat eq '' );
   $str =~ s/([$pat])/sprintf("%%%02lx", unpack("c",$1))/ge;
   $str =~ s/ /\+/g;
   return $str;
}     

# Decoda a string
sub unescape { 
   my ($str) = @_;
   $str =~ s/\+/ /g;
   $str =~ s/%(..)/pack("c", hex($1))/ge;
   return $str;
}

# substitui enters por html
sub clean {
   my($str) = @_;

   $str =~ s/\\r//g;
   $str =~ s/\\n\\n/<p>/g;
   $str =~ s/\\n/<br>/g;

   return $str;
}

1;

=head1 NAME

Ananke::Utils - Utility functions

=head1 DESCRIPTION

Utility functions used to facility your life

=head1 SYNOPSIS

	See all functions

=head1 METHODS

=head2 getCookies()
  
	Retrieves any cookie information from the browser

	%cookies = Ananke::Utils::getCookies;

=head2 getTime(timestamp)

	Return time in hh:mm:ss

	$var = &Ananke::Utils::getTime(time());

=head2 replace_chars(string)

	Replace all bad chars to html format

	$var = &Ananke::Utils::escape("«¼TesTÐª");

=head2 getForm(x,x)

	If you use modperl, this functions is very good

	my $r = shift;
	my (%form,$i,$j);
	$i=$r->content; $j=$r->args;
	%form = &Ananke::Utils::getForm($i,$j);

	this function understand array input, id[1], id[2],id[3]...

=head2 salt()

	Return randomic string, used for generate password

=head2 escape(string)

	URL encode

	http://web/this has spaces' -> 'http://web/this%20has%20spaces'

	$var = &Ananke::Utils::escape($ENV{'REQUEST_URI'});

=head2 unescape(string)

	URL decode

	http://web/this%20has%20spaces -> http://web/this has spaces'

	$var = &Ananke::Utils::unescape("http://web/this%20has%20spaces");

=head2 clean(string)

	Convert enter to <br> and 2 enters to <p>

	$var = clean($textarea);

=head1 AUTHOR

	Udlei D. R. Nattis
	nattis@anankeit.com.br
	http://www.nobol.com.br
	http://www.anankeit.com.br

=cut
