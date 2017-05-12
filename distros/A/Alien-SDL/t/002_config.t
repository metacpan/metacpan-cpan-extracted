# t/002_config.t - test config() functionality

use Test::More tests => 6;
use Alien::SDL;

### test some config strings
like( Alien::SDL->config('version'), qr/([0-9]+\.)*[0-9]+/, "Testing config('version')" );
like( Alien::SDL->config('prefix'), qr/.+/, "Testing config('prefix')" );

### check if prefix is a real directory
my $p = Alien::SDL->config('prefix');
diag ("Prefix='$p'");
is( (-d Alien::SDL->config('prefix')), 1, "Testing existence of 'prefix' directory" );

### check if list of ld_shared_libs contains existing files
my $l_result = 1;
foreach (@{Alien::SDL->config('ld_shared_libs')}) {
  $l_result = 0 unless (-e $_);
}
is( $l_result, 1, "Testing 'ld_shared_libs'" );

### check if list of ld_shlib_map contains existing files
my $m_result = 1;
foreach (values %{Alien::SDL->config('ld_shlib_map')}) {
  $m_result = 0 unless (-e $_);
}
is( $m_result, 1, "Testing 'ld_shlib_map'" );

### check if list of ld_paths contains existing directories
my $p_result = 1;
foreach (@{Alien::SDL->config('ld_paths')}) {
  $p_result = 0 unless (-d $_);
}
is( $p_result, 1, "Testing 'ld_paths'" );
