package  MyApp::View::Loops;

use Moo;
extends 'Catalyst::View::Template::Lace';
with 'Catalyst::View::Template::Lace::Role::URI';

sub template {q[
  <view-master id='mainwrapper'
      title=\'title:content'
      css=\'@link'
      meta=\'@meta'
      body=\'body:content'>
    <html>
      <head>
        <title>Things To Do</title>
        <link href="/static/summary.css" rel="stylesheet"/>
        <link href="/static/core.css" rel="stylesheet"/>
      </head>
      <body>
        <h1>Loops</h1>
        <ul>
          <li><view-item name=$.name number=$.number /></li>
        </ul>
      </body>
    </html>
  </view-master>
]}

sub process_dom {
  my ($self, $dom) = @_;
  my @data = (
    +{ name=>'John', number=>34 },
    +{ name=>'Vanessa', number=>24 },
  );

  use Devel::Dwarn;
  $dom->at('ul li')
    ->repeat(sub {
      my ($dom, $data) = @_;
      warn $dom;
      Dwarn keys %{$self};
      Dwarn $self->components->component_info;
      #$self->context($dom, $data);
      return $dom;
    }, @data);

  $dom->for('ul li', \@data);  # should also work


}

1;
