
use Test::More;
use Test::Exception;
use Test::Lib;
use Beam::Wire;

my $wire = Beam::Wire->new(
    config => {
        my_object => { '$class' => 'My::Service' },
    },
);

my $obj = $wire->get( 'my_object' );
is $obj->name, 'my_object', 'name is set on Beam::Service';
is $obj->container, $wire, 'container is set on Beam::Service';

done_testing;
