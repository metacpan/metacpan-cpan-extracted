use 5.14.0;
use warnings FATAL => 'all';

use FindBin;
use File::Spec;

use Test::More;
use Test::Exception;

use Config::Source;

my $user = File::Spec->catfile( $FindBin::Bin, 'config', 'user' );

# test discard_additional_keys => 0
my $config = Config::Source->new;
$config->add_source( $user );
$config->add_source( get_hash(), discard_additional_keys => 0 );

ok( $config->exists( 'another.key' ) );

is( $config->get( 'another.key' ), 'true' );

# test discard
# with regexes and values
$config = Config::Source->new;
$config->add_source( $user );
$config->add_source( get_hash(), discard => [ 'key.to.remove', qr/^match/ ], discard_additional_keys => 0 );

ok( $config->exists( 'another.key' ) );
ok( $config->exists( 'dont.match.this' ) );
ok( ! $config->exists( 'match.this' ) );
ok( ! $config->exists( 'match.this.too' ) );
ok( ! $config->exists( 'key.to.remove' ) );


done_testing();

1;

###
sub get_hash {
	{ 
		'another.key' => 'true',
		'match.this' => 1,
		'match.this.too' => 1,
		'dont.match.this' => 1,
		'key.to.remove' => 1, 
	}
}
