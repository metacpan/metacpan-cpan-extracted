package # (mst) I don't have perms to this and it's a final deprecation release
  Catalyst::Plugin::Authentication::Store::DBIC::User::CDBI;
use strict;
use base qw/Catalyst::Plugin::Authentication::Store::DBIC::User/;

sub store_session_data {
    my ( $self, $data ) = @_;
    my $col = $self->config->{auth}{session_data_field};
    my $obj = $self->obj;
    
    my $dbh = $obj->db_Main;
    local $dbh->{AutoCommit};
    $dbh->begin_work;
    $obj->$col($data);
    $obj->update;
    $dbh->commit;
}

# slow Class::DBI method
# Retrieve only as many roles as necessary to fail the check
sub _role_search {
    my ($self, @wanted_roles) = @_;
    my $cfg = $self->config->{authz};
    my $role_field = $cfg->{role_field};
    $cfg->{user_role_role_field} ||= $role_field;    

    my @roles;    
    for my $role ( @wanted_roles ) {
        if (my $role_obj = $cfg->{role_class}->search(
            { $role_field => $role } )->first)
        {
            if ( $cfg->{user_role_class}->search( {
                    $cfg->{user_role_user_field} => $self->obj->id,
                    $cfg->{user_role_role_field} => $role_obj->id,
                } ) )
            {
                push @roles, $role;
            } else {
                last;
            }
        } else {
            last;
        }
    }

    return @roles;
}

1;
