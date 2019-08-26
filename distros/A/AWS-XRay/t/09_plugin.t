use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";

use AWS::XRay qw/ capture /;
use Test::More;
use t::Util qw/ reset segments /;

sub myApp {
    capture "remote1", sub {};
}

AWS::XRay->plugins('AWS::XRay::Plugin::EC2');
AWS::XRay->add_capture("main", "myApp");

myApp();

my @seg = segments();

my $root = pop @seg;

is $root->{origin}, 'AWS::EC2::Instance';
is_deeply $root->{aws}, {
    ec2 => {
        availability_zone => '',
        instance_id       => '',
    },
};

done_testing;
