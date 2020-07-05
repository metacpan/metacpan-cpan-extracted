use Test::Simple tests => 1;

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

my $fmt = '1973-11-29T21:33:09.%06d +00:00 'x3 . '1973-11-29T22:33:09.%06d +01:00 ' .
  "Thu Nov 29 12:03:19.%06d -09:30 1973 1973-11-30T06:18:09.%06d +08:45\n";
$_ = join '', map sprintf( $fmt, ($_)x6 ), 0, 0, 100_000, 1, 123_456, 123_456;

pl 'for( @A, [$A[0], 123456] ) { E I( $_, 0 ), I( 0.0, $_ ), I( $_, "+0" ), I( $_, 1 ), D( $_, -80, "+90", "-9.5" ), ""; I "08:45", $_ }',
  qw(123456789 123456789.0 123456789.1 123456789.000001 123456789.123456789);
