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

  return $self->layout3(sub {
    my $layout = shift;

    $self->content_for(foot=>'at the footer');
    return $layout->title.$content;
  }), "ggggg", $self->from_config;
}

__PACKAGE__->view(layout3 => ['Layout', title=>333]);

__PACKAGE__->config(
  content_type=>'text/html', 
  status_codes=>[200,404,400],
  views=>+{
    layout => [ Layout => sub { my ($self, $c) = @_; return title=>'Hey!' } ],
    layout2 => [ Layout => (title=>'Yeah!') ],
  },
);

__PACKAGE__->meta->make_immutable();
