package TrueTestApp::Controller::Root;

use Moose;
BEGIN { extends 'Catalyst::Controller::ActionRole' };

__PACKAGE__->config->{namespace} = '';

sub test :Local :Does(PseudoCache) PCTrueCache(1) {
   my ( $self, $c ) = @_;

   $c->response->body('we cached your stuff');
}

sub test_key :Local :Does(PseudoCache) PCTrueCache(1) PCkey('neatkey') {
    my ( $self, $c ) = @_;

    $c->response->body('we cached your stuff with your neat key');
}

sub peek_cache_test :Local {
   my ( $self, $c ) = @_;

   my $cache = $c->cache->get('TrueTestApp::Controller::Root/test');

   $c->response->body($cache);
}

sub peek_cache_key :Local {
   my ( $self, $c ) = @_;

   my $cache = $c->cache->get('TrueTestApp::Controller::Root/test_key');

   $c->response->body($cache);
}

sub end : Private :ActionClass(RenderView) {}

1;
