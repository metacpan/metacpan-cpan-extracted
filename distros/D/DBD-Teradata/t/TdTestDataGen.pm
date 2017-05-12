package TdTestDataGen;

use Exporter;
use base ('Exporter');

@EXPORT = qw(gen_test_data collect_recs_each);

use strict;
use warnings;

my $alphas = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_ ';

BEGIN {
	$alphas .= chr($_) foreach (160..250);
}

sub gen_test_data {
	print STDERR "Generating test data; this may take a while...\n";
	open(RAW, '>rawdata.dat') || die "Can't open rawdata.dat: $!";
	binmode RAW;
	open(VARTXT, '>:utf8', 'utf8data.txt') || die "Can't open utf8data.txt: $!";
	foreach (0..24999) {
		print STDERR "Generated $_ rows...\n" unless $_%5000;
		print RAW rawinput($_);
		print VARTXT vartext_input($_), "\n";
	}
	close RAW;
	close VARTXT;
}

sub rawinput {
#
# col1 integer
# col2 smallint
# col3 byteint
# col4 char(20)
# col5 varchar(100)
# col6 float
# col7 decimal(2,1)
# col8 decimal(4,2)
# col9 decimal(8,4)
# col10 decimal(14,5), but send a float
# col11 char(10) date
# col12 char(8) time
# col13 char(19) timestamp
#
	my ($inp) = @_;
	my $col5;
	my $indic = ($inp%20 == 0) ? 16 : 0;
	$col5 = ($inp%20 == 0) ? '' : rndstring(int(rand(99))+1);
	my $col6 = rand(100000);
	my $col7 = int(rand(9));
	my $col8 = int(rand(99));
	my $col9 = int(rand(9999));
	my $col10a = int(rand(99999999));
	my $col10b = int(rand(99999));
	my $col10 = $col10a . '.' . $col10b;
#
#	updated to reflect UNICODE string sizing
#
	use bytes;
	my $varlen = length($col5);
	no bytes;
	my $len = 2 + 4 + 2 + 1 + 40 + 2 + $varlen + 8 + 1 + 2 + 4 + 8 + 4 + 15 + 19;
	return pack("Scc l s c A40 SA* d C S L d L A15 A19 c",
		$len, $indic, 0,
		$inp, $inp%32767, $inp%127, rndstring(20),
		$varlen, $col5, $col6, $col7, $col8, $col9, $col10,
			1021121, '20:02:58.002', '2002-12-04 12:09:47', 10);
}

sub vartext_input {
#
# col1 integer
# col2 smallint
# col3 byteint
# col4 char(20)
# col5 varchar(100)
# col6 float
# col7 decimal(2,1)
# col8 decimal(4,2)
# col9 decimal(8,4)
# col10 decimal(14,5), but send a float
# col11 char(10) date
# col12 char(8) time
# col13 char(19) timestamp
#
	my ($inp) = @_;
	my $col5;
	my $indic = ($inp%20 == 0) ? 16 : 0;
	$col5 = ($inp%20 == 0) ? '' : rndstring(int(rand(99))+1);
	my $col6 = rand(100000);
	my $col7 = int(rand(9));
	my $col8 = int(rand(99));
	my $col9 = int(rand(9999));
	my $col10a = int(rand(99999999));
	my $col10b = int(rand(99999));
	my $col10 = $col10a . '.' . $col10b;

	return join('|', $inp, $inp%32767, $inp%127, rndstring(20),
		$col5, $col6, $col7, $col8, $col9, $col10,
			'2002-10-02', '20:02:58.002', '2002-12-04 12:09:47');
}

sub rndstring {
	my($len) = pop(@_);
#
#	input len is number of *chars*
#	we generate string in singlebyte mode, then
#	apply encoding to convert to UTF8, which may return a string
#	with a bytelength up to 2x our reuqested charlen
#
	my $s = pack("A$len", '');
	my $j = 0;

	substr($s, $j, 1) = substr($alphas, rand(length($alphas)), 1),
	$j++
		while ($j < $len);
#
#	make it a UTF string
#
    Encode::from_to($s, "iso-8859-1", "utf-8"); # from legacy to utf-8
    $s = Encode::decode_utf8($s);
	return $s;
}

sub collect_recs {
	my ($fh, $base, $count, $sz) = @_;

	my @ary = ();
	my $i = 0;
	my $s = 0;

	$ary[$i] = readraw($fh),
	$s += length($ary[$i]) + 1,
	$i++
		while (($s < $sz) && ($i < $count));

	$$base += $i;
	return \@ary;
}

sub collect_recs_each {
	my ($base, $count, $mload, $delta) = @_;

	my @arys = ( [], [], [], [], [], [], [], [], [], [], [], [], [] );
	my $i = 0;

	foreach $i (0..12) {
		$arys[$i][$count-1] = undef;
	}

	$i = 0;
#
# col1 integer
# col2 smallint
# col3 byteint
# col4 char(20)
# col5 varchar(100)
# col6 float
# col7 decimal(2,1)
# col8 decimal(4,2)
# col9 decimal(8,4)
# col10 decimal(14,5), but send a float
# col11 char(10) date
# col12 char(8) time
# col13 char(19) timestamp
#
#	compute base record size in the output msg buffer
	my $reclen = 14 + 4 + 2 + 1 + 40 + 2 + 0 + 8 + 1 + 2 + 4 + 8 + 4 + 15 + 26;
	my $ttlsz = 0;
	use bytes;
	while (($i < $count) && ($ttlsz < 63000)) {
	$arys[0][$i] = ($$base + $delta + 300000),
	$arys[1][$i] =  ($$base + $delta  + 300000)%32767,
	$arys[2][$i] =  ($$base + $delta  + 300000)%128,
	$arys[3][$i] =  rndstring(20),
	$arys[4][$i] =  ($$base%20 == 0) ? undef : rndstring(int(rand(99))+1),
	$arys[5][$i] =  rand(100000),
	$arys[6][$i] =  int(rand(99)) * 0.1,
	$arys[7][$i] =  int(rand(9999)) * 0.01,
	$arys[8][$i] =  int(rand(99999999)) * 0.0001,
	$arys[9][$i] =  int(rand(199999999)) * 0.00001,
	$arys[10][$i] =  1021121,
	$arys[11][$i] =  '20:02:58.002',
	$arys[12][$i] =  '2002-12-04 12:09:47',
	$ttlsz += (($reclen + (defined($arys[4][$i]) ? length($arys[4][$i]) : 0)) * $mload),
	$i++,
	$$base++,
	next
		if (($i%2) && $mload);
	$arys[0][$i] = $$base + $delta ;
	$arys[1][$i] =  ($$base + $delta)%32767;
	$arys[2][$i] =  ($$base + $delta)%128;
	$arys[3][$i] =  $mload ? 'callback mload test ' : rndstring(20);
	$arys[4][$i] =  ($$base%20 == 0) ? undef : rndstring(int(rand(99))+1);
	$arys[5][$i] =  rand(100000);
	$arys[6][$i] =  int(rand(99)) * 0.1;
	$arys[7][$i] =  int(rand(9999)) * 0.01;
	$arys[8][$i] =  int(rand(99999999)) * 0.0001;
	$arys[9][$i] =  int(rand(199999999)) * 0.00001;
	$arys[10][$i] =  1021121;
	$arys[11][$i] =  '20:02:58.002';
	$arys[12][$i] =  '2002-12-04 12:09:47';
	$ttlsz += (($reclen + (defined($arys[4][$i]) ? length($arys[4][$i]) : 0)) * $mload);
	$i++;
	$$base++;
	}
	no bytes;
#
#	remove empty slots
#
	$i--;
	foreach my $j (0..12) {
		$#{$arys[$j]} = $i
	}
	return \@arys;
}

1;