use Test::More;

use File::Temp qw/tempdir/;
use File::Spec::Functions qw/catfile/;

my $td = tempdir( CLEANUP => 1 );

use_ok('App::TeleGramma::Store');

my $store = App::TeleGramma::Store->new(path => $td);
ok ($store, 'store exists');

is_deeply ($store->hash('foo'), {}, 'empty hash');
ok (-e catfile($td, 'foo'), 'file created');

$store->hash('foo')->{bar} = { baz => [1,2,3] };
$store->save_all;

undef $store;
$store = App::TeleGramma::Store->new(path => $td);
ok ($store, 'store re-instantiated');

is_deeply($store->hash('foo'), { bar => { baz => [ 1, 2, 3 ]} }, 'has correct content');

done_testing();
