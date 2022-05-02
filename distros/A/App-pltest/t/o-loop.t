use warnings;
use strict;

BEGIN {
    our $tests = 15;

    # chdir to t/
    $_ = $0;
    s~[^/\\]+$~~;
    chdir $_ if length;

    require './test.pm';
}

my @files = <atom-weight-[123].csv>;
my $files = join '', @files;
my $filesa = join '][', @files;
my $filesn = join "\n", @files, '';

pl_e '', '-o', '', @files;
pl_e $files, '-o', 'Echo', @files;
pl_e $files, '-oA<atom-weight-[123].csv>', 'Echo';
pl_e 'atom-weight-3.csv', '-oA<atom-weight-[123].csv>', '-A{ (stat)[7] < 200 }', 'Echo';
pl_e 'atom-weight-3.csv', '-oA', '{ (stat)[7] < 200 }', 'Echo', <atom-weight-[123].csv>;
pl_e "[$filesa]", '-oA"[$_]"', 'Echo', @files;
pl_e $files, '-op', '', @files;
pl_e $files[0], '-op1', '', @files;
pl_e $files[1], '-oP', '/2/', @files;
pl_e $files[1], '-oP1', '/[23]/', @files;
pl_e $filesn, '-opl12', '', @files;
pl_e $files, '-Op', '$_ = $ARGV', @files;
pl_e $filesn, '-O', 'e $A', @files;

pl_e <<O4, '-O4', '-E e $I, @A', 'e $I, @$A', 1..9;
0 1 2 3 4
4 5 6 7 8
8 9 undef undef undef
12 1 2 3 4 5 6 7 8 9 undef undef undef
O4

pl_e '6 1 -4 3 4 -10 6', '-o3E E $I, @A', '$_->[1] *= -2', 1..6;
