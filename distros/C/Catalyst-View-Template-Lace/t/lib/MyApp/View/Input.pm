package  MyApp::View::Input;

use Moo;
use Patterns::UndefObject::maybe;

extends 'Catalyst::View::Template::Lace';
with 'Template::Lace::ModelRole';

has [qw/id label name type container model/] => (is=>'ro');

has value => (
  is=>'ro',
  lazy=>1,
  default=>sub { $_[0]->container->maybe::fif->{$_[0]->name} },
);

has errors => (
  is=>'ro',
  lazy=>1,
  default=>sub { $_[0]->container->maybe::errors->{$_[0]->name} },
);

sub process_dom {
  my ($self, $dom) = @_;
  
  # Set Label content
  $dom->at('label')
    ->content($self->label)
    ->attr(for=>$self->name);

  # Set Input attributes
  $dom->at('input')->attr(
    type=>$self->type,
    value=>$self->value,
    id=>$self->id,
    name=>$self->name);

  # Set Errors or remove error block
  if($self->errors) {
    $dom->ol('.errors', $self->errors);
  } else {
    $dom->at("div.error")->remove;
  }
}

sub template {
  my $class = shift;
  return q[
    <link href="css/main.css" />
    <style id="min">
      div { border: 1px }
    </style>
    <div class="field">
      <label>LABEL</label>
      <input />
    </div>
    <div class="ui error message">
      <ol class='errors'>
        <li>ERROR</li>
      </ol>
    </div>
  ];
}

1;
