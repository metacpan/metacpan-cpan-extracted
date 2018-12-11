package CloudHealth::API::Call::SpecificCustomerReport;
  use Moo;
  use MooX::StrictConstructor;
  use Types::Standard qw/Int Str/;

  has report_type => (is => 'ro', isa => Str, required => 1);
  has report_id => (is => 'ro', isa => Str, required => 1);
  has client_api_id => (is => 'ro', isa => Int, required => 1);

  sub _query_params { [
    { name => 'client_api_id' },  
  ] }
  sub _url_params { [
    { name => 'report_type', location => 'report-type' },
    { name => 'report_id', location => 'report-id' },
  ] }
  sub _method { 'GET' }
  sub _url { 'https://chapi.cloudhealthtech.com/olap_reports/:report-type/:report-id' }

1;
