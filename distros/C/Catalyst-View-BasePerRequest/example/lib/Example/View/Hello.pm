package Example::View::Hello;

use Moose;

extends 'Catalyst::View::BasePerRequest';

has name => (is=>'ro', required=>1);
has age => (is=>'ro', required=>1);
has from_config => (is=>'ro', required=>1);

sub mytime { return scalar localtime }

sub render {
  my ($self, $c) = @_;
  my $content =  qq[
    <h1>Hello @{[ $self->name] }, at age @{[ $self->age ]}
    during @{[ $self->mytime ]} 
    with @{[ $c->stash->{test}||'NA' ]}</h1>
  ];

  return $c->view('Layout', title=>'hey!', sub {
    my $layout = shift;
    $self->content(foot=>'at the footer');
    return $layout->title.$content;
  }), "ggggg", $self->from_config;
}

__PACKAGE__->config(content_type=>'text/html', status_codes=>[200,404,400]);
__PACKAGE__->meta->make_immutable();
