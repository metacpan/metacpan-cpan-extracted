use warnings;
use strict;

BEGIN {
    our $tests = 23;

    # chdir to t/
    $_ = $0;
    s~[^/\\]+$~~;
    chdir $_ if length;

    require './test.pm';
}


my @files = <atom-weight-[123].csv>;

my $copy = $_ = <<EOF;
begin
bof
0;atom-weight-1.csv:1 0,n,Neutronium,18:noble gas,1
0;atom-weight-1.csv:2 1,H,Hydrogen,1:H & alkali metal,1.008
0;atom-weight-1.csv:3 4,Be,Beryllium,2:alkaline earth metal,9.012
0;atom-weight-1.csv:4 41,Nb,Niobium,5:no name,92.906
0;atom-weight-1.csv:5 42,Ve,Veritasium,6:an element of truth,i
0;atom-weight-1.csv:6 74,W,Tungsten,6:transition metal,183.84
0;atom-weight-1.csv:7 8,O,Oxygen,16:O & chalcogen,16
0;atom-weight-1.csv:8 80,Hg,Mercury,12:no name,200.592
eof
bof
1;atom-weight-2.csv:1 0,n,Neutronium,18:noble gas,1
1;atom-weight-2.csv:2 110,Ds,Darmstadtium,10:transition metal,[281]
1;atom-weight-2.csv:3 4,Pl,Perlium,2:pl basis,5.32.0
1;atom-weight-2.csv:4 74,W,Wolfram,6:transition metal,183.8
1;atom-weight-2.csv:5 8,O,Oxygen,16:O & chalcogen,16
1;atom-weight-2.csv:6 80,Hg,Quicksilver,12:no name,200.6
eof
bof
2;atom-weight-3.csv:1 0,n,Neutronium,18:noble gas,1
2;atom-weight-3.csv:2 1,H,Hydrogen,1:alkali metal,1
2;atom-weight-3.csv:3 8,O,Oxygen,16:O and chalcogen,16
2;atom-weight-3.csv:4 41,Nb,Columbium,5:no name,93
2;atom-weight-3.csv:5 80,Hg,Hydrargyrum,12:no name,201
2;atom-weight-3.csv:6 110,Ds,Darmstadtium,10:transition metal,281
eof
end
EOF

my @BbeE = ('-rBecho "begin"', '-b', 'e "bof"', '-ee "eof"', '-E', 'e "end"');
pl @BbeE, 'Echo "$ARGIND;$ARGV:$. $_"', @files;
pl @BbeE, 'E "$I;$A:$. $_"', @files;
sub unBbeE { s/(?:begin|[be]of|end)\n//g }
pl_a \&unBbeE,
  '-r', 'Echo "$ARGIND;$ARGV:$. $_"', @files;

{
    local $_ = $_;
    s/^([012]).+(?:5 | [48][^,]).+\n(?:\1.+\n)*//gm;
    pl @BbeE, '-p4', 'substr $_, 0, 0, "$I;$A:$. "; last if / [48][^,]/', @files;
    s/^([012]).+ (?:4[^,]|8).+\n(?:\1.+\n)*//gm;
    pl @BbeE, 'last if /^(?:4[^,]|8)/; E "$I;$A:$. $_"', @files;
    &unBbeE;
    pl '-r', 'last if /^(?:4[^,]|8)/; E "$I;$A:$. $_"', @files;
    s/(?<=\n)1[^\n]+:\K1( .+?\n).+/5$1/s;
    pl '-p4', 'substr $_, 0, 0, "$I;$A:$. "; last if / [48][^,]/', @files;
    s/(?<=\n)0[^\n]+:3 .+//s;
    pl '-p2', 'substr $_, 0, 0, "$I;$A:$. "; last if / [48][^,]/', @files;
}

substr $BbeE[0], 1, 1, '';	# done testing -r

{ my $i = 0; s/:\K([0-9]+)(?= )/++$i/eg } # convert $. to count across all files
pl @BbeE, 'E "$I;$A:$. $_"', @files;

pl_e '', '-n', '', @files;


unBbeE;
s/^.+? //gm;
$copy = $_;

# run pl, expect @F[1, 0] separated by $_[0]
sub pl_F($$) {
    at;
    my $sep = $_[0];
    pl_a { s/^(.+)$sep(.+)$/$2$sep$1/gm } "-Bmy \$j = '$sep'", $_[1], '$_ = pop @F; e join $j, $_, @F', @files;
}
pl_F ' ', '-al';
pl_F ',', '-lF,';
pl_F ':', '-lF:';


s/.+?:[0-9]+ //mg; # reduce to only file contents
pl '-n', 'E', @files;
pl '-ln', 'e', @files;
pl '-p', '', @files;
pl '-lp', '', @files;

my @lines = grep /[01],/, split /^/;
pl_e join( '', @lines[0..3], "eof\n", @lines[4, 5], "eof\n" ),
  '-P6e', 'e "eof"', '/[01],/', @files;
pl_e join( '', "bof\n",  @lines[0, 1], "bof\n",  @lines[4, 5], "bof\n",  @lines[7, 8] ),
  '-rP2b', 'e "bof"', '/[01],/', @files;

# reproduce the splits that -054 (comma) will do
s/\n0,/\n][0,/g; # new file
s/,/,][/g;
substr $_, 0, 0, '['; $_ .= ']';
pl '-054n', 'E "[$_]"', @files; # 054 is comma, also splits at file ends


# Testing -i is a bit more complicated. pl_e -i doesn't really test anything.  The actual test comes then.
my @copies = map {
    open my $in, '<', $_ or die $!;
    my $copy = "copy-$_";
    open my $out, '>', $copy or die $!;
    defined( syswrite $out, slurp $in ) or die $!;
    $copy;
} @files;

# Since -i outputs nothing, instead as a side effect test that I get STDERR.
pl_e "get me\nnow", '-pibkp', '-B warn "get me\n"; E "now"', 'tr/abc/xyz/', @copies;	# Windows perl requires -i with backup

$_ = $copy;
for my $sfx ('bkp', '') {
    test "pl -i file$sfx contents",
      join '', map {
	  open my $in, '<', $_.$sfx or die $!;
	  slurp $in;
      } @copies;
    tr/abc/xyz/;
}
