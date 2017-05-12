package Test::Serialize::View::Awful;

use base Catalyst::View;

sub render {
  my ($self, $c, $template) = @_;
  die "I don't know how to do that!";
}

sub process {
  my ($self, $c) = @_;

  my $output = eval {
    $self->render($c, "blah");
  };

  if ($@) {
    my $error = qq/Couldn't render template. Error: "$@"/;
    $c->error($error);
    return 0;
  }

  $c->res->body($output);
  return 1;
}

1;
