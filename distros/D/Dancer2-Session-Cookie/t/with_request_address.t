use Test::More;
use Test::MockObject;

use Dancer2::Session::Cookie;

sub session_of {
    my $request = Test::MockObject->new->set_always( address => shift || '127.0.0.1' );
    $request->set_isa( 'Dancer2::Core::Request' );

    Dancer2::Session::Cookie->new( with_request_address => 1, secret_key => 'hush', request => $request );
}

my $session = session_of('127.0.0.1');

my $data = $session->_freeze( 'banana' );

isnt $data => 'banana', 'encrypted';

is session_of('127.0.0.1')->_retrieve($data) => 'banana', 'decrypted';

is session_of('127.0.0.2')->_retrieve($data) => undef, 'different address, not decrypted';

done_testing;
