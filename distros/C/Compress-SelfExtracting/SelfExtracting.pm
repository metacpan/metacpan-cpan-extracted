package Compress::SelfExtracting;
use Digest::MD5 'md5_hex';
require Exporter;

use vars qw/@ISA @EXPORT @EXPORT_OK $VERSION/;

@EXPORT_OK = qw/compress decompress/;
@EXPORT = qw/zscript zfile/;
@ISA = qw/Exporter/;
$VERSION = 0.04;

my %O;
BEGIN {
    %O = (standalone => 1,
	  type => 'LZW',
	  op => 'eval',
	  uu => 1);
};

sub compress
{
    my $data = shift;
    my %o = @_;
    @O{keys %o} = values %o;
    my $cdata = &{"Compress::SelfExtracting::$O{type}::compress"}($data, \%O);
    if ($O{uu}) {
	$cdata = pack 'u', $cdata;
    }
    if ($O{standalone}) {
	my $sa = &{"Compress::SelfExtracting::$O{type}::standalone"}(\%O);
	return $sa.$cdata;
    } else {
	return "use Compress::SelfExtracting::Filter "
		.join(', ', map { "$_ => '$O{$_}'" }
		  grep!/decompress|file|data/,keys %O).";\n"
		.md5_hex($data)."\n$cdata\n";
    }
}

sub decompress
{
    my $data = shift;
    my %o = @_;
    @O{keys %o} = values %o;
    if ($data =~ /^([0-9a-f]+)\n(.*)/s) {
	if ($O{uu}) {
	    $data = unpack 'u', $2;
	} else {
	    chomp($data = $2);
	}
	$data = &{"Compress::SelfExtracting::$O{type}::decompress"}($data, \%O);
	my $cksum = md5_hex($data);
	unless ($cksum eq $1) {
	    open BAD, ">BAD";
	    print BAD $data;
	    close BAD;
	    die "Bad checksum\n";
	}
    } else {
	die "$0 doesn't look compressed\n";
    }
    $data;
}

sub zscript
{
    local $/ = undef;
    my $data = <STDIN>;
    print compress $data, @_;
}

sub zfile
{
    local $/ = undef;
    my $data = <STDIN>;
    print compress $data, @_, op => 'print';
}

############################################################
package Compress::SelfExtracting::LZ77;

sub import { }

sub compress
{
    my $str = shift;
    die "Sorry, code too long\n" if length($str) >= 1<<16;
    my @rep;
    my $la = 0;
    while ($la < length $str) {
	my $n = 1;
	my ($tmp, $p);
	$p = 0;
	while ($la + $n < length $str
	       && $n < 255
	       && ($tmp = index(substr($str, 0, $la),
				substr($str, $la, $n),
				$p)) >= 0) {
	    $p = $tmp;
	    $n++;
	}
	--$n;
	my $c = substr($str, $la + $n, 1);
	push @rep, [$p, $n, ord $c];
	$la += $n + 1;
    }
    join('', map { pack 'SCC', @$_ } @rep);
}

sub decompress
{
    my $str = shift;
    my $ret = '';
    while (length $str) {
	my ($s, $l, $c) = unpack 'SCC', $str;
	$ret .= substr($ret, $s, $l).chr$c;
	$str=substr($str,4);
    }
    $ret;
}

sub standalone
{
    my $O = shift;
    my $ret = <<'EOC';
BEGIN{open 0;$_=join'',<0>;s/^.*?}\n//s;#UUDEC#s/(...)(.)/
($o,$l)=unpack SC,$1;$r.=substr($r,$o,$l).$2/egs;#OP#$r;exit}
EOC
    if ($O->{uu}) {
	$ret =~ s/#UUDEC#/\$_=unpack'u',\$_;/;
    } else {
	$ret =~ s/#UUDEC#//;
    }
    $ret =~ s/#OP#/$O->{op}/;
    $ret;
}

############################################################
package Compress::SelfExtracting::LZSS;

sub import { }

sub compress
{
    my $str = shift;
    die "Sorry, code too long\n" if length($str) >= 1<<16;
    my @rep;
    my $la = 0;
    while ($la < length $str) {
	my $n = 1;
	my ($tmp, $p);
	$p = 0;
	while ($la + $n < length $str
	       && $n < 255
	       && ($tmp = index(substr($str, 0, $la),
				substr($str, $la, $n),
				$p)) >= 0) {
	    $p = $tmp;
	    $n++;
	}
	--$n;
	if ($n < 2) {
	    push @rep, "\0".substr($str, $la, 1);
	    ++$la;
	} else {
	    push @rep, pack 'CS', $n, $p;
	    $la += $n;
	}
    }
    join('', @rep);
}

sub decompress
{
    my $str = shift;
    my $ret = '';
    my $o = 0;
    while ($o < length $str) {
	my $n = unpack 'C', substr($str, $o);
	if ($n == 0) {
	    $ret .= substr($str, $o + 1, 1);
	    $o += 2;
	} else {
	    my $p = unpack 'S', substr($str, $o + 1);
	    $ret .= substr($ret, $p, $n);
	    $o += 3;
	}
    }
    $ret;
}

sub standalone
{
    my $ret = <<'END';
BEGIN{open 0;$_=join'',<0>;s/^.*?}\n//s;#UUDEC#($r.=($n=ord substr$_,
$o++)?substr$r,(unpack S,substr$_,$o++),$n:substr$_,$o,1),$o++
while$o<length;#OP#$r;exit}
END
    my $O = shift;
    if ($O->{uu}) {
	$ret =~ s/#UUDEC#/\$_=unpack'u',\$_;/
    } else {
	$ret =~ s/#UUDEC#//;
    }
    $ret =~ s/#OP#/$O->{op}/;
    $ret;
}

############################################################
package Compress::SelfExtracting::LZW;

my (%LZ, %UNLZ, %SA);

sub import
{
    %LZ = (12 => sub {
		 my $v = '';
		 for my $i (0..$#_) {
		     vec($v, 3*$i, 4) = $_[$i]/256;
		     vec($v, 3*$i+1, 4) = ($_[$i]/16)%16;
		     vec($v, 3*$i+2, 4) = $_[$i]%16;
		 }
		 $v;
	     },
	     16 => sub { pack 'S*', @_ });
    %UNLZ = (12 => sub {
		   my $code = shift;
		   my @code;
		   my $len = length($code);
		   my $reallen = 2*$len/3;
		   print STDERR "len = $len, reallen = $reallen\n";
		   foreach (0..$reallen - 1) {
		       push @code, (vec($code, 3*$_, 4)<<8)
			         | (vec($code, 3*$_+1, 4)<<4)
				 | (vec($code, 3*$_+2, 4));
		   }
		   @code;
	       },
	       16 => sub { unpack 'S*', shift; });
    # Now the self-extracting glop:
    my $ANY_16 = <<'EOC';
BEGIN{open 0;$/=$!;%d=map{($_,chr)}0..($n=255);($s=join'',<0>)
=~s/^.*?}\n//s;#OP# join'',map{($C,$P)=@d{$_,$p};$p=$_;if
(!defined$P){$d{$p}}elsif(defined$C){$d{++$n}=$P.substr$C,0,
1;$C}else{$d{++$n}=$P.substr$P,0,1}}unpack'S*',#UUDEC#;exit}
EOC
    (my $u16 = $ANY_16) =~ s/#UUDEC#/unpack'u',\$s/;
    (my $n16 = $ANY_16) =~ s/#UUDEC#/\$s/;
    my $ANY_12 = <<'EOC';
BEGIN{open 0;$/=$!;%d=map{($_,chr)}0..($n=255);($s=join'',<0>)
=~s/^.*?}\n//s;#UUDEC##OP# join'',map{($C,$P)=@d{$_,$p};$p=$_;if
(!defined$P){$C}elsif(defined$C){$d{++$n}=$P.substr$C,0,1;$C}else{
$d{++$n}=$P.substr$P,0,1}}map{vec($s,3*$_,4)<<8|vec($s,3*$_+1,4)<<4
|vec$s,3*$_+2,4}0..length($s)*2/3-1;exit}
EOC
    (my $u12 = $ANY_12) =~ s/#UUDEC#/\$s=unpack'u',\$s;/;
    (my $n12 = $ANY_12) =~ s/#UUDEC#//;
    %SA = ('12u0' => $n12, '12u1' => $u12, '16u0' => $n16, '16u1' => $u16);
}

sub compress
{
    my ($str, $O) = @_;
    my $p = ''; my %d = map{(chr $_, $_)} 0..255;
    my @o = ();
    my $ncw = 256;
    for (split '', $str) {
	if (exists $d{$p.$_}) {
	    $p .= $_;
	} else {
	    push @o, $d{$p};
	    $d{$p.$_} = $ncw++;
	    $p = $_;
	}
    }
    push @o, $d{$p};
    if ($O->{bits} != 16 && $ncw < 1<<12) {
	$O->{bits} = 12;
	return $LZ{12}->(@o);
    } elsif ($ncw < 1<<16) {
	$O->{bits} = 16;
	return $LZ{16}->(@o);
    } else {
	die "Sorry, code-word overflow";
    }
}

sub decompress
{
    my %d = (map{($_, chr $_)} 0..255);
    my $ncw = 256;
    my $ret = '';
    my ($str, $O) = @_;
    my ($p, @code) = $UNLZ{$O->{bits}}->($str);
    $ret .= $d{$p};
    for (@code) {
	if (exists $d{$_}) {
	    $ret .= $d{$_};
	    $d{$ncw++} = $d{$p}.substr($d{$_}, 0, 1);
	} else {
	    my $dp = $d{$p};
	    warn unless $_ == $ncw++;
	    $ret .= ($d{$_} = $dp.substr($dp, 0, 1));
	}
	$p = $_;
    }
    $ret;
}

sub standalone
{
    my $O = shift;
    my $ret = $SA{"$O->{bits}u$O->{uu}"};
    $ret =~ s/#OP#/$O->{op}/;
    $ret;
}

############################################################
package Compress::SelfExtracting::Huffman;

# Compute bit-codes from tree.
sub tree2str
{
    my ($str, $x) = @_;
    if (!defined $x->[2]) {
	$rep{$x->[1]} = $str;
    } else {
	tree2str($str.'0', $x->[1]);
	tree2str($str.'1', $x->[2]);
    }
}

sub compress
{
    my %p = ();
    my $s = shift;
    my @chars;
    if (ref $s eq 'ARRAY') {
	@chars = @$s;
    } else {
	@chars = split '', $s;
    }
    for (@chars) {
	$p{$_}++;
    }
    my @elts = sort { $a->[0] <=> $b->[0] }
	map { [ $p{$_}, $_, undef ] } keys %p;
    while (@elts > 1) {
	my ($x, $y) = splice @elts, 0, 2;
	my $z = [ $x->[0] + $y->[0], $x, $y ];
	foreach my $i (0..$#elts) {
	    if ($elts[$i]->[0] >= $z->[0]) {
		splice @elts, $i, 0, $z;
		undef $z;
		last;
	    }
	}
	push @elts, $z if $z;
    }
    local %rep = ();		# gets filled in by tree2str.
    tree2str '', pop @elts;
    if ($::DEBUG) {
	foreach (sort keys %rep) {
	    print STDERR "$_ <- $rep{$_}\n";
	}
    }
    my $data = '';
    for (@chars) {
	$data .= $rep{$_};
    }
    my $nbits = length($data);
    my $tree = pack 'CL', scalar keys %rep, $nbits;
    print STDERR "len = ", scalar keys %rep, "nbits = $nbits\n" if $::DEBUG;
    while (my ($k, $v) = each %rep) {
	die "Sorry, Huffman code too long ($v)\n" if length $v >= 32;
	$tree .= pack('Cb32', ord($k), '0'x(31 - length $v).'1'.$v);
    }
    $data = pack 'b*', $data.('0'x((8 - $nbits%8) % 8));
    print STDERR length($data), " bytes of data\n" if $::DEBUG;
    $tree.$data;
}

sub decompress
{
    my $str = shift;
    my ($len, $nbits) = unpack 'CL', $str;
    $str = substr($str, 5);
    print STDERR "len = $len, nbits = $nbits\n" if $::DEBUG;
    my %rep;
    for (0..$len - 1) {
	my ($c, $x) = unpack 'Cb32', substr($str, 5*$_, 5);
	$x =~ s/^0*1//;
	die "Duplicate: $x -> $c" if exists $rep{$x};
	$rep{$x} = chr $c;
    }
    if ($::DEBUG) {
	foreach (sort keys %rep) {
	    print STDERR "$_ <- $rep{$_}\n";
	}
    }
    $str = substr($str, 5*$len);
    print STDERR length $str, " bytes of data\n" if $::DEBUG;
    my $data = unpack "b$nbits", $str;
    my $ret = '';
    my $n;
    while (length $data > 0) {
	$n = 1;
	while (!exists($rep{substr($data, 0, $n)})) {
	    $n++;
	    die $n if $n > length $data;
	}
	$ret .= $rep{substr($data, 0, $n)};
	$data = substr($data, $n);
    }
    $ret;
}

sub standalone
{

    my $ret = <<'EOC';
BEGIN{open 0;$/=$!;($s=join'',<0>)=~s/^.*?}\n//s;#UUDEC#($l,$L)=
unpack'CL',$s;$s=substr$s,5;for(1..$l){($c,$x)=unpack'Cb32',$s;
$x=~s/^0*1//;$r{$x}=chr$c;$s=substr$s,5}$_=unpack"b$L",$s;while
(length){$n=1;1while!exists$r{substr$_,0,$n++};$r.=$r{substr$_,
0,--$n};$_=substr$_,$n}#OP#$r;exit}
EOC
    my $O = shift;
    if ($O->{uu}) {
	$ret =~ s/#UUDEC#/\$s=unpack'u',\$s;/;
    } else {
	$ret =~ s/#UUDEC#//;
    }
    $ret =~ s/#OP#/$O->{op}/;
    $ret;
}

############################################################
package Compress::SelfExtracting::BWT;
# Burrows-Wheeler Transform block-sorting compression (i.e. bzip).
#
# This implementation is a straightforward translation of this Dr
# Dobbs' piece: http://www.ddj.com/documents/s=957/ddj9609f/.  Also
# see
# http://gatekeeper.dec.com/pub/DEC/SRC/research-reports/SRC-124.ps.gz
# for the original, which IMO better describes the block-sorting.
#

import Compress::SelfExtracting::Huffman;

sub import { }

##############################
# BWT block-sorting

sub BLKSIZE() { 16*1024 }	# unused, so this sucks for big files.
sub QSORT_SIZE() { 5 }		# when to use qsort instead of counting sort.
sub _counting_sort
{
    my ($p, $o) = @_;
    if ($::DEBUG) {
	++$calls;
	if ($o > $maxdepth) {
	    $maxdepth = $o;
	    print STDERR "$o\r";
	}
    }
    my @a;
    foreach (@$p) {
	push @{$a[ord substr($s, $_+$o, 1)]}, $_;
    }
    my @ret;
    foreach (@a) {
	next unless ref $_;
	if (@$_ == 1) {
	    push @ret, $_->[0];
	} elsif (@$_ < QSORT_SIZE) {
	    my $tmp = $o+1;
	    push @ret, sort { substr($s, $a+$tmp).substr($s, 0, $a+$o) cmp
				  substr($s, $b+$tmp).substr($s, 0, $b+$o) }
		@$_;
	} else {
	    push @ret, _counting_sort($_, $o+1);
	}
    }
    @ret;
}

sub counting_sort
{
    local $s = shift;
    local $^W = 0;
    my $l = length $s;
    $s .= $s;
    local $maxdepth = 0;
    local $calls = 0;
    my @ret = _counting_sort([0..$l-1], 0);
    print STDERR "Counting sort max depth $maxdepth, calls = $calls\n"
	if $::DEBUG;
    @ret;
}

sub BWT
{
    my $str = shift;
    my $slow;
    if (length $str > BLKSIZE) {
	$slow = 1;
	warn "BWT will be very slow for ", length $str, " bytes\n";
    }
    my $d = 0;
    my ($pi, @L);
    my @posns = counting_sort($str);
    # This is quite a bit slower than counting sort.
#     my @posns = sort { substr($str, $a).substr($str, 0, $a-1) cmp
# 			   substr($str, $b).substr($str, 0, $b-1) }
# 	(0 .. length($str) - 1);
    my $i;
    foreach $i (0..$#posns) {
	if ($posns[$i] == 0) {
	    $pi = $i;
	}
	push @L, ord(substr($str, $posns[$i] - 1, 1));
    }
    ($pi, \@L);
}

sub unBWT
{
    my ($pi, $L) = @_;
    my (@P, @C);
    my @ret;
    print STDERR "length = ".@$L."\n" if $::DEBUG;
    for (0..$#{$L}) {
	my $c = $L->[$_];
	$P[$_] = $C[$c] || 0;
	$C[$c]++;
    }
    my $sum = 0;
    {
	no warnings;
	for (@C) {
	    $sum += $_;
	    $_ = $sum - $_;
	}
    }
    for (reverse 0..$#{$L}) {
	my $c = $L->[$pi];
	$ret[$_] = $c;
	$pi = $P[$pi] + $C[$c];
    }
    die unless @ret == @$L;
    return \@ret;
}

##############################
# Move-to-front coder

sub MTF
{
    my $L = shift;
    my @ret;
    my @c = 0..255;
    foreach (@$L) {
	for my $i (0..$#c) {
	    if ($c[$i] == $_) {
		push @ret, $i;
		splice @c, $i, 1;
		unshift @c, $_;
		last;
	    }
	}
    }
    \@ret;
}

sub unMTF
{
    my $L = shift;
    my @ret;
    my @c = 0..255;
    foreach (@$L) {
	my $x = $c[$_];
	push @ret, $x;
	splice @c, $_, 1;
	unshift @c, $x;
    }
    \@ret;
}

##############################
# Run-length coder

sub RLE
{
    my @ret;
    my $l = shift;
    my $c = $l->[0];
    my $n = 1;
    foreach (@{$l}[1..$#{$l}]) {
	if ($c != $_) {
	    push @ret, $c, $n;
	    $n = 1;
	    $c = $_;
	} else {
	    if (++$n > 255) {
		push @ret, $c, 255;
		$n = 1;
	    }
	}
    }
    push @ret, $c, $n;
    if ($::DEBUG) {
	my $i = 0;
	while ($i < @ret) {
	    print STDERR "$ret[$i], $ret[$i+1]\n";
	    $i += 2;
	}
    }
    \@ret;
}

sub unRLE
{
    my @l = @{shift @_};
    my @ret;
    die unless @l % 2 == 0;
    my ($c, $n);
    while (@l) {
	$c = shift @l;
	$n = shift @l;
	print STDERR "$c, $n\n" if $::DEBUG;
	push @ret, $c for 1..$n;
    }
    \@ret;
}

##############################
# Main compression routines

sub compress
{
    my ($str, $O) = @_;
    print STDERR "BWT..." if $::DEBUG;
    my ($pi, $L) = BWT($str);
    print STDERR "\nMTF..." if $::DEBUG;
    $L = MTF($L);
    print STDERR "\nRLE..." if $::DEBUG;
    $L = RLE($L);
    print STDERR "\nHuffman..." if $::DEBUG;
    $L = Compress::SelfExtracting::Huffman::compress(pack('L', $pi)
					     .join('', map { chr } @$L),
					     $O);
    print STDERR "done\n" if $::DEBUG;
    return $L;
}

sub decompress
{
    my $str = shift;
    # Huffman decode to a string:
    $str = Compress::SelfExtracting::Huffman::decompress($str);
    my $pi = unpack 'L', $str;
    $str = [map {ord} split '', substr($str, 4)];
    $str = unRLE($str);
    $str = unMTF($str);
    $str = unBWT($pi, $str);
    join '', map { chr } @$str;
}

# Oh, yeah.
sub standalone
{
    my $ret = <<'EOC';
BEGIN{open$^W=0;$/=$!;($s=join'',<0>)=~s/^.*?}\n//s;#UUDEC#($l,$L)=
unpack'CL',$s;$s=substr$s,5;for(1..$l){($c,$x)=unpack'Cb32',$s;$x=~
s/^0*1//;$r{$x}=chr$c;$s=substr$s,5}$_=unpack"b$L",$s;while(length){
$n=1;1while!exists$r{substr$_,0,$n++};$r.=$r{substr$_,0,--$n};$_=
substr$_,$n}$P=unpack'L',$r;@l=map{ord}split'',substr$r,4;while(@l){
push@R,(shift@l)x shift@l}@c=0..255;for(@R){push@M,$x=$c[$_];splice
@c,$_,1;unshift@c,$x}for(0..$#M){$c=$M[$_];$P[$_]=$C[$c]++}for(@C){
$s+=$_;$_=$s-$_}for(reverse 0..$#M){$c=$M[$P];$r[$_]=$c;$P=$P[$P]+
$C[$c]}#OP# join'',map{chr}@r;exit}
EOC
    my $O = shift;
    if ($O->{uu}) {
	$ret =~ s/#UUDEC#/\$s=unpack'u',\$s;/;
    } else {
	$ret =~ s/#UUDEC#//;
    }
    $ret =~ s/#OP#/$O->{op}/;
    $ret;
}

package Compress::SelfExtracting;
import Compress::SelfExtracting::LZW;

1;
__END__

=head1 NAME

Compress::SelfExtracting -- create compressed scripts

=head1 SYNOPSIS

  use Compress::SelfExtracting 'compress';

  $result = compress $data, OPTIONS ... ;

or

  bash$ perl -MCompress::SelfExtracting -e 'zscript ...' \
      < script.pl > compressed.pl
  bash$ ssh user@host -e perl < compressed.pl

or

  bash$ perl -MCompress::SelfExtracting -e 'zfile ...' \
      < myfile.txt > myfile.txt.plz
  bash$ perl myfile.txt.plz > myfile.txt.copy

=head1 DESCRIPTION

C<Compress::SelfExtracting> allows you to create pure-Perl
self-extracting scripts (or files) using a variety of compression
algorithms.  These scripts (files) will then be runnable (extractable)
on any system with a recent version of Perl.

=head2 Functions

=over

=item C<zscript>

Reads a script on standard input, and writes the compressed result to
standard output.

=item C<zfile>

Like zscript, except the script it creates will print itself to
standard output instead of executing.

=item C<compress>

Takes a string as its first argument, and returns the compressed
result.

=back

=head2 Options

C<zscript> and C<compress> support the following options:

=over

=item type

Which compression algorithm to use.  C<Compress::SelfExtracting>
currently supports the five types of compression listed below.  LZW
and LZSS are probably the most useful.

=over

=item BWT -- Burrows-Wheeler Transform (bzip)

B<Note>: BWT currently only uses a single block, and is unusably slow
on files larger than about 12 kilobytes.  Furthermore, the standalone
decompression code is significantly larger than that for other
methods.

=item LZ77 -- Lempel-Ziv 77

While its compression is significantly worse than LZW and LZSS, this
method has the shortest self-extraction routine, making it useful for
.signatures and very small scripts.

=item LZSS -- a variant of LZ77

LZSS provides better compression than LZ77, and its decompression code
is only slightly longer.

=item LZW -- Lempel-Ziv 78-based algorithm

Probably the most useful algorithm, as it decompresses quickly and
yields a good compression ratio.  The decompression code, while longer
than that for LZ77 and LZSS, is much shorter than that for BWT.

=item Huffman -- Huffman character-frequency coding

Useful mainly as a subroutine in BWT coding.

=back

=item standalone (default: yes)

Create a self-extracting script, rather than one using
C<Compress::SelfExtracting::Filter>.

=item uu (default: no)

Create a uucompressed script.  The result will be one third larger,
but will still be runnable, will be 8-bit clean, and will have sane
line-lengths.

=back 

=head1 EXPORTS

C<Compress::SelfExtracting> exports the C<zscript> function by
default, for command-line convenience.

=head1 AUTHOR

Sean O'Rourke, E<lt>seano@cpan.orgE<gt>

Bug reports welcome, patches even more welcome.

=head1 COPYRIGHT

Copyright (C) 2002 Sean O'Rourke.  All rights reserved, some wrongs
reversed.  This module is distributed under the same terms as Perl
itself.  Let me know if you actually find it useful.

=cut

# You don't see this.

# Burrows-Wheeler decompressor, saved with a few comments.  Otherwise,
# this would be completely incomprehensible in no-time flat.

BEGIN{open$^W=0;$/=$!;($s=join'',<0>)=~s/^.*?}\n//s;#UUDEC#($l,$L)=unpack'CL',$s;$s=substr$s,5;for(1..$l){($c,$x)=unpack'Cb32',$s;$x=~s/^0*1//;$r{$x}=chr$c;$s=substr$s,5}$_=unpack"b$L",$s;while(length){$n=1;1while!exists$r{substr($_,0,$n++)};$r.=$r{substr$_,0,--$n};$_=substr$_,$n
}$P=unpack'L',$r;		# get $pi.
@l=map{ord}split'',substr($r,4);
# un-RLE:
while(@l){push@R,(shift@l)x shift@l}# un-MTF:
@c=0..255;for(@R){push@M,$x=$c[$_];splice@c,$_,1;unshift@c,$x}# un-BWT:
for(0..$#M){$c=$M[$_];$P[$_]=$C[$c]++||0}for(@C){$s+=$_;$_=$s-$_;
}for(reverse 0..$#M){$c=$M[$P];$r[$_]=$c;$P=$P[$P]+$C[$c]
}eval join'',map{chr}@r;exit}

#!/usr/local/bin/perl -w
@M=map{chr}@M;
$t=join'',@M;
$_=join'',sort@M;
while (/(.)\1*/sg){$l=$1;push@r,(pos$t)-1 while$t=~/$l/g}
print map{$r[$P=$t[$P]]}1..@r
