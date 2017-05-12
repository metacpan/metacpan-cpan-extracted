package MyApp::Role::Verification::TransactionalActions;

use namespace::autoclean;
use Moose::Role;

use Data::Visitor::Callback;
requires '_wrap_in_transaction';

around action_specs => sub {
    my $orig    = shift;
    my $self    = shift;
    my $actions = $self->$orig(@_);

    my $v = Data::Visitor::Callback->new( code => sub { return $self->_wrap_in_transaction( $_[1] ) } );
    $actions = $v->visit($actions);
    return $actions;

};

1;
