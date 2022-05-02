use warnings;
use strict;

BEGIN {
    our $tests = 8;

    # chdir to t/
    $_ = $0;
    s~[^/\\]+$~~;
    chdir $_ if length;

    require './test.pm';
}


my @files = <atom-weight-[123].csv>;
my( $B, $I, $G, $R, $E ) = map "\e[${_}m", 1, 3, 32, 31, '', '';

# Run one with Algorithm::Diff, once without
#pl -F, --color K *.csv | pl -pB '@c{1, 3, 32, 31, ""} = qw(B I G R E)' 's/\e\[(\d*)m/\${$c{$1}}/g'
$_ = eval { require Algorithm::Diff } ? <<EOFrich : <<EOFsimple;
${B}1${E}
	${G}1,H,Hydrogen,1:${R}H & ${G}alkali metal,1${R}.008${E}
	${I}n/a${E}
	${G}1,H,Hydrogen,1:alkali metal,1${E}
${B}4${E}
	${G}4,${R}Be${G},${R}B${G}er${R}y${G}l${R}l${G}ium,2:${R}a${G}l${R}kaline${G} ${R}e${G}a${R}rth metal${G},${R}9${G}.${R}01${G}2${E}
	${G}4,${R}Pl${G},${R}P${G}erlium,2:${R}p${G}l ${R}b${G}a${R}sis${G},${R}5${G}.${R}3${G}2${R}.0${E}
	${I}n/a${E}
${B}8${E}
	${G}8,O,Oxygen,16:O ${R}&${G} chalcogen,16${E}
	${G}8,O,Oxygen,16:O ${R}&${G} chalcogen,16${E}
	${G}8,O,Oxygen,16:O ${R}and${G} chalcogen,16${E}
${B}41${E}
	${G}41,Nb,${R}Ni${G}obium,5:no name,9${R}2.906${E}
	${I}n/a${E}
	${G}41,Nb,${R}C${G}o${R}lum${G}bium,5:no name,9${R}3${E}
${B}42${E}
	${G}42,Ve,Veritasium,6:an element of truth,i${E}
	${I}n/a${E}
	${I}n/a${E}
${B}74${E}
	${G}74,W,${R}Tungsten${G},6:transition metal,183.8${R}4${E}
	${G}74,W,${R}Wolfram${G},6:transition metal,183.8${E}
	${I}n/a${E}
${B}80${E}
	${G}80,Hg,${R}Me${G}r${R}cury${G},12:no name,20${R}0.592${E}
	${G}80,Hg,${R}Quicksilve${G}r,12:no name,20${R}0.6${E}
	${G}80,Hg,${R}Hyd${G}r${R}argyrum${G},12:no name,20${R}1${E}
${B}110${E}
	${I}n/a${E}
	${G}110,Ds,Darmstadtium,10:transition metal,${R}[${G}281${R}]${E}
	${G}110,Ds,Darmstadtium,10:transition metal,281${E}
EOFrich
${B}1${E}
	${G}1,H,Hydrogen,1:${R}H & alkali metal,1.008${E}
	${I}n/a${E}
	${G}1,H,Hydrogen,1:${R}alkali metal,1${E}
${B}4${E}
	${G}4,${R}Be,Beryllium,2:alkaline earth metal,9.012${E}
	${G}4,${R}Pl,Perlium,2:pl basis,5.32.0${E}
	${I}n/a${E}
${B}8${E}
	${G}8,O,Oxygen,16:O ${R}&${G} chalcogen,16${E}
	${G}8,O,Oxygen,16:O ${R}&${G} chalcogen,16${E}
	${G}8,O,Oxygen,16:O ${R}and${G} chalcogen,16${E}
${B}41${E}
	${G}41,Nb,${R}Niobium,5:no name,92.906${E}
	${I}n/a${E}
	${G}41,Nb,${R}Columbium,5:no name,93${E}
${B}42${E}
	${G}42,Ve,Veritasium,6:an element of truth,i${E}
	${I}n/a${E}
	${I}n/a${E}
${B}74${E}
	${G}74,W,${R}Tungsten,6:transition metal,183.84${E}
	${G}74,W,${R}Wolfram,6:transition metal,183.8${E}
	${I}n/a${E}
${B}80${E}
	${G}80,Hg,${R}Mercury,12:no name,200.592${E}
	${G}80,Hg,${R}Quicksilver,12:no name,200.6${E}
	${G}80,Hg,${R}Hydrargyrum,12:no name,201${E}
${B}110${E}
	${I}n/a${E}
	${G}110,Ds,Darmstadtium,10:transition metal,${R}[281]${E}
	${G}110,Ds,Darmstadtium,10:transition metal,${R}281${E}
EOFsimple

pl '-F,', '--color', 'K', @files;
pl '--color', '-F,', 'k $F[0]', @files;
pl '-lF,', '--color=always', 'k $F[0], $_', @files;
pl '--color=always', '-F,', '/(.*?),/; k', @files;
pl '--color', '-F,', '/(.*?),/; k, $1', @files;
pl '--color', '-lF,', '/(.*?),/; k, $1, $_', @files;

pl_a { s/\e\[\d*m//g } '-F,', '--color=never', 'K', @files;

s/\t\Q$G\E\d+,(?=\e)/\t/g;
s/\t\Q$G\E\K\d+,//g;

pl '-F,', '--color', 'k if s/(.+?),//', @files;
