use 5.14.0;
use warnings FATAL => 'all';

use FindBin;
use File::Spec;

use Test::More;
use Test::Exception;

require_ok( 'Config::Source' );

my $default = &default_config;

my $config = Config::Source->new->add_source( $default );

isnt( $config->getall, $default, 'other memory' );
is_deeply( $config->getall, $default, 'test default' );

my $hash = { 'app.name' => '...' };
is_deeply( $config->getall( include => [ 'app.name' ] ), $hash, 'test include' );
is_deeply( $config->getall( exclude => [ 'app.version', qr/^user/ ] ), $hash, 'test exclude' );
is_deeply( $config->getall( 
	include => [ 'app.name', qr/^u/ ], 
	exclude => [ 'app.version', qr/^user/ ] 
	), $hash, 'test include exclude' 
);

done_testing();

###
sub default_config {
	return {

'app.name'    => '...',
'app.version' => '123',

'user.someval' => 'WRONG!!!',

'user.someotherval' => 90,
'user.somestruct' => [100,200],
'user.somedeeperstruct' => { a => [1,2,3], b => { c => 'asd' } },
} }