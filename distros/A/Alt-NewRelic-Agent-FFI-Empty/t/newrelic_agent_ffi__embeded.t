use 5.010;
use Test2::V0 -no_srand => 1;
use NewRelic::Agent::FFI;

my $license_key = $ENV{NEWRELIC_AGENT_FFI_TEST};
skip_all 'requires license key' unless $license_key;

subtest 'init' => sub {
  my $nr = NewRelic::Agent::FFI->new;
  $nr->embed_collector;
  $nr->init;
  pass 'embed_collector; init did not crash';
};

done_testing

