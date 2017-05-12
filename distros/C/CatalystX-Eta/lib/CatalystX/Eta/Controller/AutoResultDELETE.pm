package CatalystX::Eta::Controller::AutoResultDELETE;

use Moose::Role;

requires 'result_DELETE';

around result_DELETE => \&AutoResult_around_result_DELETE;

sub AutoResult_around_result_DELETE {
    my $orig      = shift;
    my $self      = shift;
    my ($c)       = @_;
    my $config    = $self->config;
    my $something = $c->stash->{ $self->config->{object_key} };

    $self->status_gone( $c, message => 'object already deleted' ), $c->detach
      unless $something;

    if ( exists $self->config->{delete_roles} ) {
        my $do_detach = 0;
        if ( !$c->check_any_user_role( @{ $config->{delete_roles} } ) ) {
            $do_detach = 1;
        }

        # if he does not have the role, but is the creator...
        if (
               $do_detach == 1
            && exists $config->{object_key}
            && $c->stash->{ $config->{object_key} }
            && (   $c->stash->{ $config->{object_key} }->can('id')
                || $c->stash->{ $config->{object_key} }->can('user_id')
                || $c->stash->{ $config->{object_key} }->can('created_by') )
          ) {
            my $obj = $c->stash->{ $config->{object_key} };
            my $obj_id =
                $obj->can('created_by') && defined $obj->created_by ? $obj->created_by
              : $obj->can('user_id')    && defined $obj->user_id    ? $obj->user_id
              : $obj->can('roles')      && $obj->can('id')          ? $obj->id           # user it-self.
              :                                                       -999;              # false

            my $user_id = $c->user->id;

            $self->status_forbidden( $c, message => $config->{object_key} . ".invalid [$obj_id!=$user_id]", ),
              $c->detach
              if $obj_id != $user_id;

            $do_detach = 0;
        }

        if ($do_detach) {
            $self->status_forbidden( $c, message => "insufficient privileges" );
            $c->detach;
        }
    }

    $c->model('DB')->txn_do(
        sub {

            my $delete = 1;
            if ( ref $self->config->{before_delete} eq 'CODE' ) {
                $delete = $self->config->{before_delete}->( $self, $c, $something );
            }

            $something->delete if $delete;
        }
    );

    $self->status_no_content($c);
    $self->$orig(@_);
}

1;
