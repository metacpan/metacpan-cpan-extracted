package Activiti::Rest::UserAgent::LWP;
use Activiti::Sane;
use Carp qw(confess);
use Moo;
use LWP::UserAgent;
use URI::Escape qw(uri_escape);
use Data::Util qw(:check :validate);

with qw(Activiti::Rest::UserAgent);

has ua => (
  is => 'ro',
  lazy => 1,
  builder => '_build_ua'
);
sub _build_ua {
  my $self = $_[0];
  my $ua = LWP::UserAgent->new(
    cookie_jar => {}
  );
  if(is_string($ENV{LWP_TRACE})){
    $ua->add_handler("request_send",  sub { shift->dump; return });
    $ua->add_handler("response_done", sub { shift->dump; return });
  }
  for my $header(@{ $self->default_headers() }){
    $ua->default_header($header->[0] => $header->[1]);
  }
  $ua;
}

sub request {
  my($self,%args) = @_;

  my $params = $args{params};
  my $method = $args{method} || "GET";
  my $path = $args{path} || "";
  my $headers = $args{headers};

  my $url = $self->url().$path;

  my $res;
  if(uc($method) eq "GET"){
    $res = $self->_get($url,$params,$headers);
  }elsif(uc($method) eq "POST"){
    $res = $self->_post($url,$params,$headers);
  }elsif(uc($method) eq "PUT"){
    $res = $self->_put($url,$params,$headers);
  }elsif(uc($method) eq "DELETE"){
    $res = $self->_delete($url,$params,$headers);
  }else{
    confess "method $method not supported";
  }

  $res;
}
sub _post {
  my($self,$url,$params,$headers)=@_;
  my @args = ($url,_construct_params_as_array($params));
  my @headers;
  @headers = @{ _construct_params_as_array($headers) } if is_hash_ref($headers);
  push @args,@headers;
  $self->ua->post(@args);
}
sub _put {
  my($self,$url,$params,$headers)=@_;
  my @args = ($url);
  my @headers;
  @headers = @{ _construct_params_as_array($headers) } if is_hash_ref($headers);
  push @args,@headers;
  $self->ua->put(@args);
}
sub _construct_query {
  my $data = shift;
  my @parts = ();
  for my $key(keys %$data){
    if(is_array_ref($data->{$key})){
      for my $val(@{ $data->{$key} }){
          push @parts,uri_escape($key)."=".uri_escape($val // "");
      }
    }else{
      push @parts,uri_escape($key)."=".uri_escape($data->{$key} // "");
    }
  }
  join("&",@parts);
}
sub _construct_params_as_array {
  my $params = shift;
  my @array = ();
  for my $key(keys %$params){
    if(is_array_ref($params->{$key})){
      for my $val(@{ $params->{$key} }){
        push @array,$key => $val;
      }
    }else{
      push @array,$key => $params->{$key};
    }
  }
  return \@array;
}
sub _get {
  my($self,$url,$data)=@_;
  my $query = _construct_query($data) || "";
  $self->ua->get($url."?$query");
}
sub _delete {
  my($self,$url,$params,$headers)=@_;
  my $query = _construct_query($params) || "";
  $url .= "?$query";
  $self->ua->delete($url);
}

1;
