package TestApp;

use strict;
use warnings;
use Carp;

use Catalyst;
use Search::Estraier;

__PACKAGE__->config(
    name => 'TestApp',
    'Model::Search' => {
        url            => 'http://localhost:1978/node/test',
        user           => 'admin',
        passwd         => 'admin',
        croak_on_error => 1,
    },
);

__PACKAGE__->setup;

sub search :Local {
    my($self, $c) = @_;
    my $cond = Search::Estraier::Condition->new;
       $cond->set_phrase($c->req->param('q'));
    croak 'Bad model'
        unless UNIVERSAL::isa($c->model('Search'), 'Search::Estraier::Node');
    $c->res->content_type('text/plain');
    $c->res->body('ok');
}

1;
