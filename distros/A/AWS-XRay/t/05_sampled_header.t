use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";

use AWS::XRay qw/ capture capture_from /;
use Test::More;
use t::Util qw/ reset segments /;

AWS::XRay->sampling_rate(0);

my $trace_id   = AWS::XRay::new_trace_id;
my $segment_id = AWS::XRay::new_id;

my $header1 = "Root=$trace_id;Parent=$segment_id;Sampled=1";
diag $header1;
my $header2 = capture_from $header1, "from", sub {
    my $segment = shift;
    return $segment->trace_header;
};
diag $header2;
capture_from $header2, "to", sub {
    capture "sub", sub { };
};

my @seg = segments();
ok @seg == 3;

my $from = shift @seg;
is $from->{name}, "from";

my $to = pop @seg;
is $to->{name}      => "to";
is $to->{parent_id} => $from->{id};
is $to->{trace_id}  => $from->{trace_id};
is $to->{type}      => "subsegment";

my $sub = pop @seg;
is $sub->{name}      => "sub";
is $sub->{parent_id} => $to->{id};
is $sub->{trace_id}  => $from->{trace_id};
is $sub->{type}      => "subsegment";

done_testing;
