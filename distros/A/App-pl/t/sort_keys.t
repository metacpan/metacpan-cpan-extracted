use warnings;
use strict;

use Test::Simple tests => 12;

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
# run pl, shift -B arg, sort list
sub pl_s($@) {
    my( $B, @l ) = @_;
    local $_ = join '',
      map "$_:  0\n", @l;
    pl '-B', $B, '@R{@A} = (0) x @A', @l;
}

my @l = qw(0 07 08 a b c aa 0b1 0b2 bb be cc bad babe);
pl_s '', @l;
pl_s '$H = 1', sort { hex $a <=> hex $b } @l;

@l = sort @l;
pl_s '$H = $T = 1', @l;
pl_s '$H = 1', @l, 'z';

pl_s '$H = 1', sort @l, qw(1.1 +2);

pl_s '$H = 1', sort @l, 'c_c';
pl_s '$H = 1', sort @l, 'CC';

pl_s '$H = 1', sort { $a <=> $b } qw(-1 -.5 0 1 +2 3 04);

@l = qw(-1 0 1 -1.1 .2 +.3 5. -1e-2 +1e-2 -1.e2 -.1e2 1.E2 -0X2 0x0_2 -0b1_1 0B1_1 04 -04);
my $old = ! eval 'no warnings; 0X2 == 2 && 0B10 == 2'; # old perl
@l  = map { $_ = lc } @l if $old;

pl_s '$H = 1', sort { eval $a <=> eval $b } @l;
pl_s '$H = 1', sort @l, '08';
pl_s '$H = 1', sort @l, $old ? '0x2' : '0X2';
pl_s '$H = 1', sort @l, 100;
