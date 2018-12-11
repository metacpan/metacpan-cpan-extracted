package CloudHealth::API::Call::MetricsForSingleAsset;
  use Moo;
  use MooX::StrictConstructor;
  use Types::Standard qw/Str Int Bool/;

  has asset => (is => 'ro', isa => Str, required => 1);
  has granularity => (is => 'ro', isa => Str);
  has from => (is => 'ro', isa => Str);
  has to => (is => 'ro', isa => Str);
  has time_range => (is => 'ro', isa => Str);
  has page => (is => 'ro', isa => Int);
  has per_page => (is => 'ro', isa => Int);

  sub _query_params { [
    { name => 'asset' },
    { name => 'granularity' },
    { name => 'from' },
    { name => 'to' },
    { name => 'time_range' },
    { name => 'page' },
    { name => 'per_page' },
  ] }
  sub _url_params { [ ] }
  sub _method { 'GET' }
  sub _url { 'https://chapi.cloudhealthtech.com/v1/metrics' }

1;
