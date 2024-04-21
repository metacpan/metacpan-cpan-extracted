use strict;
use warnings;

use Test::More 'no_plan';
use lib './lib';

# The modules that we require
my @req_mods = qw(
	Captcha::Stateless::Text
	Lingua::EN::Nums2Words
	Try::Tiny
	Crypt::Mode::CBC
	JSON
	);
foreach my $mod (@req_mods) {
  use_ok $mod;
}

my $captcha = Captcha::Stateless::Text->new();
$captcha->set_iv('gkbx5g9hsvhqrosg');                  # Must be 16 bytes / 128 bits
$captcha->set_key('tyDjb39dQ20pdva0lTpyuiowWfxSSwa9'); # 32 bytes / 256 bits (AES256)
my $ep_pre = $captcha->get_ep_pre();

my $tests = {
  'chars_invalid' => {
     valid => 0,
     'a' => 'GVS',
     'enc_payload' => $ep_pre.'qctvYSVBfjzYh1V0DfrZ23Yd_-nmOHbJdC7JUlUKMfZ6I13qt2R5vSePdWS0vAJS1Z3WgeK-q1s5U3BOv2F8XqYmnoCjfHX8f5Q83AjexhO_FRAi_3rl40PPdx2RR6rf',
     'a_real' => 'GQS',
     },
  'math_invalid' => {
     valid => 0,
     'a' => 6,
     'enc_payload' => $ep_pre.'HjSg-HEJJMMIj55rDfyLOehzmhzpepwvZU8kOePW5Sk',
     'a_real' => '10',
     },
  'chars_isvalid' => {
     valid => 1,
     'a' => 'GQS',
     'enc_payload' => $ep_pre.'qctvYSVBfjzYh1V0DfrZ23Yd_-nmOHbJdC7JUlUKMfZ6I13qt2R5vSePdWS0vAJS1Z3WgeK-q1s5U3BOv2F8XqYmnoCjfHX8f5Q83AjexhO_FRAi_3rl40PPdx2RR6rf',
     },
  'math_isvalid' => {
     valid => 1,
     'a' => 10,
     'enc_payload' => $ep_pre.'HjSg-HEJJMMIj55rDfyLOehzmhzpepwvZU8kOePW5Sk',
     },
};

foreach my $test (sort keys %{$tests}) {
  my $this_test = $tests->{$test};
  my $is_valid = $captcha->validate($this_test->{a}, $this_test->{enc_payload});
  #print "$test is_valid=$is_valid: ".Dumper($this_test)."\n";
  is($is_valid, $this_test->{valid}, "for $test: got is_valid=$is_valid and expected $this_test->{valid}");
}

# After first putting this module in service it was hit with some random
# gibberish for the enc_payload and did not handle that well, so version
# 0.3 fixed that and this test was added. To be clear, it did not
# false-positive prior, but it didn't prevent things like JSON::decode()
# on invalid data and that would croak and be noisy in log files.
my $should_be_0 = $captcha->validate('a', 'bad data');
is($should_be_0, 0, "invalid enc_payload to validate()");


1;

