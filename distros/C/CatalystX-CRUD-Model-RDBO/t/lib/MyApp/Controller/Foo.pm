package MyApp::Controller::Foo;
use strict;
use base qw( CatalystX::CRUD::Test::Controller );
use Carp;
use MyApp::Form::Foo;

__PACKAGE__->config(
    form_class            => 'MyApp::Form::Foo',
    form_fields           => [qw( id name )],
    init_form             => 'init_with_foo',
    init_object           => 'foo_from_form',
    default_template      => 'no/such/file',
    model_name            => 'Foo',
    primary_key           => 'id',
    view_on_single_result => 0,
    page_size             => 50,
    allow_GET_writes      => 0,
);

sub test : Local {

    my ( $self, $c, @arg ) = @_;

    my $thing = $c->model('Foo')->new_object( id => 1 );

    for my $m (qw( create read update delete )) {
        croak unless $thing->can($m);
    }

    # try fetching our seed data
    $thing->read();

    unless ( $thing->delegate->name eq 'blue' and $thing->name eq 'blue' ) {
        $c->error('bad read');
        return;
    }

    $c->res->body("foo is a-ok");

}

sub end : Private {
    my ( $self, $c ) = @_;
    $c->log->debug( "resp status = " . $c->res->status ) if $c->debug;
    if ( $c->stash->{results} ) {
        delete $c->stash->{results}->query->{query_obj};
        $c->res->body( Data::Dump::dump( $c->stash->{results}->query ) );
    }
    1;
}

1;
