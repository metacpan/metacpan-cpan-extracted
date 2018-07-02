use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";

use AWS::XRay qw/ capture capture_from /;
use Test::More;
use t::Util qw/ reset segments /;

my $header;
capture_from $header, "first", sub {
};

my @seg = segments;
ok @seg == 1;

my $root = shift @seg;
is $root->{name}, "first";
like $root->{trace_id} => qr/\A1-[0-9a-fA-F]{8}-[0-9a-fA-F]{24}\z/, "trace_id format";
like $root->{id}       => qr/\A[0-9a-fA-F]{16}\z/;
is $root->{type}, undef;

done_testing;
