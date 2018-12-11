package CloudHealth::API::Credentials;
  use Moo;
  use Types::Standard qw/Maybe Str Bool/;

  has api_key => (
    is => 'ro',
    isa => Maybe[Str],
    required => 1,
    default => sub { $ENV{ CLOUDHEALTH_APIKEY } }
  );

  has is_set => (
    is => 'ro',
    isa => Bool,
    lazy => 1,
    default => sub {
      my $self = shift;
      return defined $self->api_key
    }
  );
1;
