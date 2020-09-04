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
# run pl, expect shift
sub pl_e($@) {
    local $_ = shift;
    &pl;
}


# Isodate, Date
my $fmt = '1973-11-29T21:33:09.%06d +00:00 'x3 . '1973-11-29T22:33:09.%06d +01:00 ' .
  "Thu Nov 29 12:03:19.%06d -09:30 1973 Fri Nov 30 06:18:09.%06d +08:45 1973\n";
$_ = join '', map sprintf( $fmt, ($_)x6 ), 0, 0, 100_000, 1, 123_456, 123_456;

pl 'for( @A, [$A[0], 123456] ) { E Isodate( $_, 0 ), I( 0.0, $_ ), I( $_, "+0" ), I( $_, 1 ), D( $_, -80, "+90", "-9.5" ), ""; Date "08:45", $_ }',
  qw(123456789 123456789.0 123456789.1 123456789.000001 123456789.123456789);


# Magic & predefined variables
pl_e "\"'abc'\"\n", '$RESULT = "$Q${quote}abc$q$Quote"';

pl_e <<EOF, '%R = qw(a 1 b 2 c 1 d 3)';
a:  1
b:  2
c:  1
d:  3
EOF

$_ = <<EOF;
       1: a
       1: c
       2: b
       3: d
EOF

pl '%NUMBER = qw(a 1 b 2 c 1 d 3)';
s/.*c\n//s;
pl '-ENumber', '%N = qw(a 1 b 2 c 1 d 3)';
s/.*b\n//s;
pl '-E', 'N 3', '%N = qw(a 1 b 2 c 1 d 3)';



pl_e '15241578753238836750495351562536198787501905199875019052100', '-Mbignum', 'Echo 123456789012345678901234567890 * 123456789012345678901234567890';
