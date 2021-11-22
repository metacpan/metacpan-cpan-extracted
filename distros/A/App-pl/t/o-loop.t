use warnings;
use strict;

use Test::Simple tests => 11;

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


my @files = <atom-weight-[123].csv>;
my $files = join '', @files;
my $filesa = join '][', @files;
my $filesn = join "\n", @files, '';

pl_e '', '-o', '', @files;
pl_e $files, '-o', 'Echo', @files;
pl_e $files, '-oA<atom-weight-[123].csv>', 'Echo';
pl_e "[$filesa]", '-oA"[$_]"', 'Echo', @files;
pl_e $files, '-op', '', @files;
pl_e $files[0], '-op1', '', @files;
pl_e $files[1], '-oP', '/2/', @files;
pl_e $files[1], '-oP1', '/[23]/', @files;
pl_e $filesn, '-opl12', '', @files;
pl_e $files, '-Op', '$_ = $ARGV', @files;
pl_e $filesn, '-O', 'e $A', @files;
