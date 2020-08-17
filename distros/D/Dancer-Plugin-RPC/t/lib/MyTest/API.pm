package MyTest::API;
use Moo;
use MyTest::Exception;

has test_client => (is => 'ro', required => 1);

sub rpc_ping {
    my $self = shift;
    return {result => $self->test_client->call()};
}
sub rpc_fail {
    MyTest::Exception->throw(error => "We fail\n");
}

use namespace::autoclean;
1;
