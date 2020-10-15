package Async::Microservice::HelloWorld;
use Moose;
with qw(Async::Microservice);
sub service_name {return 'asmi-helloworld';}
sub get_routes {return ('hello' => {defaults => {GET => 'GET_hello'}});}
sub GET_hello {
    my ($self, $this_req) = @_;
    return $this_req->respond(200, [], 'Hello world!');
}
1;

__END__

=head1 NAME

Async::Microservice::HelloWorld - synopsis example of async microservice

=head1 DESCRIPTION

See L<Async::Microservice> and L<Async::Microservice::Time>

=cut
