package Catmandu::MediaMosa::Response::Header;
use Catmandu::Sane;
use Moo;
use Catmandu::MediaMosa::XPath::Helper qw(:all);

has item_count => (is => 'ro',required => 1);
has item_count_total => (is => 'ro',required => 1);
has item_offset => (is => 'ro',required => 1);
has request_process_time => (is => 'ro',required => 1);
has request_result => (is => 'ro',required => 1);
has request_result_description => (is => 'ro',required => 1);
has request_result_id => (is => 'ro',required => 1);
has request_uri => (is => 'ro',required => 1);
has vpx_version => (is => 'ro',required => 1);

sub parse {
  my($class,$str_ref)=@_;
  __PACKAGE__->parse_xpath(xpath($str_ref));
}
sub parse_xpath {
  my($class,$xpath) = @_;
  __PACKAGE__->new(
    item_count => $xpath->findvalue("/response/header/item_count"),
    item_count_total => $xpath->findvalue("/response/header/item_count_total"),
    item_offset => $xpath->findvalue("/response/header/item_offset"),
    request_process_time => $xpath->findvalue("/response/header/request_process_time"),
    request_result => $xpath->findvalue("/response/header/request_result"),
    request_result_description => $xpath->findvalue("/response/header/request_result_description"),
    request_result_id => $xpath->findvalue("/response/header/request_result_id"),
    request_uri => $xpath->findvalue("/response/header/request_uri"),
    vpx_version => $xpath->findvalue("/response/header/vpx_version")
  );

}

1;
