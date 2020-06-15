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

my @abc = <[abc].txt>;
my( $B, $I, $G, $R, $E, $e ) = map "\e[${_}m", 1, 3, 32, 31, '', '';
$G = $R = $E = '' unless eval { require Algorithm::Diff };

$_ = <<EOF;
${B}b${e}
	${G}b,2:B B${E}
	${G}b,2:B${R}B${G} B${E}
	${I}n/a${e}
${B}c${e}
	${G}c,3:C C${E}
	${I}n/a${e}
	${G}c,3:C C${R}C${E}
${B}d${e}
	${I}n/a${e}
	${G}d,${R}4${G}:D D${E}
	${G}d,:D${R}D${G} D${E}
${B}e${e}
	${I}n/a${e}
	${I}n/a${e}
	${G}e,5:E EE${E}
EOF

pl '-F,', '--color', 'K', @abc;
pl '--color', '-F,', 'k $F[0]', @abc;
pl '-lF,', '--color=always', 'k $F[0], $_', @abc;
pl '--color=always', '-F,', '/(.*?),/; k', @abc;
pl '--color', '-F,', '/(.*?),/; k, $1', @abc;
pl '--color', '-lF,', '/(.*?),/; k, $1, $_', @abc;

s/\e\[\d*m//g;

pl '-F,', '--color=never', 'K', @abc;
