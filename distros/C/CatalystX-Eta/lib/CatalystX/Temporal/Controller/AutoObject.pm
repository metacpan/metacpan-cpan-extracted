package CatalystX::Temporal::Controller::AutoObject;

use Moose::Role;
requires 'object';

around object => \&AutoObject_around_object;

sub AutoObject_around_object {
    my $orig   = shift;
    my $self   = shift;
    my $config = $self->config;

    my ( $c, $id ) = @_;

    my $id_can_de_negative = $self->config->{id_can_de_negative} ? '-?' : '';

    $self->status_bad_request( $c, message => 'invalid.int' ), $c->detach
      unless $id =~ /^$id_can_de_negative[0-9]+$/;

    my $name = $self->config->{data_related_as};

    unless ( $c->req->params->{with_history} ) {
        $c->stash->{collection} = $c->stash->{collection}->search(
            {
                "$name.valid_to" => 'infinity'
            }
        );
    }

    $c->stash->{object} = $c->stash->{collection}->search( { "me.id" => $id } );

    $c->stash->{ $config->{object_key} } = $c->stash->{object}->next;

    $c->detach('/error_404') unless defined $c->stash->{ $config->{object_key} };

    $self->$orig(@_);
}

1;
