package CloudHealth::API::Call::ListReportsOfSpecificType;
  use Moo;
  use MooX::StrictConstructor;
  use Types::Standard qw/Str Int Bool/;

  has type => (is => 'ro', isa => Str, required => 1);

  sub _query_params { [ ] }
  sub _url_params { [
    { name => 'type', location => 'report-type' }    
  ] }
  sub _method { 'GET' }
  sub _url { 'https://chapi.cloudhealthtech.com/olap_reports/:report-type' }

1;
