#!/usr/bin/perl
# Denis Almeida Vieira Junior
# davieira@uol.com.br
use Data::Translate;
$data=new Translate;
$str=$ARGV[0]?$ARGV[0]:"DAVIEIRA";

print "Received String: $str\n";

#####################################

print "\nTranslating ASCII->Binary...";
($s,$bin)=$data->a2b($str);
print "done\n--> $bin\n";

#####################################

print "\nTranslating ASCII->Decimal...";
($s,@dec)=$data->a2d($str);
print "done\n--> @dec\n";

#####################################

print "\nTranslating ASCII->Hex...";
($s,@hh)=$data->a2h($str);
print "done\n--> ",join(' ',@hh),"\n";

#####################################

print "\nTranslating Binary->ASCII...";
($s,$asc)=$data->b2a($bin);
print "done\n--> $asc\n";

#####################################

print "\nTranslating Binary->Decimal...";
@t=unpack("A8" x (length($bin)/8),$bin);
foreach $binary (@t) {
   ($s,$decimal)=$data->b2d($binary);
   $g.=$decimal." ";
}
print "done\n--> $g\n";

#####################################

print "\nTranslating Binary->Hex...";
foreach $binary (@t) {
   ($s,$hx)=$data->b2h($binary);
   $f.="$hx ";
}
print "done\n--> $f\n";

#####################################

print "\nTranslating Decimal->ASCII...";
($s,@a)=$data->d2a(@dec);
print "done\n--> ",join('',@a),"\n";

#####################################

print "\nTranslating Decimal->Binary...";
($s,@b)=$data->d2b(@dec);
print "done\n--> ",join('',@b),"\n";

#####################################

print "\nTranslating Decimal->Hex...";
($s,@bh)=$data->d2h(@dec);
print "done\n--> ",join(' ',@bh),"\n";

#####################################

print "\nTranslating Hex->ASCII...";
($s,@ha)=$data->h2a(@hh);
print "done\n--> ",join('',@ha),"\n";

#####################################

print "\nTranslating Hex->Decimal...";
($s,@hd)=$data->h2d(@hh);
print "done\n--> ",join(' ',@hd),"\n";

#####################################

print "\nTranslating Hex->Binary...";
($s,@hb)=$data->h2b(@hh);
print "done\n--> ",join('',@hb),"\n";

