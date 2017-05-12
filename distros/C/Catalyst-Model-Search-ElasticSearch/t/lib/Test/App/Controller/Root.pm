package Test::App::Controller::Root;
use base 'Catalyst::Controller';
use Data::Dumper;
__PACKAGE__->config(namespace => '');

sub test : Local {
  my ($self, $c) = @_;
  my $params = $c->req->params;
  my $search = $c->model('Search');
  my $results = $search->search(
    index => 'test',
    type  => 'test',
    body  => { query => { term => { schpongle => $params->{'q'} } } }
  );
  $c->res->body(Dumper $results);

}

sub dump_config : Local {
  my ($self, $c) = @_;
  $c->res->body( Dumper $c->config->{'Model::Search'} );
}
1;
