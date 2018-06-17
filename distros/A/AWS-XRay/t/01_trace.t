use strict;
use AWS::XRay qw/ capture /;
use Test::More;
use IO::Scalar;
use JSON::XS;
use Time::HiRes qw/ sleep /;

my $buf;
no warnings 'redefine';

*AWS::XRay::sock = sub {
    IO::Scalar->new(\$buf);
};

capture "myApp", sub {
    my $seg = shift;
    sleep 0.1;
    capture "remote1", sub { sleep 0.1 };
    capture "remote2", sub {
        sleep 0.1;
        capture "remote3", sub { sleep 0.1 };
    };
    $seg->{annotations}->{foo} = "bar";
};

is $buf =~ s/{"format":"json","version":1}//g => 4, "includes 4 segment headers";
diag $buf;
my @seg = split /\n/, $buf;
shift @seg; # despose first ""

my $root = decode_json(pop @seg);
is $root->{name}, "myApp";
like $root->{trace_id} => qr/\A1-[0-9a-fA-F]{8}-[0-9a-fA-F]{24}\z/, "trace_id format";
like $root->{id}       => qr/\A[0-9a-fA-F]{16}\z/;
is $root->{type}, undef;
ok $root->{start_time} < $root->{end_time};
is $root->{annotations}->{foo} => "bar";

my $trace_id = $root->{trace_id};
my $root_id  = $root->{id};

# remote1
my $seg1 = decode_json(shift @seg);
like $seg1->{id}      => qr/\A[0-9a-fA-F]{16}\z/;
is $seg1->{name}      => "remote1";
is $seg1->{parent_id} => $root_id;
is $seg1->{trace_id}  => $trace_id;
is $seg1->{type}      => "subsegment";
ok $seg1->{start_time} >= $root->{start_time};
ok $seg1->{end_time}   <= $root->{end_time};

# remote2
my $seg2 = decode_json(pop @seg);
like $seg2->{id}      => qr/\A[0-9a-fA-F]{16}\z/;
is $seg2->{name}      => "remote2";
is $seg2->{parent_id} => $root_id;
is $seg2->{trace_id}  => $trace_id;
is $seg2->{type}      => "subsegment";
ok $seg2->{start_time} >= $seg1->{start_time};
ok $seg2->{end_time}   <= $root->{end_time};

# remote3
my $seg3 = decode_json(shift @seg);
like $seg3->{id}      => qr/\A[0-9a-fA-F]{16}\z/;
is $seg3->{name}      => "remote3";
is $seg3->{parent_id} => $seg2->{id};
is $seg3->{trace_id}  => $trace_id;
is $seg3->{type}      => "subsegment";
ok $seg3->{start_time} >= $seg2->{start_time};
ok $seg3->{end_time}   <= $seg2->{end_time};

done_testing;
