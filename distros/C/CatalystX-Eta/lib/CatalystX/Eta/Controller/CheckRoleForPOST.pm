package CatalystX::Eta::Controller::CheckRoleForPOST;

use Moose::Role;

requires 'list_POST';

around list_POST => \&CheckRoleForPOST_around_list_POST;

sub CheckRoleForPOST_around_list_POST {
    my $orig   = shift;
    my $self   = shift;
    my $config = $self->config;

    my ( $c, $id ) = @_;
    my $do_detach = 0;

    if ( exists $self->config->{create_roles} ) {
        if ( !$c->check_any_user_role( @{ $config->{create_roles} } ) ) {
            $self->status_forbidden( $c, message => "insufficient privileges" );
            $c->detach;
        }

    }
    $self->$orig(@_);
}

1;

