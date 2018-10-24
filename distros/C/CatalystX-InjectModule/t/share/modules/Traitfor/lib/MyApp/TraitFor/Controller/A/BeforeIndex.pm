package MyApp::TraitFor::Controller::A::BeforeIndex;

use MooseX::MethodAttributes::Role;
use namespace::autoclean;

requires qw/
    index
/;

before 'index' => sub {
    my ( $self, $c ) = @_;

    $c->stash->{traitfor_beforeindex} = 1;
};
 
1;
