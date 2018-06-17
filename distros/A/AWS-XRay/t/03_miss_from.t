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

my $header;
capture_from $header, "first", sub {
};

is $buf =~ s/{"format":"json","version":1}//g => 1, "includes 1 segment headers";
diag $buf;
my @seg = split /\n/, $buf;
shift @seg; # despose first ""

my $root = decode_json(shift @seg);
is $root->{name}, "first";
like $root->{trace_id} => qr/\A1-[0-9a-fA-F]{8}-[0-9a-fA-F]{24}\z/, "trace_id format";
like $root->{id}       => qr/\A[0-9a-fA-F]{16}\z/;
is $root->{type}, undef;

done_testing;
