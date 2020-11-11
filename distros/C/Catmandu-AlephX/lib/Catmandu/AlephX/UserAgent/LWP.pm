package Catmandu::AlephX::UserAgent::LWP;
use Catmandu::Sane;
use Carp qw(confess);
use Moo;
use LWP::UserAgent;
use URI::Escape;
use Catmandu::Util qw(:check :is);

our $VERSION = "1.072";

with qw(Catmandu::AlephX::UserAgent);

has ua => (
  is => 'ro',
  lazy => 1,
  default => sub {
    my $ua = LWP::UserAgent->new(
      cookie_jar => {}
    );
    if(is_string($ENV{LWP_TRACE})){
      $ua->add_handler("request_send",  sub { shift->dump; return });
      $ua->add_handler("response_done", sub { shift->dump; return });
    }
    $ua;
  }
);

sub request {
  my($self,$params,$method)=@_;

  #default_args
  $params = { %{ $self->default_args() }, %$params };

  $method ||= "GET";
  my $res;
  if(uc($method) eq "GET"){
    $res = $self->_get($params);
  }elsif(uc($method) eq "POST"){
    $res = $self->_post($params);
  }else{
    confess "method $method not supported";
  }
  _validate_web_response($res);

  $res;
}

sub _validate_web_response {
  my($res) = @_;
  ($res->is_error || $res->content_type !~ /xml/io) && confess($res->content);
}
sub _post {
  my($self,$data)=@_;
  $self->ua->post($self->url,_construct_params_as_array($data));
}
sub _construct_query {
  my $data = shift;
  my @parts = ();
  for my $key(keys %$data){
    if(is_array_ref($data->{$key})){
      for my $val(@{ $data->{$key} }){
          push @parts,URI::Escape::uri_escape($key)."=".URI::Escape::uri_escape($val // "");
      }
    }else{
      push @parts,URI::Escape::uri_escape($key)."=".URI::Escape::uri_escape($data->{$key} // "");
    }
  }
  join("&",@parts);
}
sub _construct_params_as_array {
  my $params = shift;
  my @array = ();
  for my $key(keys %$params){
    if(is_array_ref($params->{$key})){
      #PHP only recognizes 'arrays' when their keys are appended by '[]' (yuk!)
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
  my($self,$data)=@_;
  my $query = _construct_query($data) || "";
  $self->ua->get($self->url."?$query");
}

1;
