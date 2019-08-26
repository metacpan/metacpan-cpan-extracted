use strict;
use warnings;
use FindBin;

use Test::More;
use AWS::XRay qw/ capture /;

capture "myApp", sub {
    ok !defined(wantarray), 'void context';
};

my $ret = capture "myApp", sub {
    ok defined(wantarray) && !wantarray, 'scalar context';
};

my @ret = capture "myApp", sub {
    ok defined(wantarray) && wantarray, 'list context';
};

done_testing;
