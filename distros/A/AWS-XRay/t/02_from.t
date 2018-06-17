use strict;
use AWS::XRay qw/ capture capture_from /;
use Test::More;
use IO::Scalar;
use JSON::XS;
use Time::HiRes qw/ sleep /;

my $buf;
no warnings 'redefine';

*AWS::XRay::sock = sub {
    IO::Scalar->new(\$buf);
};

my $header = capture "from", sub {
    my $segment = shift;
    return $segment->trace_header;
};
diag $header;

capture_from $header, "to", sub {
};

is $buf =~ s/{"format":"json","version":1}//g => 2, "includes 2 segment headers";
diag $buf;
my @seg = split /\n/, $buf;
shift @seg; # despose first ""

my $from = decode_json(shift @seg);
is $from->{name}, "from";

my $to = decode_json(shift @seg);
is $to->{name}      => "to";
is $to->{parent_id} => $from->{id};
is $to->{trace_id}  => $from->{trace_id};
is $to->{type}      => "subsegment";

done_testing;
