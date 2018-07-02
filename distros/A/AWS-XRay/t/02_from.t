use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";

use AWS::XRay qw/ capture capture_from /;
use Test::More;
use t::Util qw/ reset segments /;

my $header = capture "from", sub {
    my $segment = shift;
    return $segment->trace_header;
};
diag $header;

capture_from $header, "to", sub {
};

my @seg = segments();
ok @seg == 2;

my $from = shift @seg;
is $from->{name}, "from";

my $to = shift @seg;
is $to->{name}      => "to";
is $to->{parent_id} => $from->{id};
is $to->{trace_id}  => $from->{trace_id};
is $to->{type}      => "subsegment";

done_testing;
