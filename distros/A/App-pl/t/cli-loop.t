use Test::Simple tests => 27;

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
# run pl, expect shift
sub pl_e($@) {
    local $_ = shift;
    &pl;
}
# run pl, expect $_ altered by shift->()
sub pl_a(&@) {
    local $_ = $_;
    shift->();
    &pl;
}


my @abc = <[abc].txt>;
my $abc = join '', @abc;
my $abcn = join "\n", @abc, '';

pl_e '', '-o', '', @abc;
pl_e $abc, '-o', 'E', @abc;
pl_e $abc, '-op', '', @abc;
pl_e $abc[0], '-op1', '', @abc;
pl_e $abc[1], '-oP', '/b/', @abc;
pl_e $abc[1], '-oP1', '/b|c/', @abc;
pl_e $abcn, '-opl12', '', @abc;
pl_e $abc, '-Op', '$_ = $A', @abc;
pl_e $abcn, '-O', 'e $A', @abc;


my $copy = $_ = <<EOF;
begin
bof
0;a.txt;1;a,1:A A
0;a.txt;2;b,2:B B
0;a.txt;3;c,3:C C
eof
bof
1;b.txt;1;a,1:A A
1;b.txt;2;b,2:BB B
1;b.txt;3;d,4:D D
eof
bof
2;c.txt;1;a,1:A A
2;c.txt;2;c,3:C CC
2;c.txt;3;d,:DD D
2;c.txt;4;e,5:E EE
eof
end
EOF

my @BbeE = ('-rBecho "begin"', '-b', 'e "bof"', '-ee "eof"', '-E', 'e "end"');
sub unBbeE { s/(?:begin|[be]of|end)\n//g }
pl @BbeE, 'Echo "$ARGIND;$ARGV;$.;$_"', @abc;
pl @BbeE, 'E "$I;$A;$.;$_"', @abc;
pl_a \&unBbeE,
  '-r', 'Echo "$ARGIND;$ARGV;$.;$_"', @abc;

	#use v5.10;say $_;
sub cut_from_34 { s/([0-9]).+,[34].+\n(?:\1.+\n)*//gm }
	#cut_from_34;say $_;
pl_a \&cut_from_34,
  @BbeE, 'last if /[34]/; E "$I;$A;$.;$_"', @abc;
pl_a { &cut_from_34; &unBbeE }
  '-r', 'last if /[34]/; E "$I;$A;$.;$_"', @abc;

substr $BbeE[0], 1, 1, '';	# done testing -r

sub renumber { my $i = 0; s/;\K([1-9])(?=;)/++$i/eg } # convert $. to count across all files
renumber;
pl @BbeE, 'E "$I;$A;$.;$_"', @abc;

sub cut_after_23 { s/([0-9]).+,[23].+\n\K(?:\1.+\n)*//gm }
pl_a { cut_after_23; renumber }
  @BbeE, 'E "$I;$A;$.;$_"; last if /[23]/', @abc;

pl_e '', '-n', '', @abc;

unBbeE;
s/.*;//mg; # reduce to only file contents
pl '-n', 'E', @abc;
pl '-ln', 'e', @abc;
pl '-p', '', @abc;
pl '-lp', '', @abc;

my @cdlines = grep /[cd]/, split /^/;
pl_e join( '', $cdlines[0], "eof\n", $cdlines[1], "eof\n" x 2 ), '-P2e', 'e "eof"', '/[cde]/', @abc;
pl_e join( '', @cdlines ), '-rP2', '/[cde]/', @abc;

# run pl, expect @F[1, 0] separated by $_[0]
sub pl_F10($$) {
    my $sep = $_[0];
    pl_a { s/^(.+)$sep(.+)$/$2 $1/gm } $_[1], 'e @F[1, 0]', @abc;
}
pl_F10 ' ', '-al';
pl_F10 ',', '-lF,';
pl_F10 ':', '-lF:';

# reproduce the splits that -054 (comma) will do
$_ = $copy;
unBbeE;
s/^(.).*\K\n(?!\1)/\n][/mg; # different file numbers
chop; # extra [ on last line
s/[0-9].*;//mg; # reduce to only file contents
s/,/,][/g;
substr $_, 0, 0, '[';
pl '-054n', 'E "[$_]"', @abc; # 054 is comma, also splits at file ends
