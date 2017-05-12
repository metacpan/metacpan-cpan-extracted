use 5.14.0;
use warnings FATAL => 'all';

use FindBin;
use File::Spec;

use Test::More;
use Test::Exception;

BEGIN {
	eval 'use Config::General';
	if( $@ ) {
		plan skip_all => 'Config::General required for testing' 
	}
}


require_ok( 'Config::Source' );

my $user      = File::Spec->catfile( $FindBin::Bin, 'config', 'Config-General-user' );
my $user_save = File::Spec->catfile( $FindBin::Bin, 'config', 'Config-General-user_save' );
my $system    = File::Spec->catfile( $FindBin::Bin, 'config', 'Config-General-system' );

# new
my $config = new_ok( 'Config::Source' );

# init
lives_ok {
	$config->add_source( default_config() );
} 'add default source';

# a config general
my %user   = Config::General->new( $user )->getall;
my %system = Config::General->new( $system )->getall;

lives_ok { $config->add_source( \%user )->add_source( \%system ) } 'add two Config::General sources';

# get
is( $config->get( 'app.name' ), 'new name', 'get value' );

# set
lives_ok { $config->set( 'user.someotherval' => 'TESTVAL' ) } 'test set - 1';
is( $config->get( 'user.someotherval' ), 'TESTVAL', 'test set - 2' );

# exists
ok( ! $config->exists( 'additional_key' ), 'key should not exist' );

# keys
is( join( ', ', $config->keys( qr/^app/ ) ), 'app.name, app.version', 'keys' );

# save back
lives_ok { Config::General->new->save_file( $user_save, $config->getall ) } 'save Config::General back';

my $config2 = new_ok( 'Config::Source' );
$config2->add_source( { Config::General->new( $user_save )->getall } );

# and getall
is_deeply( $config->getall, $config2->getall, 'check after save' );

# cleanup
END {
	unlink $user_save if -f $user_save;
} 

# done
done_testing();


sub default_config {
	return {

'app.name'    => '...',
'app.version' => '123',

'user.someval' => 'WRONG!!!',

'user.someotherval' => 90,
'user.somestruct' => [100,200],
'user.somedeeperstruct' => { a => [1,2,3], b => { c => 'asd' } },


} }