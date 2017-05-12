#!/usr/bin/perl -w
#########################################################################
#        This Perl script is Copyright (c) 2002, Peter J Billam         #
#               c/o P J B Computing, www.pjb.com.au                     #
#                                                                       #
#     This script is free software; you can redistribute it and/or      #
#            modify it under the same terms as Perl itself.             #
#########################################################################

use Test::Simple tests => 13;
use Crypt::Tea_JS;
use integer;

my $text = <<'EOT';
Hier lieg' ich auf dem Frülingshügel:
die Wolke wird mein Flügel,
ein Vogel fliegt mir voraus.

Ach, sag' mir, all-einzige Liebe,
wo du bleibst, daß ich bei dir bliebe !
doch du und die Lüfte, ihr habt kein Haus.

Der Sonnenblume gleich steht mein Gemüthe offen,
sehnend, sich dehnend in Lieben und Hoffen.
Frühling, was bist du gewillt ?
wenn werd' ich gestillt ?

Die Wolke seh' ich wandeln und den Fluß,
es dringt der Sonne goldner Kuß tief bis in's Geblüt hinein;
die Augen, wunderbar berauschet, thun, als scliefen sie ein,
nur noch das Ohr der Ton der Biene lauschet.

Ich denke Diess und denke Das,
ich sehne mich, und weiss nicht recht, nach was:
halb ist es Lust, halb ist es Klage;
mein Herz, o sage,
was webst du für Erinnerung
in goldnen grüner Zweige Dämmerung ?

Alte, unnennbare Tage !
EOT

ok (&Crypt::Tea_JS::binary2ascii(1234567,7654321,9182736,8273645)
 eq "ABLWhwB0y7EAjB4QAH4-7Q", "binary2ascii");

my @ary = &Crypt::Tea_JS::ascii2binary("GUQEX19vG3csxE9v2Vtwh");
ok (&equal(\@ary,
 [423887967, 1601117047, 751062895, 3646648452]), "ascii2binary");

@ary = &Crypt::Tea_JS::oldtea_code((2048299521,595110280),
  (032234174231,554905533,637549562,035705455446));
ok (&equal(\@ary, [034504733200, 1589210186]), "oldtea_code");

@ary = &Crypt::Tea_JS::oldtea_decode((2048299521,595110280),
  (032234174231,554905533,637549562,035705455446));
ok (&equal(\@ary, [036053034552, 023357663604]), "oldtea_decode");

@ary = &Crypt::Tea_JS::pp_oldtea_code((2048299521,595110280),
  (032234174231,554905533,637549562,035705455446));
ok (&equal(\@ary, [034504733200, 1589210186]), "pp_oldtea_code");

@ary = &Crypt::Tea_JS::pp_oldtea_decode((2048299521,595110280),
  (032234174231,554905533,637549562,035705455446));
ok (&equal(\@ary, [036053034552, 023357663604]), "pp_oldtea_decode");

@ary = &Crypt::Tea_JS::tea_code((2048299521,595110280),
  (032234174231,554905533,637549562,035705455446));
ok (&equal(\@ary, [023450705615, 826873245]), "tea_code");

@ary = &Crypt::Tea_JS::tea_decode((2048299521,595110280),
  (032234174231,554905533,637549562,035705455446));
ok (&equal(\@ary, [021317044354, 034350376361]), "tea_decode");

@ary = &Crypt::Tea_JS::pp_tea_code((2048299521,595110280),
  (032234174231,554905533,637549562,035705455446));
ok (&equal(\@ary, [023450705615, 826873245]), "pp_tea_code");

@ary = &Crypt::Tea_JS::pp_tea_decode((2048299521,595110280),
  (032234174231,554905533,637549562,035705455446));
ok (&equal(\@ary, [021317044354, 034350376361]), "pp_tea_decode");

ok (&asciidigest($text) eq "7IGNTaSe2ch6WTwcz6c1eA", "asciidigest");

my $key1 = &asciidigest ("G $$ ". time);
my $c = &encrypt ($text, $key1);
my $p = &decrypt ($c, $key1);
ok (($p eq $text), "encrypt and decrypt");

{
	no integer;
	if ($] > 5.007) {
		require Encode;
		$x = chr(400);
		$c = &encrypt ($x, $key1);
		$p = Encode::decode_utf8(&decrypt ($c, $key1));
		ok (($p eq $x), "encrypt and decrypt utf8");
	} else {
		ok (1, "skipping utf8 test for perl version < 5.007");
	}
}

&generate_test_html();

exit;
# --------------------------- infrastructure ----------------
sub equal { my ($xref, $yref) = @_;
	my $eps = .000000001;
	my @x = @$xref; my @y = @$yref;
	if (scalar @x != scalar @y) { return 0; }
	my $i; for ($i=$[; $i<=$#x; $i++) {
		if (abs($x[$i]-$y[$i]) > $eps) { return 0; }
	}
	return 1;
}

sub generate_test_html {
$key1 = &asciidigest ("G $$ ". time);
my $key2 = &asciidigest ("Arghhh... " . time ."Xgloopiegleep $$");

my $p1 = <<EOT;
If you are reading this paragraph, it has been successfully
encrypted by <I>Perl</I> and decrypted by <I>JavaScript</I>.
The password used was "$key1".
A localised error in the cyphertext will cause about
16 bytes of binary garbage to appear in the plaintext output.
EOT
my $p2 = <<EOT;
And if you are reading this one, it has been successfully
encrypted by <I>Perl</I>, decrypted by <I>JavaScript</I>,
and then, using a different password "$key2",
re-encrypted and re-decrypted by <I>JavaScript</I>.
This means that <B>everyting&nbsp;works</B>&nbsp;:-)
EOT

if (! open (F, '>test.html')) { die "# sorry, can't write to test.html: $!\n"; }
$ENV{REMOTE_ADDR} = '123.321.123.321';  # simulate CGI context
my $c1 = &encrypt ($p1, $key1); 
my $c2 = &encrypt ($p2, $key1); 
print F "<HTML><HEAD><TITLE>test.html</TITLE>\n",&tea_in_javascript(),<<'EOT';
</HEAD><BODY BGCOLOR="#FFFFFF">
<P><H2>
This page is a test of the JavaScript side of
<A HREF="http://search.cpan.org/~pjb">Crypt::Tea_JS.pm</A>
</H2></P>

<HR>
<H3>First a quick check of the various JavaScript functions . . .</H3>
<P>If any of these functions do not return what they should,
please use your mouse to cut-and-paste all the bit in
<CODE>constant-width</CODE> font, and paste it into an email to
<A HREF="http://www.pjb.com.au/comp/contact.html">Peter&nbsp;Billam</A>
</P>
<PRE>
<SCRIPT LANGUAGE="JavaScript"> <!--
EOT
print F <<EOT;
document.write('Crypt::Tea_JS ${Crypt::Tea_JS::VERSION} on ' + navigator.appName
EOT
print F <<'EOT';
 + ' ' + navigator.appVersion);
// -->
</SCRIPT>

binary2ascii(1234567,7654321,9182736,8273645)
<SCRIPT LANGUAGE="JavaScript"> <!--
var blocks = new Array();
blocks[0]=1234567; blocks[1]=7654321; blocks[2]=9182736; blocks[3]=8273645;
document.write('   returns ' + binary2ascii(blocks));
// -->
</SCRIPT>
 should be ABLWhwB0y7EAjB4QAH4-7Q

ascii2binary('GUQEX19vG3csxE9v2Vtwh') returns 
<SCRIPT LANGUAGE="JavaScript"> <!--
var b = new Array; b = ascii2binary('GUQEX19vG3csxE9v2Vtwh');
var ib = 0;  var lb = b.length;
document.write('   returns ');
while (1) {
 if (ib >= lb) break;
 document.write(b[ib] + ', ');
 ib++;
}
// -->
</SCRIPT>
 should be 423887967, 1601117047, 751062895, -648318844,

str2bytes('GUQEX19vG3csxE9')
<SCRIPT LANGUAGE="JavaScript"> <!--
var b = new Array; b = str2bytes('GUQEX19vG3csxE9');
var ib = 0;  var lb = b.length;
document.write('   returns ');
while (1) {
 if (ib >= lb) break;
 document.write(b[ib] + ', ');
 ib++;
}
// -->
</SCRIPT>
 should be 71, 85, 81, 69, 88, 49, 57, 118, 71, 51, 99, 115, 120, 69, 57,

bytes2str(88, 49, 118, 99, 115, 69)
<SCRIPT LANGUAGE="JavaScript"> <!--
var b = new Array;
b[0]=88; b[1]=49; b[2]=118; b[3]=99; b[4]=115; b[5]=69;
document.write('   returns ' + bytes2str(b));
// -->
</SCRIPT>
 should be X1vcsE

ascii2bytes('GUQEX19vG3csxE9v2') returns
<SCRIPT LANGUAGE="JavaScript"> <!--
var b = new Array; b = ascii2bytes('GUQEX19vG3csxE9v2');
var ib = 0;  var lb = b.length;
document.write('   returns ');
while (1) {
 if (ib >= lb) break;
 document.write(b[ib] + ', ');
 ib++;
}
// -->
</SCRIPT>
 should be 25, 68, 4, 95, 95, 111, 27, 119, 44, 196, 79, 111, 216,

bytes2str(88, 49, 118, 99, 115, 69)
<SCRIPT LANGUAGE="JavaScript"> <!--
var b = new Array;
b[0]=88; b[1]=49; b[2]=118; b[3]=99; b[4]=115; b[5]=69;
document.write('   returns ' + bytes2ascii(b));
// -->
</SCRIPT>
 should be WDF2Y3NF

bytes2blocks(88, 49, 118, 99, 115, 69)
<SCRIPT LANGUAGE="JavaScript"> <!--
var by = new Array;
by[0]=88; by[1]=49; by[2]=118; by[3]=99; by[4]=115; by[5]=69;
var bl = bytes2blocks(by); var ibl = 0;  var lbl = bl.length;
document.write('   returns ');
while (1) {
 if (ibl >= lbl) break;
 document.write(bl[ibl] + ', ');
 ibl++;
}
// -->
</SCRIPT>
 should be 1479636579, 1933901824,

digest_pad(88, 49, 118, 99, 115, 69)
<SCRIPT LANGUAGE="JavaScript"> <!--
var by = new Array;
by[0]=88; by[1]=49; by[2]=118; by[3]=99; by[4]=115; by[5]=69;
var bl = digest_pad(by); var ibl = 0;  var lbl = bl.length;
document.write('   returns ');
while (1) {
 if (ibl >= lbl) break;
 document.write(bl[ibl] + ', ');
 ibl++;
}
// -->
</SCRIPT>
 should be 9, 88, 49, 118, 99, 115, 69, 0, 0, 0, 0, 0, 0, 0, 0, 0,

pad(88, 49, 118, 99, 115, 69)
<SCRIPT LANGUAGE="JavaScript"> <!--
var by = new Array;
by[0]=88; by[1]=49; by[2]=118; by[3]=99; by[4]=115; by[5]=69;
var bl = pad(by); var ibl = 0;  var lbl = bl.length;
document.write('   returns ');
while (1) {
 if (ibl >= lbl) break;
 document.write(bl[ibl] + ', ');
 ibl++;
}
// -->
</SCRIPT>
 should be ??, 88, 49, 118, 99, 115, 69, ??,
 but note that the first and last bytes are random

unpad(121, 88, 49, 118, 99, 115, 69, 162)
<SCRIPT LANGUAGE="JavaScript"> <!--
var by = new Array;
by[0]=121;by[1]=88;by[2]=49;by[3]=118;by[4]=99;by[5]=115;by[6]=69;by[7]=162;
var bl = unpad(by); var ibl = 0;  var lbl = bl.length;
document.write('   returns ');
while (1) {
 if (ibl >= lbl) break;
 document.write(bl[ibl] + ', ');
 ibl++;
}
// -->
</SCRIPT>
 should be 88, 49, 118, 99, 115, 69,

asciidigest('Gloop gleep glorp glurp')
<SCRIPT LANGUAGE="JavaScript"> <!--
document.write('   returns ' + asciidigest('Gloop gleep glorp glurp'));
// -->
</SCRIPT>
 should be CygjbXoiuZ5g_O7F0MQG_A

binarydigest('Gloop gleep glorp glurp', 'ksmZjyFSBRc3_cHLUag9zA')
<SCRIPT LANGUAGE="JavaScript"> <!--
var bl = binarydigest('Gloop gleep glorp glurp', 'ksmZjyFSBRc3_cHLUag9zA');
var ibl = 0;  var lbl = bl.length;
document.write('   returns ');
while (1) {
 if (ibl >= lbl) break;
 document.write(bl[ibl] + ', ');
 ibl++;
}
// -->
</SCRIPT>
 should be 187179885, 2049096094, 1627188933, -792459524,

xor_blocks((2048299521, 595110280), (-764348263, -554905533))
<SCRIPT LANGUAGE="JavaScript"> <!--
var bl1 = new Array(); var bl2 = new Array();
bl1[0]=2048299521; bl1[1]=595110280; bl2[0]=-764348263; bl2[1]=-554905533;
var bl = xor_blocks(bl1,bl2);
var ibl = 0;  var lbl = bl.length;
document.write('   returns ');
while (1) {
 if (ibl >= lbl) break;
 document.write(bl[ibl] + ', ');
 ibl++;
}
// -->
</SCRIPT>
 should be -1469683048, -40601141,

tea_code((2048299521,595110280),
  (-764348263,554905533,637549562,-283747546))
<SCRIPT LANGUAGE="JavaScript"> <!--
var v = new Array(); var key = new Array();
v[0]=2048299521; v[1]=595110280;
key[0]=-764348263; key[1]=554905533;
key[2]=637549562; key[3]=-283747546;
var bl = tea_code(v,key);
var ibl = 0;  var lbl = bl.length;
document.write('   returns ');
while (1) {
 if (ibl >= lbl) break;
 document.write(bl[ibl] + ', ');
 ibl++;
}
// -->
</SCRIPT>
 should be -1667003507, 826873245,

tea_decode((2048299521,595110280),
  (-764348263,554905533,637549562,-283747546))
<SCRIPT LANGUAGE="JavaScript"> <!--
var v = new Array(); var key = new Array();
v[0]=2048299521; v[1]=595110280;
key[0]=-764348263; key[1]=554905533;
key[2]=637549562; key[3]=-283747546;
var bl = tea_decode(v,key);
var ibl = 0;  var lbl = bl.length;
document.write('   returns ');
while (1) { 
 if (ibl >= lbl) break; 
 document.write(bl[ibl] + ', ');
 ibl++;
}
// -->
</SCRIPT>
 should be -1958983444, -475923215,

</PRE>

EOT
print F <<EOT;
<HR><H3>Now a test of JavaScript decryption . . .</H3><P><FONT SIZE='+1'>
<SCRIPT LANGUAGE="JavaScript"> <!--
document.write(decrypt('$c1','$key1'));
// -->
</SCRIPT>
</FONT></P>

<HR><H3>Finally a test of JavaScript encryption . . .</H3><P><FONT SIZE='+1'>
<SCRIPT LANGUAGE="JavaScript"> <!--
var c2 = encrypt(decrypt('$c2','$key1'),'$key2');
document.write(decrypt(c2,'$key2'));
// -->
</SCRIPT>
</FONT></P>
<HR></BODY></HTML>
EOT
close F;

print "#      Now use a JavaScript-capable browser to view test.html ...\n";
}

__END__

=pod

=head1 NAME

test.pl - Perl script to test Crypt::Tea_JS.pm

=head1 SYNOPSIS

  make test
  netscape file:test.html

=head1 DESCRIPTION

This tests the Crypt::Tea_JS.pm module.

=head1 AUTHOR

Peter J Billam  http://www.pjb.com.au/comp/contact.html

=head1 SEE ALSO

http://www.pjb.com.au/ http://www.cpan.org perl(1).

=cut


