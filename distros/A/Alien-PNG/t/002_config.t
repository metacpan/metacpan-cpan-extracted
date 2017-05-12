# t/002_config.t - test config() functionality

use Test::More tests => 5;
use Alien::PNG;

### test some config strings
like( Alien::PNG->config('version'), qr/([0-9]+\.)*[0-9]+/, "Testing config('version')" );
like( Alien::PNG->config('prefix'), qr/.+/, "Testing config('prefix')" );

### check if prefix is a real directory
my $p = Alien::PNG->config('prefix');
diag ("Prefix='$p'");
is( (-d Alien::PNG->config('prefix')), 1, "Testing existence of 'prefix' directory" );

### check if list of ld_shared_libs contains existing files
my $l_result = 1;
foreach (@{Alien::PNG->config('ld_shared_libs')}) {
  $l_result = 0 unless (-e $_);
}
is( $l_result, 1, "Testing 'ld_shared_libs'" );

### check if list of ld_paths contains existing directories
my $p_result = 1;
foreach (@{Alien::PNG->config('ld_paths')}) {
  $p_result = 0 unless (-d $_);
}
is( $p_result, 1, "Testing 'ld_paths'" );
