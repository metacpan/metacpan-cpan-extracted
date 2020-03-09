package AWS::XRay::Plugin::EC2;
use strict;
use warnings;

use HTTP::Tiny;

# for test
our $_base_url = "http://169.254.169.254/latest";

sub ID_ADDR() {
    return "$_base_url/meta-data/instance-id";
}

sub AZ_ADDR() {
    return "$_base_url/meta-data/placement/availability-zone";
}

our $METADATA;

sub apply_plugin {
    my ($class, $segment) = @_;

    $METADATA ||= do {
        my $ua = HTTP::Tiny->new(timeout => 1);

        # get token for IMDSv2
        my $token = do {
            my $res = $ua->request(
                "PUT",
                "$_base_url/api/token", {
                    headers => {
                        'X-aws-ec2-metadata-token-ttl-seconds' => '60',
                    },
                }
            );
            $res->{success} ? $res->{content} : '';
        };
        my $opt = {};
        if ($token ne '') {
            $opt->{headers}->{'X-aws-ec2-metadata-token'} = $token;
        }

        my $instance_id = do {
            my $res = $ua->get(ID_ADDR, $opt);
            $res->{success} ? $res->{content} : '';
        };
        my $az = do {
            my $res = $ua->get(AZ_ADDR, $opt);
            $res->{success} ? $res->{content} : '';
        };

        +{
            instance_id       => $instance_id,
            availability_zone => $az,
        };
    };

    $segment->{origin} = 'AWS::EC2::Instance';
    $segment->{aws}->{ec2} = $METADATA;
}

1;
