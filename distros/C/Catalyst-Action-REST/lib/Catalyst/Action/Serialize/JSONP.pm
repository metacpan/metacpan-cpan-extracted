package Catalyst::Action::Serialize::JSONP;
$Catalyst::Action::Serialize::JSONP::VERSION = '1.20';
use Moose;
use namespace::autoclean;

extends 'Catalyst::Action::Serialize::JSON';

after 'execute' => sub {
  my $self = shift;
  my ($controller, $c) = @_;

  my $callback_key = (
    $controller->{'serialize'} ?
      $controller->{'serialize'}->{'callback_key'} :
      $controller->{'callback_key'}
    ) || 'callback';

  my $callback_value = $c->req->param($callback_key);
  if ($callback_value) {
    if ($callback_value =~ /^[.\w]+$/) {
      $c->res->content_type('text/javascript');
      $c->res->output($callback_value.'('.$c->res->output().');');
    } else {
      warn 'Callback: '.$callback_value.' will not generate valid Javascript. Falling back to JSON output';
    }
  }
};

__PACKAGE__->meta->make_immutable;

1;
