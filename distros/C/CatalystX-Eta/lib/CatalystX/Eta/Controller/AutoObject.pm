package CatalystX::Eta::Controller::AutoObject;

use Moose::Role;
requires 'object';

around object => \&AutoObject_around_object;

sub AutoObject_around_object {
    my $orig   = shift;
    my $self   = shift;
    my $config = $self->config;

    my ( $c, $id ) = @_;

    my $primary_column = $self->config->{primary_key_column} || 'id';

    $config->{object_verify_type} = !defined $config->{object_verify_type} ? 'int' : $config->{object_verify_type};

    unless ( $config->{object_verify_type} eq 'none' ) {

        if ( $config->{object_verify_type} eq 'int' ) {
            my $id_can_de_negative = $self->config->{id_can_de_negative} ? '-?' : '';
            $self->status_bad_request( $c, message => 'invalid.int' ), $c->detach
              unless $id =~ /^$id_can_de_negative[0-9]+$/;
        }
        elsif ( $config->{object_verify_type} eq 'uuid4' ) {
            $self->status_bad_request( $c, message => 'invalid.uuid' ), $c->detach
              unless $id =~ /[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89aAbB][a-f0-9]{3}-[a-f0-9]{12}/i;
        }
        else {
            $c->log->error(
                "CatalystX::Eta::Controller::AutoObject: unknown object_verify_type " . $config->{object_verify_type} );
        }

    }

    $c->stash->{object} = $c->stash->{collection}->search( { "me.$primary_column" => $id } );
    $c->stash->{ $config->{object_key} } = $c->stash->{object}->next;

    $c->detach('/error_404') unless defined $c->stash->{ $config->{object_key} };

    $self->$orig(@_);
}

1;
