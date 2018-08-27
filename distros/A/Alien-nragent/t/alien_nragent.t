use Test2::V0 -no_srand => 1;
use Alien::nragent;
use FFI::Platypus;
use Test::Alien;

alien_ok 'Alien::nragent';

ffi_ok with_subtest {
  my($ffi) = @_;
  my $address = $ffi->find_symbol('newrelic_message_handler');
  ok $address, 'has newrelic_message_handler';
  note "address = @{[ $address || 'undef' ]}";
  note "lib     = $_" for $ffi->lib;
};

done_testing
