use warnings;
use strict;

use Test::Simple tests => 7;

# chdir to t/
$_ = $0;
s~[^/\\]+$~~;
chdir $_ if length;

# run pl, expect $_
sub pl(@) {
    my $fh;
    if( $^O =~ /^MSWin/ ) {
	require Win32::ShellQuote;
	open $fh, Win32::ShellQuote::quote_native( $^X, '-W', '..\pl', @_ ) . '|';
    } else {
	open $fh, '-|', $^X, '-W', '../pl', @_;
    }
    local $/;
    my $ret = <$fh>;
    ok $ret eq $_, join ' ', 'pl', map /[\s*?()[\]{}\$\\'";|&]|^$/ ? "'$_'" : $_, @_
      or print "got: '$ret', expected: '$_'\n";
}

my @files = <atom-weight-[123].csv>;
my( $B, $I, $G, $R, $E, $e ) = map "\e[${_}m", 1, 3, 32, 31, '', '';
$G = $R = $E = '' unless eval { require Algorithm::Diff };

#pl -F, --color K *.csv | pl -pB '@c{1, 3, 32, 31, ""} = qw(B I G R E)' 's/\e\[(\d*)m/\${$c{$1}}/g; s/\t?\$\{[BI]\}.*\$\{\KE/e/'
$_ = <<EOF;
${B}1${e}
	${G}1,H,Hydrogen,1:${R}H & ${G}alkali metal,1${R}.008${E}
	${I}n/a${e}
	${G}1,H,Hydrogen,1:alkali metal,1${E}
${B}4${e}
	${G}4,${R}Be${G},${R}B${G}er${R}y${G}l${R}l${G}ium,2:${R}a${G}l${R}kaline${G} ${R}e${G}a${R}rth metal${G},${R}9${G}.${R}01${G}2${E}
	${G}4,${R}Pl${G},${R}P${G}erlium,2:${R}p${G}l ${R}b${G}a${R}sis${G},${R}5${G}.${R}3${G}2${R}.0${E}
	${I}n/a${e}
${B}8${e}
	${G}8,O,Oxygen,16:O ${R}&${G} chalcogen,1${R}5.999${E}
	${G}8,O,Oxygen,16:O ${R}&${G} chalcogen,1${R}6${E}
	${G}8,O,Oxygen,16:O ${R}and${G} chalcogen,1${R}6${E}
${B}41${e}
	${G}41,Nb,${R}Ni${G}obium,5:no name,9${R}2.906${E}
	${I}n/a${e}
	${G}41,Nb,${R}C${G}o${R}lum${G}bium,5:no name,9${R}3${E}
${B}74${e}
	${G}74,W,${R}Tungsten${G},6:transition metal,183.8${R}4${E}
	${G}74,W,${R}Wolfram${G},6:transition metal,183.8${E}
	${I}n/a${e}
${B}80${e}
	${G}80,Hg,${R}Me${G}r${R}cury${G},12:no name,20${R}0.592${E}
	${G}80,Hg,${R}Quicksilve${G}r,12:no name,20${R}0.6${E}
	${G}80,Hg,${R}Hyd${G}r${R}argyrum${G},12:no name,20${R}1${E}
${B}110${e}
	${I}n/a${e}
	${G}110,Ds,Darmstadtium,10:transition metal,${R}[${G}281${R}]${E}
	${G}110,Ds,Darmstadtium,10:transition metal,281${E}
EOF

pl '-F,', '--color', 'K', @files;
pl '--color', '-F,', 'k $F[0]', @files;
pl '-lF,', '--color=always', 'k $F[0], $_', @files;
pl '--color=always', '-F,', '/(.*?),/; k', @files;
pl '--color', '-F,', '/(.*?),/; k, $1', @files;
pl '--color', '-lF,', '/(.*?),/; k, $1, $_', @files;

s/\e\[\d*m//g;

pl '-F,', '--color=never', 'K', @files;
