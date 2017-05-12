use 5.14.0;
use warnings FATAL => 'all';

use FindBin;
use File::Spec;

use Test::More;
use Test::Exception;

require_ok( 'Config::Source' );

my $user      = File::Spec->catfile( $FindBin::Bin, 'config', 'user' );
my $user_save = File::Spec->catfile( $FindBin::Bin, 'config', 'user_save' );
my $system    = File::Spec->catfile( $FindBin::Bin, 'config', 'system' );

# new
my $config = new_ok( 'Config::Source' );

# init
lives_ok {
	$config->add_source( default_config() );
	$config->add_source( $user );
	$config->add_source( $system );
} 'add multiple sources';

# get
is( $config->get( 'app.name' ), 'new name', 'get value' );

# test bug in <= 0.04 undefined value
lives_ok {
	$config->get( 'bug.undef.value' );
} 'test bug prior 0.04 undefined value';

# set
lives_ok { $config->set( 'user.someotherval' => 'TESTVAL' ) } 'test set - 1';
is( $config->get( 'user.someotherval' ), 'TESTVAL', 'test set - 2' );

# exists
ok( ! $config->exists( 'additional_key' ), 'key should not exist' );

# keys
is( join( ', ', $config->keys( qr/^app/ ) ), 'app.name, app.version', 'keys' );

# reset
lives_ok { $config->reset( 'user.someotherval', $user ) } 'reset test #1 - 1';
is( $config->get( 'user.someotherval' ), 90, 'reset test #1 - 2' );

lives_ok { $config->reset( 'user.someotherval', $system ) } 'reset test #2 - 1';
is( $config->get( 'user.someotherval' ), 'my system val', 'reset test #2 - 2' );

lives_ok { $config->reset( 'user.someotherval', default_config() ) } 'reset test #3 - 1';
is( $config->get( 'user.someotherval' ), 90, 'reset test #3 - 2' );

# save
lives_ok { $config->save_file( $user_save ) } 'save test';

my $config2 = new_ok( 'Config::Source' );
$config2->add_source( $user_save );

# and getall
is_deeply( $config->getall, $config2->getall, 'check after save' );

# cleanup
END {
	unlink $user_save if -f $user_save;
} 

# done
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

'bug.undef.value' => undef,

} }

1;
