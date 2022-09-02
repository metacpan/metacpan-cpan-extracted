# Test suite for ControlBreak

use strict;
use warnings;
use v5.18;      # minimum needed for Object::Pad

use Test::More tests => 1;

use FindBin;
use lib $FindBin::Bin . '/../lib';

use Capture::Tiny ':all';

my ($stdout, $stdin, $exit) = capture {
    count_runs();
};


my $expected = <<__EX__;
L1 A -> 0 x 1
L1 A -> 1 x 7
L2 ========= A
L1 B -> 1 x 1
L1 B -> 0 x 1
L1 B -> 1 x 2
L1 B -> 0 x 3
L1 B -> 1 x 4
L1 B -> 0 x 2
L2 ========= B
L1 C -> 0 x 2
L1 C -> 1 x 1
L2 ========= C
__EX__


is $stdout, $expected;


sub count_runs {
    use v5.18;

    use lib $FindBin::Bin . '/../lib';

    use ControlBreak;

    # two levels, the lowest is numeric and the highest is alpha
    my $cb = ControlBreak->new( 'IsExtreme', 'Label' );

    $cb->comparison( IsExtreme => '==' );


    my @result;

    while (my $line = <DATA>) {
        chomp $line;

        my ($label, $v) = split ' ', $line;

        # test the values; make sure the variables are listed in the correct order
        $cb->test($v, $label);

        # take action if this was a level 1 control break, or above
        if ($cb->break('IsExtreme')) {
            say 'L1 ', $cb->last('Label'), ' -> ', $cb->last('IsExtreme'), ' x ', scalar @result;
            @result = ();   # clear captured values
        }

        # take action if this was a level 2 control break, or above
        if ($cb->break('Label')) {
            say 'L2 ========= ', $cb->last('Label');
            @result = ();   # clear captured values
        }

        # capture current value
        push @result, $v;
    }
    continue {
        # this sets up the next iteration, by making the current values
        # (as received by ->test) into the last values
        $cb->continue();
    }

    # uncoverable branch false
    if ($cb->iteration > 0) {
        say 'L1 ', $cb->last('Label'), ' -> ', $cb->last('IsExtreme'), ' x ', scalar @result;
        say 'L2 ========= ', $cb->last('Label');
    }
}

__DATA__
A 0
A 1
A 1
A 1
A 1
A 1
A 1
A 1
B 1
B 0
B 1
B 1
B 0
B 0
B 0
B 1
B 1
B 1
B 1
B 0
B 0
C 0
C 0
C 1
