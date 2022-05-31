package MiniUA;
use strict;
use warnings;
use Plack::Test ();
use HTTP::Cookies;
use HTTP::Request::Common;

sub new {
  my ($class, $app, $opts) = @_;
  my $psgi
    = ref $app eq 'CODE' ? $app
    : do {
      eval "require $app;" or die $@;
      $app->psgi_app;
    };
  $opts ||= {};

  my $self = bless {
    psgi        => $psgi,
    plack_test  => Plack::Test->create($psgi),
    cookie_jar  => HTTP::Cookies->new(hide_cookie2 => 1),
    headers     => $opts,
  }, $class;
  return $self;
}

sub agent {
  my $self = shift;
  if (@_) {
    return $self->{headers}{'User-Agent'} = shift;
  }
  return $self->{headers}{'User-Agent'};
}

sub cookie_jar {
  my $self = shift;
  return $self->{cookie_jar};
}

sub request {
  my ($self, $req) = @_;
  my $pt = $self->{plack_test};
  my $jar = $self->cookie_jar;
  my $headers = $self->{headers};

  my $uri = $req->uri;
  $uri->scheme('http') unless defined $uri->scheme;
  $uri->host('localhost') unless defined $uri->host;

  $req->header(%$headers)
    if %$headers;

  $jar->add_cookie_header($req);

  my $res = $pt->request($req);
  $jar->extract_cookies($res);

  return $res;
}

sub get {
  my ($self, $url) = @_;
  $self->request(GET $url);
}

1;
