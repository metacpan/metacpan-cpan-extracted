# Tea_JS.pm 
#########################################################################
#        This Perl module is Copyright (c) 2000, Peter J Billam         #
#               c/o P J B Computing, www.pjb.com.au                     #
#                                                                       #
#     This module is free software; you can redistribute it and/or      #
#            modify it under the same terms as Perl itself.             #
#########################################################################
#
# implements TEA, the Tiny Encryption Algorithm, in Perl and Javascript.
# http://www.cl.cam.ac.uk/ftp/papers/djw-rmn/djw-rmn-tea.html
#
# Usage:
#    use Tea_JS;
#    $key = 'PUFgob$*LKDF D)(F IDD&P?/';
#    $ascii_cyphertext = encrypt($plaintext, $key);
#    ...
#    $plaintext_again = decrypt($ascii_cyphertext, $key);
#    ...
#    $signature = asciidigest($text);
#
# The $key is a sufficiently longish string; at least 17 random 8-bit bytes
#
# Written by Peter J Billam, http://www.pjb.com.au

package Crypt::Tea_JS;
$VERSION = '2.23';
# Don't like depending on externals; this is strong encrytion ... but ...
require Exporter;
@ISA = qw(Exporter);

eval { require XSLoader; XSLoader::load('Crypt::Tea_JS', $VERSION); };
if ($@) {   # 2.23 revert to PurePerl
	*tea_code      = \&pp_tea_code;
	*tea_decode    = \&pp_tea_decode;
	*oldtea_code   = \&pp_oldtea_code;
	*oldtea_decode = \&pp_oldtea_decode;
}

@EXPORT = qw(asciidigest encrypt decrypt tea_in_javascript);
@EXPORT_OK = qw(str2ascii ascii2str encrypt_and_write);
%EXPORT_TAGS = (ALL => [@EXPORT,@EXPORT_OK]);

BEGIN {
	if ($] < 5.006) {
		$INC{"bytes.pm"} = 1;       # cheating that bytes.pm is loaded
		*bytes::import   = sub { }; # do nothing
		*bytes::unimport = sub { };
	}
	if ($] > 5.007) { require Encode; }
}
if (! defined &tea_code) {
	die "C library missing, and couldn't eval pp_tea_code\n";
}
use bytes;

# begin config
my %a2b = (
	A=>000, B=>001, C=>002, D=>003, E=>004, F=>005, G=>006, H=>007,
	I=>010, J=>011, K=>012, L=>013, M=>014, N=>015, O=>016, P=>017,
	Q=>020, R=>021, S=>022, T=>023, U=>024, V=>025, W=>026, X=>027,
	Y=>030, Z=>031, a=>032, b=>033, c=>034, d=>035, e=>036, f=>037,
	g=>040, h=>041, i=>042, j=>043, k=>044, l=>045, m=>046, n=>047,
	o=>050, p=>051, q=>052, r=>053, s=>054, t=>055, u=>056, v=>057,
	w=>060, x=>061, y=>062, z=>063, '0'=>064,  '1'=>065, '2'=>066, '3'=>067,
	'4'=>070,'5'=>071,'6'=>072,'7'=>073,'8'=>074,'9'=>075,'-'=>076,'_'=>077,
);
my %b2a = reverse %a2b;
# $a2b{'+'}=076;
# end config

# ------------------ infrastructure ...

sub tea_in_javascript {
	my @js; while (<DATA>) { last if /^EOT$/; push @js, $_; } join '', @js;
}
sub encrypt_and_write { my ($str, $key) = @_;
	return unless $str; return unless $key;
	print
	"<SCRIPT LANGUAGE=\"JavaScript\">\n<!--\nparent.decrypt_and_write('";
	print encrypt($str,$key);
	print "');\n// -->\n</SCRIPT>\n";
}
sub binary2ascii {
	return str2ascii(binary2str(@_));
}
sub ascii2binary {
	return str2binary(ascii2str($_[$[]));
}
sub str2binary {   my @str = split //, $_[$[];
	my @intarray = (); my $ii = $[;
	while (1) {
		last unless @str; $intarray[$ii]  = (0xFF & ord shift @str)<<24;
		last unless @str; $intarray[$ii] |= (0xFF & ord shift @str)<<16;
		last unless @str; $intarray[$ii] |= (0xFF & ord shift @str)<<8;
		last unless @str; $intarray[$ii] |=  0xFF & ord shift @str;
		$ii++;
	}
	return @intarray;
}
sub binary2str {
	my @str = ();
	foreach $i (@_) {
		push @str, chr(0xFF & ($i>>24)), chr(0xFF & ($i>>16)),
		 chr(0xFF & ($i>>8)), chr(0xFF & $i);
	}
	return join '', @str;
}
sub ascii2str {   my $a = $_[$[]; # converts pseudo-base64 to string of bytes
	local $^W = 0;
	$a =~ tr#-A-Za-z0-9+_##cd;
	my $ia = $[-1;  my $la = length $a;   # BUG not length, final!
	my $ib = $[;  my @b = ();
	my $carry;
	while (1) {   # reads 4 ascii chars and produces 3 bytes
		$ia++; last if ($ia>=$la);
		$b[$ib]  = $a2b{substr $a, $ia+$[, 1}<<2;
		$ia++; last if ($ia>=$la);
		$carry=$a2b{substr $a, $ia+$[, 1};  $b[$ib] |= ($carry>>4); $ib++;
		# if low 4 bits of $carry are 0 and its the last char, then break
		$carry = 0xF & $carry; last if ($carry == 0 && $ia == ($la-1));
		$b[$ib]  = $carry<<4;
		$ia++; last if ($ia>=$la);
		$carry=$a2b{substr $a, $ia+$[, 1};  $b[$ib] |= ($carry>>2); $ib++;
		# if low 2 bits of $carry are 0 and its the last char, then break
		$carry = 03 & $carry; last if ($carry == 0 && $ia == ($la-1));
		$b[$ib]  = $carry<<6;
		$ia++; last if ($ia>=$la);
		$b[$ib] |= $a2b{substr $a, $ia+$[, 1}; $ib++;
	}
	return pack 'C*', @b;   # 2.16
}
sub str2ascii {   my $b = $_[$[]; # converts string of bytes to pseudo-base64
	my $ib = $[;  my $lb = length $b;  my @s = ();
	my $b1; my $b2; my $b3;
	my $carry;
	while (1) {   # reads 3 bytes and produces 4 ascii chars
		if ($ib >= $lb) { last; };
		$b1 = ord substr $b, $ib+$[, 1;  $ib++;
		push @s, $b2a{$b1>>2}; $carry = 03 & $b1;
		if ($ib >= $lb) { push @s, $b2a{$carry<<4}; last; }
		$b2 = ord substr $b, $ib+$[, 1;  $ib++;
		push @s, $b2a{($b2>>4) | ($carry<<4)}; $carry = 0xF & $b2;
		if ($ib >= $lb) { push @s, $b2a{$carry<<2}; last; }
		$b3 = ord substr $b, $ib+$[, 1;  $ib++;
		push @s, $b2a{($b3>>6) | ($carry<<2)}, $b2a{077 & $b3};
		if (!$ENV{REMOTE_ADDR} && (($ib % 36) == 0)) { push @s, "\n"; }
	}
	return join('', @s);
}
sub asciidigest {   # returns 22-char ascii signature
	return binary2ascii(binarydigest($_[$[]));
}
sub binarydigest { my $str = $_[$[];  # returns 4 32-bit-int binary signature
	# warning: mode of use invented by Peter Billam 1998, needs checking !
	return '' unless $str;
	if ($] > 5.007 && Encode::is_utf8($str)) {
		Encode::_utf8_off($str);
		# $str = Encode::encode_utf8($str);
	}
	# add 1 char ('0'..'15') at front to specify no of pad chars at end ...
	my $npads = 15 - ((length $str) % 16);
	$str  = chr($npads) . $str;
	if ($npads) { $str .= "\0" x $npads; }
	my @str = str2binary($str);
	my @key = (0x61626364, 0x62636465, 0x63646566, 0x64656667);

	my ($cswap, $v0, $v1, $v2, $v3);
	my $c0 = 0x61626364; my $c1 = 0x62636465; # CBC Initial Value. Retain !
	my $c2 = 0x61626364; my $c3 = 0x62636465; # likewise (abcdbcde).
	while (@str) {
		# shift 2 blocks off front of str ...
		$v0 = shift @str; $v1 = shift @str; $v2 = shift @str; $v3 = shift @str;
		# cipher them XOR'd with previous stage ...
		($c0,$c1) = tea_code($v0^$c0, $v1^$c1, @key);
		($c2,$c3) = tea_code($v2^$c2, $v3^$c3, @key);
		# mix up the two cipher blocks with a 4-byte left rotation ...
		$cswap  = $c0; $c0=$c1; $c1=$c2; $c2=$c3; $c3=$cswap;
	}
	return ($c0,$c1,$c2,$c3);
}
sub encrypt { my ($str,$key)=@_; # encodes with CBC (Cipher Block Chaining)
	return '' unless $str; return '' unless $key;
	if ($] > 5.007 && Encode::is_utf8($str)) {
		Encode::_utf8_off($str);
		# $str = Encode::encode_utf8($str);
	}
	use integer;
	@key = binarydigest($key);

	# add 1 char ('0'..'7') at front to specify no of pad chars at end ...
	my $npads = 7 - ((length $str) % 8);
	$str  = chr($npads|(0xF8 & rand_byte())) . $str;
	if ($npads) {
		my $padding = pack 'CCCCCCC', rand_byte(), rand_byte(),
		 rand_byte(), rand_byte(), rand_byte(), rand_byte(), rand_byte(); 
		$str  = $str . substr($padding,$[,$npads);
	}
	my @pblocks = str2binary($str);
	my $v0; my $v1;
	my $c0 = 0x61626364; my $c1 = 0x62636465; # CBC Initial Value. Retain !
	my @cblocks;
	while (1) {
		last unless @pblocks; $v0 = shift @pblocks; $v1 = shift @pblocks;
		($c0,$c1) = tea_code($v0^$c0, $v1^$c1, @key);
		push @cblocks, $c0, $c1;
	}
	return str2ascii( binary2str(@cblocks) );
}
sub decrypt { my ($acstr, $key) = @_;   # decodes with CBC
	use integer;
	return '' unless $acstr; return '' unless $key;
	@key = binarydigest($key);
	my $v0; my $v1; my $c0; my $c1; my @pblocks = (); my $de0; my $de1;
	my $lastc0 = 0x61626364; my $lastc1 = 0x62636465; # CBC Init Val. Retain!
	my @cblocks = str2binary( ascii2str($acstr) );
	while (1) {
		last unless @cblocks; $c0 = shift @cblocks; $c1 = shift @cblocks;
		($de0, $de1) = tea_decode($c0,$c1, @key);
		$v0 = $lastc0 ^ $de0;   $v1 = $lastc1 ^ $de1;
		push @pblocks, $v0, $v1;
		$lastc0 = $c0;   $lastc1 = $c1;
	}
	my $str = binary2str(@pblocks);
	# remove no of pad chars at end specified by 1 char ('0'..'7') at front
	my $npads = 0x7 & ord $str; substr ($str, $[, 1) = '';
	if ($npads) { substr ($str, 0 - $npads) = ''; }
	return $str;
}
sub triple_encrypt { my ($plaintext,  $long_key) = @_;  # not yet ...
}
sub triple_decrypt { my ($cyphertext, $long_key) = @_;  # not yet ...
}

# PurePerl versions: introduced in 2.23
sub pp_tea_code  { my ($v0,$v1,@k) = @_;
	# Note that both "<<" and ">>" in Perl are implemented directly using
	# "<<" and ">>" in C.  If "use integer" (see "Integer Arithmetic") is in
	# force then signed C integers are used, else unsigned C integers are used.
	use integer;
	my $sum = 0; my $n = 32;
	while ($n-- > 0) {
		$v0 += ((($v1<<4)^(0x07FFFFFF&($v1>>5)))+$v1) ^ ($sum+$k[$sum&3]);
		$v0 &= 0xFFFFFFFF;
		$sum += 0x9e3779b9;   # TEA magic number delta
		# $sum &= 0xFFFFFFFF; # changes nothing
		$v1 += ((($v0<<4)^(0x07FFFFFF&($v0>>5)))+$v0)^($sum+$k[($sum>>11)&3]);
		$v1 &= 0xFFFFFFFF;
	}
	return ($v0, $v1);
}
sub pp_tea_decode  { my ($v0,$v1, @k) = @_;
	use integer;
	my $sum = 0; my $n = 32;
	$sum = 0x9e3779b9 << 5 ;   # TEA magic number delta
	while ($n-- > 0) {
		$v1 -= ((($v0<<4)^(0x07FFFFFF&($v0>>5)))+$v0)^($sum+$k[($sum>>11)&3]);
		$v1 &= 0xFFFFFFFF;
		$sum -= 0x9e3779b9 ;
		$v0 -= ((($v1<<4)^(0x07FFFFFF&($v1>>5)))+$v1) ^ ($sum+$k[$sum&3]);
		$v0 &= 0xFFFFFFFF;
	}
	return ($v0, $v1);
}
sub pp_oldtea_code  { my ($v0,$v1, $k0,$k1,$k2,$k3) = @_;
	use integer;
	my $sum = 0; my $n = 32;
	while ($n-- > 0) {
		$sum += 0x9e3779b9;   # TEA magic number delta
		$v0 += (($v1<<4)+$k0) ^ ($v1+$sum) ^ ((0x07FFFFFF & ($v1>>5))+$k1) ;
		$v0 &= 0xFFFFFFFF;
		$v1 += (($v0<<4)+$k2) ^ ($v0+$sum) ^ ((0x07FFFFFF & ($v0>>5))+$k3) ;
		$v1 &= 0xFFFFFFFF;
	}
	return ($v0, $v1);
}
sub pp_oldtea_decode  { my ($v0,$v1, $k0,$k1,$k2,$k3) = @_;
	use integer;
	my $sum = 0; my $n = 32;
	$sum = 0x9e3779b9 << 5 ;   # TEA magic number delta
	while ($n-- > 0) {
		$v1 -= (($v0<<4)+$k2) ^ ($v0+$sum) ^ ((0x07FFFFFF & ($v0>>5))+$k3) ;
		$v1 &= 0xFFFFFFFF;
		$v0 -= (($v1<<4)+$k0) ^ ($v1+$sum) ^ ((0x07FFFFFF & ($v1>>5))+$k1) ;
		$v0 &= 0xFFFFFFFF;
		$sum -= 0x9e3779b9 ;
	}
	return ($v0, $v1);
}

sub rand_byte {
	if (! $rand_byte_already_called) {
		srand(time() ^ ($$+($$<<15))); # could do better, but its only padding
		$rand_byte_already_called = 1;
	}
	int(rand 256);
}
1;

__DATA__

<SCRIPT LANGUAGE="JavaScript">
<!--
//        This JavaScript is Copyright (c) 2000, Peter J Billam
//              c/o P J B Computing, www.pjb.com.au
// It was generated by the Crypt::Tea_JS.pm Perl module and is free software;
// you can redistribute and modify it under the same terms as Perl itself.

// -- conversion routines between string, bytes, ascii encoding, & blocks --
function binary2ascii (s) {
 return bytes2ascii( blocks2bytes(s) );
}
function binary2str (s) {
 return bytes2str( blocks2bytes(s) );
}
function ascii2binary (s) {
 return bytes2blocks( ascii2bytes(s) );
}
function str2binary (s) {
 return bytes2blocks( str2bytes(s) );
}
function str2bytes(s) {   // converts string to array of bytes
 var is = 0;  var ls = s.length;  var b = new Array();
 while (1) {
  if (is >= ls) break;
  if (c2b[s.charAt(is)] == null) { b[is] = 0xF7;
   alert ('is = '+is + '\nchar = '+s.charAt(is) + '\nls = '+ls);
  } else { b[is] = c2b[s.charAt(is)];
  }
  is++;
 }
 return b;
}
function bytes2str(b) {   // converts array of bytes to string
 var ib = 0;  var lb = b.length;  var s = '';
 while (1) {
  if (ib >= lb) break;
  s += b2c[0xFF&b[ib]];   // if its like perl, could be faster with join
  ib++;
 }
 return s;
}
function ascii2bytes(a) { // converts pseudo-base64 to array of bytes
 var ia = -1;  var la = a.length;
 var ib = 0;  var b = new Array();
 var carry;
 while (1) {   // reads 4 chars and produces 3 bytes
  while (1) { ia++; if (ia>=la) return b; if (a2b[a.charAt(ia)]!=null) break; }
  b[ib]  = a2b[a.charAt(ia)]<<2;
  while (1) { ia++; if (ia>=la) return b; if (a2b[a.charAt(ia)]!=null) break; }
  carry=a2b[a.charAt(ia)];  b[ib] |= carry>>>4; ib++;
  // if low 4 bits of carry are 0 and its the last char, then break
  carry = 0xF & carry;
  if (carry == 0 && ia == (la-1)) return b;
  b[ib]  = carry<<4;
  while (1) { ia++; if (ia>=la) return b; if (a2b[a.charAt(ia)]!=null) break; }
  carry=a2b[a.charAt(ia)];  b[ib] |= carry>>>2; ib++;
  // if low 2 bits of carry are 0 and its the last char, then break
  carry = 3 & carry;
  if (carry == 0 && ia == (la-1)) return b;
  b[ib]  = carry<<6;
  while (1) { ia++; if (ia>=la) return b; if (a2b[a.charAt(ia)]!=null) break; }
  b[ib] |= a2b[a.charAt(ia)];   ib++;
 }
 return b;
}
function bytes2ascii(b) { // converts array of bytes to pseudo-base64 ascii
 var ib = 0;   var lb = b.length;  var s = '';
 var b1; var b2; var b3;
 var carry;
 while (1) {   // reads 3 bytes and produces 4 chars
  if (ib >= lb) break;   b1 = 0xFF & b[ib];
  s += b2a[63 & (b1>>>2)];
  carry = 3 & b1;
  ib++;  if (ib >= lb) { s += b2a[carry<<4]; break; }  b2 = 0xFF & b[ib];
  s += b2a[(0xF0 & (carry<<4)) | (b2>>>4)];
  carry = 0xF & b2;
  ib++;  if (ib >= lb) { s += b2a[carry<<2]; break; }  b3 = 0xFF & b[ib];
  s += b2a[(60 & (carry<<2)) | (b3>>>6)] + b2a[63 & b3];
  ib++;
  if (ib % 36 == 0) s += "\n";
 }
 return s;
}
function bytes2blocks(bytes) {
 var blocks = new Array(); var ibl = 0;
 var iby = 0; var nby = bytes.length;
 while (1) {
  blocks[ibl]  = (0xFF & bytes[iby])<<24; iby++; if (iby >= nby) break;
  blocks[ibl] |= (0xFF & bytes[iby])<<16; iby++; if (iby >= nby) break;
  blocks[ibl] |= (0xFF & bytes[iby])<<8;  iby++; if (iby >= nby) break;
  blocks[ibl] |=  0xFF & bytes[iby];      iby++; if (iby >= nby) break;
  ibl++;
 }
 return blocks;
}
function blocks2bytes(blocks) {
 var bytes = new Array(); var iby = 0;
 var ibl = 0; var nbl = blocks.length;
 while (1) {
  if (ibl >= nbl) break;
  bytes[iby] = 0xFF & (blocks[ibl] >>> 24); iby++;
  bytes[iby] = 0xFF & (blocks[ibl] >>> 16); iby++;
  bytes[iby] = 0xFF & (blocks[ibl] >>> 8);  iby++;
  bytes[iby] = 0xFF & blocks[ibl]; iby++;
  ibl++;
 }
 return bytes;
}
function digest_pad (bytearray) {
 // add 1 char ('0'..'15') at front to specify no of \x00 pad chars at end
 var newarray = new Array();  var ina = 0;
 var iba = 0; var nba = bytearray.length;
 var npads = 15 - (nba % 16); newarray[ina] = npads; ina++;
 while (iba < nba) { newarray[ina] = bytearray[iba]; ina++; iba++; }
 var ip = npads; while (ip>0) { newarray[ina] = 0; ina++; ip--; }
 return newarray;
}
function pad (bytearray) {
 // add 1 char ('0'..'7') at front to specify no of rand pad chars at end
 // unshift and push fail on Netscape 4.7 :-(
 var newarray = new Array();  var ina = 0;
 var iba = 0; var nba = bytearray.length;
 var npads = 7 - (nba % 8);
 newarray[ina] = (0xF8 & rand_byte()) | (7 & npads); ina++;
 while (iba < nba) { newarray[ina] = bytearray[iba]; ina++; iba++; }
 var ip = npads; while (ip>0) { newarray[ina] = rand_byte(); ina++; ip--; }
 return newarray;
}
function rand_byte() {   // used by pad
 return Math.floor( 256*Math.random() );  // Random needs js1.1 . Seed ?
 // for js1.0 compatibility, could try following ...
 if (! rand_byte_already_called) {
  var now = new Date();  seed = now.milliseconds;
  rand_byte_already_called = true;
 }
 seed = (1029*seed + 221591) % 1048576;  // see Fortran77, Wagener, p177
 return Math.floor(seed / 4096);
}
function unpad (bytearray) {
 // remove no of pad chars at end specified by 1 char ('0'..'7') at front
 // unshift and push fail on Netscape 4.7 :-(
 var iba = 0;
 var newarray = new Array();  var ina = 0;
 var npads = 0x7 & bytearray[iba]; iba++; var nba = bytearray.length - npads;
 while (iba < nba) { newarray[ina] = bytearray[iba]; ina++; iba++; }
 return newarray;
}

// --- TEA stuff, translated from the Perl Tea_JS.pm see www.pjb.com.au/comp ---

// In JavaScript we express an 8-byte block as an array of 2 32-bit ints
function asciidigest (str) {
 return binary2ascii( binarydigest(str) );
}
function binarydigest (str, keystr) {  // returns 22-char ascii signature
 var key = new Array(); // key = binarydigest(keystr);
 key[0]=0x61626364; key[1]=0x62636465; key[2]=0x63646566; key[3]=0x64656667;

 // Initial Value for CBC mode = "abcdbcde". Retain for interoperability.
 var c0 = new Array(); c0[0] = 0x61626364; c0[1] = 0x62636465;
 var c1 = new Array(); c1 = c0;

 var v0 = new Array(); var v1 = new Array(); var swap;
 var blocks = new Array(); blocks = bytes2blocks(digest_pad(str2bytes(str))); 
 var ibl = 0;   var nbl = blocks.length;
 while (1) {
  if (ibl >= nbl) break;
  v0[0] = blocks[ibl]; ibl++; v0[1] = blocks[ibl]; ibl++;
  v1[0] = blocks[ibl]; ibl++; v1[1] = blocks[ibl]; ibl++;
  // cipher them XOR'd with previous stage ...
  c0 = tea_code( xor_blocks(v0,c0), key );
  c1 = tea_code( xor_blocks(v1,c1), key );
  // mix up the two cipher blocks with a 32-bit left rotation ...
  swap=c0[0]; c0[0]=c0[1]; c0[1]=c1[0]; c1[0]=c1[1]; c1[1]=swap;
 }
 var concat = new Array();
 concat[0]=c0[0]; concat[1]=c0[1]; concat[2]=c1[0]; concat[3]=c1[1];
 return concat;
}
function encrypt (str,keystr) {  // encodes with CBC (Cipher Block Chaining)
 if (! keystr) { alert("encrypt: no key"); return false; }
 var key = new Array();  key = binarydigest(keystr);
 if (! str) return "";
 var blocks = new Array(); blocks = bytes2blocks(pad(str2bytes(str)));
 var ibl = 0;  var nbl = blocks.length;
 // Initial Value for CBC mode = "abcdbcde". Retain for interoperability.
 var c = new Array(); c[0] = 0x61626364; c[1] = 0x62636465;
 var v = new Array(); var cblocks = new Array();  var icb = 0;
 while (1) {
  if (ibl >= nbl) break;
  v[0] = blocks[ibl];  ibl++; v[1] = blocks[ibl];  ibl++;
  c = tea_code( xor_blocks(v,c), key );
  cblocks[icb] = c[0]; icb++; cblocks[icb] = c[1]; icb++;
 }
 return binary2ascii(cblocks);
}
function decrypt (ascii, keystr) {   // decodes with CBC
 if (! keystr) { alert("decrypt: no key"); return false; }
 var key = new Array();  key = binarydigest(keystr);
 if (! ascii) return "";
 var cblocks = new Array(); cblocks = ascii2binary(ascii);
 var icbl = 0;  var ncbl = cblocks.length;
 // Initial Value for CBC mode = "abcdbcde". Retain for interoperability.
 var lastc = new Array(); lastc[0] = 0x61626364; lastc[1] = 0x62636465;
 var v = new Array(); var c = new Array();
 var blocks = new Array(); var ibl = 0;
 while (1) {
  if (icbl >= ncbl) break;
  c[0] = cblocks[icbl];  icbl++;  c[1] = cblocks[icbl];  icbl++;
  v = xor_blocks( lastc, tea_decode(c,key) );
  blocks[ibl] = v[0];  ibl++;  blocks[ibl] = v[1];  ibl++;
  lastc[0] = c[0]; lastc[1] = c[1];
 }
 return bytes2str(unpad(blocks2bytes(blocks)));
}
function xor_blocks(blk1, blk2) { // xor of two 8-byte blocks
 var blk = new Array();
 blk[0] = blk1[0]^blk2[0]; blk[1] = blk1[1]^blk2[1];
 return blk;
}
function tea_code (v, k) {
 // NewTEA. 2-int (64-bit) cyphertext block in v. 4-int (128-bit) key in k.
 var v0  = v[0]; var v1 = v[1];
 var sum = 0; var n = 32;
 while (n-- > 0) {
  v0 += (((v1<<4)^(v1>>>5))+v1) ^ (sum+k[sum&3]) ; v0 = v0|0 ;
  sum -= 1640531527; // TEA magic number 0x9e3779b9 
  sum = sum|0;  // force it back to 32-bit int
  v1 += (((v0<<4)^(v0>>>5))+v0) ^ (sum+k[(sum>>>11)&3]); v1 = v1|0 ;
 }
 var w = new Array(); w[0] = v0; w[1] = v1; return w;
}
function tea_decode (v, k) {
 // NewTEA. 2-int (64-bit) cyphertext block in v. 4-int (128-bit) key in k.
 var v0 = v[0]; var v1 = v[1];
 var sum = 0; var n = 32;
 sum = -957401312 ; // TEA magic number 0x9e3779b9<<5 
 while (n-- > 0) {
  v1 -= (((v0<<4)^(v0>>>5))+v0) ^ (sum+k[(sum>>>11)&3]); v1 = v1|0 ;
  sum += 1640531527; // TEA magic number 0x9e3779b9 ;
  sum = sum|0; // force it back to 32-bit int
  v0 -= (((v1<<4)^(v1>>>5))+v1) ^ (sum+k[sum&3]); v0 = v0|0 ;
 }
 var w = new Array(); w[0] = v0; w[1] = v1; return w;
}

// ------------- assocarys used by the conversion routines -----------
c2b = new Object();
c2b["\x00"]=0;  c2b["\x01"]=1;  c2b["\x02"]=2;  c2b["\x03"]=3;
c2b["\x04"]=4;  c2b["\x05"]=5;  c2b["\x06"]=6;  c2b["\x07"]=7;
c2b["\x08"]=8;  c2b["\x09"]=9;  c2b["\x0A"]=10; c2b["\x0B"]=11;
c2b["\x0C"]=12; c2b["\x0D"]=13; c2b["\x0E"]=14; c2b["\x0F"]=15;
c2b["\x10"]=16; c2b["\x11"]=17; c2b["\x12"]=18; c2b["\x13"]=19;
c2b["\x14"]=20; c2b["\x15"]=21; c2b["\x16"]=22; c2b["\x17"]=23;
c2b["\x18"]=24; c2b["\x19"]=25; c2b["\x1A"]=26; c2b["\x1B"]=27;
c2b["\x1C"]=28; c2b["\x1D"]=29; c2b["\x1E"]=30; c2b["\x1F"]=31;
c2b["\x20"]=32; c2b["\x21"]=33; c2b["\x22"]=34; c2b["\x23"]=35;
c2b["\x24"]=36; c2b["\x25"]=37; c2b["\x26"]=38; c2b["\x27"]=39;
c2b["\x28"]=40; c2b["\x29"]=41; c2b["\x2A"]=42; c2b["\x2B"]=43;
c2b["\x2C"]=44; c2b["\x2D"]=45; c2b["\x2E"]=46; c2b["\x2F"]=47;
c2b["\x30"]=48; c2b["\x31"]=49; c2b["\x32"]=50; c2b["\x33"]=51;
c2b["\x34"]=52; c2b["\x35"]=53; c2b["\x36"]=54; c2b["\x37"]=55;
c2b["\x38"]=56; c2b["\x39"]=57; c2b["\x3A"]=58; c2b["\x3B"]=59;
c2b["\x3C"]=60; c2b["\x3D"]=61; c2b["\x3E"]=62; c2b["\x3F"]=63;
c2b["\x40"]=64; c2b["\x41"]=65; c2b["\x42"]=66; c2b["\x43"]=67;
c2b["\x44"]=68; c2b["\x45"]=69; c2b["\x46"]=70; c2b["\x47"]=71;
c2b["\x48"]=72; c2b["\x49"]=73; c2b["\x4A"]=74; c2b["\x4B"]=75;
c2b["\x4C"]=76; c2b["\x4D"]=77; c2b["\x4E"]=78; c2b["\x4F"]=79;
c2b["\x50"]=80; c2b["\x51"]=81; c2b["\x52"]=82; c2b["\x53"]=83;
c2b["\x54"]=84; c2b["\x55"]=85; c2b["\x56"]=86; c2b["\x57"]=87;
c2b["\x58"]=88; c2b["\x59"]=89; c2b["\x5A"]=90; c2b["\x5B"]=91;
c2b["\x5C"]=92; c2b["\x5D"]=93; c2b["\x5E"]=94; c2b["\x5F"]=95;
c2b["\x60"]=96; c2b["\x61"]=97; c2b["\x62"]=98; c2b["\x63"]=99;
c2b["\x64"]=100; c2b["\x65"]=101; c2b["\x66"]=102; c2b["\x67"]=103;
c2b["\x68"]=104; c2b["\x69"]=105; c2b["\x6A"]=106; c2b["\x6B"]=107;
c2b["\x6C"]=108; c2b["\x6D"]=109; c2b["\x6E"]=110; c2b["\x6F"]=111;
c2b["\x70"]=112; c2b["\x71"]=113; c2b["\x72"]=114; c2b["\x73"]=115;
c2b["\x74"]=116; c2b["\x75"]=117; c2b["\x76"]=118; c2b["\x77"]=119;
c2b["\x78"]=120; c2b["\x79"]=121; c2b["\x7A"]=122; c2b["\x7B"]=123;
c2b["\x7C"]=124; c2b["\x7D"]=125; c2b["\x7E"]=126; c2b["\x7F"]=127;
c2b["\x80"]=128; c2b["\x81"]=129; c2b["\x82"]=130; c2b["\x83"]=131;
c2b["\x84"]=132; c2b["\x85"]=133; c2b["\x86"]=134; c2b["\x87"]=135;
c2b["\x88"]=136; c2b["\x89"]=137; c2b["\x8A"]=138; c2b["\x8B"]=139;
c2b["\x8C"]=140; c2b["\x8D"]=141; c2b["\x8E"]=142; c2b["\x8F"]=143;
c2b["\x90"]=144; c2b["\x91"]=145; c2b["\x92"]=146; c2b["\x93"]=147;
c2b["\x94"]=148; c2b["\x95"]=149; c2b["\x96"]=150; c2b["\x97"]=151;
c2b["\x98"]=152; c2b["\x99"]=153; c2b["\x9A"]=154; c2b["\x9B"]=155;
c2b["\x9C"]=156; c2b["\x9D"]=157; c2b["\x9E"]=158; c2b["\x9F"]=159;
c2b["\xA0"]=160; c2b["\xA1"]=161; c2b["\xA2"]=162; c2b["\xA3"]=163;
c2b["\xA4"]=164; c2b["\xA5"]=165; c2b["\xA6"]=166; c2b["\xA7"]=167;
c2b["\xA8"]=168; c2b["\xA9"]=169; c2b["\xAA"]=170; c2b["\xAB"]=171;
c2b["\xAC"]=172; c2b["\xAD"]=173; c2b["\xAE"]=174; c2b["\xAF"]=175;
c2b["\xB0"]=176; c2b["\xB1"]=177; c2b["\xB2"]=178; c2b["\xB3"]=179;
c2b["\xB4"]=180; c2b["\xB5"]=181; c2b["\xB6"]=182; c2b["\xB7"]=183;
c2b["\xB8"]=184; c2b["\xB9"]=185; c2b["\xBA"]=186; c2b["\xBB"]=187;
c2b["\xBC"]=188; c2b["\xBD"]=189; c2b["\xBE"]=190; c2b["\xBF"]=191;
c2b["\xC0"]=192; c2b["\xC1"]=193; c2b["\xC2"]=194; c2b["\xC3"]=195;
c2b["\xC4"]=196; c2b["\xC5"]=197; c2b["\xC6"]=198; c2b["\xC7"]=199;
c2b["\xC8"]=200; c2b["\xC9"]=201; c2b["\xCA"]=202; c2b["\xCB"]=203;
c2b["\xCC"]=204; c2b["\xCD"]=205; c2b["\xCE"]=206; c2b["\xCF"]=207;
c2b["\xD0"]=208; c2b["\xD1"]=209; c2b["\xD2"]=210; c2b["\xD3"]=211;
c2b["\xD4"]=212; c2b["\xD5"]=213; c2b["\xD6"]=214; c2b["\xD7"]=215;
c2b["\xD8"]=216; c2b["\xD9"]=217; c2b["\xDA"]=218; c2b["\xDB"]=219;
c2b["\xDC"]=220; c2b["\xDD"]=221; c2b["\xDE"]=222; c2b["\xDF"]=223;
c2b["\xE0"]=224; c2b["\xE1"]=225; c2b["\xE2"]=226; c2b["\xE3"]=227;
c2b["\xE4"]=228; c2b["\xE5"]=229; c2b["\xE6"]=230; c2b["\xE7"]=231;
c2b["\xE8"]=232; c2b["\xE9"]=233; c2b["\xEA"]=234; c2b["\xEB"]=235;
c2b["\xEC"]=236; c2b["\xED"]=237; c2b["\xEE"]=238; c2b["\xEF"]=239;
c2b["\xF0"]=240; c2b["\xF1"]=241; c2b["\xF2"]=242; c2b["\xF3"]=243;
c2b["\xF4"]=244; c2b["\xF5"]=245; c2b["\xF6"]=246; c2b["\xF7"]=247;
c2b["\xF8"]=248; c2b["\xF9"]=249; c2b["\xFA"]=250; c2b["\xFB"]=251;
c2b["\xFC"]=252; c2b["\xFD"]=253; c2b["\xFE"]=254; c2b["\xFF"]=255;
b2c = new Object();
for (b in c2b) { b2c[c2b[b]] = b; }

// ascii to 6-bit bin to ascii
a2b = new Object();
a2b["A"]=0;  a2b["B"]=1;  a2b["C"]=2;  a2b["D"]=3;
a2b["E"]=4;  a2b["F"]=5;  a2b["G"]=6;  a2b["H"]=7;
a2b["I"]=8;  a2b["J"]=9;  a2b["K"]=10; a2b["L"]=11;
a2b["M"]=12; a2b["N"]=13; a2b["O"]=14; a2b["P"]=15;
a2b["Q"]=16; a2b["R"]=17; a2b["S"]=18; a2b["T"]=19;
a2b["U"]=20; a2b["V"]=21; a2b["W"]=22; a2b["X"]=23;
a2b["Y"]=24; a2b["Z"]=25; a2b["a"]=26; a2b["b"]=27;
a2b["c"]=28; a2b["d"]=29; a2b["e"]=30; a2b["f"]=31;
a2b["g"]=32; a2b["h"]=33; a2b["i"]=34; a2b["j"]=35;
a2b["k"]=36; a2b["l"]=37; a2b["m"]=38; a2b["n"]=39;
a2b["o"]=40; a2b["p"]=41; a2b["q"]=42; a2b["r"]=43;
a2b["s"]=44; a2b["t"]=45; a2b["u"]=46; a2b["v"]=47;
a2b["w"]=48; a2b["x"]=49; a2b["y"]=50; a2b["z"]=51;
a2b["0"]=52; a2b["1"]=53; a2b["2"]=54; a2b["3"]=55;
a2b["4"]=56; a2b["5"]=57; a2b["6"]=58; a2b["7"]=59;
a2b["8"]=60; a2b["9"]=61; a2b["-"]=62; a2b["_"]=63;

b2a = new Object();
for (b in a2b) { b2a[a2b[b]] = ''+b; }
// -->
</SCRIPT>
EOT

=pod

=head1 NAME

Tea_JS.pm - The Tiny Encryption Algorithm in Perl and JavaScript

=head1 SYNOPSIS

Usage:

 use Crypt::Tea_JS;
 $key = 'PUFgob$*LKDF D)(F IDD&P?/';
 $ascii_cyphertext = encrypt($plaintext, $key);
 ...
 $plaintext_again = decrypt($ascii_cyphertext, $key);
 ...
 $signature = asciidigest($text);

In CGI scripts:

 use Crypt::Tea_JS;
 print tea_in_javascript();
 # now the browser can encrypt and decrypt ! In JS:
 var ascii_ciphertext = encrypt (plaintext, key);
 var plaintext_again  = decrypt (ascii_ciphertext, key);
 var signature = asciidigest (text);

=head1 DESCRIPTION

This module implements TEA, the Tiny Encryption Algorithm,
and some Modes of Use, in Perl and JavaScript.

The $key is a sufficiently longish string; at least 17 random 8-bit
bytes for single encryption.

Crypt::Tea_JS can be used for secret-key encryption in general,
or, in particular, to communicate securely between browser and web-host.
In this case, the simplest arrangement is for the user to
enter the key into a JavaScript variable, and for the host to
retrieve that user's key from a database.
Or, for extra security, the first message (or even each message)
between browser and host could contain a random challenge-string,
which each end would then turn into a signature,
and use that signature as the encryption-key for the session (or the reply).

If a travelling employee can carry a session-startup file
(e.g. I<login_on_the_road.html>) on their laptop,
then they are invulnerable to imposter-web-hosts
trying to feed them trojan JavaScript.

Version 2.23

(c) Peter J Billam 1998

=head1 SUBROUTINES

=over 3

=item I<encrypt>( $plaintext, $key );

Encrypts with CBC (Cipher Block Chaining)

=item I<decrypt>( $cyphertext, $key );

Decrypts with CBC (Cipher Block Chaining)

=item I<asciidigest>( $a_string );

Returns an asciified binary signature of the argument.

=item I<tea_in_javascript>();

Returns a compatible implementation of TEA in JavaScript,
for use in CGI scripts to communicate with browsers.

=back

=head1 EXPORT_OK SUBROUTINES

The following routines are not exported by default,
but are exported under the I<ALL> tag, so if you need them you should:

 import Crypt::Tea_JS qw(:ALL);

=over 3

=item I<binary2ascii>( $a_binary_string );

Provides an ascii text encoding of the binary argument.
If Tea_JS.pm is not being invoked from a GCI script,
the ascii is split into lines of 72 characters.

=item I<ascii2binary>( $an_ascii_string );

Provides the binary original of an ascii text encoding.

=back

=head1 JAVASCRIPT

At the browser end, the following functions offer the same
functionality as their perl equivalents above:

=over 3

=item I<encrypt> ( str, keystr )

=item I<decrypt> ( ascii, keystr )

=item I<asciidigest> ( str );

=back

Of course the same Key must be used by the Perl on the server
and by the JavaScript in the browser, and of course you
don't want to transmit the Key in cleartext between them.
Let's assume you've already asked the user to fill in a form
asking for their Username, and that this username can be transmitted
back and forth in cleartext as an ordinary form variable.

On the server, typically you will retrieve the Key from a
database of some sort, for example:

 dbmopen %keys, "/home/wherever/passwords", 0666;
 $key = $keys{$username};  dbmclose %keys;
 $cyphertext = encrypt("<P>Hello World !</P>\n", $key);

At the browser end, just ask the user for their password when
they load an encrypted page, e.g.

 print tea_in_javascript(), <<EOT;
 <SCRIPT LANGUAGE="JavaScript">
 var key = prompt("Password ?","");
 document.write(decrypt($cyphertext, key));
 </SCRIPT>
 EOT

To submit an encrypted FORM, the traditional way is to construct two FORMs;
an overt one which the user fills in but which never actually gets
submitted, and a covert one which will hold the cyphertext.
See the cgi script C<examples/old_tea_demo.cgi> in the distribution directory.

More often you want the browser to remember its Key from page to page, to
form a session.  If you store the Key in a Cookie, it is vulnerable to any
imposter server who imitates your IP address, and also to anyone who sits
down at the user's computer.  Better is to store the Key in a JavaScript
variable, and communicate with the server in I<Ajax> style, with
I<XMLHttpRequest> or I<ActiveXObject>, and I<responseText> or I<responseXML>.
See the cgi script C<examples/tea_demo.cgi> in the distribution directory.

In the distribution directory there is also C<Tea_JS.js>, which is
simply the output of C<tea_in_javascript()>.  This could be useful
if your initial login page is an HTML page rather than a CGI script.

=head1 ROADMAP

Crypt::Tea conflicted with a similarly-named Crypt::TEA by Abhijit Menon-Sen.
Unfortunately, Microsoft operating systems confused the two names and are
unable to install both.  Version 2.10 of Crypt::Tea is mature, and apart
perhaps from minor bug fixes will probably remain the final version.
Further development will take place under the name Crypt::Tea_JS.
The calling interface is identical.

I've taken advantage of the new name to make two important changes.
Firstly, Crypt::Tea_JS uses the New Improved version of the Tea algorithm,
which provides even stronger encryption, though it does surrender
backward-compatibility for files encrypted by the old Crypt::Tea.
Secondly, some of the core routines are now implemented in C, for improved
performance (at the server end, if you're using it in a CGI context).

=head1 AUTHOR

Peter J Billam ( http://www.pjb.com.au/comp/contact.html ).

=head1 CREDITS

Based on TEA, as described in
http://www.cl.cam.ac.uk/ftp/papers/djw-rmn/djw-rmn-tea.html ,
and on some help from I<Applied Cryptography> by Bruce Schneier
as regards the modes of use.
Thanks also to Neil Watkiss for the MakeMaker packaging,
to Scott Harrison for suggesting workarounds for MacOS 10.2 browsers,
to Morgan Burke for pointing out the problem with URL query strings,
and to Slaven Razic for portability advice in spite of "use bytes".

=head1 SEE ALSO

examples/tea_demo.cgi, perldoc Encode,
http://www.pjb.com.au/comp, tea(1), perl(1).

=cut

