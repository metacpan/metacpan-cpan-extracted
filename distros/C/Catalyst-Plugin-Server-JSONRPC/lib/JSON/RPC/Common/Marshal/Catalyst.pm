package JSON::RPC::Common::Marshal::Catalyst;
use Moose;

use Carp qw(croak);

extends qw(JSON::RPC::Common::Marshal::HTTP);

#OVERRIDE TO CATALYST REQUEST
sub post_request_to_call {
	my ( $self, $request ) = @_;
	#read catalyst request body
    my $body    = $request->body;
    my $content = do { local $/; <$body> };
	$self->json_to_call( $content );
}

sub write_result_to_response {
        my ( $self, $result, $response, @args ) = @_;

        my %args = $self->result_to_response_params($result);

        foreach my $key ( keys %args ) {
                if ( $response->can($key) ) {
                        $response->$key(delete $args{$key});
                }
        }

        #Copied from base class
        #JSON::RPC::Common::Marshal::HTTP introduced a "die" here. The
        # following keys where left over... and we were getting a "BAH" in
        # all Catalyst requests.
        #           'Content_Length' => 92,
        #           'Content_Type' => 'application/json'
        # Had to comment it out:
        #croak "BAH" if keys %args;

        return 1;
}

__PACKAGE__->meta->make_immutable();

__PACKAGE__

__END__

=pod

=head1 NAME

JSON::RPC::Common::Marshal::Catalyst - Convert L<Catalyst::Request> 
to L<JSON::RPC::Common:Call>.

Based on L<JSON::RPC::Common::Marshal::HTTP>. Only one method has been overriden.

=head1 SYNOPSIS

	use JSON::RPC::Common::Marshal::Catalyst;

	sub simple_json_endpoint : Local {
		my ($self, $c, @args) = @_;
		my $m = JSON::RPC::Common::Marshal::Catalyst->new;
		my $call = $m->request_to_call($c->req);
		my $res = $call->call($self);
		$m->write_result_to_response($c->res);
	}

=head1 DESCRIPTION

This object provides marshalling routines to convert L<Catalyst::Request> 
to L<JSON::RPC::Common:Call> object.

Use  L<JSON::RPC::Common::Marshal::Catalyst> to work with L<HTTP::Request>

=head1 METHODS

=over 4

=item post_request_to_call $http_request

Convert an L<Catalyst::Request> to a L<JSON::RPC::Common::Procedure::Call>. Overriden method only differ from parent that use $request->body instead of $request->content;

=back

=cut


