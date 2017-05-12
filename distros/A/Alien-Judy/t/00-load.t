#!perl -T
use Test::More tests => 3;

# Test that lib/Alien/Judy.pm can be loaded.
BEGIN {
    $Alien::Judy::DEBUG = 1;
	use_ok( 'Alien::Judy' );
}
diag( "Testing Alien::Judy $Alien::Judy::VERSION, Perl $], $^X" );

# Test that -lJudy can be loaded
my $loaded = Alien::Judy::dl_load_libjudy();
ok( $loaded, "Loaded -lJudy" );

# Test that the libJudy C function JudyHSGet function is available
my $hs_get = DynaLoader::dl_find_symbol( $Alien::Judy::HANDLE, 'JudyHSGet' );
ok( $hs_get, "Found JudyHSGet" );
