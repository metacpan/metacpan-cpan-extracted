# todo, native Windows needs a different pl($@)

use Test::Simple tests => 14;

# chdir to t/
$_ = $0;
s~[^/]+$~~;
chdir $_;

sub pl($@) {
    my $expect = shift;
    my @prog = map "'$_'", @_;
    my $ret = `'$^X' ../pl @prog 2>&1`;
    ok $ret eq $expect, "pl @prog";
    print "got: '$ret', expected: '$expect'\n" if $ret ne $expect;
}



my @abc = <[abc].txt>;

pl join( '', @abc ), '-o', 'E', @abc;
pl join( "\n", @abc, '' ), '-O', 'e $A', @abc;


my $copy = $_ = <<EOF;
0;a.txt;1;a,1:A A
0;a.txt;2;b,2:B B
0;a.txt;3;c,3:C C
1;b.txt;1;a,1:A A
1;b.txt;2;b,2:BB B
1;b.txt;3;d,4:D D
2;c.txt;1;a,1:A A
2;c.txt;2;c,3:C CC
2;c.txt;3;d,:DD D
2;c.txt;4;e,5:E EE
EOF

pl $_, '-n', 'echoN "$ARGI;$ARGV;$.;$_"; close ARGV if eof', @abc;
pl $_, '-n', 'E "$I;$A;$.;$_"; close A if eof', @abc;

{ my $i = 0; s/;\K([1-9])(?=;)/++$i/eg } # convert $. to count across all files
pl $_, '-n', 'E "$I;$A;$.;$_"', @abc;

pl '', '-n', '', @abc;

s/.*;//mg; # reduce to only file contents
pl $_, '-n', 'E', @abc;
pl $_, '-ln', 'e', @abc;
pl $_, , '-p', '', @abc;
pl $_, , '-lp', '', @abc;

sub pl10($$) {
    local $_ = $_;
    ref( $_[1] ) ? $_[1]->() : s/^(.+)$_[1](.+)$/$2 $1/gm;
    pl $_, $_[0], 'e @F[1, 0]', @abc;
}
pl10 '-al', ' ';
pl10 '-lF,', ',';
pl10 '-lF:', ':';
#pl10 '-054F:', sub {};
#pl10 '-034F:', ':';


# reproduce the splits that -054 will do
$_ = $copy;
s/^(.).*\K\n(?!\1)/\n][/mg; # different file numbers
chop; # extra [ on last line
s/[0-9].*;//mg; # reduce to only file contents
s/,/,][/g;
substr $_, 0, 0, '[';
pl $_, '-054n', 'E "[$_]"', @abc; # 054 is comma, also splits at file ends
