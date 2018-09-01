use Test2::V0 -no_srand => 1;
use Alien::nragent;
use FFI::Platypus;
use Test::Alien;
use Capture::Tiny qw( capture_merged );

alien_ok 'Alien::nragent';

my $pass = 0;

ffi_ok with_subtest {
  my($ffi) = @_;
  my $address = $ffi->find_symbol('newrelic_message_handler');
  $pass = ok $address, 'has newrelic_message_handler';
  note "address = @{[ $address || 'undef' ]}";
  note "lib     = $_" for $ffi->lib;
};

unless($pass)
{
  foreach my $dll (Alien::nragent->dynamic_libs)
  {
    diag capture_merged {
      system 'ldd', $dll;
      ();
    };
  }
}

done_testing
