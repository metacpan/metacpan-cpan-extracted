use Test::Simple tests => 27;

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
my $abc = join '', @abc;
my $abcn = join "\n", @abc, '';

pl '', '-o', '', @abc;
pl $abc, '-o', 'E', @abc;
pl $abc, '-op', '', @abc;
pl $abc[0], '-op1', '', @abc;
pl $abc[1], '-oP', '/b/', @abc;
pl $abc[1], '-oP1', '/b|c/', @abc;
pl $abcn, '-opl12', '', @abc;
pl $abc, '-Op', '$_ = $A', @abc;
pl $abcn, '-O', 'e $A', @abc;


my $copy = $_ = <<EOF;
begin
0;a.txt;1;a,1:A A
0;a.txt;2;b,2:B B
0;a.txt;3;c,3:C C
eof
1;b.txt;1;a,1:A A
1;b.txt;2;b,2:BB B
1;b.txt;3;d,4:D D
eof
2;c.txt;1;a,1:A A
2;c.txt;2;c,3:C CC
2;c.txt;3;d,:DD D
2;c.txt;4;e,5:E EE
eof
end
EOF

my @bze = ('-rbecho q{begin}', '-ze q{eof}', '-e', 'e q{end}');
sub unbze { s/(?:begin|eof|end)\n//g }
pl $_, @bze, 'Echo qq{$ARGIND;$ARGV;$.;$_}', @abc;
pl $_, @bze, 'E qq{$I;$A;$.;$_}', @abc;
alter \&unbze,
  '-r', 'Echo qq{$ARGIND;$ARGV;$.;$_}', @abc;

sub cut_from_34 { s/([0-9]).+,[34].+\n(?:\1.+\n)*//gm }
alter \&cut_from_34,
  @bze, 'last if /[34]/; E qq{$I;$A;$.;$_}', @abc;
alter { cut_from_34; s/(?:begin|eof|end)\n//g }
  '-r', 'last if /[34]/; E qq{$I;$A;$.;$_}', @abc;

substr $bze[0], 1, 1, '';	# done testing -r

sub renumber { my $i = 0; s/;\K([1-9])(?=;)/++$i/eg } # convert $. to count across all files
renumber;
pl $_, @bze, 'E qq{$I;$A;$.;$_}', @abc;

sub cut_after_23 { s/([0-9]).+,[23].+\n\K(?:\1.+\n)*//gm }
alter { cut_after_23; renumber }
  @bze, 'E qq{$I;$A;$.;$_}; last if /[23]/', @abc;

pl '', '-n', '', @abc;

unbze;
s/.*;//mg; # reduce to only file contents
pl $_, '-n', 'E', @abc;
pl $_, '-ln', 'e', @abc;
pl $_, '-p', '', @abc;
pl $_, '-lp', '', @abc;

my @cdlines = grep /[cd]/, split /^/;
pl join( '', $cdlines[0], "eof\n", $cdlines[1], "eof\n" x 2 ), '-P2z', 'e q{eof}', '/[cde]/', @abc;
pl join( '', @cdlines ), '-rP2', '/[cde]/', @abc;

sub pl10($$) {
    my $sep = $_[1];
    alter { s/^(.+)$sep(.+)$/$2 $1/gm } $_[0], 'e @F[1, 0]', @abc;
}
pl10 '-al', ' ';
pl10 '-lF,', ',';
pl10 '-lF:', ':';

# reproduce the splits that -054 (comma) will do
$_ = $copy;
unbze;
s/^(.).*\K\n(?!\1)/\n][/mg; # different file numbers
chop; # extra [ on last line
s/[0-9].*;//mg; # reduce to only file contents
s/,/,][/g;
substr $_, 0, 0, '[';
pl $_, '-054n', 'E qq{[$_]}', @abc; # 054 is comma, also splits at file ends
