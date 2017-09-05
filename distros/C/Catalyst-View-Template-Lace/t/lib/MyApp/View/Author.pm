package  MyApp::View::Author;

use Moo;

extends 'Catalyst::View::Template::Lace';

has author => (is=>'ro', required=>1);

sub process_dom {
  my ($self, $dom) = @_;
  $dom->at('#author')
    ->content($self->author);
}

sub template {
  my $class = shift;
  return q[
    <style id="authorstyle">
      #author {
        background: white;
      }
    </style>
    <script id="authorscript">
    alert(1);
    </script>
    <script>calit(1,2);</script>
    <div id="author"></div>
  ];
}

1;
