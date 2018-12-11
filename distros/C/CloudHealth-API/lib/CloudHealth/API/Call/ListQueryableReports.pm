package CloudHealth::API::Call::ListQueryableReports;
  use Moo;
  use MooX::StrictConstructor;
  use Types::Standard qw/Str Int Bool/;

  sub _query_params { [ ] }
  sub _url_params { [ ] }
  sub _method { 'GET' }
  sub _url { 'https://chapi.cloudhealthtech.com/olap_reports' }

1;
