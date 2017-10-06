use strict;
use warnings;
use Test::More;

my $test_data = do {
  open my $test_fh, '<', 't/ip-ranges.json' or die $!;
  local $/;
  <$test_fh>;
};

# loads ok
use_ok('AWS::IP', 'load module');
ok my $aws = AWS::IP->new(600), 'constructor';
ok $aws->_refresh_cache_from_string($test_data), 'refresh cache';

# ip range checks
ok $aws->ip_is_aws('50.19.0.1'), 'ip 50.19.0.1 is found in AWS range';
ok $aws->ip_is_aws('54.239.98.0', 'AMAZON'), 'ip 54.239.98.0 is found in AMAZON AWS range';
ok !$aws->ip_is_aws('54.239.98.0', 'EC2'), 'ip 54.239.98.0 is not found in EC2 AWS range';

# counts
is 383, @{$aws->get_cidrs}, '383 CIDRs are present';
is 5, @{$aws->get_services}, '5 services are present';
is 12, @{$aws->get_regions}, '12 regions are present';

# cache expiry
ok my $aws_2 = AWS::IP->new(1), 'constructor with 1 second cache';
ok $aws->_refresh_cache_from_string($test_data), 'refresh cache';
sleep(2); # let cache expire
ok !$aws_2->{cache}->entry('AWS_IPS')->exists, 'Entry no longer exists';
ok !$aws_2->{cache}->entry('AWS_IPS')->get, 'Data is no longer cached';

done_testing;
