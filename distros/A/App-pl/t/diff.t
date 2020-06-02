use Test::Simple tests => 7;

# chdir to t/
$_ = $0;
s~[^/]+$~~;
chdir $_ if length;

sub pl($@) {
    my $expect = shift;
    die "Will fail on Win, coz of \": @_\n", if grep /"/, @_;
    my $win = require Win32::ShellQuote if $^O =~ /^MSWin/;
    open my $fh, '-|', $^X, '-W', $win ? '..\pl' : '../pl',
      $win ? map '"'.join('""', split /"/).'"', @_ : @_;
    local $/;
    my $ret = <$fh>;
    ok $ret eq $expect, join ' ', 'pl', map /[\s*?()[\]{}\$\\'";|&]|^$/ ? "'$_'" : $_, @_;
    print "got: '$ret', expected: '$expect'\n" if $ret ne $expect;
}

sub alter(&@) {
    local $_ = $_;
    shift->();
    pl $_, @_;
}

my @abc = <[abc].txt>;
my( $B, $I, $G, $R, $E, $e ) = map "\e[${_}m", 1, 3, 32, 31, '', '';
$G = $R = $E = '' unless eval { require Algorithm::Diff };

my $diff = <<EOF;
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

pl $diff, '-F,', '--color', 'K', @abc;
pl $diff, '--color', '-F,', 'k $F[0]', @abc;
pl $diff, '-lF,', '--color=always', 'k $F[0], $_', @abc;
pl $diff, '--color=always', '-F,', '/(.*?),/; k', @abc;
pl $diff, '--color', '-F,', '/(.*?),/; k, $1', @abc;
pl $diff, '--color', '-lF,', '/(.*?),/; k, $1, $_', @abc;

$diff =~ s/\e\[\d*m//g;

pl $diff, '-F,', '--color=never', 'K', @abc;
