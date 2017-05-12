#!/usr/bin/perl
# 10_Ponie.t (was text.t)
# This tests OK as taint-safe (i.e. with -Tw added to first line above).

use strict;
use Acme::EyeDrops qw(sightly hjoin_shapes get_eye_string pour_text);

# --------------------------------------------------

select(STDERR);$|=1;select(STDOUT);$|=1;  # autoflush

print "1..34\n";

my $snow = get_eye_string('snow');

my $src = <<'SNOWING';
$_=q~vZvZ&%('$&"'"&(&"&$&"'"&$Z$#$$$#$%$&"'"&(&#
%$&"'"&#Z#$$$#%#%$%$%$%(%%%#%$%$%#Z"%*#$%$%$%$%(%%%#%$%$
%#Z"%,($%$%$%(%%%#%$%$%#Z"%*%"%$%$%$%(%%%#%$%$%#Z#%%"#%#%
$%$%$%$##&#%$%$%$%#Z$&""$%"&$%$%$%#%"%"&%%$%$%#Z%&%&#
%"'"'"'###%*'"'"'"ZT%?ZT%?ZS'>Zv~;
s;\s;;g;
$;='@,=map{$.=$";join"",map((($.^=O)x(-33+ord)),/./g),$/}split+Z;
s/./(rand)<.2?"o":$"/egfor@;=((5x84).$/)x30;map{
system$^O=~W?CLS:"clear";print@;;splice@;,-$_,2,pop@,;
@;=($/,@;);sleep!$%}2..17';
$;=~s;\s;;g;eval$;
SNOWING

# -------------------------------------------------

my $itest = 0;

my $snowflake = pour_text($snow, "",  1, '#');
$snowflake eq $snow or print "not ";
++$itest; print "ok $itest\n";

# -------------------------------------------------

$snowflake = pour_text($snow, $src,  1, "");
my $t = $snowflake; $t =~ s/\s+//g;
my $v = $src; $v =~ s/\s+//g;
substr($t, 0, length($v)) eq $v or print "not ";
++$itest; print "ok $itest\n";
substr($t, length($v)) eq '' or print "not ";
++$itest; print "ok $itest\n";

# -------------------------------------------------

$snowflake = pour_text($snow, $src,  1, '#');
$t = $snowflake;
$t =~ tr/!-~/#/;
$t eq $snow or print "not ";
++$itest; print "ok $itest\n";
$t = $snowflake; $t =~ s/\s+//g;
$v = $src; $v =~ s/\s+//g;
substr($t, 0, length($v)) eq $v or print "not ";
++$itest; print "ok $itest\n";
substr($t, length($v)) eq '#' x (length($t)-length($v)) or print "not ";
++$itest; print "ok $itest\n";

# -------------------------------------------------

$snowflake = sightly( { Shape         => 'snow',
                        SourceString  => $src,
                        Text          => 1,
                        TextFiller    => '#' } );
$t = $snowflake;
$t =~ tr/!-~/#/;
$t eq $snow or print "not ";
++$itest; print "ok $itest\n";
$t = $snowflake; $t =~ s/\s+//g;
$v = $src; $v =~ s/\s+//g;
substr($t, 0, length($v)) eq $v or print "not ";
++$itest; print "ok $itest\n";
substr($t, length($v)) eq '#' x (length($t)-length($v)) or print "not ";
++$itest; print "ok $itest\n";

# -------------------------------------------------

my $shape = "## ###\n";
my $p = pour_text($shape, "", 1, "");
$p eq "\n" or print "not ";
++$itest; print "ok $itest\n";
$p = pour_text($shape, 'X', 1, "");
$p eq "X\n" or print "not ";
++$itest; print "ok $itest\n";
$p = pour_text($shape, 'XX', 1, "");
$p eq "XX\n" or print "not ";
++$itest; print "ok $itest\n";
$p = pour_text($shape, 'XXX', 1, "");
$p eq "XX X\n" or print "not ";
++$itest; print "ok $itest\n";
$p = pour_text($shape, 'XXXXX', 1, "");
$p eq "XX XXX\n" or print "not ";
++$itest; print "ok $itest\n";
$p = pour_text($shape, 'XXXXXX', 1, "");
$p eq "XX XXX\n\nX\n" or print "not ";
++$itest; print "ok $itest\n";

my $shape_gap = "## ###\n\n####\n";
$p = pour_text($shape_gap, 'XXXXX', 4, "");
$p eq "XX XXX\n" or print "not ";
++$itest; print "ok $itest\n";
$p = pour_text($shape_gap, 'XXXXXX', 4, "");
$p eq "XX XXX\n\nX\n" or print "not ";
++$itest; print "ok $itest\n";
$p = pour_text($shape_gap, 'XXXXXXXXX', 4, "");
$p eq "XX XXX\n\nXXXX\n" or print "not ";
++$itest; print "ok $itest\n";
$p = pour_text($shape_gap, 'XXXXXXXXXX', 4, "");
$p eq "XX XXX\n\nXXXX\n\n\n\n\nX\n" or print "not ";
++$itest; print "ok $itest\n";

# -------------------------------------------------

$p = pour_text($shape, '', 2, '#');
$p eq "## ###\n" or print "not ";
++$itest; print "ok $itest\n";
$p = pour_text($shape, 'X', 2, '#');
$p eq "X# ###\n" or print "not ";
++$itest; print "ok $itest\n";
$p = pour_text($shape, 'XX', 2, '#');
$p eq "XX ###\n" or print "not ";
++$itest; print "ok $itest\n";
$p = pour_text($shape, 'XXX', 2, '#');
$p eq "XX X##\n" or print "not ";
++$itest; print "ok $itest\n";
$p = pour_text($shape, 'XXXX', 2, '#');
$p eq "XX XX#\n" or print "not ";
++$itest; print "ok $itest\n";
$p = pour_text($shape, 'XXXXX', 2, '#');
$p eq "XX XXX\n" or print "not ";
++$itest; print "ok $itest\n";
$p = pour_text($shape, 'XXXXXX', 2, '#');
$p eq "XX XXX\n\n\nX# ###\n" or print "not ";
++$itest; print "ok $itest\n";

# -------------------------------------------------

$p = pour_text($shape, 'X', 3, 'abc');
$p eq "Xa bca\n" or print "not ";
++$itest; print "ok $itest\n";
$p = pour_text($shape, 'X', 3, 'abcd');
$p eq "Xa bcd\n" or print "not ";
++$itest; print "ok $itest\n";
$p = pour_text($shape, 'XXXXX', 3, 'abc');
$p eq "XX XXX\n" or print "not ";
++$itest; print "ok $itest\n";
$p = pour_text($shape, '1234567', 3, 'abc');
$p eq "12 345\n\n\n\n67 abc\n" or print "not ";
++$itest; print "ok $itest\n";

# -------------------------------------------------

$p = sightly( { SourceString  => 'knob',
                Width         => 1,
                Text          => 1,
                TextFiller    => '#' } );
$p eq "k\nn\no\nb\n" or print "not ";
++$itest; print "ok $itest\n";

$p = sightly( { SourceString  => 'knob',
                Width         => 3,
                Text          => 1,
                TextFiller    => '#' } );
$p eq "kno\nb##\n" or print "not ";
++$itest; print "ok $itest\n";

$p = sightly( { SourceString  => 'knob',
                Width         => 4,
                Text          => 1,
                TextFiller    => '#' } );
$p eq "knob\n" or print "not ";
++$itest; print "ok $itest\n";

# -------------------------------------------------

$p = hjoin_shapes(2, "##\n###\n", "#\n##\n###\n");
$p eq "##   #\n###  ##\n     ###\n" or print "not ";
++$itest; print "ok $itest\n";

# -------------------------------------------------
