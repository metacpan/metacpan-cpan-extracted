package CloudHealth::API::ResultParser;
  use Moo;
  use JSON::MaybeXS;
  use CloudHealth::API::Error;

  has parser => (is => 'ro', default => sub { JSON::MaybeXS->new });

  sub result2return {
    my ($self, $response) = @_;

    if ($response->status >= 400) {
      return $self->process_error($response);
    } else {
      return 1 if (not defined $response->content);
      return $self->process_response($response);
    } 
  }

  sub process_response {
    my ($self, $response) = @_;
    
    my $struct = eval {
      $self->parser->decode($response->content);
    };
    CloudHealth::API::Error->throw(
      type => 'UnparseableResponse',
      message => 'Can\'t parse response ' . $response->content . ' with error ' . $@
    ) if ($@);

    return $struct;
  }

  # Process a response following http://apidocs.cloudhealthtech.com/#documentation_error-codes
  sub process_error {
    my ($self, $response) = @_;

    my $struct = eval {
      $self->parser->decode($response->content);
    };

    CloudHealth::API::Error->throw(
      type => 'UnparseableResponse',
      message => 'Can\'t parse JSON content',
      detail => $response->content,
    ) if ($@);

    my $message;
    if (defined $struct->{ error }) {
      $message = $struct->{ error };
    } elsif ($struct->{ errors } and ref($struct->{ errors }) eq 'ARRAY') {
      $message = join ',', @{ $struct->{ errors } };
    } else {
      $message = 'No message';
    }

    CloudHealth::API::RemoteError->throw(
      status => $response->status,
      message => $message,
    )
  }
1;
